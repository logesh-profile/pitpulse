import uuid
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.models.refresh_token import RefreshToken
from app.models.user import RoleEnum, User


@pytest.mark.asyncio
async def test_password_hashing_and_verification():
    """Verify Argon2id password hashing and verification."""
    password = "SuperSecretPassword123!"
    hashed = hash_password(password)

    assert hashed != password
    assert hashed.startswith("$argon2id$")
    assert verify_password(password, hashed) is True
    assert verify_password("WrongPassword123!", hashed) is False


@pytest.mark.asyncio
async def test_user_registration_success(async_client: AsyncClient, db_session: AsyncSession):
    """Verify successful user registration into PostgreSQL."""
    email = f"patient_{uuid.uuid4().hex[:8]}@pitpulse.org"
    payload = {
        "email": email,
        "password": "SecurePassword123!",
        "full_name": "Ravi Kumar",
        "phone": f"+9198{uuid.uuid4().hex[:8]}",
        "role": "PATIENT",
    }

    response = await async_client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()

    assert data["email"] == email
    assert data["full_name"] == "Ravi Kumar"
    assert data["role"] == "PATIENT"
    assert data["is_active"] is True
    assert "id" in data
    assert "password" not in data
    assert "password_hash" not in data

    # Verify directly in PostgreSQL
    stmt = select(User).where(User.email == email)
    result = await db_session.execute(stmt)
    db_user = result.scalar_one_or_none()
    assert db_user is not None
    assert db_user.full_name == "Ravi Kumar"
    assert verify_password("SecurePassword123!", db_user.password_hash) is True


@pytest.mark.asyncio
async def test_duplicate_email_registration_rejection(async_client: AsyncClient):
    """Verify that registering with an already existing email is rejected."""
    email = f"dup_{uuid.uuid4().hex[:8]}@pitpulse.org"
    payload = {
        "email": email,
        "password": "SecurePassword123!",
        "full_name": "User One",
        "role": "PATIENT",
    }

    resp1 = await async_client.post("/api/v1/auth/register", json=payload)
    assert resp1.status_code == 201

    resp2 = await async_client.post("/api/v1/auth/register", json=payload)
    assert resp2.status_code == 400
    assert "already exists" in resp2.json()["detail"]


@pytest.mark.asyncio
async def test_prevent_public_admin_registration(async_client: AsyncClient):
    """Verify that public registration endpoint rejects ADMIN role creation."""
    payload = {
        "email": f"hacker_{uuid.uuid4().hex[:8]}@pitpulse.org",
        "password": "SecurePassword123!",
        "full_name": "Fake Admin",
        "role": "ADMIN",
    }

    response = await async_client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 422  # Pydantic validation rejection


@pytest.mark.asyncio
async def test_successful_login_and_token_issuance(async_client: AsyncClient, db_session: AsyncSession):
    """Verify login against PostgreSQL Argon2id hash and JWT token issuance."""
    email = f"doctor_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "DoctorPassword123!"

    # Register doctor
    reg_payload = {
        "email": email,
        "password": password,
        "full_name": "Dr. Ananya Sharma",
        "role": "DOCTOR",
    }
    reg_resp = await async_client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_resp.status_code == 201

    # Login
    login_payload = {
        "email": email,
        "password": password,
    }
    login_resp = await async_client.post("/api/v1/auth/login", json=login_payload)
    assert login_resp.status_code == 200
    data = login_resp.json()

    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == email
    assert data["user"]["role"] == "DOCTOR"

    # Verify refresh token hash was persisted in PostgreSQL
    token_hash = hash_token(data["refresh_token"])
    stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
    result = await db_session.execute(stmt)
    db_token = result.scalar_one_or_none()
    assert db_token is not None
    assert db_token.revoked_at is None


@pytest.mark.asyncio
async def test_invalid_password_rejection(async_client: AsyncClient):
    """Verify that wrong password is rejected with generic 401 error."""
    email = f"asha_{uuid.uuid4().hex[:8]}@pitpulse.org"
    reg_payload = {
        "email": email,
        "password": "AshaPassword123!",
        "full_name": "Priya Devi",
        "role": "ASHA",
    }
    await async_client.post("/api/v1/auth/register", json=reg_payload)

    login_resp = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "WrongPassword999!"},
    )
    assert login_resp.status_code == 401
    assert login_resp.json()["detail"] == "Invalid email or password."


