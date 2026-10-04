import re
from typing import Any, Dict, List, Optional
from enum import Enum


class PatientIntent(str, Enum):
    ACTIVE_PREGNANCY_STATUS = "active_pregnancy_status"
    PREGNANCY_TIMELINE = "pregnancy_timeline"
    VITALS_EXPLANATION = "vitals_explanation"
    VITALS_TRENDS_CHANGE = "vitals_trends_change"
    DOCTOR_APPOINTMENT_PREPARATION = "doctor_appointment_preparation"
    MATERNAL_WELLNESS_NUTRITION = "maternal_wellness_nutrition"
    ASHA_COMMUNITY_VISITS = "asha_community_visits"
    HEALTH_RECORD_SUMMARY = "health_record_summary"
    SCREENING_RULE_EXPLANATION = "screening_rule_explanation"
    EMERGENCY_RED_FLAG = "emergency_red_flag"
    OUT_OF_SCOPE = "out_of_scope"


class ToolPlanItem:
    def __init__(self, tool_name: str, arguments: Optional[Dict[str, Any]] = None):
        self.tool_name = tool_name
        self.arguments = arguments or {}


class AgentPlanner:
    """
    Semantic Intent Parser & Multi-Tool Plan-and-Solve Orchestrator.
    Maps natural language variations (including phrasing never seen before)
    into structured execution plans consisting of authorized DB tools & knowledge queries.
    """

    @classmethod
    def plan_execution(cls, user_text: str, has_red_flags: bool = False) -> Tuple[PatientIntent, List[ToolPlanItem]]:
        """
        Analyzes user message and generates a structured tool calling plan.
        """
        if has_red_flags:
            return PatientIntent.EMERGENCY_RED_FLAG, []

        q = user_text.lower().strip()
        tools_plan: List[ToolPlanItem] = []

        # 1. Doctor Appointment Preparation
        if any(w in q for w in ["doctor", "physician", "obstetrician", "appointment", "clinic visit"]) and any(
            w in q for w in ["ask", "question", "prep", "prepare", "bring", "discuss", "next visit"]
        ):
            tools_plan.append(ToolPlanItem("get_my_active_pregnancy"))
            tools_plan.append(ToolPlanItem("get_my_latest_vitals"))
            tools_plan.append(
                ToolPlanItem(
                    "retrieve_maternal_knowledge",
                    {"query": "doctor appointment preparation prenatal consultation", "topic": "doctor_prep"},
                )
            )
            return PatientIntent.DOCTOR_APPOINTMENT_PREPARATION, tools_plan

        # 2. Vitals Trends / Changes / History
        if (any(w in q for w in ["change", "trend", "history", "past readings", "recent readings", "previous", "over time", "last week", "compared"])
            and any(w in q for w in ["bp", "blood pressure", "vital", "weight", "reading", "pulse", "measurement"])):
            tools_plan.append(ToolPlanItem("get_my_vitals_history", {"limit": 5}))
            return PatientIntent.VITALS_TRENDS_CHANGE, tools_plan

        # 3. Vitals & BP Explanation / Screening Flags
        # (e.g. "My BP was 148/96 today, why is that important?", "Why did PitPulse tell me to get my BP reviewed?")
        bp_match = re.search(r"(\d{2,3})\s*[/]\s*(\d{2,3})", q)
        if bp_match:
            sys_val = int(bp_match.group(1))
            dia_val = int(bp_match.group(2))
            tools_plan.append(
                ToolPlanItem(
                    "evaluate_vital_screening",
                    {"systolic_bp": sys_val, "diastolic_bp": dia_val},
                )
            )
            tools_plan.append(ToolPlanItem("get_my_latest_vitals"))
            tools_plan.append(
                ToolPlanItem(
                    "retrieve_maternal_knowledge",
                    {"query": "blood pressure screening preeclampsia maternal hypertension", "topic": "hypertension_education"},
                )
            )
            return PatientIntent.VITALS_EXPLANATION, tools_plan

        if any(w in q for w in ["bp", "blood pressure", "vital", "weight", "temperature", "reading", "pulse", "reviewed", "flagged", "alert"]):
            tools_plan.append(ToolPlanItem("get_my_latest_vitals"))
            tools_plan.append(
                ToolPlanItem(
                    "retrieve_maternal_knowledge",
                    {"query": "blood pressure screening maternal vitals", "topic": "hypertension_education"},
                )
            )
            return PatientIntent.VITALS_EXPLANATION, tools_plan

        # 4. Active Pregnancy Status & Gestational Age
        # (e.g. "What week am I in?", "Can you explain what is happening with my pregnancy right now?", "When is my due date?")
        if any(
            w in q for w in [
                "what week", "which week", "how far along", "gestat", "due date", "edd", "lmp",
                "trimester", "baby size", "baby grow", "how big", "happening with my pregnancy",
                "pregnancy status", "am i pregnant", "how many weeks", "my pregnancy right now"
            ]
        ):
            tools_plan.append(ToolPlanItem("get_my_active_pregnancy"))
            tools_plan.append(
                ToolPlanItem(
                    "retrieve_maternal_knowledge",
                    {"query": "fetal development maternal body gestational milestone"},
                )
            )
            return PatientIntent.ACTIVE_PREGNANCY_STATUS, tools_plan

        # 5. Maternal Wellness, Symptoms & Nutrition
        # (e.g. "I've been feeling tired recently, is that common during pregnancy?", "What should I eat?", "Morning sickness")
        if any(
            w in q for w in [
                "food", "diet", "eat", "nutrition", "vitamin", "iron", "folic", "calcium",
                "tired", "fatigue", "nausea", "vomit", "morning sickness", "heartburn", "acid reflux",
                "cramp", "sleep", "swelling", "exercise", "water", "hydration", "common during pregnancy",
                "normal to feel", "discomfort"
            ]
        ):
            tools_plan.append(ToolPlanItem("get_my_active_pregnancy"))
            tools_plan.append(
                ToolPlanItem(
                    "retrieve_maternal_knowledge",
                    {"query": user_text, "topic": "nutrition" if any(w in q for w in ["food", "diet", "eat", "nutrition", "iron", "folic", "calcium", "vitamin"]) else "discomforts"},
                )
            )
            return PatientIntent.MATERNAL_WELLNESS_NUTRITION, tools_plan

        # 6. ASHA Worker Field Visits
        if any(w in q for w in ["asha", "home visit", "field worker", "checkup at home", "last visit", "health worker visit"]):
            tools_plan.append(ToolPlanItem("get_my_recent_home_visits", {"limit": 5}))
            return PatientIntent.ASHA_COMMUNITY_VISITS, tools_plan

        # 7. Complete Health Summary
        if any(w in q for w in ["health record", "my profile", "summary", "my details", "health summary", "overview"]):
            tools_plan.append(ToolPlanItem("get_my_health_summary"))
            return PatientIntent.HEALTH_RECORD_SUMMARY, tools_plan

        # 8. All Pregnancies Timeline
        if any(w in q for w in ["previous pregnancies", "past pregnancies", "all pregnancies", "timeline"]):
            tools_plan.append(ToolPlanItem("get_my_pregnancy_timeline"))
            return PatientIntent.PREGNANCY_TIMELINE, tools_plan

        # 9. Fallback / Out of scope check
        # If the query is completely unrelated to pregnancy or maternal health:
        medical_or_pregnancy_terms = [
            "baby", "pregnant", "pregnancy", "fetus", "maternal", "health", "care", "delivery",
            "birth", "hospital", "body", "pain", "month", "trimester", "doctor", "clinic"
        ]
        if not any(t in q for t in medical_or_pregnancy_terms):
            return PatientIntent.OUT_OF_SCOPE, []

        # If it contains generic maternal queries, default to active pregnancy + general maternal knowledge
        tools_plan.append(ToolPlanItem("get_my_active_pregnancy"))
        tools_plan.append(ToolPlanItem("retrieve_maternal_knowledge", {"query": user_text}))
        return PatientIntent.MATERNAL_WELLNESS_NUTRITION, tools_plan
