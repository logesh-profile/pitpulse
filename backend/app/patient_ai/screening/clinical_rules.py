from typing import Dict, List, Optional, Any
from app.patient_ai.domain.schemas import AiScreeningFlag, ScreeningSeverity


class ClinicalScreeningRules:
    """
    Deterministic clinical screening algorithms and red-flag escalation logic.
    Clinical thresholds are hard-coded deterministic rules, NEVER LLM hallucinations.
    """

    # Emergency obstetric danger signs (WHO & MoHFW Emergency Triage)
    RED_FLAG_DEFINITIONS: List[Dict[str, Any]] = [
        {
            "id": "vaginal_bleeding",
            "keywords": ["bleeding", "vaginal bleeding", "spotting heavy", "blood discharge", "discharge red", "loss of blood", "hemorrhage"],
            "title": "Active Vaginal Bleeding Warning",
            "severity": ScreeningSeverity.EMERGENCY,
            "description": "Any noticeable or active vaginal bleeding in pregnancy requires urgent clinical evaluation to rule out placenta previa, abruptio placentae, or cervical changes.",
            "clinical_basis": "WHO Maternal Emergency Triage Guidelines; ACOG Committee Opinion on Bleeding in Pregnancy.",
            "action": "Proceed immediately to the nearest maternity emergency department or hospital delivery unit.",
        },
        {
            "id": "preeclampsia_triad",
            "keywords": ["severe headache", "blurry vision", "blurred vision", "flashing lights", "scotoma", "spots in vision", "vision change"],
            "title": "Severe Preeclampsia / Neurological Flag",
            "severity": ScreeningSeverity.HIGH,
            "description": "Persistent severe frontal headache with visual disturbances (flashing lights, blurry vision) is a hallmark clinical indicator of cerebral edema secondary to elevated blood pressure.",
            "clinical_basis": "ACOG Practice Bulletin No. 222; ISSHP Hypertensive Disorders of Pregnancy (2021).",
            "action": "Seek urgent same-day medical assessment. Contact your obstetrician or visit the maternity emergency room for BP and urine protein screening.",
        },
        {
            "id": "sudden_severe_edema",
            "keywords": ["swollen face", "swelling face", "puffy face", "swollen eyes", "sudden swelling hands", "rapid swelling"],
            "title": "Rapid Generalized Edema Alert",
            "severity": ScreeningSeverity.CAUTION,
            "description": "Sudden, rapid onset swelling involving the face, periorbital area, and hands within 24–48 hours can signal pathological fluid retention and warrants blood pressure screening.",
            "clinical_basis": "ACOG Diagnostic Guidelines for Hypertensive Disorders of Pregnancy.",
            "action": "Schedule a prompt blood pressure check with your ASHA worker or healthcare clinic within 24 hours.",
        },
        {
            "id": "decreased_fetal_movement",
            "keywords": ["baby stopped moving", "no kicks", "reduced movement", "less movement", "fewer kicks", "baby not active", "no baby movements"],
            "title": "Fetal Movement Alarm",
            "severity": ScreeningSeverity.EMERGENCY,
            "description": "A marked reduction or cessation of fetal activity after 24–28 weeks gestation is an essential marker of potential fetal compromise.",
            "clinical_basis": "RCOG Green-top Guideline No. 57: Reduced Fetal Movements; ACOG Fetal Surveillance Protocols.",
            "action": "Drink cold water, lie on your left side for 1 hour. If you perceive fewer than 4-5 distinct kicks, proceed to the maternity clinic for immediate Cardiotocography / Fetal Doppler check.",
        },
        {
            "id": "fluid_leakage",
            "keywords": ["water broke", "leaking fluid", "amniotic fluid", "gush of water", "constant trickle fluid"],
            "title": "Possible Premature Rupture of Membranes (PROM)",
            "severity": ScreeningSeverity.EMERGENCY,
            "description": "A sudden gush or persistent clear fluid leak from the vagina indicates possible rupture of the amniotic membrane.",
            "clinical_basis": "ACOG Practice Bulletin No. 217: Prelabor Rupture of Membranes; WHO Intrapartum Care.",
            "action": "Note the time and color of fluid, avoid inserting anything vaginally, and go directly to the hospital labor triage.",
        },
        {
            "id": "severe_abdominal_pain",
            "keywords": ["severe abdominal pain", "severe stomach pain", "sharp pain right side", "epigastric pain", "constant belly pain"],
            "title": "Severe Epigastric / Abdominal Pain Flag",
            "severity": ScreeningSeverity.HIGH,
            "description": "Severe constant abdominal pain or right upper quadrant epigastric pain can indicate placental abruption or hepatic distension (HELLP syndrome).",
            "clinical_basis": "ACOG Practice Bulletin No. 222; WHO Antenatal Triage.",
            "action": "Obtain immediate clinical evaluation at a medical facility.",
        },
        {
            "id": "high_fever",
            "keywords": ["high fever", "fever over 38", "chills and fever", "shivering with fever", "temperature 39"],
            "title": "Maternal Febrile Illness Flag",
            "severity": ScreeningSeverity.HIGH,
            "description": "Maternal core temperature >= 38.5°C (101.3°F) can trigger uterine irritability, fetal tachycardia, or reflect maternal systemic infection.",
            "clinical_basis": "CDC & WHO Guidelines on Maternal Infection Management.",
            "action": "Consult your physician promptly for diagnosis and safe antipyretic/antimicrobial management. Do not self-medicate.",
        },
    ]

    @classmethod
    def evaluate_blood_pressure(cls, systolic: int, diastolic: int) -> Dict[str, Any]:
        """
        Evaluates Blood Pressure against standard obstetrical clinical screening cutoffs.
        Returns non-diagnostic screening categorization and actionable guidance.
        """
        if systolic >= 160 or diastolic >= 110:
            return {
                "category": "SEVERE_HYPERTENSIVE_RANGE",
                "severity": ScreeningSeverity.EMERGENCY,
                "is_screening_flag": True,
                "label": "Severe Hypertensive Screening Flag (>=160/110 mmHg)",
                "description": (
                    f"Recorded Blood Pressure ({systolic}/{diastolic} mmHg) is in the severe hypertensive range. "
                    "This is a critical clinical screening observation that requires urgent medical verification to prevent maternal-fetal complications."
                ),
                "clinical_basis": "ACOG Emergency Hypertensive Crisis Protocol; WHO Maternal Guidelines.",
                "action": "Contact your doctor immediately or go to the nearest emergency maternity center for confirmation and management.",
            }
        elif systolic >= 140 or diastolic >= 90:
            return {
                "category": "ELEVATED_HYPERTENSIVE_SCREENING_RANGE",
                "severity": ScreeningSeverity.HIGH,
                "is_screening_flag": True,
                "label": "Elevated Blood Pressure Screening Flag (>=140/90 mmHg)",
                "description": (
                    f"Recorded Blood Pressure ({systolic}/{diastolic} mmHg) meets the clinical threshold (>=140/90 mmHg) "
                    "used to screen for gestational hypertension or preeclampsia. This is not a diagnosis, but an indicator that clinical evaluation is warranted."
                ),
                "clinical_basis": "ACOG Practice Bulletin No. 222 (Gestational Hypertension & Preeclampsia); ISSHP Guidelines (2021).",
                "action": "Schedule a clinical review with your doctor or ASHA worker within 24–48 hours for repeated measurement and urine protein evaluation.",
            }
        elif systolic >= 120 or diastolic >= 80:
            return {
                "category": "PRE_HYPERTENSIVE_RANGE",
                "severity": ScreeningSeverity.CAUTION,
                "is_screening_flag": False,
                "label": "Borderline / Pre-Hypertensive Range (120–139 / 80–89 mmHg)",
                "description": (
                    f"Recorded Blood Pressure ({systolic}/{diastolic} mmHg) is slightly above optimal resting baseline (<120/80 mmHg). "
                    "It is not classified as hypertension, but regular monitoring is beneficial."
                ),
                "clinical_basis": "American Heart Association (AHA) & ACOG Blood Pressure Guidelines.",
                "action": "Maintain optimal hydration, moderate dietary sodium, ensure adequate rest, and have BP checked at your next scheduled visit.",
            }
        else:
            return {
                "category": "OPTIMAL_NORMAL_RANGE",
                "severity": ScreeningSeverity.NORMAL,
                "is_screening_flag": False,
                "label": "Optimal Normal Maternal Blood Pressure (<120/80 mmHg)",
                "description": (
                    f"Recorded Blood Pressure ({systolic}/{diastolic} mmHg) is within the optimal healthy range for maternal-placental perfusion."
                ),
                "clinical_basis": "Standard Obstetrical Clinical Reference Ranges.",
                "action": "Continue routine prenatal care and healthy nutritional habits.",
            }

    @classmethod
    def scan_for_red_flags(cls, user_text: str) -> List[AiScreeningFlag]:
        """
        Scans user natural language text for emergency symptoms and returns matching screening flags.
        """
        flags: List[AiScreeningFlag] = []
        text_lower = user_text.lower()

        for rf in cls.RED_FLAG_DEFINITIONS:
            # Check for keyword match
            keywords = rf["keywords"]
            if any(kw in text_lower for kw in keywords):
                flags.append(
                    AiScreeningFlag(
                        severity=rf["severity"],
                        title=rf["title"],
                        description=rf["description"],
                        clinical_basis=rf["clinical_basis"],
                        recommended_action=rf["action"],
                    )
                )

        return flags
