import hashlib
import logging
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.verification_token import TokenTypeEnum, VerificationToken

logger = logging.getLogger("pitpulse.email_service")


def hash_token(token: str) -> str:
    """Computes SHA-256 hash of a verification/activation token for secure storage."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


class EmailService:
    @staticmethod
    async def create_verification_token(
        db: AsyncSession,
        user_id: UUID,
        token_type: TokenTypeEnum = TokenTypeEnum.EMAIL_VERIFICATION,
        expire_hours: int = 24,
    ) -> str:
        """
        Generates a high-entropy URL-safe token, stores its SHA-256 hash in PostgreSQL,
        and returns the raw token string (only returned once for delivery).
        """
        raw_token = secrets.token_urlsafe(32)
        token_digest = hash_token(raw_token)
        expires_at = datetime.now(timezone.utc) + timedelta(hours=expire_hours)

        token_record = VerificationToken(
            user_id=user_id,
            token_hash=token_digest,
            token_type=token_type,
            expires_at=expires_at,
            is_used=False,
        )
        db.add(token_record)
        await db.flush()

        logger.info(
            f"Created {token_type.value} token for user_id={user_id}, expires={expires_at.isoformat()}"
        )
        return raw_token

    @staticmethod
    async def verify_and_consume_token(
        db: AsyncSession,
        raw_token: str,
        expected_type: TokenTypeEnum,
    ) -> VerificationToken:
        """
        Validates token hash, checks expiration and single-use status,
        and marks the token as used.
        """
        token_digest = hash_token(raw_token)
        now = datetime.now(timezone.utc)

        stmt = (
            select(VerificationToken)
            .where(
                VerificationToken.token_hash == token_digest,
                VerificationToken.token_type == expected_type,
                VerificationToken.is_used == False,
                VerificationToken.expires_at > now,
            )
        )
        result = await db.execute(stmt)
        token_record = result.scalar_one_or_none()

        if not token_record:
            return None

        # Mark token consumed
        token_record.is_used = True
        await db.flush()
        return token_record

    @staticmethod
    async def send_verification_email(email: str, token: str) -> None:
        """
        Dispatches email verification message.
        In development / test environment, logs safely to console.
        """
        logger.info(
            f"[EMAIL DISPATCH] Verification email to {email}: token={token}"
        )

    @staticmethod
    async def send_professional_activation_email(
        email: str, full_name: str, role: str, token: str
    ) -> None:
        """
        Dispatches activation email for provisioned Doctor / ASHA.
        """
        logger.info(
            f"[EMAIL DISPATCH] Activation email to {email} ({full_name}, {role}): activation_token={token}"
        )
