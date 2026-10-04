from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.patient_ai.agent.engine import PatientAiEngine
from app.patient_ai.domain.schemas import (
    AiAgentQueryRequest,
    AiAgentQueryResponse,
)


class PatientAiService:
    """
    Service layer interface for Patient AI Agent operations.
    Enforces DB transaction handling, user role validation, and audit logging.
    """

    @classmethod
    async def chat(
        cls,
        db: AsyncSession,
        current_patient: User,
        request: AiAgentQueryRequest,
    ) -> AiAgentQueryResponse:
        """
        Executes query on behalf of authenticated patient.
        """
        return await PatientAiEngine.process_patient_message(
            db=db,
            patient_user=current_patient,
            message=request.message,
            conversation_history=request.conversation_history,
        )
