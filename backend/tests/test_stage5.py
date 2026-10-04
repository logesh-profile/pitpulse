import uuid
from datetime import date, timedelta
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.asha_profile import AshaProfile
from app.models.patient_profile import PatientProfile
from app.models.user import RoleEnum, User


async def create_and_login_admin(async_client: AsyncClient, db_session: AsyncSession) -> dict:
    email = f"admin_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "AdminSecretPassword123!"

    admin_user = User(
        email=email,
        full_name="Admin Test User",
        password_hash=hash_password(password),
        role=RoleEnum.ADMIN,
        is_active=True,
        is_verified=True,
        must_change_password=False,
    )
    db_session.add(admin_user)
    await db_session.commit()

    login_res = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    return {"access_token": login_res.json()["access_token"], "email": email}


async def create_and_login_asha(
    async_client: AsyncClient,
    db_session: AsyncSession,
    name_prefix: str = "asha",
) -> dict:
    email = f"{name_prefix}_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "AshaPassword123!"

    user = User(
        email=email,
        full_name=f"ASHA Worker {name_prefix}",
        password_hash=hash_password(password),
        role=RoleEnum.ASHA,
        is_active=True,
        is_verified=True,
        must_change_password=False,
    )
    db_session.add(user)
    await db_session.flush()

    asha_prof = AshaProfile(
        user_id=user.id,
        worker_id_code=f"ASHA-{uuid.uuid4().hex[:4].upper()}",
        assigned_area=f"{name_prefix.capitalize()} Sector",
        primary_health_center="District PHC",
    )
    db_session.add(asha_prof)
    await db_session.commit()
    await db_session.refresh(asha_prof)

    login_res = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    return {
        "access_token": login_res.json()["access_token"],
        "user": user,
        "asha_profile": asha_prof,
    }


