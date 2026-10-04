import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class MaternalVitalRecordCreateRequest(BaseModel):
    pregnancy_id: Optional[uuid.UUID] = Field(
        None,
        description="Pregnancy UUID. If omitted, automatically resolves to current active pregnancy of the patient.",
    )
    home_visit_id: Optional[uuid.UUID] = Field(
        None,
        description="Optional ID of associated home visit during which vitals were measured.",
    )
    recorded_at: Optional[datetime] = Field(
        None,
        description="Timestamp of vital measurement (defaults to current UTC time).",
    )
    systolic_bp: Optional[int] = Field(
        None,
        ge=40,
        le=300,
        description="Systolic blood pressure in mmHg (valid range: 40-300).",
    )
    diastolic_bp: Optional[int] = Field(
        None,
        ge=20,
        le=200,
        description="Diastolic blood pressure in mmHg (valid range: 20-200).",
    )
    weight_kg: Optional[float] = Field(
        None,
        ge=20.0,
        le=300.0,
        description="Maternal weight in kilograms (valid range: 20.0-300.0 kg).",
    )
    temperature_c: Optional[float] = Field(
        None,
        ge=30.0,
        le=45.0,
        description="Body temperature in Celsius (valid range: 30.0-45.0 °C).",
    )
    notes: Optional[str] = Field(
        None,
        max_length=1000,
        description="Optional clinical observations related to vitals.",
    )


class MaternalVitalRecordResponse(BaseModel):
    id: uuid.UUID
    pregnancy_id: uuid.UUID
    pregnancy_number: Optional[int] = None
    home_visit_id: Optional[uuid.UUID] = None
    recorded_by_user_id: uuid.UUID
    recorded_by_name: str
    recorded_by_role: str
    recorded_at: datetime
    systolic_bp: Optional[int] = None
    diastolic_bp: Optional[int] = None
    weight_kg: Optional[float] = None
    temperature_c: Optional[float] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MaternalVitalRecordListResponse(BaseModel):
    items: list[MaternalVitalRecordResponse]
    total: int
