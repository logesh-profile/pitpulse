from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from enum import Enum
import uuid
from datetime import datetime


class AiSourceType(str, Enum):
    ACTIVE_PREGNANCY = "active_pregnancy"
    PREGNANCY_TIMELINE = "pregnancy_timeline"
    MATERNAL_VITALS = "maternal_vitals"
    VITALS_HISTORY = "vitals_history"
    ASHA_HOME_VISIT = "asha_home_visit"
    PATIENT_HEALTH_RECORD = "patient_health_record"
    CURATED_KNOWLEDGE = "curated_knowledge"
    CLINICAL_SCREENING_RULE = "clinical_screening_rule"
    SAFETY_ESCALATION_PROTOCOL = "safety_escalation_protocol"


class ScreeningSeverity(str, Enum):
    NORMAL = "normal"
    INFO = "info"
    CAUTION = "caution"
    HIGH = "high"
    EMERGENCY = "emergency"


class ToolCallRecord(BaseModel):
    tool_name: str
    arguments: Dict[str, Any] = Field(default_factory=dict)
    execution_status: str = "success"  # success, error, unauthorized
    result_summary: Optional[str] = None
    executed_at: datetime = Field(default_factory=datetime.utcnow)


class AiSourceBadge(BaseModel):
    source_type: AiSourceType
    title: str
    detail: str
    provenance_citation: Optional[str] = None


class AiScreeningFlag(BaseModel):
    severity: ScreeningSeverity
    title: str
    description: str
    clinical_basis: str
    recommended_action: str


class AiAgentQueryRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    conversation_history: List[Dict[str, str]] = Field(default_factory=list)


class AiAgentQueryResponse(BaseModel):
    reply_text: str
    is_safe: bool = True
    confidence: float = 1.0
    intent_detected: str
    tools_called: List[ToolCallRecord] = Field(default_factory=list)
    sources: List[AiSourceBadge] = Field(default_factory=list)
    screening_flags: List[AiScreeningFlag] = Field(default_factory=list)
    suggested_followups: List[str] = Field(default_factory=list)
    disclaimer: str = (
        "PitPulse AI provides informational guidance grounded in your authenticated health records and verified maternal protocols. "
        "It does not provide clinical diagnosis, treatment decisions, or prescriptions. Always consult your qualified healthcare provider."
    )
    generated_at: datetime = Field(default_factory=datetime.utcnow)
