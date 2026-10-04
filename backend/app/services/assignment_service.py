import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.asha_patient_assignment import (
    AshaPatientAssignment,
    AssignmentStatusEnum,
)
from app.models.asha_profile import AshaProfile
from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.user import RoleEnum, User
from app.schemas.assignment import (
    AshaAssignmentCreateRequest,
    AshaAssignmentListResponse,
    AshaAssignmentResponse,
    AshaAssignmentUpdateRequest,
)


def _to_assignment_response(a: AshaPatientAssignment) -> AshaAssignmentResponse:
    asha_name = a.asha_worker.user.full_name if a.asha_worker and a.asha_worker.user else "ASHA Worker"
    asha_code = a.asha_worker.worker_id_code if a.asha_worker else None
    asha_area = a.asha_worker.assigned_area if a.asha_worker else None

    patient_name = a.patient.user.full_name if a.patient and a.patient.user else "Patient"
    hr_num = a.patient.health_record.record_number if a.patient and a.patient.health_record else None
    village = a.patient.village_locality if a.patient else None

    return AshaAssignmentResponse(
        id=a.id,
        asha_worker_id=a.asha_worker_id,
        asha_worker_name=asha_name,
        asha_worker_code=asha_code,
        asha_assigned_area=asha_area,
        patient_id=a.patient_id,
        patient_name=patient_name,
        patient_health_record_number=hr_num,
        patient_village=village,
        status=a.status,
        assigned_at=a.assigned_at,
        unassigned_at=a.unassigned_at,
        notes=a.notes,
        created_at=a.created_at,
        updated_at=a.updated_at,
    )


