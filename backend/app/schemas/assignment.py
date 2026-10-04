import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.asha_patient_assignment import AssignmentStatusEnum


class AshaAssignmentCreateRequest(BaseModel):
    asha_worker_id: uuid.UUID = Field(
        ...,
        description="UUID of the ASHA worker profile.",
    )
    patient_id: uuid.UUID = Field(
        ...,
        description="UUID of the Patient profile.",
    )
    notes: Optional[str] = Field(
        None,
        max_length=500,
        description="Optional administrative assignment notes.",
    )


class AshaAssignmentUpdateRequest(BaseModel):
    status: Optional[AssignmentStatusEnum] = Field(
        None,
        description="Updated status (ACTIVE or INACTIVE).",
    )
    notes: Optional[str] = Field(
        None,
        max_length=500,
        description="Updated administrative notes.",
    )


class AshaAssignmentResponse(BaseModel):
    id: uuid.UUID
    asha_worker_id: uuid.UUID
    asha_worker_name: str
    asha_worker_code: Optional[str] = None
    asha_assigned_area: Optional[str] = None
    patient_id: uuid.UUID
    patient_name: str
    patient_health_record_number: Optional[str] = None
    patient_village: Optional[str] = None
    status: AssignmentStatusEnum
    assigned_at: datetime
    unassigned_at: Optional[datetime] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AshaAssignmentListResponse(BaseModel):
    items: list[AshaAssignmentResponse]
    total: int


class AshaPatientItemResponse(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    patient_name: str
    patient_email: Optional[str] = None
    patient_phone: Optional[str] = None
    health_record_number: Optional[str] = None
    village_locality: Optional[str] = None
    has_active_pregnancy: bool = False
    pregnancy_id: Optional[uuid.UUID] = None
    pregnancy_number: Optional[int] = None
    last_visit_date: Optional[datetime] = None
    total_visits: int = 0
    asha_worker_id: uuid.UUID
    asha_worker_name: Optional[str] = None
    status: AssignmentStatusEnum = AssignmentStatusEnum.ACTIVE
    assigned_at: datetime
    notes: Optional[str] = None

