from typing import Dict, List, Any


class ToolRegistry:
    """
    Registry of structured, authorization-aware tool specifications.
    Provides schema definitions for function calling and tool execution.
    """

    TOOLS: List[Dict[str, Any]] = [
        {
            "name": "get_my_active_pregnancy",
            "description": "Retrieves the authenticated patient's current active pregnancy record, including calculated gestational age weeks, days, trimester, and Estimated Due Date (EDD).",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": [],
            },
        },
        {
            "name": "get_my_pregnancy_timeline",
            "description": "Retrieves all pregnancy records (both historical and active) belonging to the authenticated patient.",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": [],
            },
        },
        {
            "name": "get_my_latest_vitals",
            "description": "Retrieves the most recent maternal vital sign observations (Blood Pressure, Weight, Temperature, Clinical notes) recorded by health workers.",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": [],
            },
        },
        {
            "name": "get_my_vitals_history",
            "description": "Retrieves historical log of vital sign records for trends analysis.",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of vital records to retrieve (default: 10)",
                        "default": 10,
                    }
                },
                "required": [],
            },
        },
        {
            "name": "get_my_recent_home_visits",
            "description": "Retrieves recent ASHA worker community home visits, observations, and follow-up care alerts.",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of visits to retrieve (default: 5)",
                        "default": 5,
                    }
                },
                "required": [],
            },
        },
        {
            "name": "get_my_health_summary",
            "description": "Retrieves a unified health summary of the authenticated patient (Identity, Health Record Number, Active Pregnancy, Latest Vitals, Assigned ASHA).",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": [],
            },
        },
        {
            "name": "retrieve_maternal_knowledge",
            "description": "Searches the curated, versioned clinical maternal-health knowledge base for evidence-based guidelines with citations (nutrition, discomforts, appointment prep, hypertension rules).",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search text or topic keywords",
                    },
                    "topic": {
                        "type": "string",
                        "description": "Optional specific topic category (e.g., 'nutrition', 'discomforts', 'doctor_prep', 'hypertension_education', 'fetal_movement')",
                    },
                    "week": {
                        "type": "integer",
                        "description": "Optional gestational week number (1 to 40)",
                    },
                },
                "required": ["query"],
            },
        },
        {
            "name": "evaluate_vital_screening",
            "description": "Runs deterministic clinical screening thresholds against Blood Pressure to assess maternal risk levels.",
            "parameters": {
                "type": "object",
                "properties": {
                    "systolic_bp": {
                        "type": "integer",
                        "description": "Systolic blood pressure in mmHg",
                    },
                    "diastolic_bp": {
                        "type": "integer",
                        "description": "Diastolic blood pressure in mmHg",
                    },
                },
                "required": ["systolic_bp", "diastolic_bp"],
            },
        },
    ]

    @classmethod
    def get_all_tools(cls) -> List[Dict[str, Any]]:
        return cls.TOOLS

    @classmethod
    def get_tool_names(cls) -> List[str]:
        return [t["name"] for t in cls.TOOLS]
