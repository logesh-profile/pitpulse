import enum
import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class PregnancyStatusEnum(str, enum.Enum):
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"
    TERMINATED = "TERMINATED"
    UNKNOWN = "UNKNOWN"


class Pregnancy(Base):
    __tablename__ = "pregnancies"
    __table_args__ = (
        UniqueConstraint("patient_id", "pregnancy_number", name="uq_patient_pregnancy_number"),
        CheckConstraint("pregnancy_number > 0", name="ck_pregnancy_number_positive"),
    )

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
    pregnancy_number: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    status: Mapped[PregnancyStatusEnum] = mapped_column(
        Enum(
            PregnancyStatusEnum,
            name="pregnancy_status_enum",
            values_callable=lambda obj: [e.value for e in obj],
        ),
        nullable=False,
        default=PregnancyStatusEnum.ACTIVE,
        index=True,
    )
    lmp: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )
    edd: Mapped[date] = mapped_column(
        Date,
        nullable=False,
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
    patient: Mapped["PatientProfile"] = relationship(
        "PatientProfile",
        back_populates="pregnancies",
    )
