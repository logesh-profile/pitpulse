import uuid
from datetime import date, datetime
from typing import Any, Dict, List, Optional
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.asha_patient_assignment import AshaPatientAssignment
from app.models.asha_profile import AshaProfile
from app.models.home_visit import HomeVisit
from app.models.maternal_vital_record import MaternalVitalRecord
from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.user import User
from app.patient_ai.domain.schemas import (
    AiSourceBadge,
    AiSourceType,
    ScreeningSeverity,
)
from app.patient_ai.knowledge.maternal_kb import MaternalKnowledgeBase
from app.patient_ai.screening.clinical_rules import ClinicalScreeningRules
from app.utils.pregnancy_calculations import (
    calculate_edd,
    calculate_gestational_age,
    calculate_trimester,
)


class PatientAiTools:
    """
    Strongly typed, authorization-enforced patient data and knowledge retrieval tools.
    Every patient data tool MUST take `patient_user` derived strictly from JWT authentication.
    """

    @classmethod
    async def get_patient_profile(
        cls, db: AsyncSession, patient_user: User
    ) -> Optional[PatientProfile]:
        """Helper to get patient profile with health record."""
        stmt = (
            select(PatientProfile)
            .where(PatientProfile.user_id == patient_user.id)
            .options(selectinload(PatientProfile.health_record))
        )
        res = await db.execute(stmt)
        return res.scalar_one_or_none()

    @classmethod
    async def get_my_active_pregnancy(
        cls, db: AsyncSession, patient_user: User
    ) -> Dict[str, Any]:
        """
        Tool: get_my_active_pregnancy
        Retrieves the authenticated patient's currently active pregnancy record.
        Calculates gestational age weeks, days, trimester, and Estimated Due Date (EDD).
        """
        profile = await cls.get_patient_profile(db, patient_user)
        if not profile:
            return {
                "has_active_pregnancy": False,
                "message": "Patient profile not found or not initialized.",
            }

        stmt = (
            select(Pregnancy)
            .where(
                Pregnancy.patient_id == profile.id,
                Pregnancy.status == PregnancyStatusEnum.ACTIVE,
            )
            .order_by(desc(Pregnancy.pregnancy_number))
        )
        res = await db.execute(stmt)
        active_preg = res.scalar_one_or_none()

        if not active_preg:
            return {
                "has_active_pregnancy": False,
                "message": "No active pregnancy record registered in your PitPulse account.",
            }

        weeks, days, ga_display = calculate_gestational_age(lmp=active_preg.lmp)
        trimester_num, trimester_display = calculate_trimester(weeks=weeks)
        edd_val = calculate_edd(lmp=active_preg.lmp)

        return {
            "has_active_pregnancy": True,
            "pregnancy_id": str(active_preg.id),
            "pregnancy_number": active_preg.pregnancy_number,
            "status": active_preg.status.value,
            "lmp": active_preg.lmp.isoformat(),
            "edd": edd_val.isoformat(),
            "gestational_age_weeks": weeks,
            "gestational_age_days": days,
            "gestational_age_display": ga_display,
            "trimester": trimester_num,
            "trimester_display": trimester_display,
            "notes": active_preg.notes,
        }

    @classmethod
    async def get_my_pregnancy_timeline(
        cls, db: AsyncSession, patient_user: User
    ) -> Dict[str, Any]:
        """
        Tool: get_my_pregnancy_timeline
        Retrieves all pregnancy records (past and present) for the authenticated patient.
        """
        profile = await cls.get_patient_profile(db, patient_user)
        if not profile:
            return {"total_records": 0, "pregnancies": []}

        stmt = (
            select(Pregnancy)
            .where(Pregnancy.patient_id == profile.id)
            .order_by(desc(Pregnancy.pregnancy_number))
        )
        res = await db.execute(stmt)
        records = res.scalars().all()

        timeline = []
        for p in records:
            weeks, days, ga_display = calculate_gestational_age(lmp=p.lmp)
            trimester_num, trimester_display = calculate_trimester(weeks=weeks)
            edd_val = calculate_edd(lmp=p.lmp)
            timeline.append({
                "pregnancy_id": str(p.id),
                "pregnancy_number": p.pregnancy_number,
                "status": p.status.value,
                "lmp": p.lmp.isoformat(),
                "edd": edd_val.isoformat(),
                "gestational_age_display": ga_display,
                "trimester_display": trimester_display,
            })

        return {
            "total_records": len(timeline),
            "pregnancies": timeline,
        }

    @classmethod
    async def get_my_latest_vitals(
        cls, db: AsyncSession, patient_user: User
    ) -> Dict[str, Any]:
        """
        Tool: get_my_latest_vitals
        Retrieves the most recent maternal vital sign observation (Blood Pressure, Weight, Temperature).
        """
        profile = await cls.get_patient_profile(db, patient_user)
        if not profile:
            return {"has_vitals": False, "message": "Patient profile not found."}

        stmt = (
            select(MaternalVitalRecord)
            .join(Pregnancy, MaternalVitalRecord.pregnancy_id == Pregnancy.id)
            .where(Pregnancy.patient_id == profile.id)
            .options(
                selectinload(MaternalVitalRecord.recorded_by),
                selectinload(MaternalVitalRecord.pregnancy),
            )
            .order_by(desc(MaternalVitalRecord.recorded_at))
            .limit(1)
        )
        res = await db.execute(stmt)
        vital = res.scalar_one_or_none()

        if not vital:
            return {
                "has_vitals": False,
                "message": "No maternal vitals have been recorded yet in your account.",
            }

        bp_eval = None
        if vital.systolic_bp is not None and vital.diastolic_bp is not None:
            bp_eval = ClinicalScreeningRules.evaluate_blood_pressure(
                systolic=vital.systolic_bp,
                diastolic=vital.diastolic_bp,
            )

        return {
            "has_vitals": True,
            "vital_id": str(vital.id),
            "pregnancy_number": vital.pregnancy.pregnancy_number if vital.pregnancy else None,
            "recorded_at": vital.recorded_at.isoformat(),
            "systolic_bp": vital.systolic_bp,
            "diastolic_bp": vital.diastolic_bp,
            "bp_display": f"{vital.systolic_bp}/{vital.diastolic_bp} mmHg" if vital.systolic_bp and vital.diastolic_bp else None,
            "weight_kg": vital.weight_kg,
            "temperature_c": vital.temperature_c,
            "notes": vital.notes,
            "recorded_by_name": vital.recorded_by.full_name if vital.recorded_by else "Health Worker",
            "recorded_by_role": vital.recorded_by.role.value if vital.recorded_by else "ASHA",
            "bp_screening_evaluation": bp_eval,
        }

    @classmethod
    async def get_my_vitals_history(
        cls, db: AsyncSession, patient_user: User, limit: int = 10
    ) -> Dict[str, Any]:
        """
        Tool: get_my_vitals_history
        Retrieves chronological history of all vital observations for the authenticated patient.
        """
        profile = await cls.get_patient_profile(db, patient_user)
        if not profile:
            return {"total_observations": 0, "observations": []}

        stmt = (
            select(MaternalVitalRecord)
            .join(Pregnancy, MaternalVitalRecord.pregnancy_id == Pregnancy.id)
            .where(Pregnancy.patient_id == profile.id)
            .options(
                selectinload(MaternalVitalRecord.recorded_by),
                selectinload(MaternalVitalRecord.pregnancy),
            )
            .order_by(desc(MaternalVitalRecord.recorded_at))
            .limit(limit)
        )
        res = await db.execute(stmt)
        vitals = res.scalars().all()

        observations = []
        for v in vitals:
            bp_eval = None
            if v.systolic_bp is not None and v.diastolic_bp is not None:
                bp_eval = ClinicalScreeningRules.evaluate_blood_pressure(
                    systolic=v.systolic_bp, diastolic=v.diastolic_bp
                )
            observations.append({
                "vital_id": str(v.id),
                "recorded_at": v.recorded_at.isoformat(),
                "bp_display": f"{v.systolic_bp}/{v.diastolic_bp} mmHg" if v.systolic_bp and v.diastolic_bp else "N/A",
                "weight_kg": v.weight_kg,
                "temperature_c": v.temperature_c,
                "notes": v.notes,
                "recorded_by": v.recorded_by.full_name if v.recorded_by else "Health Worker",
                "bp_evaluation": bp_eval,
            })

        return {
            "total_observations": len(observations),
            "observations": observations,
        }

    @classmethod
    async def get_my_recent_home_visits(
        cls, db: AsyncSession, patient_user: User, limit: int = 5
    ) -> Dict[str, Any]:
        """
        Tool: get_my_recent_home_visits
        Retrieves ASHA field visits and community checkup logs conducted for the patient.
        """
        profile = await cls.get_patient_profile(db, patient_user)
        if not profile:
            return {"total_visits": 0, "visits": []}

        stmt = (
            select(HomeVisit)
            .where(HomeVisit.patient_id == profile.id)
            .options(selectinload(HomeVisit.asha_worker).selectinload(AshaProfile.user))
            .order_by(desc(HomeVisit.visit_date))
            .limit(limit)
        )
        res = await db.execute(stmt)
        visits = res.scalars().all()

        results = []
        for vis in visits:
            worker_name = "ASHA Worker"
            if vis.asha_worker and vis.asha_worker.user:
                worker_name = vis.asha_worker.user.full_name
            results.append({
                "visit_id": str(vis.id),
                "visit_date": vis.visit_date.isoformat(),
                "asha_worker_name": worker_name,
                "purpose": vis.purpose,
                "observations": vis.observations,
                "notes": vis.notes,
                "follow_up_required": vis.follow_up_required,
                "follow_up_notes": vis.follow_up_notes,
            })

        return {
            "total_visits": len(results),
            "visits": results,
        }

    @classmethod
    async def get_my_health_summary(
        cls, db: AsyncSession, patient_user: User
    ) -> Dict[str, Any]:
        """
        Tool: get_my_health_summary
        Aggregates baseline profile identity, active pregnancy, latest vitals, and assigned ASHA.
        """
        profile = await cls.get_patient_profile(db, patient_user)
        active_preg = await cls.get_my_active_pregnancy(db, patient_user)
        latest_vitals = await cls.get_my_latest_vitals(db, patient_user)

        # Query assigned ASHA worker
        assigned_asha_name = None
        if profile:
            stmt = (
                select(AshaPatientAssignment)
                .where(
                    AshaPatientAssignment.patient_id == profile.id,
                    AshaPatientAssignment.status == "ACTIVE",
                )
                .options(selectinload(AshaPatientAssignment.asha_worker).selectinload(AshaProfile.user))
                .order_by(desc(AshaPatientAssignment.assigned_at))
                .limit(1)
            )
            res = await db.execute(stmt)
            assignment = res.scalar_one_or_none()
            if assignment and assignment.asha_worker and assignment.asha_worker.user:
                assigned_asha_name = assignment.asha_worker.user.full_name

        return {
            "patient_name": patient_user.full_name,
            "patient_email": patient_user.email,
            "health_record_number": profile.health_record.record_number if profile and profile.health_record else None,
            "blood_group": profile.blood_group if profile else None,
            "village_locality": profile.village_locality if profile else None,
            "assigned_asha_worker": assigned_asha_name,
            "active_pregnancy": active_preg if active_preg.get("has_active_pregnancy") else None,
            "latest_vitals": latest_vitals if latest_vitals.get("has_vitals") else None,
        }

    @classmethod
    def retrieve_maternal_knowledge(
        cls, query: str, topic: Optional[str] = None, week: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Tool: retrieve_maternal_knowledge
        Searches the curated, versioned clinical knowledge base for verified guidelines and citations.
        """
        results = MaternalKnowledgeBase.search_knowledge(query=query, topic_filter=topic, weeks=week)
        return {
            "query": query,
            "kb_version": MaternalKnowledgeBase.VERSION,
            "match_count": len(results),
            "articles": results,
        }

    @classmethod
    def evaluate_vital_screening(
        cls, systolic_bp: int, diastolic_bp: int
    ) -> Dict[str, Any]:
        """
        Tool: evaluate_vital_screening
        Runs deterministic obstetrical screening thresholds on blood pressure.
        """
        return ClinicalScreeningRules.evaluate_blood_pressure(systolic=systolic_bp, diastolic=diastolic_bp)
