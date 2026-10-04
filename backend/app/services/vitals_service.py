import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.home_visit import HomeVisit
from app.models.maternal_vital_record import MaternalVitalRecord
from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.user import RoleEnum, User
from app.schemas.vitals import (
    MaternalVitalRecordCreateRequest,
    MaternalVitalRecordListResponse,
    MaternalVitalRecordResponse,
)
from app.services.assignment_service import AssignmentService
from app.services.patient_service import PatientService


def _to_vital_response(v: MaternalVitalRecord) -> MaternalVitalRecordResponse:
    rec_name = v.recorded_by.full_name if v.recorded_by else "Health Professional"
    rec_role = v.recorded_by.role.value if v.recorded_by else "HEALTH_WORKER"
    preg_num = v.pregnancy.pregnancy_number if v.pregnancy else None

    return MaternalVitalRecordResponse(
        id=v.id,
        pregnancy_id=v.pregnancy_id,
        pregnancy_number=preg_num,
        home_visit_id=v.home_visit_id,
        recorded_by_user_id=v.recorded_by_user_id,
        recorded_by_name=rec_name,
        recorded_by_role=rec_role,
        recorded_at=v.recorded_at,
        systolic_bp=v.systolic_bp,
        diastolic_bp=v.diastolic_bp,
        weight_kg=v.weight_kg,
        temperature_c=v.temperature_c,
        notes=v.notes,
        created_at=v.created_at,
        updated_at=v.updated_at,
    )


class VitalsService:
    @staticmethod
    async def record_vitals_for_asha(
        db: AsyncSession,
        asha_user: User,
        patient_id: uuid.UUID,
        visit_id: Optional[uuid.UUID],
        req: MaternalVitalRecordCreateRequest,
    ) -> MaternalVitalRecordResponse:
        """ASHA records maternal vitals during an authorized home visit."""
        if asha_user.role != RoleEnum.ASHA:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only ASHA health workers can record field maternal vitals.",
            )

        # 1. Verify active ASHA assignment
        await AssignmentService.verify_asha_patient_access(
            db=db,
            asha_user_id=asha_user.id,
            patient_id=patient_id,
        )

        # 2. Verify Home Visit if supplied
        home_visit_id = visit_id or req.home_visit_id
        if home_visit_id:
            stmt_visit = select(HomeVisit).where(
                HomeVisit.id == home_visit_id,
                HomeVisit.patient_id == patient_id,
            )
            visit = (await db.execute(stmt_visit)).scalar_one_or_none()
            if not visit:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Specified home visit record does not belong to this patient.",
                )

        # 3. Resolve pregnancy
        pregnancy_id = req.pregnancy_id
        if pregnancy_id:
            stmt_preg = select(Pregnancy).where(
                Pregnancy.id == pregnancy_id,
                Pregnancy.patient_id == patient_id,
            )
            preg = (await db.execute(stmt_preg)).scalar_one_or_none()
            if not preg:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Specified pregnancy record does not belong to this patient.",
                )
        else:
            stmt_active_preg = select(Pregnancy).where(
                Pregnancy.patient_id == patient_id,
                Pregnancy.status == PregnancyStatusEnum.ACTIVE,
            )
            active_preg = (await db.execute(stmt_active_preg)).scalar_one_or_none()
            if not active_preg:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Patient does not have an active pregnancy record. Create a pregnancy record before logging maternal vitals.",
                )
            pregnancy_id = active_preg.id

        now = datetime.now(timezone.utc)
        vital_record = MaternalVitalRecord(
            pregnancy_id=pregnancy_id,
            home_visit_id=home_visit_id,
            recorded_by_user_id=asha_user.id,
            recorded_at=req.recorded_at or now,
            systolic_bp=req.systolic_bp,
            diastolic_bp=req.diastolic_bp,
            weight_kg=req.weight_kg,
            temperature_c=req.temperature_c,
            notes=req.notes.strip() if req.notes else None,
        )
        db.add(vital_record)
        await db.commit()
        await db.refresh(vital_record)

        # Reload with relations
        stmt_reload = (
            select(MaternalVitalRecord)
            .where(MaternalVitalRecord.id == vital_record.id)
            .options(
                selectinload(MaternalVitalRecord.recorded_by),
                selectinload(MaternalVitalRecord.pregnancy),
            )
        )
        reloaded = (await db.execute(stmt_reload)).scalar_one()
        return _to_vital_response(reloaded)

    @staticmethod
    async def list_patient_vitals_for_asha(
        db: AsyncSession,
        asha_user: User,
        patient_id: uuid.UUID,
    ) -> MaternalVitalRecordListResponse:
        """Lists vitals for an actively assigned patient."""
        await AssignmentService.verify_asha_patient_access(
            db=db,
            asha_user_id=asha_user.id,
            patient_id=patient_id,
        )

        stmt = (
            select(MaternalVitalRecord)
            .join(Pregnancy, MaternalVitalRecord.pregnancy_id == Pregnancy.id)
            .where(Pregnancy.patient_id == patient_id)
            .options(
                selectinload(MaternalVitalRecord.recorded_by),
                selectinload(MaternalVitalRecord.pregnancy),
            )
            .order_by(MaternalVitalRecord.recorded_at.desc())
        )
        items = (await db.execute(stmt)).scalars().all()
        responses = [_to_vital_response(v) for v in items]
        return MaternalVitalRecordListResponse(items=responses, total=len(responses))

    @staticmethod
    async def list_my_vitals_for_patient(
        db: AsyncSession,
        patient_user: User,
    ) -> MaternalVitalRecordListResponse:
        """Patient retrieves their own recorded maternal vitals."""
        profile_resp = await PatientService.get_or_create_patient_profile(db=db, user=patient_user)
        patient_id = profile_resp.id

        stmt = (
            select(MaternalVitalRecord)
            .join(Pregnancy, MaternalVitalRecord.pregnancy_id == Pregnancy.id)
            .where(Pregnancy.patient_id == patient_id)
            .options(
                selectinload(MaternalVitalRecord.recorded_by),
                selectinload(MaternalVitalRecord.pregnancy),
            )
            .order_by(MaternalVitalRecord.recorded_at.desc())
        )
        items = (await db.execute(stmt)).scalars().all()
        responses = [_to_vital_response(v) for v in items]
        return MaternalVitalRecordListResponse(items=responses, total=len(responses))

    @staticmethod
    async def list_patient_vitals_for_authorized_user(
        db: AsyncSession,
        current_user: User,
        patient_id: uuid.UUID,
    ) -> MaternalVitalRecordListResponse:
        """Access-controlled clinical maternal vitals listing."""
        stmt_prof = select(PatientProfile).where(PatientProfile.id == patient_id)
        profile = (await db.execute(stmt_prof)).scalar_one_or_none()
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Patient profile not found.",
            )

        if current_user.role == RoleEnum.PATIENT and profile.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You do not have permission to view another patient's vital records.",
            )

        stmt = (
            select(MaternalVitalRecord)
            .join(Pregnancy, MaternalVitalRecord.pregnancy_id == Pregnancy.id)
            .where(Pregnancy.patient_id == patient_id)
            .options(
                selectinload(MaternalVitalRecord.recorded_by),
                selectinload(MaternalVitalRecord.pregnancy),
            )
            .order_by(MaternalVitalRecord.recorded_at.desc())
        )
        items = (await db.execute(stmt)).scalars().all()
        responses = [_to_vital_response(v) for v in items]
        return MaternalVitalRecordListResponse(items=responses, total=len(responses))
