import uuid
from datetime import date, timedelta
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.user import RoleEnum, User
from app.utils.pregnancy_calculations import (
    calculate_edd,
    calculate_gestational_age,
    calculate_trimester,
)


async def create_and_login_patient(async_client: AsyncClient, name_prefix: str = "patient") -> dict:
    """Registers and authenticates a real patient user."""
    email = f"{name_prefix}_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "PatientPassword123!"
    full_name = f"Test Patient {name_prefix}"

    reg_res = await async_client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": full_name},
    )
    assert reg_res.status_code == 201
    dev_token = reg_res.json()["dev_verification_token"]
    await async_client.post("/api/v1/auth/verify-email", json={"token": dev_token})

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


async def create_and_login_doctor(async_client: AsyncClient, db_session: AsyncSession) -> dict:
    """Provisions and authenticates a doctor user."""
    email = f"doctor_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "DoctorPassword123!"

    doc = User(
        email=email,
        full_name="Dr. Tester",
        password_hash=hash_password(password),
        role=RoleEnum.DOCTOR,
        is_active=True,
        is_verified=True,
        must_change_password=False,
    )
    db_session.add(doc)
    await db_session.commit()

    login_res = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    return {"access_token": login_res.json()["access_token"]}


# ==========================================
# 1. Deterministic Calculation Unit Tests
# ==========================================

def test_deterministic_pregnancy_calculations():
    lmp = date(2026, 1, 1)
    
    # 1. EDD calculation (LMP + 280 days)
    edd = calculate_edd(lmp)
    assert edd == lmp + timedelta(days=280)
    assert edd == date(2026, 10, 8)

    # 2. Gestational age calculation
    # As of 70 days later (10 weeks 0 days)
    as_of_70 = lmp + timedelta(days=70)
    weeks, days, display = calculate_gestational_age(lmp, as_of=as_of_70)
    assert weeks == 10
    assert days == 0
    assert display == "10 weeks 0 days"

    # As of 73 days later (10 weeks 3 days)
    as_of_73 = lmp + timedelta(days=73)
    weeks, days, display = calculate_gestational_age(lmp, as_of=as_of_73)
    assert weeks == 10
    assert days == 3
    assert display == "10 weeks 3 days"

    # 3. Trimester calculation
    assert calculate_trimester(10) == (1, "1st Trimester")
    assert calculate_trimester(12) == (1, "1st Trimester")
    assert calculate_trimester(13) == (2, "2nd Trimester")
    assert calculate_trimester(20) == (2, "2nd Trimester")
    assert calculate_trimester(27) == (2, "2nd Trimester")
    assert calculate_trimester(28) == (3, "3rd Trimester")
    assert calculate_trimester(38) == (3, "3rd Trimester")

    # Future LMP raises ValueError
    future_lmp = date.today() + timedelta(days=5)
    with pytest.raises(ValueError):
        calculate_gestational_age(future_lmp)


# ==========================================
# 2. Backend Integration & IDOR Tests
# ==========================================

