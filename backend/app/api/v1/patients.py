import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_patient
from app.core.database import get_db
from app.models.user import User
from app.schemas.patient import (
    PatientProfileResponse,
    PatientProfileUpdateRequest,
)
from app.services.patient_service import PatientService

router = APIRouter(prefix="/patients", tags=["Patient Profiles & Health Identity"])


@router.get(
    "/me",
    response_model=PatientProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current patient profile & health record anchor",
    description="Returns the authenticated patient's demographics, contact information, and health record number.",
)
async def get_my_patient_profile(
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> PatientProfileResponse:
    return await PatientService.get_or_create_patient_profile(db=db, user=current_patient)


@router.put(
    "/me",
    response_model=PatientProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Update current patient profile",
    description="Updates demographics, village, address, emergency contact, or baseline health information.",
)
async def update_my_patient_profile(
    req: PatientProfileUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> PatientProfileResponse:
    return await PatientService.update_patient_profile(db=db, user=current_patient, req=req)


@router.get(
    "/{patient_id}",
    response_model=PatientProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get patient profile by ID (Access Controlled)",
    description="Protected endpoint with backend IDOR enforcement (patients can only access their own profile).",
)
async def get_patient_profile_by_id(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PatientProfileResponse:
    return await PatientService.get_patient_profile_by_id(
        db=db,
        current_user=current_user,
        patient_id=patient_id,
    )
