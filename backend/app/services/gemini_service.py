import json
import logging
from typing import Any, Dict, List, Optional
import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


class GeminiService:
    """
    Google Gemini AI Service for MAATRA.
    100% Free Tier integration using Gemini 3.5 Flash Lite / 3.8 Flash.
    Grounds replies dynamically with authenticated patient data (zero fake data).
    """

    SUPPORTED_MODELS = [
        "gemini-3.5-flash-lite",
        "gemini-flash-lite-latest",
        "gemini-3.8-flash",
        "gemini-flash-latest",
    ]

    @classmethod
    def get_api_key(cls) -> str:
        return settings.GEMINI_API_KEY.strip()

    @classmethod
    async def chat_completion(
        cls,
        user_message: str,
        patient_context: Optional[Dict[str, Any]] = None,
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> Dict[str, Any]:
        """
        Sends query to Google Gemini API with real patient data grounding.
        """
        api_key = cls.get_api_key()
        if not api_key:
            return {
                "success": False,
                "error": "missing_api_key",
                "reply": "Gemini API key is not configured on the server.",
            }

        # System Prompt with Grounding Guidelines
        system_instruction = (
            "You are MAATRA, an empathetic, highly knowledgeable medical and health assistant.\n"
            "You converse naturally in English, Tamil, and Tanglish with a warm, caring tone (like ChatGPT/Claude).\n"
            "GUIDELINES:\n"
            "1. Natural Human Conversations: Greet warmly, engage in friendly small talk, and listen attentively.\n"
            "2. Comprehensive Health & Home Remedies: Explain practical home remedies, first-aid, fever, headache, cold, digestion, elderly and maternal wellness, nutrition, and blood pressure. For acute red flags (severe bleeding, chest pain), instruct to call 108 immediately.\n"
            "3. ZERO HARDCODED / FAKE DATA: Never invent fake clinic names, fake worker names, or imaginary numbers. If personal medical data is needed, rely strictly on the authenticated patient records provided below. If the patient has no records recorded yet, state that gently.\n"
        )

        if patient_context:
            system_instruction += f"\nAUTHENTICATED PATIENT CLINICAL FILE:\n{json.dumps(patient_context, indent=2, default=str)}\n"
        else:
            system_instruction += "\nNo active clinical records recorded in this patient's profile yet.\n"

        contents: List[Dict[str, Any]] = []
        last_role = None

        if conversation_history:
            for turn in conversation_history[-6:]:
                role = "user" if turn.get("role") == "user" else "model"
                text = turn.get("content", "").strip()
                if text and role != last_role:
                    contents.append({"role": role, "parts": [{"text": text}]})
                    last_role = role

        if last_role == "user" and contents:
            contents[-1]["parts"].append({"text": user_message})
        else:
            contents.append({"role": "user", "parts": [{"text": user_message}]})

        headers = {"Content-Type": "application/json"}
        payload = {
            "system_instruction": {
                "parts": [{"text": system_instruction}]
            },
            "contents": contents,
            "generationConfig": {
                "temperature": 0.5,
                "maxOutputTokens": 800,
            },
        }

        # Try candidate models in order of priority
        async with httpx.AsyncClient(timeout=25.0) as client:
            for model_name in cls.SUPPORTED_MODELS:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
                try:
                    resp = await client.post(url, headers=headers, json=payload)
                    if resp.status_code == 200:
                        data = resp.json()
                        candidates = data.get("candidates", [])
                        if candidates:
                            parts = candidates[0].get("content", {}).get("parts", [])
                            if parts:
                                reply = parts[0].get("text", "").strip()
                                if reply:
                                    return {
                                        "success": True,
                                        "reply": reply,
                                        "model": model_name,
                                    }
                    elif resp.status_code in (404, 503):
                        logger.warning("Gemini model %s returned status %s, trying next model", model_name, resp.status_code)
                        continue
                    else:
                        logger.warning("Gemini API error %s: %s", resp.status_code, resp.text)
                except Exception as ex:
                    logger.warning("Timeout or error calling Gemini model %s: %s", model_name, str(ex))
                    continue

        return {
            "success": False,
            "error": "all_models_unavailable",
            "reply": "",
        }
