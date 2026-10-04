import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_patient
from app.core.database import get_db
from app.models.user import User
from app.schemas.pregnancy import (
    PregnancyCreateRequest,
    PregnancyListResponse,
    PregnancyResponse,
    PregnancyUpdateRequest,
)
from app.services.pregnancy_service import PregnancyService

router = APIRouter(prefix="/patients", tags=["Pregnancy & Maternal Health"])


# ==========================================
# 1. Patient Self-Service Pregnancy Endpoints
# ==========================================

@router.post(
    "/me/pregnancies",
    response_model=PregnancyResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create pregnancy record for authenticated patient",
    description="Calculates deterministic EDD, initial gestational age, and trimester based on LMP.",
)
async def create_my_pregnancy(
    req: PregnancyCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> PregnancyResponse:
    return await PregnancyService.create_pregnancy(
        db=db,
        current_user=current_patient,
        req=req,
    )


@router.get(
    "/me/pregnancies",
    response_model=PregnancyListResponse,
    status_code=status.HTTP_200_OK,
    summary="List all pregnancy records for authenticated patient",
    description="Returns all historical and active pregnancy records ordered by pregnancy sequence number descending.",
)
async def get_my_pregnancies(
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> PregnancyListResponse:
    return await PregnancyService.get_my_pregnancies(
        db=db,
        current_user=current_patient,
    )


@router.get(
    "/me/pregnancies/{pregnancy_id}",
    response_model=PregnancyResponse,
    status_code=status.HTTP_200_OK,
    summary="Get single pregnancy record for authenticated patient",
    description="Retrieves pregnancy details with live-derived gestational age and trimester.",
)
async def get_my_pregnancy_by_id(
    pregnancy_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> PregnancyResponse:
    return await PregnancyService.get_my_pregnancy_by_id(
        db=db,
        current_user=current_patient,
        pregnancy_id=pregnancy_id,
    )


@router.patch(
    "/me/pregnancies/{pregnancy_id}",
    response_model=PregnancyResponse,
    status_code=status.HTTP_200_OK,
    summary="Update editable pregnancy fields (status, notes)",
    description="Updates non-derived fields on a pregnancy record owned by the authenticated patient.",
)
async def update_my_pregnancy(
    pregnancy_id: uuid.UUID,
    req: PregnancyUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> PregnancyResponse:
    return await PregnancyService.update_my_pregnancy(
        db=db,
        current_user=current_patient,
        pregnancy_id=pregnancy_id,
        req=req,
    )


# ==========================================
# 2. Access-Controlled Endpoints (Doctor / ASHA / Admin / Patient)
# ==========================================

@router.get(
    "/{patient_id}/pregnancies",
    response_model=PregnancyListResponse,
    status_code=status.HTTP_200_OK,
    summary="Get all pregnancy records for a patient ID (Access Controlled)",
    description="Enforces IDOR checks: Patients can only view their own records; DOCTOR/ASHA/ADMIN can view.",
)
async def get_patient_pregnancies(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PregnancyListResponse:
    return await PregnancyService.get_patient_pregnancies_by_patient_id(
        db=db,
        current_user=current_user,
        patient_id=patient_id,
    )


@router.get(
    "/{patient_id}/pregnancies/{pregnancy_id}",
    response_model=PregnancyResponse,
    status_code=status.HTTP_200_OK,
    summary="Get specific pregnancy record for a patient ID (Access Controlled)",
    description="Enforces IDOR checks: Patients can only view their own records; DOCTOR/ASHA/ADMIN can view.",
)
async def get_patient_pregnancy_by_id(
    patient_id: uuid.UUID,
    pregnancy_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PregnancyResponse:
    return await PregnancyService.get_patient_pregnancy_by_id_for_user(
        db=db,
        current_user=current_user,
        patient_id=patient_id,
        pregnancy_id=pregnancy_id,
    )