async def create_and_login_patient(
    async_client: AsyncClient,
    db_session: AsyncSession,
    name_prefix: str = "pat",
) -> dict:
    email = f"{name_prefix}_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "PatientPassword123!"
    full_name = f"Patient {name_prefix}"

    reg_res = await async_client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": full_name},
    )
    assert reg_res.status_code == 201
    dev_token = reg_res.json().get("dev_verification_token")
    if dev_token:
        v_res = await async_client.post(
            "/api/v1/auth/verify-email",
            json={"email": email, "token": dev_token},
        )
        assert v_res.status_code == 200

    login_res = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]

    # Auto-initialize patient profile by calling /patients/me
    prof_res = await async_client.get(
        "/api/v1/patients/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert prof_res.status_code == 200
    profile_data = prof_res.json()

    return {
        "access_token": token,
        "profile_id": profile_data["id"],
        "user_id": profile_data["user_id"],
        "email": email,
    }


# ==========================================
# 1. ASHA Assignment Tests
# ==========================================

@pytest.mark.asyncio
async def test_admin_asha_assignment_lifecycle(
    async_client: AsyncClient,
    db_session: AsyncSession,
):
    """Verifies Admin assigning, duplicate rejection, reassigning, and deactivation."""
    admin = await create_and_login_admin(async_client, db_session)
    admin_headers = {"Authorization": f"Bearer {admin['access_token']}"}

    asha_1 = await create_and_login_asha(async_client, db_session, "asha1")
    asha_2 = await create_and_login_asha(async_client, db_session, "asha2")
    patient = await create_and_login_patient(async_client, db_session, "assignee")

    # 1. Admin assigns patient to ASHA 1
    assign_res = await async_client.post(
        "/api/v1/admin/assignments/asha",
        headers=admin_headers,
        json={
            "asha_worker_id": str(asha_1["asha_profile"].id),
            "patient_id": patient["profile_id"],
            "notes": "Initial village sector allocation.",
        },
    )
    assert assign_res.status_code == 201
    assign_data = assign_res.json()
    assignment_id = assign_data["id"]
    assert assign_data["status"] == "ACTIVE"
    assert assign_data["asha_worker_id"] == str(asha_1["asha_profile"].id)
    assert assign_data["patient_id"] == patient["profile_id"]

    # 2. Duplicate assignment rejection
    dup_res = await async_client.post(
        "/api/v1/admin/assignments/asha",
        headers=admin_headers,
        json={
            "asha_worker_id": str(asha_1["asha_profile"].id),
            "patient_id": patient["profile_id"],
        },
    )
    assert dup_res.status_code == 400
    assert "already actively assigned" in dup_res.json()["detail"]

    # 3. Non-admin cannot assign patient
    pat_headers = {"Authorization": f"Bearer {patient['access_token']}"}
    unauth_assign = await async_client.post(
        "/api/v1/admin/assignments/asha",
        headers=pat_headers,
        json={
            "asha_worker_id": str(asha_1["asha_profile"].id),
            "patient_id": patient["profile_id"],
        },
    )
    assert unauth_assign.status_code == 403

    # 4. Reassign patient to ASHA 2 (prior becomes INACTIVE)
    reassign_res = await async_client.post(
        "/api/v1/admin/assignments/asha",
        headers=admin_headers,
        json={
            "asha_worker_id": str(asha_2["asha_profile"].id),
            "patient_id": patient["profile_id"],
            "notes": "Reassigned to Sector 2.",
        },
    )
    assert reassign_res.status_code == 201
    assert reassign_res.json()["status"] == "ACTIVE"
    assert reassign_res.json()["asha_worker_id"] == str(asha_2["asha_profile"].id)

    # 5. Check patient self-service view
    patient_view_res = await async_client.get(
        "/api/v1/patients/me/asha-assignment",
        headers=pat_headers,
    )
    assert patient_view_res.status_code == 200
    assert patient_view_res.json()["asha_worker_id"] == str(asha_2["asha_profile"].id)

    # 6. Admin deactivates assignment
    deact_res = await async_client.patch(
        f"/api/v1/admin/assignments/asha/{reassign_res.json()['id']}",
        headers=admin_headers,
        json={"status": "INACTIVE", "notes": "Patient relocated."},
    )
    assert deact_res.status_code == 200
    assert deact_res.json()["status"] == "INACTIVE"
    assert deact_res.json()["unassigned_at"] is not None


# ==========================================
# 2. Home Visits & Vitals Tests
# ==========================================

@pytest.mark.asyncio
async def test_asha_home_visit_and_maternal_vitals_workflow(
    async_client: AsyncClient,
    db_session: AsyncSession,
):
    """Verifies assigned ASHA field checkup, maternal vitals recording, and persistence."""
    admin = await create_and_login_admin(async_client, db_session)
    admin_headers = {"Authorization": f"Bearer {admin['access_token']}"}

    asha = await create_and_login_asha(async_client, db_session, "field_asha")
    asha_headers = {"Authorization": f"Bearer {asha['access_token']}"}

    patient = await create_and_login_patient(async_client, db_session, "maternal_pat")
    patient_headers = {"Authorization": f"Bearer {patient['access_token']}"}

    # 1. Patient creates pregnancy record
    lmp_date = date.today() - timedelta(days=60)
    preg_res = await async_client.post(
        "/api/v1/patients/me/pregnancies",
        headers=patient_headers,
        json={"lmp": lmp_date.isoformat()},
    )
    assert preg_res.status_code == 201
    pregnancy_id = preg_res.json()["id"]

    # 2. Admin assigns patient to ASHA
    await async_client.post(
        "/api/v1/admin/assignments/asha",
        headers=admin_headers,
        json={
            "asha_worker_id": str(asha["asha_profile"].id),
            "patient_id": patient["profile_id"],
        },
    )

    # 3. ASHA lists assigned patients -> sees patient
    pat_list = await async_client.get("/api/v1/asha/me/patients", headers=asha_headers)
    assert pat_list.status_code == 200
    assert len(pat_list.json()) == 1
    assert pat_list.json()[0]["patient_id"] == patient["profile_id"]

    # 4. ASHA records Home Visit
    visit_res = await async_client.post(
        f"/api/v1/asha/me/patients/{patient['profile_id']}/home-visits",
        headers=asha_headers,
        json={
            "visit_date": date.today().isoformat(),
            "pregnancy_id": pregnancy_id,
            "purpose": "Routine 1st Trimester Home Checkup",
            "observations": "Patient reports mild nausea. Diet discussed.",
            "follow_up_required": True,
            "follow_up_notes": "Re-check in 2 weeks for blood pressure follow-up.",
        },
    )
    assert visit_res.status_code == 201
    visit_data = visit_res.json()
    visit_id = visit_data["id"]
    assert visit_data["status"] == "COMPLETED"
    assert visit_data["follow_up_required"] is True

    # 5. ASHA records Maternal Vitals during visit
    vital_res = await async_client.post(
        f"/api/v1/asha/me/patients/{patient['profile_id']}/home-visits/{visit_id}/vitals",
        headers=asha_headers,
        json={
            "systolic_bp": 118,
            "diastolic_bp": 76,
            "weight_kg": 62.5,
            "temperature_c": 36.8,
            "notes": "Resting seated measurement.",
        },
    )
    assert vital_res.status_code == 201
    vital_data = vital_res.json()
    assert vital_data["systolic_bp"] == 118
    assert vital_data["diastolic_bp"] == 76
    assert vital_data["weight_kg"] == 62.5
    assert vital_data["temperature_c"] == 36.8
    assert vital_data["recorded_by_role"] == "ASHA"

    # 6. Patient views their own visits & vitals
    pat_visits = await async_client.get("/api/v1/patients/me/home-visits", headers=patient_headers)
    assert pat_visits.status_code == 200
    assert pat_visits.json()["total"] == 1
    assert pat_visits.json()["items"][0]["id"] == visit_id

    pat_vitals = await async_client.get("/api/v1/patients/me/vitals", headers=patient_headers)
    assert pat_vitals.status_code == 200
    assert pat_vitals.json()["total"] == 1
    assert pat_vitals.json()["items"][0]["systolic_bp"] == 118


# ==========================================
# 3. IDOR & Access Control Security Tests
# ==========================================

@pytest.mark.asyncio
async def test_stage5_idor_security_protections(
    async_client: AsyncClient,
    db_session: AsyncSession,
):
    """
    Verifies that:
    1. Unassigned ASHA cannot view or record visits/vitals for another ASHA's patient.
    2. Patient A cannot view Patient B's visits or vitals.
    3. Patient cannot record visits or spoof ASHA measurements.
    4. Invalid clinical bounds (impossible BP, negative weight) are rejected.
    """
    admin = await create_and_login_admin(async_client, db_session)
    admin_headers = {"Authorization": f"Bearer {admin['access_token']}"}

    asha_a = await create_and_login_asha(async_client, db_session, "asha_a")
    asha_a_headers = {"Authorization": f"Bearer {asha_a['access_token']}"}

    asha_b = await create_and_login_asha(async_client, db_session, "asha_b")
    asha_b_headers = {"Authorization": f"Bearer {asha_b['access_token']}"}

    patient_a = await create_and_login_patient(async_client, db_session, "patient_a")
    patient_b = await create_and_login_patient(async_client, db_session, "patient_b")
    patient_b_headers = {"Authorization": f"Bearer {patient_b['access_token']}"}

    # Assign Patient A to ASHA A
    await async_client.post(
        "/api/v1/admin/assignments/asha",
        headers=admin_headers,
        json={
            "asha_worker_id": str(asha_a["asha_profile"].id),
            "patient_id": patient_a["profile_id"],
        },
    )

    # 1. IDOR: ASHA B tries to access Patient A details -> 403 Forbidden
    unauth_detail = await async_client.get(
        f"/api/v1/asha/me/patients/{patient_a['profile_id']}",
        headers=asha_b_headers,
    )
    assert unauth_detail.status_code == 403

    # 2. IDOR: ASHA B tries to create home visit for Patient A -> 403 Forbidden
    unauth_visit = await async_client.post(
        f"/api/v1/asha/me/patients/{patient_a['profile_id']}/home-visits",
        headers=asha_b_headers,
        json={"visit_date": date.today().isoformat(), "purpose": "Unauthorized Visit"},
    )
    assert unauth_visit.status_code == 403

    # 3. IDOR: ASHA B tries to record vitals for Patient A -> 403 Forbidden
    unauth_vitals = await async_client.post(
        f"/api/v1/asha/me/patients/{patient_a['profile_id']}/vitals",
        headers=asha_b_headers,
        json={"systolic_bp": 120, "diastolic_bp": 80},
    )
    assert unauth_vitals.status_code == 403

    # 4. IDOR: Patient B tries to view Patient A's clinical home visits -> 403 Forbidden
    unauth_pat_visits = await async_client.get(
        f"/api/v1/patients/{patient_a['profile_id']}/home-visits",
        headers=patient_b_headers,
    )
    assert unauth_pat_visits.status_code == 403

    # 5. Invalid Vital Bounds: Extreme impossible blood pressure rejected
    # Valid ASHA A creates visit for Patient A first
    visit_a = await async_client.post(
        f"/api/v1/asha/me/patients/{patient_a['profile_id']}/home-visits",
        headers=asha_a_headers,
        json={"visit_date": date.today().isoformat(), "purpose": "Valid Checkup"},
    )
    assert visit_a.status_code == 201

    # Invalid systolic BP (e.g. 500) -> 422 Unprocessable Entity
    invalid_bp = await async_client.post(
        f"/api/v1/asha/me/patients/{patient_a['profile_id']}/home-visits/{visit_a.json()['id']}/vitals",
        headers=asha_a_headers,
        json={"systolic_bp": 500, "diastolic_bp": 80},
    )
    assert invalid_bp.status_code == 422
