from datetime import date, datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.user import RoleEnum


class CreateDoctorRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: Optional[str] = Field(None, max_length=20)
    medical_license_number: Optional[str] = Field(None, max_length=100)
    specialization: Optional[str] = Field(None, max_length=100)
    facility_name: Optional[str] = Field(None, max_length=255)


class CreateAshaRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: Optional[str] = Field(None, max_length=20)
    worker_id_code: Optional[str] = Field(None, max_length=100)
    assigned_area: Optional[str] = Field(None, max_length=255)
    primary_health_center: Optional[str] = Field(None, max_length=255)


class DoctorProvisionResponse(BaseModel):
    user_id: UUID
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    role: RoleEnum = RoleEnum.DOCTOR
    activation_token: Optional[str] = None
    temporary_password: Optional[str] = None
    must_change_password: bool = True
    is_active: bool = True
    medical_license_number: Optional[str] = None
    specialization: Optional[str] = None
    facility_name: Optional[str] = None
    created_at: datetime


class AshaProvisionResponse(BaseModel):
    user_id: UUID
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    role: RoleEnum = RoleEnum.ASHA
    activation_token: Optional[str] = None
    temporary_password: Optional[str] = None
    must_change_password: bool = True
    is_active: bool = True
    worker_id_code: Optional[str] = None
    assigned_area: Optional[str] = None
    primary_health_center: Optional[str] = None
    created_at: datetime


class ProfessionalUserItem(BaseModel):
    id: UUID
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    role: RoleEnum
    is_active: bool
    must_change_password: bool
    created_at: datetime
    details: Optional[Dict[str, Any]] = None

    model_config = ConfigDict(from_attributes=True)


class UserStatusUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    is_active: bool


class CreatePatientRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: Optional[str] = Field(None, max_length=20)
    password: Optional[str] = Field(None, min_length=6, max_length=100)
    date_of_birth: Optional[date] = None
    sex: Optional[str] = Field("FEMALE", max_length=20)
    blood_group: Optional[str] = Field(None, max_length=10)
    address: Optional[str] = None
    village_locality: Optional[str] = Field(None, max_length=255)
    emergency_contact_name: Optional[str] = Field(None, max_length=255)
    emergency_contact_phone: Optional[str] = Field(None, max_length=20)
    baseline_health_info: Optional[str] = None


class PatientProvisionResponse(BaseModel):
    user_id: UUID
    patient_id: UUID
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    health_record_number: Optional[str] = None
    village_locality: Optional[str] = None
    blood_group: Optional[str] = None
    is_active: bool = True
    created_at: datetime


class AshaWorkerItemResponse(BaseModel):
    id: UUID
    user_id: UUID
    full_name: str
    email: EmailStr
    phone: Optional[str] = None
    worker_id_code: Optional[str] = None
    assigned_area: Optional[str] = None
    primary_health_center: Optional[str] = None
    user: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime


