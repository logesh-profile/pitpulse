import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import require_admin
from app.core.database import get_db
from app.models.asha_patient_assignment import AssignmentStatusEnum
from app.models.asha_profile import AshaProfile
from app.models.patient_profile import PatientProfile
from app.models.user import User
from app.schemas.admin import (
    AshaProvisionResponse,
    AshaWorkerItemResponse,
    CreateAshaRequest,
    CreateDoctorRequest,
    CreatePatientRequest,
    DoctorProvisionResponse,
    PatientProvisionResponse,
    ProfessionalUserItem,
    UserStatusUpdateRequest,
)
from app.schemas.assignment import (
    AshaAssignmentCreateRequest,
    AshaAssignmentListResponse,
    AshaAssignmentResponse,
    AshaAssignmentUpdateRequest,
)
from app.schemas.auth import UserResponse
from app.schemas.patient import HealthRecordResponse, PatientProfileResponse
from app.services.admin_service import AdminService
from app.services.assignment_service import AssignmentService
from app.services.patient_service import PatientService

router = APIRouter(prefix="/admin", tags=["Admin Professional & Assignment Management"])


@router.post(
    "/users/doctors",
    response_model=DoctorProvisionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Provision a new Doctor account",
    description="Admin-only endpoint to create Doctor accounts with secure activation credentials.",
)
async def create_doctor(
    req: CreateDoctorRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> DoctorProvisionResponse:
    return await AdminService.create_doctor(db=db, req=req)


@router.post(
    "/users/asha-workers",
    response_model=AshaProvisionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Provision a new ASHA healthcare worker account",
    description="Admin-only endpoint to create ASHA worker accounts with secure activation credentials.",
)
async def create_asha(
    req: CreateAshaRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> AshaProvisionResponse:
    return await AdminService.create_asha(db=db, req=req)


@router.post(
    "/users/patients",
    response_model=PatientProvisionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Provision a new Patient account",
    description="Admin-only endpoint to create Patient accounts with anchor health records.",
)
async def create_patient(
    req: CreatePatientRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> PatientProvisionResponse:
    return await AdminService.create_patient(db=db, req=req)


@router.get(
    "/users/professionals",
    response_model=List[ProfessionalUserItem],
    status_code=status.HTTP_200_OK,
    summary="List provisioned Doctors and ASHA workers",
    description="Admin-only endpoint to inspect all registered professional healthcare providers.",
)
async def list_professionals(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> List[ProfessionalUserItem]:
    return await AdminService.list_professionals(db=db)


@router.patch(
    "/users/{user_id}/status",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Activate or Deactivate User Account",
    description="Admin-only endpoint to toggle account active status.",
)
async def update_user_status(
    user_id: uuid.UUID,
    req: UserStatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> UserResponse:
    user = await AdminService.update_user_status(db=db, user_id=user_id, is_active=req.is_active)
    return UserResponse.model_validate(user)


@router.delete(
    "/users/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete User Account",
    description="Admin-only endpoint to permanently remove an account and its clinical/profile data.",
)
async def delete_user(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> None:
    await AdminService.delete_user(db=db, user_id=user_id)



# ==========================================
# STAGE 5: ASHA-Patient Assignment Management
# ==========================================

@router.post(
    "/assignments/asha",
    response_model=AshaAssignmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Assign or reassign a Patient to an ASHA worker",
    description="Admin assigns patient to ASHA. Any previous active assignment is marked INACTIVE.",
)
async def create_asha_assignment(
    req: AshaAssignmentCreateRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> AshaAssignmentResponse:
    return await AssignmentService.create_assignment(
        db=db,
        admin_user=admin_user,
        req=req,
    )


@router.get(
    "/assignments/asha",
    response_model=AshaAssignmentListResponse,
    status_code=status.HTTP_200_OK,
    summary="List all ASHA-patient assignments",
    description="Admin-only endpoint to view assignment history and active relationships.",
)
async def list_asha_assignments(
    status: Optional[AssignmentStatusEnum] = Query(None, description="Filter by ACTIVE or INACTIVE"),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> AshaAssignmentListResponse:
    return await AssignmentService.list_assignments(
        db=db,
        status_filter=status,
    )


@router.patch(
    "/assignments/asha/{assignment_id}",
    response_model=AshaAssignmentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update or deactivate an ASHA-patient assignment",
    description="Admin modifies assignment status (e.g. INACTIVE) or administrative notes.",
)
async def update_asha_assignment(
    assignment_id: uuid.UUID,
    req: AshaAssignmentUpdateRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> AshaAssignmentResponse:
    return await AssignmentService.update_assignment(
        db=db,
        admin_user=admin_user,
        assignment_id=assignment_id,
        req=req,
    )


@router.get(
    "/patients",
    response_model=List[PatientProfileResponse],
    status_code=status.HTTP_200_OK,
    summary="List all patient profiles for administrative assignment",
    description="Admin-only endpoint to browse registered patients to assign to field health workers.",
)
async def list_patients_for_admin(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> List[PatientProfileResponse]:
    stmt = (
        select(PatientProfile)
        .options(
            selectinload(PatientProfile.user),
            selectinload(PatientProfile.health_record),
        )
        .order_by(PatientProfile.created_at.desc())
    )
    result = await db.execute(stmt)
    profiles = result.scalars().all()
    return [
        PatientProfileResponse(
            id=p.id,
            user_id=p.user.id,
            full_name=p.user.full_name,
            email=p.user.email,
            phone=p.user.phone,
            date_of_birth=p.date_of_birth,
            sex=p.sex,
            address=p.address,
            village_locality=p.village_locality,
            emergency_contact_name=p.emergency_contact_name,
            emergency_contact_phone=p.emergency_contact_phone,
            blood_group=p.blood_group,
            baseline_health_info=p.baseline_health_info,
            health_record=HealthRecordResponse(
                id=p.health_record.id,
                record_number=p.health_record.record_number,
                created_at=p.health_record.created_at,
            ) if p.health_record else None,
            created_at=p.created_at,
            updated_at=p.updated_at,
        )
        for p in profiles
    ]


@router.get(
    "/asha-workers",
    response_model=List[AshaWorkerItemResponse],
    status_code=status.HTTP_200_OK,
    summary="List all ASHA workers for administrative assignment",
    description="Admin-only endpoint to browse registered ASHA workers for patient allocations.",
)
async def list_asha_workers_for_admin(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> List[AshaWorkerItemResponse]:
    stmt = (
        select(AshaProfile)
        .options(selectinload(AshaProfile.user))
        .order_by(AshaProfile.created_at.desc())
    )
    result = await db.execute(stmt)
    profiles = result.scalars().all()
    return [
        AshaWorkerItemResponse(
            id=p.id,
            user_id=p.user.id,
            full_name=p.user.full_name,
            email=p.user.email,
            phone=p.user.phone,
            worker_id_code=p.worker_id_code,
            assigned_area=p.assigned_area,
            primary_health_center=p.primary_health_center,
            user={
                "id": str(p.user.id),
                "full_name": p.user.full_name,
                "email": p.user.email,
                "phone": p.user.phone,
            },
            created_at=p.created_at,
            updated_at=p.updated_at,
        )
        for p in profiles
    ]

