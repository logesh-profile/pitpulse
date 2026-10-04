import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import CheckConstraint, DateTime, Float, ForeignKey, Integer, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class MaternalVitalRecord(Base):
    __tablename__ = "maternal_vital_records"
    __table_args__ = (
        CheckConstraint(
            "systolic_bp IS NULL OR (systolic_bp >= 40 AND systolic_bp <= 300)",
            name="ck_vitals_systolic_bp",
        ),
        CheckConstraint(
            "diastolic_bp IS NULL OR (diastolic_bp >= 20 AND diastolic_bp <= 200)",
            name="ck_vitals_diastolic_bp",
        ),
        CheckConstraint(
            "weight_kg IS NULL OR (weight_kg >= 20.0 AND weight_kg <= 300.0)",
            name="ck_vitals_weight_kg",
        ),
        CheckConstraint(
            "temperature_c IS NULL OR (temperature_c >= 30.0 AND temperature_c <= 45.0)",
            name="ck_vitals_temperature_c",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        index=True,
    )
    pregnancy_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("pregnancies.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    home_visit_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("home_visits.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    recorded_by_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    systolic_bp: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
    )
    diastolic_bp: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
    )
    weight_kg: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
    )
    temperature_c: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
    )
    notes: Mapped[Optional[str]] = mapped_column(
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
    pregnancy: Mapped["Pregnancy"] = relationship(
        "Pregnancy",
        back_populates="vitals",
    )
    home_visit: Mapped[Optional["HomeVisit"]] = relationship(
        "HomeVisit",
        back_populates="vitals",
    )
    recorded_by: Mapped["User"] = relationship(
        "User",
    )
