import uuid
from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import require_asha
from app.core.database import get_db
from app.models.asha_patient_assignment import (
    AshaPatientAssignment,
    AssignmentStatusEnum,
)
from app.models.asha_profile import AshaProfile
from app.models.home_visit import HomeVisit
from app.models.patient_profile import PatientProfile
from app.models.pregnancy import Pregnancy, PregnancyStatusEnum
from app.models.user import User
from app.schemas.assignment import AshaPatientItemResponse
from app.schemas.home_visit import (
    HomeVisitCreateRequest,
    HomeVisitListResponse,
    HomeVisitResponse,
)
from app.schemas.patient import PatientProfileResponse
from app.schemas.pregnancy import PregnancyResponse
from app.schemas.vitals import (
    MaternalVitalRecordCreateRequest,
    MaternalVitalRecordListResponse,
    MaternalVitalRecordResponse,
)
from app.services.assignment_service import AssignmentService
from app.services.home_visit_service import HomeVisitService
from app.services.pregnancy_service import _to_pregnancy_response
from app.services.vitals_service import VitalsService

router = APIRouter(prefix="/asha", tags=["ASHA Field Healthcare Operations"])


# ==========================================
# 1. Assigned Patients Listing & Detail
# ==========================================

@router.get(
    "/me/patients",
    response_model=List[AshaPatientItemResponse],
    status_code=status.HTTP_200_OK,
    summary="List patients actively assigned to authenticated ASHA worker",
    description="Returns only patients where an ACTIVE assignment exists for this ASHA.",
)
async def get_my_assigned_patients(
    db: AsyncSession = Depends(get_db),
    current_asha: User = Depends(require_asha),
) -> List[AshaPatientItemResponse]:
    # 1. Get ASHA profile
    stmt_prof = select(AshaProfile).where(AshaProfile.user_id == current_asha.id)
    asha_prof = (await db.execute(stmt_prof)).scalar_one_or_none()
    if not asha_prof:
        return []

    # 2. Get active assignments with patient profile and user
    stmt = (
        select(AshaPatientAssignment)
        .where(
            AshaPatientAssignment.asha_worker_id == asha_prof.id,
            AshaPatientAssignment.status == AssignmentStatusEnum.ACTIVE,
        )
        .options(
            selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.user),
            selectinload(AshaPatientAssignment.patient).selectinload(PatientProfile.health_record),
        )
        .order_by(AshaPatientAssignment.assigned_at.desc())
    )
    assignments = (await db.execute(stmt)).scalars().all()

    items = []
    for a in assignments:
        # Check active pregnancy
        stmt_preg = select(Pregnancy).where(
            Pregnancy.patient_id == a.patient.id,
            Pregnancy.status == PregnancyStatusEnum.ACTIVE,
        )
        active_preg = (await db.execute(stmt_preg)).scalar_one_or_none()

        # Check visits count and latest visit
        stmt_vis = (
            select(HomeVisit)
            .where(HomeVisit.patient_id == a.patient.id)
            .order_by(HomeVisit.visit_date.desc())
        )
        vis_records = (await db.execute(stmt_vis)).scalars().all()
        last_vis_date = (
            datetime.combine(vis_records[0].visit_date, datetime.min.time())
            if vis_records
            else None
        )

        hr_num = a.patient.health_record.record_number if a.patient.health_record else None

        items.append(
            AshaPatientItemResponse(
                id=a.id,
                patient_id=a.patient.id,
                patient_name=a.patient.user.full_name,
                patient_email=a.patient.user.email,
                patient_phone=a.patient.user.phone,
                health_record_number=hr_num,
                village_locality=a.patient.village_locality,
                has_active_pregnancy=active_preg is not None,
                pregnancy_id=active_preg.id if active_preg else None,
                pregnancy_number=active_preg.pregnancy_number if active_preg else None,
                last_visit_date=last_vis_date,
                total_visits=len(vis_records),
                asha_worker_id=asha_prof.id,
                asha_worker_name=current_asha.full_name,
                status=a.status,
                assigned_at=a.assigned_at,
                notes=a.notes,
            )
        )

    return items