class AssignmentService:
    @staticmethod
    async def create_assignment(
        db: AsyncSession,
        admin_user: User,
        req: AshaAssignmentCreateRequest,
    ) -> AshaAssignmentResponse:
        """Admin or Doctor creates or reassigns a patient to an ASHA worker."""
        if admin_user.role not in (RoleEnum.ADMIN, RoleEnum.DOCTOR):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only Doctors or System Administrators can create or modify ASHA patient assignments.",
            )

        # 1. Validate ASHA profile
        stmt_asha = (
            select(AshaProfile)
            .where(AshaProfile.id == req.asha_worker_id)
            .options(selectinload(AshaProfile.user))
        )
        asha_res = await db.execute(stmt_asha)
        asha_prof = asha_res.scalar_one_or_none()
        if not asha_prof:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="ASHA worker profile not found.",
            )

        # 2. Validate Patient profile
        stmt_pat = (
            select(PatientProfile)
            .where(PatientProfile.id == req.patient_id)
            .options(
                selectinload(PatientProfile.user),
                selectinload(PatientProfile.health_record),
            )
        )
        pat_res = await db.execute(stmt_pat)
        pat_prof = pat_res.scalar_one_or_none()
        if not pat_prof:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Patient profile not found.",
            )

        # 3. Check for existing active assignment
        stmt_active = select(AshaPatientAssignment).where(
            AshaPatientAssignment.patient_id == req.patient_id,
            AshaPatientAssignment.status == AssignmentStatusEnum.ACTIVE,
        )
        active_res = await db.execute(stmt_active)
        active_assignment = active_res.scalar_one_or_none()

        now = datetime.now(timezone.utc)

        if active_assignment:
            if active_assignment.asha_worker_id == req.asha_worker_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="This patient is already actively assigned to this ASHA worker.",
                )
            # Reassignment: Deactivate prior active assignment
            active_assignment.status = AssignmentStatusEnum.INACTIVE
            active_assignment.unassigned_at = now
            active_assignment.updated_at = now

        # 4. Create new active assignment
        new_assignment = AshaPatientAssignment(
            asha_worker_id=req.asha_worker_id,
            patient_id=req.patient_id,
            status=AssignmentStatusEnum.ACTIVE,
            assigned_at=now,
            notes=req.notes.strip() if req.notes else None,
        )
        db.add(new_assignment)
        await db.commit()
        await db.refresh(new_assignment)

        # Reload with relations
        stmt_reload = (
            select(AshaPatientAssignment)
            .where(AshaPatientAssignment.id == new_assignment.id)
            .options(
                selectinload(AshaPatientAssignment.asha_worker).selectinload(AshaProfile.user),
                selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.user),
                selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.health_record),
            )
        )
        reloaded = (await db.execute(stmt_reload)).scalar_one()
        return _to_assignment_response(reloaded)

    @staticmethod
    async def list_assignments(
        db: AsyncSession,
        status_filter: Optional[AssignmentStatusEnum] = None,
    ) -> AshaAssignmentListResponse:
        """Lists all assignments across the system with optional status filter."""
        stmt = (
            select(AshaPatientAssignment)
            .options(
                selectinload(AshaPatientAssignment.asha_worker).selectinload(AshaProfile.user),
                selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.user),
                selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.health_record),
            )
            .order_by(AshaPatientAssignment.assigned_at.desc())
        )
        if status_filter:
            stmt = stmt.where(AshaPatientAssignment.status == status_filter)

        result = await db.execute(stmt)
        items = result.scalars().all()
        responses = [_to_assignment_response(a) for a in items]
        return AshaAssignmentListResponse(items=responses, total=len(responses))

    @staticmethod
    async def update_assignment(
        db: AsyncSession,
        admin_user: User,
        assignment_id: uuid.UUID,
        req: AshaAssignmentUpdateRequest,
    ) -> AshaAssignmentResponse:
        """Admin deactivates or updates an assignment record."""
        if admin_user.role != RoleEnum.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only System Administrators can update assignment records.",
            )

        stmt = (
            select(AshaPatientAssignment)
            .where(AshaPatientAssignment.id == assignment_id)
            .options(
                selectinload(AshaPatientAssignment.asha_worker).selectinload(AshaProfile.user),
                selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.user),
                selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.health_record),
            )
        )
        res = await db.execute(stmt)
        assignment = res.scalar_one_or_none()
        if not assignment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Assignment record not found.",
            )

        now = datetime.now(timezone.utc)
        if req.status is not None:
            assignment.status = req.status
            if req.status == AssignmentStatusEnum.INACTIVE and not assignment.unassigned_at:
                assignment.unassigned_at = now
            elif req.status == AssignmentStatusEnum.ACTIVE:
                assignment.unassigned_at = None

        if req.notes is not None:
            assignment.notes = req.notes.strip() if req.notes else None

        assignment.updated_at = now
        await db.commit()
        await db.refresh(assignment)

        return _to_assignment_response(assignment)

    @staticmethod
    async def get_patient_active_assignment(
        db: AsyncSession,
        patient_id: uuid.UUID,
    ) -> Optional[AshaAssignmentResponse]:
        """Retrieves active ASHA assignment for a patient profile."""
        stmt = (
            select(AshaPatientAssignment)
            .where(
                AshaPatientAssignment.patient_id == patient_id,
                AshaPatientAssignment.status == AssignmentStatusEnum.ACTIVE,
            )
            .options(
                selectinload(AshaPatientAssignment.asha_worker).selectinload(AshaProfile.user),
                selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.user),
                selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.health_record),
            )
        )
        res = await db.execute(stmt)
        assignment = res.scalar_one_or_none()
        if not assignment:
            return None
        return _to_assignment_response(assignment)

    @staticmethod
    async def verify_asha_patient_access(
        db: AsyncSession,
        asha_user_id: uuid.UUID,
        patient_id: uuid.UUID,
    ) -> AshaProfile:
        """
        Verifies that the authenticated ASHA user has an ACTIVE assignment for the given patient_id.
        Raises 403 if unassigned or unauthorized.
        """
        stmt_prof = select(AshaProfile).where(AshaProfile.user_id == asha_user_id)
        asha_prof = (await db.execute(stmt_prof)).scalar_one_or_none()
        if not asha_prof:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User does not have an active ASHA worker profile.",
            )

        stmt_check = select(AshaPatientAssignment).where(
            AshaPatientAssignment.asha_worker_id == asha_prof.id,
            AshaPatientAssignment.patient_id == patient_id,
            AshaPatientAssignment.status == AssignmentStatusEnum.ACTIVE,
        )
        active_assignment = (await db.execute(stmt_check)).scalar_one_or_none()
        if not active_assignment:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: Patient is not actively assigned to you.",
            )

        return asha_prof