@pytest.mark.asyncio
async def test_patient_pregnancy_lifecycle_and_calculations(
    async_client: AsyncClient,
    db_session: AsyncSession,
):
    """Verifies complete creation, persistence, deterministic calculation, list, and detail flow."""
    patient = await create_and_login_patient(async_client, "maternal")
    headers = {"Authorization": f"Bearer {patient['access_token']}"}

    # 1. Initial pregnancy list should be empty
    list_res = await async_client.get("/api/v1/patients/me/pregnancies", headers=headers)
    assert list_res.status_code == 200
    assert list_res.json()["items"] == []
    assert list_res.json()["total"] == 0

    # 2. Create pregnancy record with LMP 50 days ago
    lmp_date = date.today() - timedelta(days=50)
    expected_edd = lmp_date + timedelta(days=280)
    expected_weeks = 50 // 7
    expected_days = 50 % 7

    create_res = await async_client.post(
        "/api/v1/patients/me/pregnancies",
        headers=headers,
        json={
            "lmp": lmp_date.isoformat(),
            "notes": "First pregnancy baseline record.",
        },
    )
    assert create_res.status_code == 201
    created_data = create_res.json()
    pregnancy_id = created_data["id"]

    assert created_data["pregnancy_number"] == 1
    assert created_data["status"] == "ACTIVE"
    assert created_data["lmp"] == lmp_date.isoformat()
    assert created_data["edd"] == expected_edd.isoformat()
    assert created_data["gestational_age_weeks"] == expected_weeks
    assert created_data["gestational_age_days"] == expected_days
    assert created_data["gestational_age_display"] == f"{expected_weeks} weeks {expected_days} days"
    assert created_data["trimester"] == 1
    assert created_data["trimester_display"] == "1st Trimester"
    assert created_data["notes"] == "First pregnancy baseline record."

    # 3. Retrieve pregnancy detail by ID
    get_res = await async_client.get(
        f"/api/v1/patients/me/pregnancies/{pregnancy_id}",
        headers=headers,
    )
    assert get_res.status_code == 200
    assert get_res.json()["id"] == pregnancy_id
    assert get_res.json()["pregnancy_number"] == 1

    # 4. List now contains 1 pregnancy
    list_res_2 = await async_client.get("/api/v1/patients/me/pregnancies", headers=headers)
    assert list_res_2.status_code == 200
    assert list_res_2.json()["total"] == 1
    assert list_res_2.json()["items"][0]["id"] == pregnancy_id

    # 5. Prevent creating duplicate active pregnancy
    dup_res = await async_client.post(
        "/api/v1/patients/me/pregnancies",
        headers=headers,
        json={"lmp": (date.today() - timedelta(days=30)).isoformat()},
    )
    assert dup_res.status_code == 400
    assert "already has an active pregnancy" in dup_res.json()["detail"]

    # 6. Update pregnancy status to COMPLETED
    patch_res = await async_client.patch(
        f"/api/v1/patients/me/pregnancies/{pregnancy_id}",
        headers=headers,
        json={"status": "COMPLETED", "notes": "Successfully delivered full-term healthy baby."},
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["status"] == "COMPLETED"
    assert "Successfully delivered" in patch_res.json()["notes"]

    # 7. Now patient can create Pregnancy #2
    lmp_date_2 = date.today() - timedelta(days=20)
    create_res_2 = await async_client.post(
        "/api/v1/patients/me/pregnancies",
        headers=headers,
        json={"lmp": lmp_date_2.isoformat()},
    )
    assert create_res_2.status_code == 201
    assert create_res_2.json()["pregnancy_number"] == 2
    assert create_res_2.json()["status"] == "ACTIVE"


@pytest.mark.asyncio
async def test_pregnancy_validation_rules(
    async_client: AsyncClient,
    db_session: AsyncSession,
):
    """Verifies that future LMP dates and invalid pregnancy numbers are rejected."""
    patient = await create_and_login_patient(async_client, "validation")
    headers = {"Authorization": f"Bearer {patient['access_token']}"}

    # 1. Reject future LMP date
    future_date = date.today() + timedelta(days=10)
    res_future = await async_client.post(
        "/api/v1/patients/me/pregnancies",
        headers=headers,
        json={"lmp": future_date.isoformat()},
    )
    assert res_future.status_code == 400
    assert "cannot be a future date" in res_future.json()["detail"]

    # 2. Reject non-positive pregnancy number
    res_zero = await async_client.post(
        "/api/v1/patients/me/pregnancies",
        headers=headers,
        json={
            "lmp": (date.today() - timedelta(days=20)).isoformat(),
            "pregnancy_number": 0,
        },
    )
    assert res_zero.status_code == 422  # Pydantic Field(ge=1) validation failure


@pytest.mark.asyncio
async def test_pregnancy_idor_protection(
    async_client: AsyncClient,
    db_session: AsyncSession,
):
    """
    Verifies that Patient A cannot view, retrieve, or update Patient B's pregnancy record.
    Verifies Doctor can view Patient's pregnancy via authorized clinical endpoint.
    """
    patient_a = await create_and_login_patient(async_client, "patient_a")
    headers_a = {"Authorization": f"Bearer {patient_a['access_token']}"}

    patient_b = await create_and_login_patient(async_client, "patient_b")
    headers_b = {"Authorization": f"Bearer {patient_b['access_token']}"}

    # Patient A creates a pregnancy
    lmp_a = date.today() - timedelta(days=60)
    create_a = await async_client.post(
        "/api/v1/patients/me/pregnancies",
        headers=headers_a,
        json={"lmp": lmp_a.isoformat(), "notes": "Patient A private notes"},
    )
    assert create_a.status_code == 201
    preg_a_id = create_a.json()["id"]
    patient_a_profile_id = create_a.json()["patient_id"]

    # 1. IDOR: Patient B tries to get Patient A's pregnancy via self-service endpoint
    idor_res_1 = await async_client.get(
        f"/api/v1/patients/me/pregnancies/{preg_a_id}",
        headers=headers_b,
    )
    assert idor_res_1.status_code == 404

    # 2. IDOR: Patient B tries to patch Patient A's pregnancy
    idor_res_2 = await async_client.patch(
        f"/api/v1/patients/me/pregnancies/{preg_a_id}",
        headers=headers_b,
        json={"notes": "Maliciously modified"},
    )
    assert idor_res_2.status_code == 404

    # 3. IDOR: Patient B tries to access Patient A's pregnancies via /patients/{patient_id}/pregnancies
    idor_res_3 = await async_client.get(
        f"/api/v1/patients/{patient_a_profile_id}/pregnancies",
        headers=headers_b,
    )
    assert idor_res_3.status_code == 403
    assert "Access denied" in idor_res_3.json()["detail"]

    # 4. Doctor CAN view Patient A's pregnancy via /patients/{patient_id}/pregnancies
    doctor = await create_and_login_doctor(async_client, db_session)
    headers_doc = {"Authorization": f"Bearer {doctor['access_token']}"}

    doc_view_res = await async_client.get(
        f"/api/v1/patients/{patient_a_profile_id}/pregnancies",
        headers=headers_doc,
    )
    assert doc_view_res.status_code == 200
    assert doc_view_res.json()["total"] == 1
    assert doc_view_res.json()["items"][0]["id"] == preg_a_id


@pytest.mark.asyncio
async def test_unauthenticated_and_role_access_rejection(
    async_client: AsyncClient,
    db_session: AsyncSession,
):
    """Verifies that missing or invalid JWT and non-patient self-service attempts fail."""
    # 1. Missing authentication
    res_no_auth = await async_client.get("/api/v1/patients/me/pregnancies")
    assert res_no_auth.status_code in (401, 403)

    # 2. Invalid JWT token
    res_bad_token = await async_client.get(
        "/api/v1/patients/me/pregnancies",
        headers={"Authorization": "Bearer invalid_gibberish_token"},
    )
    assert res_bad_token.status_code in (401, 403)

    # 3. Non-patient (Doctor) attempting to call patient self-service creation endpoint
    doctor = await create_and_login_doctor(async_client, db_session)
    doc_create_res = await async_client.post(
        "/api/v1/patients/me/pregnancies",
        headers={"Authorization": f"Bearer {doctor['access_token']}"},
        json={"lmp": (date.today() - timedelta(days=40)).isoformat()},
    )
    assert doc_create_res.status_code == 403
