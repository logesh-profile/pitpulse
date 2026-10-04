import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_doctor
from app.core.database import get_db
from app.models.user import User
from app.schemas.assignment import AshaAssignmentResponse
from app.schemas.doctor import (
    DoctorAshaListResponse,
    DoctorAssignAshaRequest,
    DoctorPatientRosterResponse,
)
from app.services.doctor_service import DoctorService

router = APIRouter(prefix="/doctor", tags=["Doctor Clinical Coordination"])


@router.get(
    "/me/patients",
    response_model=DoctorPatientRosterResponse,
    status_code=status.HTTP_200_OK,
    summary="Get patient roster for authenticated doctor",
    description="Retrieves patient roster with pregnancy and ASHA assignment status.",
)
async def get_doctor_patients(
    db: AsyncSession = Depends(get_db),
    current_doctor: User = Depends(require_doctor),
) -> DoctorPatientRosterResponse:
    return await DoctorService.get_doctor_patients(
        db=db,
        doctor_user=current_doctor,
        unassigned_only=False,
    )


@router.get(
    "/me/patients/unassigned",
    response_model=DoctorPatientRosterResponse,
    status_code=status.HTTP_200_OK,
    summary="Get patients needing ASHA assignment",
    description="Lists patients in doctor's scope who do not currently have an active ASHA assignment.",
)
async def get_unassigned_patients(
    db: AsyncSession = Depends(get_db),
    current_doctor: User = Depends(require_doctor),
) -> DoctorPatientRosterResponse:
    return await DoctorService.get_doctor_patients(
        db=db,
        doctor_user=current_doctor,
        unassigned_only=True,
    )


@router.get(
    "/me/available-asha",
    response_model=DoctorAshaListResponse,
    status_code=status.HTTP_200_OK,
    summary="List available ASHA workers for assignment",
    description="Returns active ASHA workers in primary health center / area with active patient workloads.",
)
async def get_available_ashas(
    db: AsyncSession = Depends(get_db),
    current_doctor: User = Depends(require_doctor),
) -> DoctorAshaListResponse:
    return await DoctorService.get_available_ashas(
        db=db,
        doctor_user=current_doctor,
    )


@router.post(
    "/me/patients/{patient_id}/asha-assignment",
    response_model=AshaAssignmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Doctor assigns ASHA worker to a patient",
    description="Allocates patient care to an ASHA worker. Deactivates/transfers previous active assignment.",
)
async def doctor_assign_asha(
    patient_id: uuid.UUID,
    req: DoctorAssignAshaRequest,
    db: AsyncSession = Depends(get_db),
    current_doctor: User = Depends(require_doctor),
) -> AshaAssignmentResponse:
    return await DoctorService.doctor_assign_asha(
        db=db,
        doctor_user=current_doctor,
        patient_id=patient_id,
        asha_worker_id=req.asha_worker_id,
        notes=req.notes,
    )
