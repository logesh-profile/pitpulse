import uuid
from datetime import date, datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.asha_patient_assignment import (
    AshaPatientAssignment,
    AssignmentStatusEnum,
)
from app.models.asha_profile import AshaProfile
from app.models.doctor_profile import DoctorProfile
from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.user import RoleEnum, User
from app.models.verification_token import TokenTypeEnum, VerificationToken


async def create_admin_token(async_client: AsyncClient, db_session: AsyncSession) -> str:
    email = f"admin_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "AdminPassword123!"
    admin = User(
        email=email,
        full_name="Admin Master",
        password_hash=hash_password(password),
        role=RoleEnum.ADMIN,
        is_active=True,
        is_verified=True,
    )
    db_session.add(admin)
    await db_session.commit()

    res = await async_client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert res.status_code == 200
    return res.json()["access_token"]


async def create_verified_patient(async_client: AsyncClient) -> dict:
    email = f"patient_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "PatientPass123!"
    reg_res = await async_client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Verified Patient"},
    )
    assert reg_res.status_code == 201
    dev_token = reg_res.json()["dev_verification_token"]

    ver_res = await async_client.post("/api/v1/auth/verify-email", json={"token": dev_token})
    assert ver_res.status_code == 200

    login_res = await async_client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]

    prof_res = await async_client.get("/api/v1/patients/me", headers={"Authorization": f"Bearer {token}"})
    assert prof_res.status_code == 200

    return {
        "email": email,
        "password": password,
        "token": token,
        "patient_id": prof_res.json()["id"],
        "user_id": prof_res.json()["user_id"],
    }


@pytest.mark.asyncio
async def test_email_verification_lifecycle(async_client: AsyncClient, db_session: AsyncSession):
    """1. Test that unverified patients cannot log in, and email verification unlocks login."""
    email = f"unverified_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "Password123!"

    reg_res = await async_client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Test Unverified"},
    )
    assert reg_res.status_code == 201
    token = reg_res.json()["dev_verification_token"]

    # Login before verification must fail with 403
    login_fail = await async_client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert login_fail.status_code == 403
    assert "Email verification required" in login_fail.json()["detail"]

    # Invalid token must fail
    bad_token_res = await async_client.post("/api/v1/auth/verify-email", json={"token": "InvalidToken1234567890"})
    assert bad_token_res.status_code == 400

    # Successful verification
    ver_res = await async_client.post("/api/v1/auth/verify-email", json={"token": token})
    assert ver_res.status_code == 200
    assert ver_res.json()["is_verified"] is True

    # Reusing token must fail (single-use constraint)
    reuse_res = await async_client.post("/api/v1/auth/verify-email", json={"token": token})
    assert reuse_res.status_code == 400

    # Login now succeeds
    login_success = await async_client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert login_success.status_code == 200
    assert login_success.json()["user"]["is_verified"] is True


