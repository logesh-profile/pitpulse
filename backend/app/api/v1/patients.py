import uuid
from typing import Optional

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_patient
from app.core.database import get_db
from app.models.user import User
from app.schemas.assignment import AshaAssignmentResponse
from app.schemas.home_visit import HomeVisitListResponse
from app.schemas.patient import (
    PatientProfileResponse,
    PatientProfileUpdateRequest,
)
from app.schemas.vitals import MaternalVitalRecordListResponse
from app.services.assignment_service import AssignmentService
from app.services.home_visit_service import HomeVisitService
from app.services.patient_service import PatientService
from app.services.vitals_service import VitalsService

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


# ==========================================
# STAGE 5: Patient Self-Service Views
# ==========================================

@router.get(
    "/me/asha-assignment",
    response_model=Optional[AshaAssignmentResponse],
    status_code=status.HTTP_200_OK,
    summary="Get active ASHA healthcare worker assigned to authenticated patient",
    description="Returns the active ASHA worker details, contact info, and assigned date.",
)
async def get_my_asha_assignment(
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> Optional[AshaAssignmentResponse]:
    profile_resp = await PatientService.get_or_create_patient_profile(db=db, user=current_patient)
    return await AssignmentService.get_patient_active_assignment(db=db, patient_id=profile_resp.id)


@router.get(
    "/me/home-visits",
    response_model=HomeVisitListResponse,
    status_code=status.HTTP_200_OK,
    summary="List home visits conducted for authenticated patient",
    description="Returns chronological history of all field checkups and maternal assessments.",
)
async def get_my_home_visits(
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> HomeVisitListResponse:
    return await HomeVisitService.list_my_home_visits_for_patient(db=db, patient_user=current_patient)


@router.get(
    "/me/vitals",
    response_model=MaternalVitalRecordListResponse,
    status_code=status.HTTP_200_OK,
    summary="List maternal vitals recorded for authenticated patient",
    description="Returns chronological history of blood pressure, weight, and temperature observations.",
)
async def get_my_vitals(
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> MaternalVitalRecordListResponse:
    return await VitalsService.list_my_vitals_for_patient(db=db, patient_user=current_patient)


# ==========================================
# Access-Controlled Clinical Inspection Endpoints
# ==========================================

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


@router.get(
    "/{patient_id}/home-visits",
    response_model=HomeVisitListResponse,
    status_code=status.HTTP_200_OK,
    summary="Get home visits for patient ID (Access Controlled)",
    description="IDOR-enforced endpoint for doctors and clinicians to inspect patient home visits.",
)
async def get_patient_home_visits(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> HomeVisitListResponse:
    return await HomeVisitService.list_patient_home_visits_for_authorized_user(
        db=db,
        current_user=current_user,
        patient_id=patient_id,
    )


@router.get(
    "/{patient_id}/vitals",
    response_model=MaternalVitalRecordListResponse,
    status_code=status.HTTP_200_OK,
    summary="Get maternal vitals for patient ID (Access Controlled)",
    description="IDOR-enforced endpoint for doctors and clinicians to inspect patient maternal vitals.",
)
async def get_patient_vitals(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MaternalVitalRecordListResponse:
    return await VitalsService.list_patient_vitals_for_authorized_user(
        db=db,
        current_user=current_user,
        patient_id=patient_id,
    )
