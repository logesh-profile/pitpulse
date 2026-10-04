import uuid
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.home_visit import VisitStatusEnum


class HomeVisitCreateRequest(BaseModel):
    visit_date: date = Field(
        ...,
        description="Date of the field home visit (cannot be future).",
    )
    pregnancy_id: Optional[uuid.UUID] = Field(
        None,
        description="Optional ID of active pregnancy associated with visit.",
    )
    started_at: Optional[datetime] = Field(
        None,
        description="Timestamp when visit commenced.",
    )
    completed_at: Optional[datetime] = Field(
        None,
        description="Timestamp when visit concluded.",
    )
    purpose: str = Field(
        ...,
        min_length=3,
        max_length=255,
        description="Purpose of home visit (e.g., Routine Antenatal Checkup, Postnatal Follow-up).",
    )
    observations: Optional[str] = Field(
        None,
        max_length=2000,
        description="Clinical / physical observations noted by ASHA.",
    )
    notes: Optional[str] = Field(
        None,
        max_length=1000,
        description="General field notes.",
    )
    follow_up_required: bool = Field(
        False,
        description="Flag if follow-up home visit or clinical escalation is needed.",
    )
    follow_up_notes: Optional[str] = Field(
        None,
        max_length=1000,
        description="Specific follow-up instructions or scheduling notes.",
    )


class HomeVisitResponse(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    patient_name: str
    patient_health_record_number: Optional[str] = None
    pregnancy_id: Optional[uuid.UUID] = None
    pregnancy_number: Optional[int] = None
    asha_worker_id: uuid.UUID
    asha_worker_name: str
    visit_date: date
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    status: VisitStatusEnum
    purpose: str
    observations: Optional[str] = None
    notes: Optional[str] = None
    follow_up_required: bool
    follow_up_notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class HomeVisitListResponse(BaseModel):
    items: list[HomeVisitResponse]
    total: int
