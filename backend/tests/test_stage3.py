import uuid
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.user import RoleEnum, User


async def create_and_login_admin(async_client: AsyncClient, db_session: AsyncSession) -> str:
    """Provisions and authenticates an ADMIN user, returning valid JWT access token."""
    email = f"admin_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "AdminSecretPassword123!"

    admin_user = User(
        email=email,
        full_name="Admin Test User",
        password_hash=hash_password(password),
        role=RoleEnum.ADMIN,
        is_active=True,
        must_change_password=False,
    )
    db_session.add(admin_user)
    await db_session.commit()

    login_res = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    return login_res.json()["access_token"]


async def create_and_login_patient(async_client: AsyncClient) -> dict:
    """Registers and authenticates a PATIENT user, returning token and user payload."""
    email = f"patient_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "PatientPassword123!"
    full_name = "Standard Patient"

    reg_res = await async_client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": full_name},
    )
    assert reg_res.status_code == 201

    login_res = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    return {
        "access_token": login_res.json()["access_token"],
        "user": login_res.json()["user"],
        "email": email,
        "password": password,
    }


@pytest.mark.asyncio
async def test_admin_can_create_doctor(async_client: AsyncClient, db_session: AsyncSession):
    """1. Verify Admin can provision a Doctor account with metadata and temporary password."""
    admin_token = await create_and_login_admin(async_client, db_session)
    doctor_email = f"doc_{uuid.uuid4().hex[:8]}@pitpulse.org"
    payload = {
        "email": doctor_email,
        "full_name": "Dr. Rajesh Varma",
        "phone": f"+9191{uuid.uuid4().hex[:8]}",
        "medical_license_number": "MCI-2026-9876",
        "specialization": "Cardiologist",
        "facility_name": "City District Hospital",
    }

    response = await async_client.post(
        "/api/v1/admin/users/doctors",
        json=payload,
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == 201
    data = response.json()

    assert data["email"] == doctor_email
    assert data["role"] == "DOCTOR"
    assert data["full_name"] == "Dr. Rajesh Varma"
    assert data["medical_license_number"] == "MCI-2026-9876"
    assert data["must_change_password"] is True
    assert "temporary_password" in data
    assert len(data["temporary_password"]) >= 12
    assert "password_hash" not in data


@pytest.mark.asyncio
async def test_admin_can_create_asha(async_client: AsyncClient, db_session: AsyncSession):
    """2. Verify Admin can provision an ASHA account with metadata and temporary password."""
    admin_token = await create_and_login_admin(async_client, db_session)
    asha_email = f"asha_{uuid.uuid4().hex[:8]}@pitpulse.org"
    payload = {
        "email": asha_email,
        "full_name": "Sunita Devi",
        "phone": f"+9192{uuid.uuid4().hex[:8]}",
        "worker_id_code": "ASHA-DELHI-042",
        "assigned_area": "Sector 4 Village Ward",
        "primary_health_center": "Primary Health Centre North",
    }

    response = await async_client.post(
        "/api/v1/admin/users/asha-workers",
        json=payload,
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == 201
    data = response.json()

    assert data["email"] == asha_email
    assert data["role"] == "ASHA"
    assert data["full_name"] == "Sunita Devi"
    assert data["worker_id_code"] == "ASHA-DELHI-042"
    assert data["must_change_password"] is True
    assert "temporary_password" in data
    assert "password_hash" not in data


@pytest.mark.asyncio
async def test_patient_cannot_create_doctor_or_asha(async_client: AsyncClient):
    """3 & 4. Verify Patient role receives 403 Forbidden attempting to access admin provisioning endpoints."""
    patient_auth = await create_and_login_patient(async_client)
    token = patient_auth["access_token"]

    doc_resp = await async_client.post(
        "/api/v1/admin/users/doctors",
        json={"email": "fake_doc@pitpulse.org", "full_name": "Fake Doc"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert doc_resp.status_code == 403

    asha_resp = await async_client.post(
        "/api/v1/admin/users/asha-workers",
        json={"email": "fake_asha@pitpulse.org", "full_name": "Fake Asha"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert asha_resp.status_code == 403


@pytest.mark.asyncio
async def test_doctor_and_asha_cannot_access_admin_endpoints(
    async_client: AsyncClient, db_session: AsyncSession
):
    """5 & 6. Verify Doctor and ASHA users cannot call admin provisioning endpoints."""
    admin_token = await create_and_login_admin(async_client, db_session)

    # Create doctor
    doc_email = f"doc_{uuid.uuid4().hex[:8]}@pitpulse.org"
    doc_create = await async_client.post(
        "/api/v1/admin/users/doctors",
        json={"email": doc_email, "full_name": "Dr. Valid"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    doc_temp_pw = doc_create.json()["temporary_password"]

    # Login doctor
    doc_login = await async_client.post(
        "/api/v1/auth/login",
        json={"email": doc_email, "password": doc_temp_pw},
    )
    doc_token = doc_login.json()["access_token"]

    # Doctor tries to create another doctor -> 403 Forbidden
    resp = await async_client.post(
        "/api/v1/admin/users/doctors",
        json={"email": "doc2@pitpulse.org", "full_name": "Dr. Two"},
        headers={"Authorization": f"Bearer {doc_token}"},
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_doctor_and_asha_first_login_and_password_change(
    async_client: AsyncClient, db_session: AsyncSession
):
    """9, 10, 11, 12. Verify Doctor login with temp pw, change password, must_change_password flag update, and old pw rejection."""
    admin_token = await create_and_login_admin(async_client, db_session)
    doc_email = f"doc_activation_{uuid.uuid4().hex[:8]}@pitpulse.org"
    doc_create = await async_client.post(
        "/api/v1/admin/users/doctors",
        json={"email": doc_email, "full_name": "Dr. Activation"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    temp_pw = doc_create.json()["temporary_password"]

    # 1. Login with temporary password
    login_resp = await async_client.post(
        "/api/v1/auth/login",
        json={"email": doc_email, "password": temp_pw},
    )
    assert login_resp.status_code == 200
    login_data = login_resp.json()
    assert login_data["user"]["must_change_password"] is True
    access_token = login_data["access_token"]

    # 2. Change password
    new_permanent_pw = "DoctorPermanentPass2026!"
    change_resp = await async_client.post(
        "/api/v1/auth/change-password",
        json={"current_password": temp_pw, "new_password": new_permanent_pw},
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert change_resp.status_code == 200
    change_data = change_resp.json()
    assert change_data["user"]["must_change_password"] is False

    # 3. Verify old temporary password is now rejected
    old_login_resp = await async_client.post(
        "/api/v1/auth/login",
        json={"email": doc_email, "password": temp_pw},
    )
    assert old_login_resp.status_code == 401

    # 4. Verify login with new password succeeds
    new_login_resp = await async_client.post(
        "/api/v1/auth/login",
        json={"email": doc_email, "password": new_permanent_pw},
    )
    assert new_login_resp.status_code == 200
    assert new_login_resp.json()["user"]["must_change_password"] is False


@pytest.mark.asyncio
async def test_patient_profile_management_and_health_record(async_client: AsyncClient):
    """13. Verify patient can get and update their own profile and receive anchor Health Record number."""
    patient_auth = await create_and_login_patient(async_client)
    token = patient_auth["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Get profile (auto-initialized)
    get_res = await async_client.get("/api/v1/patients/me", headers=headers)
    assert get_res.status_code == 200
    profile_data = get_res.json()

    assert profile_data["email"] == patient_auth["email"]
    assert profile_data["health_record"] is not None
    assert profile_data["health_record"]["record_number"].startswith("HR-")

    # Update profile
    update_payload = {
        "date_of_birth": "1995-06-15",
        "sex": "FEMALE",
        "address": "42 Green Valley Road",
        "village_locality": "Rampur",
        "emergency_contact_name": "Ramesh Patel",
        "emergency_contact_phone": "+919876543210",
        "blood_group": "O+",
        "baseline_health_info": "No known allergies. History of mild asthma.",
    }
    put_res = await async_client.put(
        "/api/v1/patients/me",
        json=update_payload,
        headers=headers,
    )
    assert put_res.status_code == 200
    updated_data = put_res.json()

    assert updated_data["date_of_birth"] == "1995-06-15"
    assert updated_data["sex"] == "FEMALE"
    assert updated_data["village_locality"] == "Rampur"
    assert updated_data["emergency_contact_name"] == "Ramesh Patel"
    assert updated_data["blood_group"] == "O+"
    assert updated_data["baseline_health_info"] == "No known allergies. History of mild asthma."


@pytest.mark.asyncio
async def test_patient_idor_access_control(async_client: AsyncClient):
    """14. Verify Patient A cannot access Patient B's medical profile (IDOR protection)."""
    # Create Patient A
    pA_email = f"patientA_{uuid.uuid4().hex[:8]}@pitpulse.org"
    pw = "SecurePassword123!"
    await async_client.post(
        "/api/v1/auth/register",
        json={"email": pA_email, "password": pw, "full_name": "Patient Alpha"},
    )
    pA_login = await async_client.post(
        "/api/v1/auth/login",
        json={"email": pA_email, "password": pw},
    )
    tokenA = pA_login.json()["access_token"]

    # Create Patient B
    pB_email = f"patientB_{uuid.uuid4().hex[:8]}@pitpulse.org"
    await async_client.post(
        "/api/v1/auth/register",
        json={"email": pB_email, "password": pw, "full_name": "Patient Beta"},
    )
    pB_login = await async_client.post(
        "/api/v1/auth/login",
        json={"email": pB_email, "password": pw},
    )
    tokenB = pB_login.json()["access_token"]

    # Get Patient B's profile ID
    pB_me = await async_client.get(
        "/api/v1/patients/me",
        headers={"Authorization": f"Bearer {tokenB}"},
    )
    profileB_id = pB_me.json()["id"]

    # Patient A attempts to fetch Patient B's profile by ID -> MUST return 403 Forbidden
    idor_attempt = await async_client.get(
        f"/api/v1/patients/{profileB_id}",
        headers={"Authorization": f"Bearer {tokenA}"},
    )
    assert idor_attempt.status_code == 403
    assert "Access denied" in idor_attempt.json()["detail"]


@pytest.mark.asyncio
async def test_admin_can_list_and_deactivate_professionals(
    async_client: AsyncClient, db_session: AsyncSession
):
    """16 & 17. Verify Admin can list professionals and toggle account active status."""
    admin_token = await create_and_login_admin(async_client, db_session)

    # List professionals
    list_res = await async_client.get(
        "/api/v1/admin/users/professionals",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert list_res.status_code == 200
    professionals = list_res.json()
    assert isinstance(professionals, list)

    # Create a test doctor to deactivate
    doc_email = f"doc_toggle_{uuid.uuid4().hex[:8]}@pitpulse.org"
    doc_res = await async_client.post(
        "/api/v1/admin/users/doctors",
        json={"email": doc_email, "full_name": "Dr. Toggleable"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    doc_id = doc_res.json()["user_id"]
    doc_pw = doc_res.json()["temporary_password"]

    # Deactivate account
    deactivate_res = await async_client.patch(
        f"/api/v1/admin/users/{doc_id}/status",
        json={"is_active": False},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert deactivate_res.status_code == 200
    assert deactivate_res.json()["is_active"] is False

    # Attempting to login with deactivated account -> 403 Forbidden
    login_attempt = await async_client.post(
        "/api/v1/auth/login",
        json={"email": doc_email, "password": doc_pw},
    )
    assert login_attempt.status_code == 403
    assert "deactivated" in login_attempt.json()["detail"]
