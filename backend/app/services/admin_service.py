import secrets
import string
import uuid
from typing import List

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import hash_password
from app.models.asha_profile import AshaProfile
from app.models.doctor_profile import DoctorProfile
from app.models.user import RoleEnum, User
from app.models.verification_token import TokenTypeEnum
from app.schemas.admin import (
    AshaProvisionResponse,
    CreateAshaRequest,
    CreateDoctorRequest,
    DoctorProvisionResponse,
    ProfessionalUserItem,
)
from app.services.email_service import EmailService


def generate_secure_temporary_password(length: int = 14) -> str:
    """Generates a high-entropy temporary password satisfying all complexity constraints."""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    while True:
        password = "".join(secrets.choice(alphabet) for _ in range(length))
        if (
            any(c.islower() for c in password)
            and any(c.isupper() for c in password)
            and any(c.isdigit() for c in password)
            and any(c in "!@#$%^&*" for c in password)
        ):
            return password


class AdminService:
    @staticmethod
    async def create_doctor(db: AsyncSession, req: CreateDoctorRequest) -> DoctorProvisionResponse:
        """Admin-only provisioning of DOCTOR account with secure temporary activation password."""
        email_clean = req.email.lower().strip()

        # Check duplicate email
        stmt = select(User).where(User.email == email_clean)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An account with this email address already exists.",
            )

        # Check duplicate phone if provided
        if req.phone:
            phone_clean = req.phone.strip()
            phone_stmt = select(User).where(User.phone == phone_clean)
            phone_res = await db.execute(phone_stmt)
            if phone_res.scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="An account with this phone number already exists.",
                )

        # Initial random password hash to prevent empty login
        dummy_seed_pw = generate_secure_temporary_password()
        hashed_pw = hash_password(dummy_seed_pw)

        new_user = User(
            email=email_clean,
            phone=req.phone.strip() if req.phone else None,
            full_name=req.full_name.strip(),
            password_hash=hashed_pw,
            role=RoleEnum.DOCTOR,
            is_active=True,
            is_verified=False,
            must_change_password=True,
        )
        db.add(new_user)
        await db.flush()

        doc_profile = DoctorProfile(
            user_id=new_user.id,
            medical_license_number=req.medical_license_number.strip() if req.medical_license_number else None,
            specialization=req.specialization.strip() if req.specialization else None,
            facility_name=req.facility_name.strip() if req.facility_name else None,
        )
        db.add(doc_profile)
        await db.flush()

        # Generate activation token
        activation_token = await EmailService.create_verification_token(
            db=db,
            user_id=new_user.id,
            token_type=TokenTypeEnum.PROFESSIONAL_ACTIVATION,
            expire_hours=168,  # 7 days
        )

        await db.commit()
        await db.refresh(new_user)

        # Dispatch activation email
        await EmailService.send_professional_activation_email(
            email=new_user.email,
            full_name=new_user.full_name,
            role="DOCTOR",
            token=activation_token,
        )

        return DoctorProvisionResponse(
            user_id=new_user.id,
            email=new_user.email,
            full_name=new_user.full_name,
            phone=new_user.phone,
            role=RoleEnum.DOCTOR,
            activation_token=activation_token,
            temporary_password=None,
            must_change_password=True,
            is_active=True,
            medical_license_number=doc_profile.medical_license_number,
            specialization=doc_profile.specialization,
            facility_name=doc_profile.facility_name,
            created_at=new_user.created_at,
        )

    @staticmethod
    async def create_asha(db: AsyncSession, req: CreateAshaRequest) -> AshaProvisionResponse:
        """Admin-only provisioning of ASHA healthcare worker account."""
        email_clean = req.email.lower().strip()

        # Check duplicate email
        stmt = select(User).where(User.email == email_clean)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An account with this email address already exists.",
            )

        # Check duplicate phone if provided
        if req.phone:
            phone_clean = req.phone.strip()
            phone_stmt = select(User).where(User.phone == phone_clean)
            phone_res = await db.execute(phone_stmt)
            if phone_res.scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="An account with this phone number already exists.",
                )

        dummy_seed_pw = generate_secure_temporary_password()
        hashed_pw = hash_password(dummy_seed_pw)

        new_user = User(
            email=email_clean,
            phone=req.phone.strip() if req.phone else None,
            full_name=req.full_name.strip(),
            password_hash=hashed_pw,
            role=RoleEnum.ASHA,
            is_active=True,
            is_verified=False,
            must_change_password=True,
        )
        db.add(new_user)
        await db.flush()

        asha_prof = AshaProfile(
            user_id=new_user.id,
            worker_id_code=req.worker_id_code.strip() if req.worker_id_code else None,
            assigned_area=req.assigned_area.strip() if req.assigned_area else None,
            primary_health_center=req.primary_health_center.strip() if req.primary_health_center else None,
        )
        db.add(asha_prof)
        await db.flush()

        # Generate activation token
        activation_token = await EmailService.create_verification_token(
            db=db,
            user_id=new_user.id,
            token_type=TokenTypeEnum.PROFESSIONAL_ACTIVATION,
            expire_hours=168,  # 7 days
        )

        await db.commit()
        await db.refresh(new_user)

        # Dispatch activation email
        await EmailService.send_professional_activation_email(
            email=new_user.email,
            full_name=new_user.full_name,
            role="ASHA_WORKER",
            token=activation_token,
        )

        return AshaProvisionResponse(
            user_id=new_user.id,
            email=new_user.email,
            full_name=new_user.full_name,
            phone=new_user.phone,
            role=RoleEnum.ASHA,
            activation_token=activation_token,
            temporary_password=None,
            must_change_password=True,
            is_active=True,
            worker_id_code=asha_prof.worker_id_code,
            assigned_area=asha_prof.assigned_area,
            primary_health_center=asha_prof.primary_health_center,
            created_at=new_user.created_at,
        )

    @staticmethod
    async def list_professionals(db: AsyncSession) -> List[ProfessionalUserItem]:
        """Lists all provisioned DOCTOR and ASHA healthcare workers with their profile metadata."""
        stmt = (
            select(User)
            .where(User.role.in_([RoleEnum.DOCTOR, RoleEnum.ASHA]))
            .options(
                selectinload(User.doctor_profile),
                selectinload(User.asha_profile),
            )
            .order_by(User.created_at.desc())
        )
        result = await db.execute(stmt)
        users = result.scalars().all()

        items = []
        for u in users:
            details = {}
            if u.doctor_profile:
                details = {
                    "medical_license_number": u.doctor_profile.medical_license_number,
                    "specialization": u.doctor_profile.specialization,
                    "facility_name": u.doctor_profile.facility_name,
                }
            elif u.asha_profile:
                details = {
                    "worker_id_code": u.asha_profile.worker_id_code,
                    "assigned_area": u.asha_profile.assigned_area,
                    "primary_health_center": u.asha_profile.primary_health_center,
                }

            items.append(
                ProfessionalUserItem(
                    id=u.id,
                    email=u.email,
                    full_name=u.full_name,
                    phone=u.phone,
                    role=u.role,
                    is_active=u.is_active,
                    must_change_password=u.must_change_password,
                    created_at=u.created_at,
                    details=details,
                )
            )
        return items

    @staticmethod
    async def update_user_status(db: AsyncSession, user_id: uuid.UUID, is_active: bool) -> User:
        """Activates or deactivates a user account."""
        stmt = select(User).where(User.id == user_id)
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User account not found.",
            )

        if user.role == RoleEnum.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="ADMIN account status cannot be altered through this endpoint.",
            )

        user.is_active = is_active
        await db.commit()
        await db.refresh(user)
        return user
