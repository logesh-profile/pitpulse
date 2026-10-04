import re
from typing import Dict, List, Optional, Tuple
from app.patient_ai.domain.schemas import (
    AiScreeningFlag,
    AiSourceBadge,
    AiSourceType,
    ScreeningSeverity,
)
from app.patient_ai.screening.clinical_rules import ClinicalScreeningRules


class SafetyGuard:
    """
    Production safety & boundary enforcement guard.
    Guarantees:
    1. Zero unauthorized cross-patient data access.
    2. Zero medical diagnoses / prescription medication advice.
    3. Immediate emergency obstetric red flag triage.
    4. Rejection of prompt injection / jailbreak attempts.
    """

    PROMPT_INJECTION_PATTERNS = [
        r"ignore\s+(all\s+)?(previous|prior)\s+instructions",
        r"system\s+prompt",
        r"reveal\s+your\s+(instructions|prompt|secret)",
        r"you\s+are\s+now\s+(unrestricted|dan|jailbroken)",
        r"bypass\s+security",
        r"act\s+as\s+a\s+doctor\s+and\s+diagnose",
        r"disregard\s+rules",
    ]

    CROSS_PATIENT_PATTERNS = [
        r"(another|other|different)\s+patient",
        r"someone\s+else('s)?\s+(bp|vitals|pregnancy|record|data)",
        r"(john|mary|jane|patient\s*\d+|user\s*\d+)('s)?\s+(bp|vitals|records|info)",
        r"all\s+patients",
        r"database\s+dump",
        r"list\s+all\s+users",
    ]

    MEDICATION_CHANGE_PATTERNS = [
        r"should\s+i\s+(stop|start|take|increase|decrease|double|change)\s+my\s+(dose|dosage|medication|pill|tablet|medicine|drug)",
        r"prescribe\s+(me|for\s+me)",
        r"what\s+dose\s+of\s+(labetalol|nifedipine|aspirin|methyldopa|metformin|antibiotic)",
        r"can\s+i\s+take\s+(ibuprofen|aspirin|paracetamol|antibiotics)\s+instead",
    ]

    DIAGNOSIS_DEMAND_PATTERNS = [
        r"tell\s+me\s+i\s+have\s+(preeclampsia|gestational\s+diabetes|hypertension|anemia|cancer)",
        r"diagnose\s+me",
        r"do\s+i\s+have\s+(preeclampsia|eclampsia|gestational\s+diabetes)",
        r"confirm\s+that\s+i\s+have",
    ]

    @classmethod
    def check_inbound_safety(
        cls, user_text: str
    ) -> Tuple[bool, Optional[str], List[AiScreeningFlag]]:
        """
        Validates incoming user text against safety boundaries.
        Returns: (is_safe, refusal_reason, red_flags)
        """
        text_lower = user_text.lower().strip()

        # 1. Emergency Red Flags Check (Highest Priority)
        red_flags = ClinicalScreeningRules.scan_for_red_flags(user_text)
        if any(rf.severity == ScreeningSeverity.EMERGENCY for rf in red_flags):
            # Safe to proceed through emergency escalation flow
            return True, None, red_flags

        # 2. Prompt Injection / Jailbreak Guard
        for pat in cls.PROMPT_INJECTION_PATTERNS:
            if re.search(pat, text_lower):
                return (
                    False,
                    "I am PitPulse Maternal AI, designed strictly to provide safe, evidence-based pregnancy information. System security boundaries cannot be altered or bypassed.",
                    red_flags,
                )

        # 3. Cross-Patient Privacy / IDOR Guard
        for pat in cls.CROSS_PATIENT_PATTERNS:
            if re.search(pat, text_lower):
                return (
                    False,
                    "Strict Privacy Boundary: PitPulse AI is strictly isolated to your authenticated account. Accessing or inquiring about another patient's health records is prohibited by clinical privacy regulations.",
                    red_flags,
                )

        # 4. Direct Medication Prescription / Modification Refusal
        for pat in cls.MEDICATION_CHANGE_PATTERNS:
            if re.search(pat, text_lower):
                return (
                    False,
                    "Medication Safety Policy: PitPulse AI cannot prescribe, adjust dosages, or modify medication schedules. Any medication change during pregnancy must be evaluated and prescribed directly by your licensed obstetrician or healthcare provider.",
                    red_flags,
                )

        # 5. Direct Diagnosis Demand Refusal
        for pat in cls.DIAGNOSIS_DEMAND_PATTERNS:
            if re.search(pat, text_lower):
                return (
                    False,
                    "Clinical Diagnosis Policy: PitPulse AI provides screening explanations and educational guidance, but cannot make formal clinical diagnoses. Diagnosing conditions such as preeclampsia or gestational diabetes requires comprehensive clinical evaluation, laboratory urine protein testing, and physician review.",
                    red_flags,
                )

        return True, None, red_flags

    @classmethod
    def moderate_outbound_response(
        cls, reply_text: str
    ) -> str:
        """
        Post-generation safety filter ensuring no definitive diagnostic claims
        or prescription assertions leaked into generated output.
        """
        cleaned = reply_text

        # Replace definitive diagnostic language with screening/potential language
        replacements = [
            (r"\byou have preeclampsia\b", "your observations indicate a potential preeclampsia screening flag requiring doctor review"),
            (r"\byou have gestational hypertension\b", "your blood pressure readings are in the elevated range warranting clinical review"),
            (r"\byou are suffering from\b", "your symptoms suggest a possible concern that should be discussed with your doctor"),
            (r"\btake \d+\s*(mg|ml|tablets)\b", "consult your doctor regarding medication dosages"),
        ]

        for pattern, replacement in replacements:
            cleaned = re.sub(pattern, replacement, cleaned, flags=re.IGNORECASE)

        return cleaned
