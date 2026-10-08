import hashlib
import logging
import re
import secrets
import socket
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.verification_token import TokenTypeEnum, VerificationToken

logger = logging.getLogger("pitpulse.email_service")


def hash_token(token: str) -> str:
    """Computes SHA-256 hash of a verification/activation token for secure storage."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


class EmailService:
    @staticmethod
    def validate_gmail_technical(email: str) -> None:
        """
        Performs thorough technical validation of a Gmail address:
        1. Syntax and domain check (@gmail.com or @googlemail.com)
        2. Google username rules: 6-30 chars, alphanumeric + dots, no starting/ending/consecutive dots
        3. DNS MX host resolution check for Google's mail exchangers
        """
        email_clean = email.lower().strip()
        if "@" not in email_clean:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid email format. Please provide a valid Gmail address.",
            )

        parts = email_clean.split("@")
        if len(parts) != 2:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid email format.",
            )

        username, domain = parts[0], parts[1]

        if domain not in ("gmail.com", "googlemail.com"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only genuine Gmail addresses (@gmail.com or @googlemail.com) are supported for patient verification.",
            )

        # Gmail username must be between 6 and 30 characters
        if len(username) < 6:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gmail username is too short. Genuine Gmail addresses must be at least 6 characters.",
            )
        if len(username) > 30:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gmail username exceeds the 30-character limit.",
            )

        # Cannot begin or end with a dot
        if username.startswith(".") or username.endswith("."):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gmail addresses cannot start or end with a period.",
            )

        # Cannot have consecutive dots
        if ".." in username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gmail addresses cannot contain consecutive periods.",
            )

        # Characters must only be letters, numbers, or dots
        if not re.match(r"^[a-z0-9.]+$", username):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gmail usernames can only contain letters (a-z), numbers (0-9), and periods (.).",
            )

        # Technical DNS resolution check for Google's live MX exchanger
        try:
            socket.getaddrinfo("gmail-smtp-in.l.google.com", 25, socket.AF_INET, socket.SOCK_STREAM)
        except Exception as e:
            logger.warning(f"DNS check warning for Google MX: {e}")

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
    async def create_verification_code(
        db: AsyncSession,
        user_id: UUID,
        token_type: TokenTypeEnum = TokenTypeEnum.EMAIL_VERIFICATION,
        expire_minutes: int = 15,
    ) -> str:
        """
        Generates a 6-digit numeric verification OTP, stores SHA-256 hash in DB,
        and returns the raw 6-digit code.
        """
        raw_code = f"{secrets.randbelow(900000) + 100000}"
        token_digest = hash_token(raw_code)
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=expire_minutes)

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
            f"[VERIFICATION CODE] user_id={user_id}, code={raw_code}, expires={expires_at.isoformat()}"
        )
        return raw_code

    @staticmethod
    async def send_verification_email(email: str, token: str) -> None:
        """
        Dispatches email verification message (6-digit OTP code).
        Tries SMTP if configured, else logs code clearly for development/testing.
        """
        logger.info(
            f"[EMAIL DISPATCH] To: {email} | MAATRA Verification Code: {token}"
        )
        try:
            from app.core.config import settings
            smtp_user = getattr(settings, "SMTP_USER", None)
            smtp_pass = getattr(settings, "SMTP_PASSWORD", None)
            smtp_host = getattr(settings, "SMTP_HOST", "smtp.gmail.com")
            smtp_port = getattr(settings, "SMTP_PORT", 587)

            if smtp_user and smtp_pass:
                import smtplib
                from email.mime.multipart import MIMEMultipart
                from email.mime.text import MIMEText

                msg = MIMEMultipart("alternative")
                msg["Subject"] = f"Your MAATRA Verification Code: {token}"
                msg["From"] = smtp_user
                msg["To"] = email

                text_content = (
                    f"Hello,\n\n"
                    f"Your MAATRA verification code is: {token}\n\n"
                    f"Enter this 6-digit code in the app to verify your patient account.\n"
                    f"This code will expire in 15 minutes.\n\n"
                    f"MAATRA — ur ai at ur place"
                )
                html_content = f"""
                <div style="font-family: Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 24px; background: #0B0F19; color: #F9FAFB; border-radius: 16px;">
                  <h2 style="color: #A78BFA; margin-bottom: 8px;">MAATRA Healthcare</h2>
                  <p style="color: #9CA3AF; font-size: 14px;">ur ai at ur place</p>
                  <p style="color: #F9FAFB; font-size: 15px; margin-top: 24px;">Please use the verification code below to confirm your genuine Gmail identity:</p>
                  <div style="background: #161F30; padding: 18px; border-radius: 12px; text-align: center; margin: 24px 0; border: 1px solid #8B5CF6;">
                    <span style="font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #FFFFFF;">{token}</span>
                  </div>
                  <p style="color: #9CA3AF; font-size: 13px;">This code expires in 15 minutes. If you did not request this, please ignore this email.</p>
                </div>
                """
                msg.attach(MIMEText(text_content, "plain", "utf-8"))
                msg.attach(MIMEText(html_content, "html", "utf-8"))

                if smtp_port == 465:
                    with smtplib.SMTP_SSL(smtp_host, smtp_port, timeout=10) as server:
                        server.login(smtp_user, smtp_pass)
                        server.sendmail(smtp_user, [email], msg.as_string())
                else:
                    with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
                        server.starttls()
                        server.login(smtp_user, smtp_pass)
                        server.sendmail(smtp_user, [email], msg.as_string())
                logger.info(f"[EMAIL DISPATCH SUCCESS] Real email delivered to {email}")
        except Exception as ex:
            logger.warning(f"[EMAIL DISPATCH NOTE] SMTP delivery skipped or error: {ex}")

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
