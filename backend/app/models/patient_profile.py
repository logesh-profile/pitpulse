import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import Date, DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

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
    date_of_birth: Mapped[Optional[date]] = mapped_column(
        Date,
        nullable=True,
    )
    sex: Mapped[Optional[str]] = mapped_column(
        String(20),
        nullable=True,
    )
    address: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    village_locality: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
    )
    emergency_contact_name: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
    )
    emergency_contact_phone: Mapped[Optional[str]] = mapped_column(
        String(20),
        nullable=True,
    )
    blood_group: Mapped[Optional[str]] = mapped_column(
        String(10),
        nullable=True,
    )
    baseline_health_info: Mapped[Optional[str]] = mapped_column(
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
    user: Mapped["User"] = relationship("User", back_populates="patient_profile")
    health_record: Mapped[Optional["HealthRecord"]] = relationship(
        "HealthRecord",
        back_populates="patient",
        uselist=False,
        cascade="all, delete-orphan",
    )
    pregnancies: Mapped[list["Pregnancy"]] = relationship(
        "Pregnancy",
        back_populates="patient",
        cascade="all, delete-orphan",
        order_by="desc(Pregnancy.pregnancy_number)",
    )
    asha_assignments: Mapped[list["AshaPatientAssignment"]] = relationship(
        "AshaPatientAssignment",
        back_populates="patient",
        cascade="all, delete-orphan",
        order_by="desc(AshaPatientAssignment.assigned_at)",
    )
    home_visits: Mapped[list["HomeVisit"]] = relationship(
        "HomeVisit",
        back_populates="patient",
        cascade="all, delete-orphan",
        order_by="desc(HomeVisit.visit_date)",
    )
