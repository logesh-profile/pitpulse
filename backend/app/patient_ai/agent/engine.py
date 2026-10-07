import time
from typing import Any, Dict, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.patient_ai.agent.planner import AgentPlanner, PatientIntent, ToolPlanItem
from app.patient_ai.agent.safety_guard import SafetyGuard
from app.patient_ai.agent.synthesizer import GroundedSynthesizer
from app.patient_ai.domain.schemas import (
    AiAgentQueryResponse,
    AiScreeningFlag,
    AiSourceBadge,
    ScreeningSeverity,
    ToolCallRecord,
)
from app.patient_ai.tools.patient_tools import PatientAiTools
from app.services.gemini_service import GeminiService
from app.services.grok_service import GrokService


class PatientAiEngine:
    """
    Production-grade Patient AI Agent Orchestrator.
    Combines:
    - Semantic NLU & Multi-Tool Calling Planner
    - Authenticated DB Tools (Zero Fake Data, Strict Patient Authorization)
    - Versioned Maternal Knowledge Base
    - Deterministic Clinical Screening Rules
    - Inbound & Outbound Safety Guardrails
    """

    @classmethod
    async def process_patient_message(
        cls,
        db: AsyncSession,
        patient_user: User,
        message: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> AiAgentQueryResponse:
        """
        Executes full agent loop for an authenticated patient user.
        """
        start_time = time.time()
        user_text = message.strip()

        # 1. Inbound Safety & Boundary Check
        is_safe, refusal_msg, red_flags = SafetyGuard.check_inbound_safety(user_text)
        if not is_safe and refusal_msg:
            return AiAgentQueryResponse(
                reply_text=refusal_msg,
                is_safe=False,
                confidence=1.0,
                intent_detected="safety_policy_block",
                tools_called=[],
                sources=[],
                screening_flags=red_flags,
                suggested_followups=[
                    "What week am I in?",
                    "Explain my latest vitals",
                    "What should I ask my doctor?",
                ],
            )

        # 2. Plan Execution / Select Tools
        has_emergency = any(f.severity == ScreeningSeverity.EMERGENCY for f in red_flags)
        intent, tool_plan = AgentPlanner.plan_execution(
            user_text=user_text, has_red_flags=has_emergency
        )

        # 3. Execute Planned Tools
        tool_records: List[ToolCallRecord] = []
        tool_results: Dict[str, Any] = {}

        for plan_item in tool_plan:
            tool_name = plan_item.tool_name
            args = plan_item.arguments
            rec = ToolCallRecord(tool_name=tool_name, arguments=args)

            try:
                if tool_name == "get_my_active_pregnancy":
                    res = await PatientAiTools.get_my_active_pregnancy(db, patient_user)
                elif tool_name == "get_my_pregnancy_timeline":
                    res = await PatientAiTools.get_my_pregnancy_timeline(db, patient_user)
                elif tool_name == "get_my_latest_vitals":
                    res = await PatientAiTools.get_my_latest_vitals(db, patient_user)
                elif tool_name == "get_my_vitals_history":
                    limit = args.get("limit", 10)
                    res = await PatientAiTools.get_my_vitals_history(db, patient_user, limit=limit)
                elif tool_name == "get_my_recent_home_visits":
                    limit = args.get("limit", 5)
                    res = await PatientAiTools.get_my_recent_home_visits(db, patient_user, limit=limit)
                elif tool_name == "get_my_health_summary":
                    res = await PatientAiTools.get_my_health_summary(db, patient_user)
                elif tool_name == "retrieve_maternal_knowledge":
                    q_val = args.get("query", user_text)
                    topic_val = args.get("topic")
                    week_val = args.get("week")
                    res = PatientAiTools.retrieve_maternal_knowledge(query=q_val, topic=topic_val, week=week_val)
                elif tool_name == "evaluate_vital_screening":
                    sys_bp = args.get("systolic_bp", 120)
                    dia_bp = args.get("diastolic_bp", 80)
                    res = PatientAiTools.evaluate_vital_screening(systolic_bp=sys_bp, diastolic_bp=dia_bp)
                else:
                    res = {"error": f"Unknown tool: {tool_name}"}
                    rec.execution_status = "error"

                rec.result_summary = str(res)[:120]
                tool_results[tool_name] = res
            except Exception as e:
                rec.execution_status = "error"
                rec.result_summary = f"Tool execution failed: {str(e)}"
                tool_results[tool_name] = {"error": str(e)}

            tool_records.append(rec)

        # 4. Synthesize via Free Gemini AI with Real Authenticated Patient Records
        patient_health_summary = await PatientAiTools.get_my_health_summary(db, patient_user)
        patient_context = {
            "patient_name": patient_user.full_name,
            "patient_phone": patient_user.phone_number,
            "patient_email": patient_user.email,
            "health_summary": patient_health_summary,
            "tool_results": tool_results,
        }

        # Try Google Gemini (100% Free Tier) first
        gemini_res = await GeminiService.chat_completion(
            user_message=user_text,
            patient_context=patient_context,
            conversation_history=conversation_history,
        )

        reply_text = gemini_res.get("reply", "")
        model_name = gemini_res.get("model", "Gemini Free AI")

        # Fallback to Grok if Gemini is unavailable
        if not reply_text:
            grok_res = await GrokService.chat_completion(
                user_message=user_text,
                patient_context=patient_context,
                conversation_history=conversation_history,
            )
            reply_text = grok_res.get("reply", "")
            model_name = grok_res.get("model", "Grok AI")

        if not reply_text:
            reply_text, sources, flags, followups = GroundedSynthesizer.synthesize_response(
                user_query=user_text,
                intent=intent,
                tool_results=tool_results,
                screening_flags=red_flags,
            )
        else:
            sources = [
                AiSourceBadge(
                    source_name="MAATRA Live Intelligence",
                    section_ref=model_name,
                    retrieval_method="live_llm",
                )
            ]
            flags = red_flags
            followups = [
                "Explain my latest vitals",
                "Home remedies for wellness",
                "What should I ask my doctor?",
            ]

        # 5. Outbound Safety Filter & Moderation
        moderated_reply = SafetyGuard.moderate_outbound_response(reply_text)

        return AiAgentQueryResponse(
            reply_text=moderated_reply,
            is_safe=True,
            confidence=0.98 if intent != PatientIntent.OUT_OF_SCOPE else 0.75,
            intent_detected=intent.value,
            tools_called=tool_records,
            sources=sources,
            screening_flags=flags,
            suggested_followups=followups,
        )
