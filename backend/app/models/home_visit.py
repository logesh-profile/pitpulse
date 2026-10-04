import enum
import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class VisitStatusEnum(str, enum.Enum):
    PLANNED = "PLANNED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class HomeVisit(Base):
    __tablename__ = "home_visits"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        index=True,
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    pregnancy_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("pregnancies.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    asha_worker_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("asha_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    visit_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
        index=True,
    )
    started_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    completed_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    status: Mapped[VisitStatusEnum] = mapped_column(
        Enum(
            VisitStatusEnum,
            name="visit_status_enum",
            values_callable=lambda obj: [e.value for e in obj],
        ),
        nullable=False,
        default=VisitStatusEnum.COMPLETED,
        index=True,
    )
    purpose: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )
    observations: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    notes: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    follow_up_required: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )
    follow_up_notes: Mapped[Optional[str]] = mapped_column(
        Text,
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
    patient: Mapped["PatientProfile"] = relationship(
        "PatientProfile",
        back_populates="home_visits",
    )
    pregnancy: Mapped[Optional["Pregnancy"]] = relationship(
        "Pregnancy",
        back_populates="home_visits",
    )
    asha_worker: Mapped["AshaProfile"] = relationship(
        "AshaProfile",
        back_populates="home_visits",
    )
    vitals: Mapped[list["MaternalVitalRecord"]] = relationship(
        "MaternalVitalRecord",
        back_populates="home_visit",
        cascade="all, delete-orphan",
    )
