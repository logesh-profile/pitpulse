import uuid
from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_admin
from app.core.database import get_db
from app.models.user import User
from app.schemas.admin import (
    AshaProvisionResponse,
    CreateAshaRequest,
    CreateDoctorRequest,
    DoctorProvisionResponse,
    ProfessionalUserItem,
    UserStatusUpdateRequest,
)
from app.schemas.auth import UserResponse
from app.services.admin_service import AdminService

router = APIRouter(prefix="/admin", tags=["Admin Professional Management"])


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