@pytest.mark.asyncio
async def test_authenticated_auth_me_endpoint(async_client: AsyncClient):
    """Verify GET /api/v1/auth/me returns genuine database user profile."""
    email = f"user_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "MyPassword123!"

    reg_resp = await async_client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Sneha Patel", "role": "PATIENT"},
    )
    assert reg_resp.status_code == 201

    login_resp = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    access_token = login_resp.json()["access_token"]

    # Call /auth/me
    headers = {"Authorization": f"Bearer {access_token}"}
    me_resp = await async_client.get("/api/v1/auth/me", headers=headers)
    assert me_resp.status_code == 200
    user_data = me_resp.json()

    assert user_data["email"] == email
    assert user_data["full_name"] == "Sneha Patel"
    assert user_data["role"] == "PATIENT"
    assert "password" not in user_data
    assert "password_hash" not in user_data


@pytest.mark.asyncio
async def test_token_rotation_and_revocation(async_client: AsyncClient, db_session: AsyncSession):
    """Verify refresh token rotation and revocation."""
    email = f"refresh_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "MyPassword123!"

    await async_client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Test Rotation", "role": "PATIENT"},
    )
    login_resp = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    first_refresh = login_resp.json()["refresh_token"]

    # Refresh session
    refresh_resp = await async_client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": first_refresh},
    )
    assert refresh_resp.status_code == 200
    new_data = refresh_resp.json()
    second_refresh = new_data["refresh_token"]

    assert second_refresh != first_refresh
    assert "access_token" in new_data

    # Verify first refresh token is now marked revoked in PostgreSQL
    old_hash = hash_token(first_refresh)
    stmt = select(RefreshToken).where(RefreshToken.token_hash == old_hash)
    result = await db_session.execute(stmt)
    old_record = result.scalar_one_or_none()
    assert old_record is not None
    assert old_record.revoked_at is not None

    # Attempting to reuse the revoked first token must be rejected
    reuse_resp = await async_client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": first_refresh},
    )
    assert reuse_resp.status_code == 401


@pytest.mark.asyncio
async def test_logout_revokes_token_in_postgresql(async_client: AsyncClient, db_session: AsyncSession):
    """Verify POST /api/v1/auth/logout revokes refresh token in database."""
    email = f"logout_{uuid.uuid4().hex[:8]}@pitpulse.org"
    password = "MyPassword123!"

    await async_client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Logout User", "role": "PATIENT"},
    )
    login_resp = await async_client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    refresh_tok = login_resp.json()["refresh_token"]

    logout_resp = await async_client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": refresh_tok},
    )
    assert logout_resp.status_code == 200

    # Verify refresh token is revoked in DB
    tok_hash = hash_token(refresh_tok)
    stmt = select(RefreshToken).where(RefreshToken.token_hash == tok_hash)
    result = await db_session.execute(stmt)
    record = result.scalar_one_or_none()
    assert record is not None
    assert record.revoked_at is not None


@pytest.mark.asyncio
async def test_role_based_authorization_backend(async_client: AsyncClient):
    """Verify that backend strictly blocks unauthorized roles."""
    patient_email = f"patient_{uuid.uuid4().hex[:8]}@pitpulse.org"
    doctor_email = f"doctor_{uuid.uuid4().hex[:8]}@pitpulse.org"
    pw = "SecretPassword123!"

    # Create patient
    await async_client.post(
        "/api/v1/auth/register",
        json={"email": patient_email, "password": pw, "full_name": "Patient X", "role": "PATIENT"},
    )
    patient_login = await async_client.post(
        "/api/v1/auth/login",
        json={"email": patient_email, "password": pw},
    )
    patient_token = patient_login.json()["access_token"]

    # Create doctor
    await async_client.post(
        "/api/v1/auth/register",
        json={"email": doctor_email, "password": pw, "full_name": "Doctor Y", "role": "DOCTOR"},
    )
    doctor_login = await async_client.post(
        "/api/v1/auth/login",
        json={"email": doctor_email, "password": pw},
    )
    doctor_token = doctor_login.json()["access_token"]

    # Patient attempts to access doctor-only route -> 403 Forbidden
    resp = await async_client.get(
        "/api/v1/auth/role-test/doctor",
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp.status_code == 403

    # Doctor accesses doctor-only route -> 200 OK
    resp_doc = await async_client.get(
        "/api/v1/auth/role-test/doctor",
        headers={"Authorization": f"Bearer {doctor_token}"},
    )
    assert resp_doc.status_code == 200
    assert resp_doc.json()["email"] == doctor_email


@pytest.mark.asyncio
async def test_expired_access_token_rejection(async_client: AsyncClient):
    """Verify that an expired JWT access token is rejected."""
    expired_token = create_access_token(
        user_id=uuid.uuid4(),
        role="PATIENT",
        expires_delta=timedelta(seconds=-10),  # expired 10 seconds ago
    )

    resp = await async_client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {expired_token}"},
    )
    assert resp.status_code == 401
