import uuid
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.pregnancy import PregnancyStatusEnum


class PregnancyCreateRequest(BaseModel):
    pregnancy_number: Optional[int] = Field(
        None,
        ge=1,
        description="Patient pregnancy order (e.g. 1, 2). If omitted, automatically defaults to next sequence number.",
    )
    lmp: date = Field(
        ...,
        description="Last Menstrual Period (LMP) date (cannot be in the future).",
    )
    notes: Optional[str] = Field(
        None,
        max_length=1000,
        description="Optional conception or maternal baseline notes.",
    )


class PregnancyUpdateRequest(BaseModel):
    status: Optional[PregnancyStatusEnum] = Field(
        None,
        description="Updated pregnancy status (ACTIVE, COMPLETED, TERMINATED, UNKNOWN).",
    )
    notes: Optional[str] = Field(
        None,
        max_length=1000,
        description="Updated notes.",
    )


class PregnancyResponse(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    pregnancy_number: int
    status: PregnancyStatusEnum
    lmp: date
    edd: date
    gestational_age_weeks: int
    gestational_age_days: int
    gestational_age_display: str
    trimester: int
    trimester_display: str
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PregnancyListResponse(BaseModel):
    items: list[PregnancyResponse]
    total: int
