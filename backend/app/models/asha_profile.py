import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class AshaProfile(Base):
    __tablename__ = "asha_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        index=True,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    worker_id_code: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True,
    )
    assigned_area: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
    )
    primary_health_center: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="asha_profile")
    assignments: Mapped[list["AshaPatientAssignment"]] = relationship(
        "AshaPatientAssignment",
        back_populates="asha_worker",
        cascade="all, delete-orphan",
    )
    home_visits: Mapped[list["HomeVisit"]] = relationship(
        "HomeVisit",
        back_populates="asha_worker",
        cascade="all, delete-orphan",
    )
