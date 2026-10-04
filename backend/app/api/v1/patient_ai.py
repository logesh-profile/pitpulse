from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_patient
from app.core.database import get_db
from app.models.user import User
from app.patient_ai.domain.schemas import (
    AiAgentQueryRequest,
    AiAgentQueryResponse,
)
from app.patient_ai.service import PatientAiService

router = APIRouter(prefix="/patient-ai", tags=["Patient AI Agent"])


@router.post(
    "/chat",
    response_model=AiAgentQueryResponse,
    status_code=status.HTTP_200_OK,
    summary="Chat with authenticated Patient AI Agent",
    description=(
        "Processes natural-language inquiries from the authenticated patient. "
        "Executes authorized patient tools (pregnancy, vitals, visits, history), "
        "retrieves curated maternal knowledge, and evaluates deterministic clinical screening rules."
    ),
)
async def chat_with_patient_ai(
    request: AiAgentQueryRequest,
    db: AsyncSession = Depends(get_db),
    current_patient: User = Depends(require_patient),
) -> AiAgentQueryResponse:
    return await PatientAiService.chat(
        db=db,
        current_patient=current_patient,
        request=request,
    )