@pytest.mark.asyncio
async def test_professional_activation_workflow(async_client: AsyncClient, db_session: AsyncSession):
    """2. Test Admin provisioning Doctor -> Activation token -> Doctor sets password and activates."""
    admin_token = await create_admin_token(async_client, db_session)
    doctor_email = f"doc_act_{uuid.uuid4().hex[:8]}@pitpulse.org"

    prov_res = await async_client.post(
        "/api/v1/admin/users/doctors",
        json={
            "email": doctor_email,
            "full_name": "Dr. Activation Test",
            "medical_license_number": "MED-ACT-1234",
            "facility_name": "Community Health Center",
        },
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert prov_res.status_code == 201
    act_token = prov_res.json()["activation_token"]
    assert act_token is not None

    # Doctor activates account and sets permanent password
    new_password = "DoctorPermanentPass123!"
    act_res = await async_client.post(
        "/api/v1/auth/activate-professional",
        json={"token": act_token, "new_password": new_password},
    )
    assert act_res.status_code == 200
    doc_data = act_res.json()
    assert doc_data["user"]["email"] == doctor_email
    assert doc_data["user"]["role"] == "DOCTOR"
    assert doc_data["user"]["is_verified"] is True
    assert doc_data["user"]["must_change_password"] is False
    assert "access_token" in doc_data

    # Regular login works with new password
    login_res = await async_client.post(
        "/api/v1/auth/login",
        json={"email": doctor_email, "password": new_password},
    )
    assert login_res.status_code == 200


@pytest.mark.asyncio
async def test_doctor_clinical_coordination_and_asha_assignment(async_client: AsyncClient, db_session: AsyncSession):
    """3. Test Doctor views unassigned patients, available ASHAs, and assigns ASHA to patient."""
    admin_token = await create_admin_token(async_client, db_session)

    # 1. Provision & activate Doctor
    doc_email = f"doctor_{uuid.uuid4().hex[:8]}@pitpulse.org"
    doc_prov = await async_client.post(
        "/api/v1/admin/users/doctors",
        json={"email": doc_email, "full_name": "Dr. Clinical Lead", "facility_name": "PHC North"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    doc_act_token = doc_prov.json()["activation_token"]
    doc_login = await async_client.post(
        "/api/v1/auth/activate-professional",
        json={"token": doc_act_token, "new_password": "DoctorPassword123!"},
    )
    doc_token = doc_login.json()["access_token"]

    # 2. Provision & activate ASHA
    asha_email = f"asha_{uuid.uuid4().hex[:8]}@pitpulse.org"
    asha_prov = await async_client.post(
        "/api/v1/admin/users/asha-workers",
        json={"email": asha_email, "full_name": "Kavita Devi", "primary_health_center": "PHC North"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    asha_act_token = asha_prov.json()["activation_token"]
    asha_login = await async_client.post(
        "/api/v1/auth/activate-professional",
        json={"token": asha_act_token, "new_password": "AshaPassword123!"},
    )
    asha_token = asha_login.json()["access_token"]
    asha_user_id = asha_login.json()["user"]["id"]

    # Lookup ASHA profile ID
    stmt = select(AshaProfile).where(AshaProfile.user_id == uuid.UUID(asha_user_id))
    res = await db_session.execute(stmt)
    asha_profile = res.scalar_one()

    # 3. Create Patient with active pregnancy
    patient = await create_verified_patient(async_client)
    await async_client.post(
        "/api/v1/patients/me/pregnancies",
        json={"lmp": (date.today() - timedelta(days=120)).isoformat()},
        headers={"Authorization": f"Bearer {patient['token']}"},
    )

    # 4. Doctor checks unassigned patients roster
    unassigned_res = await async_client.get(
        "/api/v1/doctor/me/patients/unassigned",
        headers={"Authorization": f"Bearer {doc_token}"},
    )
    assert unassigned_res.status_code == 200
    unassigned_list = unassigned_res.json()["items"]
    assert any(p["patient_id"] == patient["patient_id"] for p in unassigned_list)

    # 5. Doctor checks available ASHAs
    ashas_res = await async_client.get(
        "/api/v1/doctor/me/available-asha",
        headers={"Authorization": f"Bearer {doc_token}"},
    )
    assert ashas_res.status_code == 200
    assert any(a["asha_id"] == str(asha_profile.id) for a in ashas_res.json()["items"])

    # 6. Doctor assigns ASHA to Patient
    assign_res = await async_client.post(
        f"/api/v1/doctor/me/patients/{patient['patient_id']}/asha-assignment",
        json={"asha_worker_id": str(asha_profile.id), "notes": "Assigned by Doctor for high-priority prenatal care."},
        headers={"Authorization": f"Bearer {doc_token}"},
    )
    assert assign_res.status_code == 201
    assert assign_res.json()["status"] == "ACTIVE"

    # 7. Patient is no longer in unassigned list
    unassigned_after = await async_client.get(
        "/api/v1/doctor/me/patients/unassigned",
        headers={"Authorization": f"Bearer {doc_token}"},
    )
    assert not any(p["patient_id"] == patient["patient_id"] for p in unassigned_after.json()["items"])

    # 8. Assigned ASHA now sees Patient in their field roster
    asha_patients = await async_client.get(
        "/api/v1/asha/me/patients",
        headers={"Authorization": f"Bearer {asha_token}"},
    )
    assert asha_patients.status_code == 200
    assert any(p["patient_id"] == patient["patient_id"] for p in asha_patients.json())


@pytest.mark.asyncio
async def test_idor_protection_generic_pregnancy_and_profile_routes(async_client: AsyncClient, db_session: AsyncSession):
    """4. Verify that unassigned ASHA cannot query generic /patients/{id}/pregnancies or /patients/{id}."""
    admin_token = await create_admin_token(async_client, db_session)

    # Create unassigned ASHA
    asha_email = f"unassigned_asha_{uuid.uuid4().hex[:8]}@pitpulse.org"
    asha_prov = await async_client.post(
        "/api/v1/admin/users/asha-workers",
        json={"email": asha_email, "full_name": "Unassigned ASHA"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    act_token = asha_prov.json()["activation_token"]
    asha_login = await async_client.post(
        "/api/v1/auth/activate-professional",
        json={"token": act_token, "new_password": "AshaPassword123!"},
    )
    unassigned_asha_token = asha_login.json()["access_token"]

    # Create Patient with pregnancy
    patient = await create_verified_patient(async_client)
    await async_client.post(
        "/api/v1/patients/me/pregnancies",
        json={"lmp": (date.today() - timedelta(days=90)).isoformat()},
        headers={"Authorization": f"Bearer {patient['token']}"},
    )

    # Unassigned ASHA tries to access generic patient profile -> 403
    prof_res = await async_client.get(
        f"/api/v1/patients/{patient['patient_id']}",
        headers={"Authorization": f"Bearer {unassigned_asha_token}"},
    )
    assert prof_res.status_code == 403
    assert "not actively assigned" in prof_res.json()["detail"]

    # Unassigned ASHA tries to access generic pregnancy list -> 403
    preg_res = await async_client.get(
        f"/api/v1/patients/{patient['patient_id']}/pregnancies",
        headers={"Authorization": f"Bearer {unassigned_asha_token}"},
    )
    assert preg_res.status_code == 403
    assert "not actively assigned" in preg_res.json()["detail"]
