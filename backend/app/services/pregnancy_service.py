import uuid
from datetime import date, datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.user import RoleEnum, User
from app.schemas.pregnancy import (
    PregnancyCreateRequest,
    PregnancyListResponse,
    PregnancyResponse,
    PregnancyUpdateRequest,
)
from app.services.patient_service import PatientService
from app.utils.pregnancy_calculations import (
    calculate_edd,
    calculate_gestational_age,
    calculate_trimester,
)


def _to_pregnancy_response(p: Pregnancy) -> PregnancyResponse:
    """Helper to convert Pregnancy ORM model into PregnancyResponse with derived calculations."""
    try:
        weeks, days, ga_display = calculate_gestational_age(p.lmp)
    except ValueError:
        weeks, days, ga_display = 0, 0, "0 weeks 0 days"

    trimester_num, trimester_display = calculate_trimester(weeks)

    return PregnancyResponse(
        id=p.id,
        patient_id=p.patient_id,
        pregnancy_number=p.pregnancy_number,
        status=p.status,
        lmp=p.lmp,
        edd=p.edd,
        gestational_age_weeks=weeks,
        gestational_age_days=days,
        gestational_age_display=ga_display,
        trimester=trimester_num,
        trimester_display=trimester_display,
        notes=p.notes,
        created_at=p.created_at,
        updated_at=p.updated_at,
    )


class PregnancyService:
    @staticmethod
    async def create_pregnancy(
        db: AsyncSession,
        current_user: User,
        req: PregnancyCreateRequest,
    ) -> PregnancyResponse:
        """Creates a new pregnancy record for the authenticated patient."""
        # Ensure patient profile exists
        profile_resp = await PatientService.get_or_create_patient_profile(db=db, user=current_user)
        patient_id = profile_resp.id

        # 1. Validate LMP date
        today = date.today()
        if req.lmp > today:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Last Menstrual Period (LMP) cannot be a future date.",
            )

        # 2. Prevent duplicate active pregnancies
        stmt_active = select(Pregnancy).where(
            Pregnancy.patient_id == patient_id,
            Pregnancy.status == PregnancyStatusEnum.ACTIVE,
        )
        res_active = await db.execute(stmt_active)
        active_p = res_active.scalar_one_or_none()
        if active_p:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Patient already has an active pregnancy (Pregnancy #{active_p.pregnancy_number}). Mark the existing pregnancy as COMPLETED or TERMINATED before registering a new one.",
            )

        # 3. Determine pregnancy number
        if req.pregnancy_number is not None:
            stmt_exists = select(Pregnancy).where(
                Pregnancy.patient_id == patient_id,
                Pregnancy.pregnancy_number == req.pregnancy_number,
            )
            res_exists = await db.execute(stmt_exists)
            if res_exists.scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Pregnancy #{req.pregnancy_number} already exists for this patient.",
                )
            p_num = req.pregnancy_number
        else:
            stmt_max = select(func.coalesce(func.max(Pregnancy.pregnancy_number), 0)).where(
                Pregnancy.patient_id == patient_id
            )
            max_num = (await db.execute(stmt_max)).scalar()
            p_num = max_num + 1

        # 4. Calculate deterministic EDD from LMP
        edd = calculate_edd(req.lmp)

        pregnancy = Pregnancy(
            patient_id=patient_id,
            pregnancy_number=p_num,
            status=PregnancyStatusEnum.ACTIVE,
            lmp=req.lmp,
            edd=edd,
            notes=req.notes.strip() if req.notes else None,
        )
        db.add(pregnancy)
        await db.commit()
        await db.refresh(pregnancy)

        return _to_pregnancy_response(pregnancy)

    @staticmethod
    async def get_my_pregnancies(
        db: AsyncSession,
        current_user: User,
    ) -> PregnancyListResponse:
        """Retrieves all pregnancy records for the authenticated patient."""
        profile_resp = await PatientService.get_or_create_patient_profile(db=db, user=current_user)
        patient_id = profile_resp.id

        stmt = (
            select(Pregnancy)
            .where(Pregnancy.patient_id == patient_id)
            .order_by(Pregnancy.pregnancy_number.desc())
        )
        result = await db.execute(stmt)
        pregnancies = result.scalars().all()

        items = [_to_pregnancy_response(p) for p in pregnancies]
        return PregnancyListResponse(items=items, total=len(items))

    @staticmethod
    async def get_my_pregnancy_by_id(
        db: AsyncSession,
        current_user: User,
        pregnancy_id: uuid.UUID,
    ) -> PregnancyResponse:
        """Retrieves a single pregnancy record by ID for the authenticated patient with IDOR protection."""
        profile_resp = await PatientService.get_or_create_patient_profile(db=db, user=current_user)
        patient_id = profile_resp.id

        stmt = select(Pregnancy).where(
            Pregnancy.id == pregnancy_id,
            Pregnancy.patient_id == patient_id,
        )
        result = await db.execute(stmt)
        pregnancy = result.scalar_one_or_none()

        if not pregnancy:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pregnancy record not found.",
            )

        return _to_pregnancy_response(pregnancy)

    @staticmethod
    async def update_my_pregnancy(
        db: AsyncSession,
        current_user: User,
        pregnancy_id: uuid.UUID,
        req: PregnancyUpdateRequest,
    ) -> PregnancyResponse:
        """Updates editable fields (status, notes) of a pregnancy record owned by the authenticated patient."""
        profile_resp = await PatientService.get_or_create_patient_profile(db=db, user=current_user)
        patient_id = profile_resp.id

        stmt = select(Pregnancy).where(
            Pregnancy.id == pregnancy_id,
            Pregnancy.patient_id == patient_id,
        )
        result = await db.execute(stmt)
        pregnancy = result.scalar_one_or_none()

        if not pregnancy:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pregnancy record not found.",
            )

        if req.status is not None:
            pregnancy.status = req.status
        if req.notes is not None:
            pregnancy.notes = req.notes.strip() if req.notes else None

        pregnancy.updated_at = datetime.now(timezone.utc)
        await db.commit()
        await db.refresh(pregnancy)

        return _to_pregnancy_response(pregnancy)

    @staticmethod
    async def get_patient_pregnancies_by_patient_id(
        db: AsyncSession,
        current_user: User,
        patient_id: uuid.UUID,
    ) -> PregnancyListResponse:
        """
        Retrieves pregnancy list for a given patient_id with backend IDOR protection.
        - Patients can only query their own patient_id.
        - DOCTOR, ASHA, and ADMIN can access.
        """
        stmt_prof = select(PatientProfile).where(PatientProfile.id == patient_id)
        prof_res = await db.execute(stmt_prof)
        profile = prof_res.scalar_one_or_none()

        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Patient profile not found.",
            )

        # IDOR enforcement
        if current_user.role == RoleEnum.PATIENT and profile.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You do not have permission to view another patient's pregnancy records.",
            )

        stmt = (
            select(Pregnancy)
            .where(Pregnancy.patient_id == patient_id)
            .order_by(Pregnancy.pregnancy_number.desc())
        )
        result = await db.execute(stmt)
        pregnancies = result.scalars().all()

        items = [_to_pregnancy_response(p) for p in pregnancies]
        return PregnancyListResponse(items=items, total=len(items))

    @staticmethod
    async def get_patient_pregnancy_by_id_for_user(
        db: AsyncSession,
        current_user: User,
        patient_id: uuid.UUID,
        pregnancy_id: uuid.UUID,
    ) -> PregnancyResponse:
        """Retrieves a specific pregnancy record for a patient_id with IDOR protection."""
        stmt_prof = select(PatientProfile).where(PatientProfile.id == patient_id)
        prof_res = await db.execute(stmt_prof)
        profile = prof_res.scalar_one_or_none()

        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Patient profile not found.",
            )

        # IDOR enforcement
        if current_user.role == RoleEnum.PATIENT and profile.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You do not have permission to view another patient's pregnancy record.",
            )

        stmt = select(Pregnancy).where(
            Pregnancy.id == pregnancy_id,
            Pregnancy.patient_id == patient_id,
        )
        result = await db.execute(stmt)
        pregnancy = result.scalar_one_or_none()

        if not pregnancy:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pregnancy record not found.",
            )

        return _to_pregnancy_response(pregnancy)
