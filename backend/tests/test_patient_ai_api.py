import pytest
from httpx import AsyncClient
from datetime import date, timedelta
import uuid
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, RoleEnum
from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.maternal_vital_record import MaternalVitalRecord
from app.models.health_record import HealthRecord
from app.core.security import create_access_token


@pytest.mark.asyncio
async def test_patient_ai_endpoint_auth_and_chat(client: AsyncClient, db_session: AsyncSession):
    # 1. Create Patient User
    patient_user = User(
        id=uuid.uuid4(),
        email=f"pat_api_ai_{uuid.uuid4().hex[:6]}@example.com",
        password_hash="test_hash",
        full_name="Pooja Patel",
        role=RoleEnum.PATIENT,
        is_active=True,
    )
    db_session.add(patient_user)
    await db_session.flush()

    profile = PatientProfile(
        id=uuid.uuid4(),
        user_id=patient_user.id,
        blood_group="A+",
        village_locality="Green Valley, Sector 12",
    )
    db_session.add(profile)
    await db_session.flush()

    hr = HealthRecord(
        id=uuid.uuid4(),
        patient_id=profile.id,
        record_number="HR-API-PAT-001",
    )
    db_session.add(hr)

    # Active Pregnancy: LMP 18 weeks ago
    lmp = date.today() - timedelta(days=126)
    edd = lmp + timedelta(days=280)
    preg = Pregnancy(
        id=uuid.uuid4(),
        patient_id=profile.id,
        pregnancy_number=1,
        status=PregnancyStatusEnum.ACTIVE,
        lmp=lmp,
        edd=edd,
    )
    db_session.add(preg)
    await db_session.flush()

    # Vitals
    vital = MaternalVitalRecord(
        id=uuid.uuid4(),
        pregnancy_id=preg.id,
        recorded_by_user_id=patient_user.id,
        systolic_bp=120,
        diastolic_bp=80,
        weight_kg=59.0,
        temperature_c=36.9,
    )
    db_session.add(vital)
    await db_session.commit()

    patient_token = create_access_token(data={"sub": str(patient_user.id), "role": RoleEnum.PATIENT.value})
    auth_headers = {"Authorization": f"Bearer {patient_token}"}

    # 2. Unauthenticated request -> 401
    resp_unauth = await client.post(
        "/api/v1/patient-ai/chat",
        json={"message": "What week am I in?"},
    )
    assert resp_unauth.status_code == 401

    # 3. Authenticated Patient AI Query
    resp_chat = await client.post(
        "/api/v1/patient-ai/chat",
        json={"message": "How is my pregnancy progressing and what week am I in?"},
        headers=auth_headers,
    )
    assert resp_chat.status_code == 200
    data = resp_chat.json()
    assert data["is_safe"] is True
    assert "18 weeks" in data["reply_text"]
    assert len(data["tools_called"]) >= 1
    assert any(t["tool_name"] == "get_my_active_pregnancy" for t in data["tools_called"])
    assert len(data["sources"]) >= 1

    # 4. Doctor Prep Query
    resp_doc = await client.post(
        "/api/v1/patient-ai/chat",
        json={"message": "What should I ask my doctor at my appointment?"},
        headers=auth_headers,
    )
    assert resp_doc.status_code == 200
    data_doc = resp_doc.json()
    assert "Doctor Consultation Preparation" in data_doc["reply_text"]

    # 5. Red Flag Emergency Query
    resp_emerg = await client.post(
        "/api/v1/patient-ai/chat",
        json={"message": "I have severe vaginal bleeding and dizziness"},
        headers=auth_headers,
    )
    assert resp_emerg.status_code == 200
    data_emerg = resp_emerg.json()
    assert "URGENT CLINICAL ATTENTION RECOMMENDED" in data_emerg["reply_text"]
    assert any(f["severity"] == "emergency" for f in data_emerg["screening_flags"])
