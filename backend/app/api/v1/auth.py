from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin, require_doctor
from app.core.database import get_db
from app.models.user import User
from app.schemas.auth import (
    ActivateProfessionalRequest,
    ChangePasswordRequest,
    CompleteProfileRequest,
    GoogleLoginRequest,
    LogoutRequest,
    RefreshTokenRequest,
    ResendVerificationRequest,
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserRegisterResponse,
    UserResponse,
    VerifyCodeRequest,
    VerifyEmailRequest,
    VerifyEmailResponse,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication & Identity"])


@router.post(
    "/register",
    response_model=UserRegisterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new patient user account",
    description="Registers a real patient user in PostgreSQL and sends an email verification code.",
)
async def register(
    req: UserRegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> UserRegisterResponse:
    user, dev_code = await AuthService.register_user(db=db, req=req)
    return UserRegisterResponse(
        message="Registration successful. A 6-digit verification code has been sent to your Gmail.",
        user=UserResponse.model_validate(user),
        dev_verification_token=dev_code,
        dev_verification_code=dev_code,
    )


@router.post(
    "/verify-code",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify 6-digit code and authenticate",
    description="Validates the 6-digit code sent to Gmail, activates the patient account, and logs in.",
)
async def verify_code(
    req: VerifyCodeRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await AuthService.verify_email_code(
        db=db,
        email=req.email,
        code=req.code,
    )


@router.post(
    "/resend-code",
    status_code=status.HTTP_200_OK,
    summary="Resend 6-digit verification code",
    description="Generates and dispatches a fresh 6-digit verification code to the given Gmail.",
)
async def resend_code(
    req: ResendVerificationRequest,
    db: AsyncSession = Depends(get_db),
):
    code = await AuthService.resend_verification_code(db=db, email=req.email)
    return {
        "message": "A fresh 6-digit verification code has been dispatched to your Gmail.",
        "dev_verification_code": code,
    }


@router.post(
    "/complete-profile",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Complete professional onboarding profile",
    description="Allows provisioned Doctor or ASHA worker to submit personal details (Name, Age, Gender, etc.) on first login.",
)
async def complete_profile(
    req: CompleteProfileRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    return await AuthService.complete_onboarding_profile(
        db=db,
        user=current_user,
        req=req,
    )


@router.post(
    "/verify-email",
    response_model=VerifyEmailResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify patient email address",
    description="Validates the cryptographically secure verification token and activates the account.",
)
async def verify_email(
    req: VerifyEmailRequest,
    db: AsyncSession = Depends(get_db),
) -> VerifyEmailResponse:
    await AuthService.verify_email(db=db, raw_token=req.token)
    return VerifyEmailResponse(
        message="Email verified successfully. You can now sign in to PitPulse.",
        is_verified=True,
    )


@router.post(
    "/resend-verification",
    response_model=VerifyEmailResponse,
    status_code=status.HTTP_200_OK,
    summary="Resend verification email",
    description="Generates and sends a fresh verification token for unverified accounts.",
)
async def resend_verification(
    req: ResendVerificationRequest,
    db: AsyncSession = Depends(get_db),
) -> VerifyEmailResponse:
    await AuthService.resend_verification(db=db, email=req.email)
    return VerifyEmailResponse(
        message="If an unverified account exists with that email, a fresh verification token has been sent.",
        is_verified=False,
    )


@router.post(
    "/activate-professional",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Activate provisioned Doctor or ASHA account",
    description="Validates professional activation token, sets initial self-chosen password, and logs in.",
)
async def activate_professional(
    req: ActivateProfessionalRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await AuthService.activate_professional(
        db=db,
        raw_token=req.token,
        new_password=req.new_password,
    )


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
    "/google-login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Direct Google Sign-In & token issuance",
    description="Authenticates or auto-provisions a genuine Google-verified patient account and issues JWT tokens.",
)
async def google_login(
    req: GoogleLoginRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await AuthService.google_login_user(db=db, req=req)


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