@router.get(
    "/me/patients/{patient_id}",
    response_model=AshaPatientItemResponse,
    status_code=status.HTTP_200_OK,
    summary="Get patient profile details for actively assigned patient",
    description="ASHA inspects demographics, pregnancy, and contact details of an assigned patient.",
)
async def get_assigned_patient_detail(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_asha: User = Depends(require_asha),
) -> AshaPatientItemResponse:
    asha_prof = await AssignmentService.verify_asha_patient_access(
        db=db,
        asha_user_id=current_asha.id,
        patient_id=patient_id,
    )

    stmt_a = select(AshaPatientAssignment).where(
        AshaPatientAssignment.asha_worker_id == asha_prof.id,
        AshaPatientAssignment.patient_id == patient_id,
        AshaPatientAssignment.status == AssignmentStatusEnum.ACTIVE,
    )
    assignment = (await db.execute(stmt_a)).scalar_one()

    stmt = (
        select(PatientProfile)
        .where(PatientProfile.id == patient_id)
        .options(
            selectinload(PatientProfile.user),
            selectinload(PatientProfile.health_record),
        )
    )
    p = (await db.execute(stmt)).scalar_one()

    # Check active pregnancy
    stmt_preg = select(Pregnancy).where(
        Pregnancy.patient_id == patient_id,
        Pregnancy.status == PregnancyStatusEnum.ACTIVE,
    )
    active_preg = (await db.execute(stmt_preg)).scalar_one_or_none()

    # Check visits
    stmt_vis = (
        select(HomeVisit)
        .where(HomeVisit.patient_id == patient_id)
        .order_by(HomeVisit.visit_date.desc())
    )
    vis_records = (await db.execute(stmt_vis)).scalars().all()
    last_vis_date = (
        datetime.combine(vis_records[0].visit_date, datetime.min.time())
        if vis_records
        else None
    )

    hr_num = p.health_record.record_number if p.health_record else None

    return AshaPatientItemResponse(
        id=assignment.id,
        patient_id=p.id,
        patient_name=p.user.full_name,
        patient_email=p.user.email,
        patient_phone=p.user.phone,
        health_record_number=hr_num,
        village_locality=p.village_locality,
        has_active_pregnancy=active_preg is not None,
        pregnancy_id=active_preg.id if active_preg else None,
        pregnancy_number=active_preg.pregnancy_number if active_preg else None,
        last_visit_date=last_vis_date,
        total_visits=len(vis_records),
        asha_worker_id=asha_prof.id,
        asha_worker_name=current_asha.full_name,
        status=assignment.status,
        assigned_at=assignment.assigned_at,
        notes=assignment.notes,
    )


# ==========================================
# 2. Home Visits Management
# ==========================================

@router.post(
    "/me/patients/{patient_id}/home-visits",
    response_model=HomeVisitResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record a field home visit for an assigned patient",
    description="ASHA records clinical checkup observations, purpose, and follow-up requirements.",
)
async def record_home_visit(
    patient_id: uuid.UUID,
    req: HomeVisitCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_asha: User = Depends(require_asha),
) -> HomeVisitResponse:
    return await HomeVisitService.create_home_visit_for_asha(
        db=db,
        asha_user=current_asha,
        patient_id=patient_id,
        req=req,
    )


@router.get(
    "/me/patients/{patient_id}/home-visits",
    response_model=HomeVisitListResponse,
    status_code=status.HTTP_200_OK,
    summary="List home visits for an assigned patient",
    description="ASHA inspects historical home visits conducted for an assigned patient.",
)
async def list_patient_home_visits(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_asha: User = Depends(require_asha),
) -> HomeVisitListResponse:
    return await HomeVisitService.list_home_visits_for_asha(
        db=db,
        asha_user=current_asha,
        patient_id=patient_id,
    )


# ==========================================
# 3. Maternal Vitals Management
# ==========================================

@router.post(
    "/me/patients/{patient_id}/home-visits/{visit_id}/vitals",
    response_model=MaternalVitalRecordResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record maternal vitals during an authorized home visit",
    description="ASHA records blood pressure, maternal weight, and temperature during a home visit.",
)
async def record_vitals_during_visit(
    patient_id: uuid.UUID,
    visit_id: uuid.UUID,
    req: MaternalVitalRecordCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_asha: User = Depends(require_asha),
) -> MaternalVitalRecordResponse:
    return await VitalsService.record_vitals_for_asha(
        db=db,
        asha_user=current_asha,
        patient_id=patient_id,
        visit_id=visit_id,
        req=req,
    )


@router.post(
    "/me/patients/{patient_id}/vitals",
    response_model=MaternalVitalRecordResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record maternal vitals for an assigned patient",
    description="ASHA records maternal vitals directly for an assigned patient's active pregnancy.",
)
async def record_vitals_direct(
    patient_id: uuid.UUID,
    req: MaternalVitalRecordCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_asha: User = Depends(require_asha),
) -> MaternalVitalRecordResponse:
    return await VitalsService.record_vitals_for_asha(
        db=db,
        asha_user=current_asha,
        patient_id=patient_id,
        visit_id=None,
        req=req,
    )


@router.get(
    "/me/patients/{patient_id}/vitals",
    response_model=MaternalVitalRecordListResponse,
    status_code=status.HTTP_200_OK,
    summary="List recorded maternal vitals for an assigned patient",
    description="ASHA inspects historical vital records for an assigned patient.",
)
async def list_patient_vitals(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_asha: User = Depends(require_asha),
) -> MaternalVitalRecordListResponse:
    return await VitalsService.list_patient_vitals_for_asha(
        db=db,
        asha_user=current_asha,
        patient_id=patient_id,
    )
