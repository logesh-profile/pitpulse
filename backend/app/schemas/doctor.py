from datetime import date, datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr

from app.schemas.assignment import AshaAssignmentResponse, AshaPatientItemResponse


class DoctorPatientItem(BaseModel):
    patient_id: UUID
    user_id: UUID
    full_name: str
    email: EmailStr
    phone: Optional[str] = None
    village_locality: Optional[str] = None
    date_of_birth: Optional[date] = None
    blood_group: Optional[str] = None
    has_active_pregnancy: bool = False
    active_pregnancy_ga_weeks: Optional[int] = None
    active_pregnancy_edd: Optional[date] = None
    assigned_asha_name: Optional[str] = None
    assigned_asha_id: Optional[UUID] = None
    latest_visit_date: Optional[datetime] = None
    latest_visit_notes: Optional[str] = None
    latest_vitals_summary: Optional[str] = None
    risk_level: str = "NORMAL"
    created_at: datetime



class DoctorPatientRosterResponse(BaseModel):
    items: List[DoctorPatientItem]
    total: int


class DoctorAshaItem(BaseModel):
    asha_id: UUID
    user_id: UUID
    full_name: str
    email: EmailStr
    phone: Optional[str] = None
    worker_id_code: Optional[str] = None
    assigned_area: Optional[str] = None
    primary_health_center: Optional[str] = None
    active_patients_count: int = 0


class DoctorAshaListResponse(BaseModel):
    items: List[DoctorAshaItem]
    total: int


class DoctorAssignAshaRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    asha_worker_id: UUID
    notes: Optional[str] = None
