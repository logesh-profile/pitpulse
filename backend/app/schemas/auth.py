from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.models.user import RoleEnum


class UserRegisterRequest(BaseModel):
    model_config = {"extra": "forbid"}

    email: EmailStr
    password: str = Field(..., min_length=8, description="Minimum 8 characters password")
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: Optional[str] = Field(None, max_length=20)

    @field_validator("password")
    def validate_password_strength(cls, value: str) -> str:
        if len(value) < 8:
            raise ValueError("Password must be at least 8 characters long.")
        return value


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class GoogleLoginRequest(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    id_token: Optional[str] = None
    google_id: Optional[str] = None
    photo_url: Optional[str] = None


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class ChangePasswordRequest(BaseModel):
    model_config = {"extra": "forbid"}

    current_password: str
    new_password: str = Field(..., min_length=8, description="New password (minimum 8 characters)")


class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    phone: Optional[str] = None
    full_name: str
    role: RoleEnum
    is_active: bool
    is_verified: bool = False
    age: Optional[int] = None
    gender: Optional[str] = None
    is_profile_completed: bool = True
    must_change_password: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse


class VerifyEmailRequest(BaseModel):
    token: str = Field(..., min_length=4, description="Email verification token or code")


class VerifyCodeRequest(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=4, max_length=10, description="6-digit verification code")


class ResendVerificationRequest(BaseModel):
    email: EmailStr


class CompleteProfileRequest(BaseModel):
    full_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    specialization: Optional[str] = None
    facility_name: Optional[str] = None
    medical_license_number: Optional[str] = None
    assigned_area: Optional[str] = None
    primary_health_center: Optional[str] = None
    worker_id_code: Optional[str] = None


class ActivateProfessionalRequest(BaseModel):
    token: str = Field(..., min_length=4, description="Professional activation token")
    new_password: str = Field(..., min_length=8, description="Chosen password (minimum 8 characters)")


class UserRegisterResponse(BaseModel):
    message: str
    user: UserResponse
    dev_verification_token: Optional[str] = None
    dev_verification_code: Optional[str] = None


class VerifyEmailResponse(BaseModel):
    message: str
    is_verified: bool
    tokens: Optional[TokenResponse] = None
