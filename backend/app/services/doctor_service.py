import uuid
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.asha_patient_assignment import (
    AshaPatientAssignment,
    AssignmentStatusEnum,
)
from app.models.asha_profile import AshaProfile
from app.models.doctor_profile import DoctorProfile
from app.models.home_visit import HomeVisit
from app.models.maternal_vital_record import MaternalVitalRecord
from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.user import RoleEnum, User
from app.schemas.assignment import AshaAssignmentCreateRequest, AshaAssignmentResponse
from app.schemas.doctor import (
    DoctorAshaItem,
    DoctorAshaListResponse,
    DoctorPatientItem,
    DoctorPatientRosterResponse,
)
from app.services.assignment_service import AssignmentService
from app.utils.pregnancy_calculations import calculate_gestational_age


class DoctorService:
    @staticmethod
    async def get_doctor_profile(db: AsyncSession, doctor_user: User) -> Optional[DoctorProfile]:
        stmt = select(DoctorProfile).where(DoctorProfile.user_id == doctor_user.id)
        res = await db.execute(stmt)
        return res.scalar_one_or_none()

    @staticmethod
    async def get_doctor_patients(
        db: AsyncSession,
        doctor_user: User,
        unassigned_only: bool = False,
    ) -> DoctorPatientRosterResponse:
        """
        Retrieves patient roster for the authenticated doctor.
        Lists patients with active pregnancy and assignment status.
        """
        stmt = (
            select(PatientProfile)
            .join(PatientProfile.user)
            .where(User.is_active == True)
            .options(
                selectinload(PatientProfile.user),
                selectinload(PatientProfile.pregnancies),
                selectinload(PatientProfile.asha_assignments).selectinload(
                    AshaPatientAssignment.asha_worker
                ).selectinload(AshaProfile.user),
            )
            .order_by(PatientProfile.created_at.desc())
        )
        result = await db.execute(stmt)
        profiles = result.scalars().all()

        items: List[DoctorPatientItem] = []
        for p in profiles:
            active_preg = next((pr for pr in p.pregnancies if pr.status == PregnancyStatusEnum.ACTIVE), None)
            active_assign = next((a for a in p.asha_assignments if a.status == AssignmentStatusEnum.ACTIVE), None)

            if unassigned_only and active_assign is not None:
                continue

            ga_weeks = None
            edd_date = None
            if active_preg:
                try:
                    ga_weeks, _, _ = calculate_gestational_age(active_preg.lmp)
                except Exception:
                    ga_weeks = None
                edd_date = active_preg.edd

            assigned_name = None
            assigned_id = None
            if active_assign and active_assign.asha_worker:
                assigned_name = active_assign.asha_worker.user.full_name
                assigned_id = active_assign.asha_worker.id

            # Query latest home visit
            stmt_v = (
                select(HomeVisit)
                .where(HomeVisit.patient_id == p.id)
                .order_by(HomeVisit.visit_date.desc())
                .limit(1)
            )
            v_res = (await db.execute(stmt_v)).scalar_one_or_none()
            latest_vis_dt = datetime.combine(v_res.visit_date, datetime.min.time()) if v_res else None
            latest_vis_notes = v_res.observations if v_res else None

            vitals_sum = None
            risk_lvl = "NORMAL"
            if active_preg:
                stmt_vit = (
                    select(MaternalVitalRecord)
                    .where(MaternalVitalRecord.pregnancy_id == active_preg.id)
                    .order_by(MaternalVitalRecord.recorded_at.desc())
                    .limit(1)
                )
                vit_res = (await db.execute(stmt_vit)).scalar_one_or_none()
                if vit_res:
                    parts = []
                    if vit_res.systolic_bp and vit_res.diastolic_bp:
                        parts.append(f"BP: {vit_res.systolic_bp}/{vit_res.diastolic_bp} mmHg")
                        if vit_res.systolic_bp >= 140 or vit_res.diastolic_bp >= 90:
                            risk_lvl = "HIGH"
                    if vit_res.weight_kg:
                        parts.append(f"Weight: {vit_res.weight_kg} kg")
                    if vit_res.temperature_c:
                        parts.append(f"Temp: {vit_res.temperature_c} °C")
                    vitals_sum = ", ".join(parts) if parts else None

            items.append(
                DoctorPatientItem(
                    patient_id=p.id,
                    user_id=p.user.id,
                    full_name=p.user.full_name,
                    email=p.user.email,
                    phone=p.user.phone,
                    village_locality=p.village_locality,
                    date_of_birth=p.date_of_birth,
                    blood_group=p.blood_group,
                    has_active_pregnancy=active_preg is not None,
                    active_pregnancy_ga_weeks=ga_weeks,
                    active_pregnancy_edd=edd_date,
                    assigned_asha_name=assigned_name,
                    assigned_asha_id=assigned_id,
                    latest_visit_date=latest_vis_dt,
                    latest_visit_notes=latest_vis_notes,
                    latest_vitals_summary=vitals_sum,
                    risk_level=risk_lvl,
                    created_at=p.created_at,
                )
            )

        return DoctorPatientRosterResponse(items=items, total=len(items))


    @staticmethod
    async def get_available_ashas(
        db: AsyncSession,
        doctor_user: User,
    ) -> DoctorAshaListResponse:
        """Retrieves active ASHA workers available for patient care assignment."""
        stmt = (
            select(AshaProfile)
            .join(AshaProfile.user)
            .where(User.is_active == True, User.role == RoleEnum.ASHA)
            .options(
                selectinload(AshaProfile.user),
                selectinload(AshaProfile.assignments),
            )
        )
        result = await db.execute(stmt)
        ashas = result.scalars().all()

        items: List[DoctorAshaItem] = []
        for a in ashas:
            active_count = sum(1 for asgn in a.assignments if asgn.status == AssignmentStatusEnum.ACTIVE)
            items.append(
                DoctorAshaItem(
                    asha_id=a.id,
                    user_id=a.user.id,
                    full_name=a.user.full_name,
                    email=a.user.email,
                    phone=a.user.phone,
                    worker_id_code=a.worker_id_code,
                    assigned_area=a.assigned_area,
                    primary_health_center=a.primary_health_center,
                    active_patients_count=active_count,
                )
            )

        return DoctorAshaListResponse(items=items, total=len(items))

    @staticmethod
    async def doctor_assign_asha(
        db: AsyncSession,
        doctor_user: User,
        patient_id: uuid.UUID,
        asha_worker_id: uuid.UUID,
        notes: Optional[str] = None,
    ) -> AshaAssignmentResponse:
        """Allows an authenticated Doctor to assign an active ASHA to a patient."""
        req = AshaAssignmentCreateRequest(
            asha_worker_id=asha_worker_id,
            patient_id=patient_id,
            notes=notes,
        )
        return await AssignmentService.create_assignment(
            db=db,
            admin_user=doctor_user,  # uses doctor's user instance as authorized assigner
            req=req,
        )
