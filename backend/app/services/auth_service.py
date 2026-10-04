from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token_pair,
    hash_password,
    hash_token,
    verify_password,
)
from app.models.refresh_token import RefreshToken
from app.models.user import RoleEnum, User
from app.schemas.auth import (
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)


class AuthService:
    @staticmethod
    async def register_user(db: AsyncSession, req: UserRegisterRequest) -> User:
        """Registers a new user into PostgreSQL after enforcing uniqueness and role security."""
        # Check duplicate email
        stmt = select(User).where(User.email == req.email.lower().strip())
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An account with this email address already exists.",
            )

        # Check duplicate phone if provided
        if req.phone:
            stmt = select(User).where(User.phone == req.phone.strip())
            result = await db.execute(stmt)
            if result.scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="An account with this phone number already exists.",
                )

        # Hash password securely with Argon2id
        hashed_pw = hash_password(req.password)

        new_user = User(
            email=req.email.lower().strip(),
            phone=req.phone.strip() if req.phone else None,
            full_name=req.full_name.strip(),
            password_hash=hashed_pw,
            role=RoleEnum.PATIENT,
            is_active=True,
        )

        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        return new_user

    @staticmethod
    async def authenticate_user(
        db: AsyncSession,
        req: UserLoginRequest,
    ) -> TokenResponse:
        """Authenticates a user against PostgreSQL Argon2id hash and issues JWT access/refresh tokens."""
        stmt = select(User).where(User.email == req.email.lower().strip())
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()

        # Generic error message prevents account enumeration
        if not user or not verify_password(req.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account has been deactivated. Please contact support.",
            )

        # Update last_login_at
        user.last_login_at = datetime.now(timezone.utc)

        # Generate tokens
        access_token = create_access_token(user_id=user.id, role=user.role.value)
        raw_refresh, token_hash, expires_at = create_refresh_token_pair(user_id=user.id)

        # Persist refresh token hash
        db_refresh = RefreshToken(
            user_id=user.id,
            token_hash=token_hash,
            expires_at=expires_at,
        )
        db.add(db_refresh)
        await db.commit()

        return TokenResponse(
            access_token=access_token,
            refresh_token=raw_refresh,
            token_type="bearer",
            expires_in=settings.JWT_ACCESS_EXPIRE_MINUTES * 60,
            user=UserResponse.model_validate(user),
        )

    @staticmethod
    async def refresh_session(
        db: AsyncSession,
        raw_refresh_token: str,
    ) -> TokenResponse:
        """Validates refresh token, enforces rotation by revoking old token, and issues new pair."""
        token_hash = hash_token(raw_refresh_token)

        stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        result = await db.execute(stmt)
        token_record = result.scalar_one_or_none()

        now = datetime.now(timezone.utc)

        if not token_record or token_record.revoked_at is not None or token_record.expires_at < now:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid, revoked, or expired refresh token.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Load user
        user_stmt = select(User).where(User.id == token_record.user_id)
        user_result = await db.execute(user_stmt)
        user = user_result.scalar_one_or_none()

        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is inactive or not found.",
            )

        # Rotate token: revoke current token
        token_record.revoked_at = now

        # Create new token pair
        new_access = create_access_token(user_id=user.id, role=user.role.value)
        new_raw_refresh, new_token_hash, new_expires_at = create_refresh_token_pair(user_id=user.id)

        new_db_refresh = RefreshToken(
            user_id=user.id,
            token_hash=new_token_hash,
            expires_at=new_expires_at,
        )
        db.add(new_db_refresh)
        await db.commit()

        return TokenResponse(
            access_token=new_access,
            refresh_token=new_raw_refresh,
            token_type="bearer",
            expires_in=settings.JWT_ACCESS_EXPIRE_MINUTES * 60,
            user=UserResponse.model_validate(user),
        )

    @staticmethod
    async def logout_user(
        db: AsyncSession,
        raw_refresh_token: str,
    ) -> None:
        """Revokes a refresh token session in PostgreSQL."""
        token_hash = hash_token(raw_refresh_token)
        stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        result = await db.execute(stmt)
        token_record = result.scalar_one_or_none()

        if token_record and token_record.revoked_at is None:
            token_record.revoked_at = datetime.now(timezone.utc)
            await db.commit()
