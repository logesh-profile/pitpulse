import uuid
from datetime import date, datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.asha_profile import AshaProfile
from app.models.home_visit import HomeVisit, VisitStatusEnum
from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.user import RoleEnum, User
from app.schemas.home_visit import (
    HomeVisitCreateRequest,
    HomeVisitListResponse,
    HomeVisitResponse,
)
from app.services.assignment_service import AssignmentService
from app.services.patient_service import PatientService


def _to_home_visit_response(v: HomeVisit) -> HomeVisitResponse:
    pat_name = v.patient.user.full_name if v.patient and v.patient.user else "Patient"
    hr_num = v.patient.health_record.record_number if v.patient and v.patient.health_record else None
    asha_name = v.asha_worker.user.full_name if v.asha_worker and v.asha_worker.user else "ASHA Worker"
    preg_num = v.pregnancy.pregnancy_number if v.pregnancy else None

    return HomeVisitResponse(
        id=v.id,
        patient_id=v.patient_id,
        patient_name=pat_name,
        patient_health_record_number=hr_num,
        pregnancy_id=v.pregnancy_id,
        pregnancy_number=preg_num,
        asha_worker_id=v.asha_worker_id,
        asha_worker_name=asha_name,
        visit_date=v.visit_date,
        started_at=v.started_at,
        completed_at=v.completed_at,
        status=v.status,
        purpose=v.purpose,
        observations=v.observations,
        notes=v.notes,
        follow_up_required=v.follow_up_required,
        follow_up_notes=v.follow_up_notes,
        created_at=v.created_at,
        updated_at=v.updated_at,
    )


class HomeVisitService:
    @staticmethod
    async def create_home_visit_for_asha(
        db: AsyncSession,
        asha_user: User,
        patient_id: uuid.UUID,
        req: HomeVisitCreateRequest,
    ) -> HomeVisitResponse:
        """ASHA creates a home visit for an actively assigned patient."""
        if asha_user.role != RoleEnum.ASHA:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only ASHA health workers can record field home visits.",
            )

        # 1. Verify active ASHA assignment
        asha_prof = await AssignmentService.verify_asha_patient_access(
            db=db,
            asha_user_id=asha_user.id,
            patient_id=patient_id,
        )

        # 2. Date validation
        if req.visit_date > date.today():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Visit date cannot be a future date.",
            )

        # 3. Pregnancy resolution & validation
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
            # Auto-link current active pregnancy if present
            stmt_active_preg = select(Pregnancy).where(
                Pregnancy.patient_id == patient_id,
                Pregnancy.status == PregnancyStatusEnum.ACTIVE,
            )
            active_preg = (await db.execute(stmt_active_preg)).scalar_one_or_none()
            if active_preg:
                pregnancy_id = active_preg.id

        now = datetime.now(timezone.utc)
        visit = HomeVisit(
            patient_id=patient_id,
            pregnancy_id=pregnancy_id,
            asha_worker_id=asha_prof.id,
            visit_date=req.visit_date,
            started_at=req.started_at,
            completed_at=req.completed_at or now,
            status=VisitStatusEnum.COMPLETED,
            purpose=req.purpose.strip(),
            observations=req.observations.strip() if req.observations else None,
            notes=req.notes.strip() if req.notes else None,
            follow_up_required=req.follow_up_required,
            follow_up_notes=req.follow_up_notes.strip() if req.follow_up_notes else None,
        )
        db.add(visit)
        await db.commit()
        await db.refresh(visit)

        # Reload with relations
        stmt_reload = (
            select(HomeVisit)
            .where(HomeVisit.id == visit.id)
            .options(
                selectinload(HomeVisit.patient).selectinload(PatientProfile.user),
                selectinload(HomeVisit.patient).selectinload(PatientProfile.health_record),
                selectinload(HomeVisit.asha_worker).selectinload(AshaProfile.user),
                selectinload(HomeVisit.pregnancy),
            )
        )
        reloaded = (await db.execute(stmt_reload)).scalar_one()
        return _to_home_visit_response(reloaded)

    @staticmethod
    async def list_home_visits_for_asha(
        db: AsyncSession,
        asha_user: User,
        patient_id: uuid.UUID,
    ) -> HomeVisitListResponse:
        """Lists home visits for an actively assigned patient."""
        await AssignmentService.verify_asha_patient_access(
            db=db,
            asha_user_id=asha_user.id,
            patient_id=patient_id,
        )

        stmt = (
            select(HomeVisit)
            .where(HomeVisit.patient_id == patient_id)
            .options(
                selectinload(HomeVisit.patient).selectinload(PatientProfile.user),
                selectinload(HomeVisit.patient).selectinload(PatientProfile.health_record),
                selectinload(HomeVisit.asha_worker).selectinload(AshaProfile.user),
                selectinload(HomeVisit.pregnancy),
            )
            .order_by(HomeVisit.visit_date.desc(), HomeVisit.created_at.desc())
        )
        items = (await db.execute(stmt)).scalars().all()
        responses = [_to_home_visit_response(v) for v in items]
        return HomeVisitListResponse(items=responses, total=len(responses))

    @staticmethod
    async def list_my_home_visits_for_patient(
        db: AsyncSession,
        patient_user: User,
    ) -> HomeVisitListResponse:
        """Patient retrieves their own home visits."""
        profile_resp = await PatientService.get_or_create_patient_profile(db=db, user=patient_user)
        patient_id = profile_resp.id

        stmt = (
            select(HomeVisit)
            .where(HomeVisit.patient_id == patient_id)
            .options(
                selectinload(HomeVisit.patient).selectinload(PatientProfile.user),
                selectinload(HomeVisit.patient).selectinload(PatientProfile.health_record),
                selectinload(HomeVisit.asha_worker).selectinload(AshaProfile.user),
                selectinload(HomeVisit.pregnancy),
            )
            .order_by(HomeVisit.visit_date.desc(), HomeVisit.created_at.desc())
        )
        items = (await db.execute(stmt)).scalars().all()
        responses = [_to_home_visit_response(v) for v in items]
        return HomeVisitListResponse(items=responses, total=len(responses))

    @staticmethod
    async def list_patient_home_visits_for_authorized_user(
        db: AsyncSession,
        current_user: User,
        patient_id: uuid.UUID,
    ) -> HomeVisitListResponse:
        """Access-controlled clinical home visits listing."""
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
                detail="Access denied: You do not have permission to view another patient's home visits.",
            )

        stmt = (
            select(HomeVisit)
            .where(HomeVisit.patient_id == patient_id)
            .options(
                selectinload(HomeVisit.patient).selectinload(PatientProfile.user),
                selectinload(HomeVisit.patient).selectinload(PatientProfile.health_record),
                selectinload(HomeVisit.asha_worker).selectinload(AshaProfile.user),
                selectinload(HomeVisit.pregnancy),
            )
            .order_by(HomeVisit.visit_date.desc(), HomeVisit.created_at.desc())
        )
        items = (await db.execute(stmt)).scalars().all()
        responses = [_to_home_visit_response(v) for v in items]
        return HomeVisitListResponse(items=responses, total=len(responses))
