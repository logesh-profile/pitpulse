from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class PatientProfileUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    date_of_birth: Optional[date] = None
    sex: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = None
    village_locality: Optional[str] = Field(None, max_length=255)
    emergency_contact_name: Optional[str] = Field(None, max_length=255)
    emergency_contact_phone: Optional[str] = Field(None, max_length=20)
    blood_group: Optional[str] = Field(None, max_length=10)
    baseline_health_info: Optional[str] = None


class HealthRecordResponse(BaseModel):
    id: UUID
    record_number: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PatientProfileResponse(BaseModel):
    id: UUID
    user_id: UUID
    full_name: str
    email: EmailStr
    phone: Optional[str] = None
    date_of_birth: Optional[date] = None
    sex: Optional[str] = None
    address: Optional[str] = None
    village_locality: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    blood_group: Optional[str] = None
    baseline_health_info: Optional[str] = None
    health_record: Optional[HealthRecordResponse] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
