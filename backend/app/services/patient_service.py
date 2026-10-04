import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.health_record import HealthRecord
from app.models.patient_profile import PatientProfile
from app.models.user import RoleEnum, User
from app.schemas.patient import (
    HealthRecordResponse,
    PatientProfileResponse,
    PatientProfileUpdateRequest,
)


def generate_health_record_number(user_id: uuid.UUID) -> str:
    """Generates unique deterministic formatted Health Record ID (e.g. HR-XXXX-XXXX)."""
    clean_hex = user_id.hex[:8].upper()
    return f"HR-{clean_hex[:4]}-{clean_hex[4:]}"


class PatientService:
    @staticmethod
    async def get_or_create_patient_profile(
        db: AsyncSession,
        user: User,
    ) -> PatientProfileResponse:
        """Retrieves or initializes the patient profile and anchor health record for a PATIENT."""
        stmt = (
            select(PatientProfile)
            .where(PatientProfile.user_id == user.id)
            .options(selectinload(PatientProfile.health_record))
        )
        result = await db.execute(stmt)
        profile = result.scalar_one_or_none()

        if not profile:
            # Initialize empty profile linked to patient
            profile = PatientProfile(user_id=user.id)
            db.add(profile)
            await db.flush()

            # Create foundation health record anchor
            hr = HealthRecord(
                patient_id=profile.id,
                record_number=generate_health_record_number(user.id),
            )
            db.add(hr)
            await db.commit()
            await db.refresh(profile)

            # Reload with health record
            stmt = (
                select(PatientProfile)
                .where(PatientProfile.id == profile.id)
                .options(selectinload(PatientProfile.health_record))
            )
            res = await db.execute(stmt)
            profile = res.scalar_one()

        hr_resp = None
        if profile.health_record:
            hr_resp = HealthRecordResponse(
                id=profile.health_record.id,
                record_number=profile.health_record.record_number,
                created_at=profile.health_record.created_at,
            )

        return PatientProfileResponse(
            id=profile.id,
            user_id=user.id,
            full_name=user.full_name,
            email=user.email,
            phone=user.phone,
            date_of_birth=profile.date_of_birth,
            sex=profile.sex,
            address=profile.address,
            village_locality=profile.village_locality,
            emergency_contact_name=profile.emergency_contact_name,
            emergency_contact_phone=profile.emergency_contact_phone,
            blood_group=profile.blood_group,
            baseline_health_info=profile.baseline_health_info,
            health_record=hr_resp,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )

    @staticmethod
    async def update_patient_profile(
        db: AsyncSession,
        user: User,
        req: PatientProfileUpdateRequest,
    ) -> PatientProfileResponse:
        """Updates demographics/baseline information on the current authenticated patient's profile."""
        stmt = (
            select(PatientProfile)
            .where(PatientProfile.user_id == user.id)
            .options(selectinload(PatientProfile.health_record))
        )
        result = await db.execute(stmt)
        profile = result.scalar_one_or_none()

        if not profile:
            profile = PatientProfile(user_id=user.id)
            db.add(profile)
            await db.flush()

            hr = HealthRecord(
                patient_id=profile.id,
                record_number=generate_health_record_number(user.id),
            )
            db.add(hr)

        # Update provided fields
        if req.date_of_birth is not None:
            profile.date_of_birth = req.date_of_birth
        if req.sex is not None:
            profile.sex = req.sex.strip()
        if req.address is not None:
            profile.address = req.address.strip()
        if req.village_locality is not None:
            profile.village_locality = req.village_locality.strip()
        if req.emergency_contact_name is not None:
            profile.emergency_contact_name = req.emergency_contact_name.strip()
        if req.emergency_contact_phone is not None:
            profile.emergency_contact_phone = req.emergency_contact_phone.strip()
        if req.blood_group is not None:
            profile.blood_group = req.blood_group.strip()
        if req.baseline_health_info is not None:
            profile.baseline_health_info = req.baseline_health_info.strip()

        profile.updated_at = datetime.now(timezone.utc)
        await db.commit()
        await db.refresh(profile)

        # Reload with health record
        stmt = (
            select(PatientProfile)
            .where(PatientProfile.id == profile.id)
            .options(selectinload(PatientProfile.health_record))
        )
        res = await db.execute(stmt)
        profile = res.scalar_one()

        hr_resp = None
        if profile.health_record:
            hr_resp = HealthRecordResponse(
                id=profile.health_record.id,
                record_number=profile.health_record.record_number,
                created_at=profile.health_record.created_at,
            )

        return PatientProfileResponse(
            id=profile.id,
            user_id=user.id,
            full_name=user.full_name,
            email=user.email,
            phone=user.phone,
            date_of_birth=profile.date_of_birth,
            sex=profile.sex,
            address=profile.address,
            village_locality=profile.village_locality,
            emergency_contact_name=profile.emergency_contact_name,
            emergency_contact_phone=profile.emergency_contact_phone,
            blood_group=profile.blood_group,
            baseline_health_info=profile.baseline_health_info,
            health_record=hr_resp,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )

    @staticmethod
    async def get_patient_profile_by_id(
        db: AsyncSession,
        current_user: User,
        patient_id: uuid.UUID,
    ) -> PatientProfileResponse:
        """Retrieves patient profile with backend-enforced IDOR authorization check."""
        stmt = (
            select(PatientProfile)
            .where(PatientProfile.id == patient_id)
            .options(
                selectinload(PatientProfile.health_record),
                selectinload(PatientProfile.user),
            )
        )
        result = await db.execute(stmt)
        profile = result.scalar_one_or_none()

        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Patient profile not found.",
            )

        # IDOR Access Control:
        # If PATIENT: MUST own the record
        if current_user.role == RoleEnum.PATIENT and profile.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You do not have permission to access another patient's medical profile.",
            )

        hr_resp = None
        if profile.health_record:
            hr_resp = HealthRecordResponse(
                id=profile.health_record.id,
                record_number=profile.health_record.record_number,
                created_at=profile.health_record.created_at,
            )

        return PatientProfileResponse(
            id=profile.id,
            user_id=profile.user.id,
            full_name=profile.user.full_name,
            email=profile.user.email,
            phone=profile.user.phone,
            date_of_birth=profile.date_of_birth,
            sex=profile.sex,
            address=profile.address,
            village_locality=profile.village_locality,
            emergency_contact_name=profile.emergency_contact_name,
            emergency_contact_phone=profile.emergency_contact_phone,
            blood_group=profile.blood_group,
            baseline_health_info=profile.baseline_health_info,
            health_record=hr_resp,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )
