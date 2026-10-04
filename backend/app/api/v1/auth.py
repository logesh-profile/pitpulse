from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin, require_doctor
from app.core.database import get_db
from app.models.user import User
from app.schemas.auth import (
    ChangePasswordRequest,
    LogoutRequest,
    RefreshTokenRequest,
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication & Identity"])


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new patient user account",
    description="Registers a real patient user in PostgreSQL. Only PATIENT role can be registered publicly.",
)
async def register(
    req: UserRegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    user = await AuthService.register_user(db=db, req=req)
    return UserResponse.model_validate(user)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="User login & token issuance",
    description="Authenticates against Argon2id hash in PostgreSQL and returns JWT access + refresh token.",
)
async def login(
    req: UserLoginRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await AuthService.authenticate_user(db=db, req=req)


@router.post(
    "/refresh",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Rotate refresh token & issue new access token",
    description="Validates and revokes the existing refresh token, then issues a fresh token pair.",
)
async def refresh_token(
    req: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await AuthService.refresh_session(db=db, raw_refresh_token=req.refresh_token)


@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
    summary="Logout & revoke refresh session",
    description="Revokes the refresh token in PostgreSQL.",
)
async def logout(
    req: LogoutRequest,
    db: AsyncSession = Depends(get_db),
):
    await AuthService.logout_user(db=db, raw_refresh_token=req.refresh_token)
    return {"message": "Logged out successfully."}


@router.post(
    "/change-password",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Change password and complete professional activation",
    description="Verifies current password, updates Argon2id password hash, resets must_change_password flag, and issues fresh token pair.",
)
async def change_password(
    req: ChangePasswordRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TokenResponse:
    return await AuthService.change_password(
        db=db,
        user=current_user,
        current_password=req.current_password,
        new_password=req.new_password,
    )



@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current authenticated user profile",
    description="Returns the real PostgreSQL record of the currently authenticated user.",
)
async def get_me(
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    return UserResponse.model_validate(current_user)


@router.get(
    "/role-test/doctor",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Doctor Role Verification Endpoint",
)
async def doctor_role_test(
    doctor_user: User = Depends(require_doctor),
) -> UserResponse:
    return UserResponse.model_validate(doctor_user)


@router.get(
    "/role-test/admin",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Admin Role Verification Endpoint",
)
async def admin_role_test(
    admin_user: User = Depends(require_admin),
) -> UserResponse:
    return UserResponse.model_validate(admin_user)
