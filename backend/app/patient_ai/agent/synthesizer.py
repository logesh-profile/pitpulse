from typing import Any, Dict, List, Optional, Tuple
from app.patient_ai.agent.planner import PatientIntent
from app.patient_ai.domain.schemas import (
    AiScreeningFlag,
    AiSourceBadge,
    AiSourceType,
    ScreeningSeverity,
)


class GroundedSynthesizer:
    """
    Evidence-grounded response synthesizer.
    Combines authenticated tool outputs, knowledge base articles, and screening flags
    into clear, clinically safe, empathetic patient responses.
    """

    @classmethod
    def synthesize_response(
        cls,
        user_query: str,
        intent: PatientIntent,
        tool_results: Dict[str, Any],
        screening_flags: List[AiScreeningFlag],
    ) -> Tuple[str, List[AiSourceBadge], List[AiScreeningFlag], List[str]]:
        """
        Synthesizes response text, source provenance badges, screening flags, and followup questions.
        """
        sources: List[AiSourceBadge] = []
        flags: List[AiScreeningFlag] = list(screening_flags)
        followups: List[str] = []

        # 0. Emergency Red Flag Response
        if intent == PatientIntent.EMERGENCY_RED_FLAG or any(f.severity == ScreeningSeverity.EMERGENCY for f in flags):
            primary_flag = next((f for f in flags if f.severity == ScreeningSeverity.EMERGENCY), flags[0] if flags else None)
            title = primary_flag.title if primary_flag else "Obstetric Emergency Alert"
            desc = primary_flag.description if primary_flag else "Urgent clinical evaluation required."
            action = primary_flag.recommended_action if primary_flag else "Contact emergency medical services."

            reply_text = (
                f"🚨 **URGENT CLINICAL ATTENTION RECOMMENDED**\n\n"
                f"**{title}**\n{desc}\n\n"
                f"**Recommended Immediate Action:**\n{action}\n\n"
                f"> **Important Safety Notice:** PitPulse AI is strictly an informational assistant. In the presence of acute symptoms, "
                f"please proceed immediately to the nearest maternity emergency center or hospital delivery unit."
            )
            sources.append(
                AiSourceBadge(
                    source_type=AiSourceType.SAFETY_ESCALATION_PROTOCOL,
                    title="Emergency Obstetric Protocol",
                    detail="WHO & MoHFW Antenatal Danger Signs Triage",
                    provenance_citation="WHO Guidelines on Maternal Emergency Triage and Obstetric Care",
                )
            )
            followups = [
                "What is my hospital emergency contact?",
                "Who is my assigned ASHA field worker?",
            ]
            return reply_text, sources, flags, followups

        # 1. Active Pregnancy Status
        if intent == PatientIntent.ACTIVE_PREGNANCY_STATUS:
            preg_data = tool_results.get("get_my_active_pregnancy", {})
            kb_data = tool_results.get("retrieve_maternal_knowledge", {})

            if not preg_data.get("has_active_pregnancy"):
                reply_text = (
                    "You do not have an active pregnancy record registered in your PitPulse account yet.\n\n"
                    "To track your gestational age, Estimated Due Date (EDD), and receive week-by-week development updates, "
                    "you can register your pregnancy from the **My Health Dashboard** using your Last Menstrual Period (LMP) date."
                )
                followups = [
                    "How do I register a pregnancy in PitPulse?",
                    "What is normal blood pressure during pregnancy?",
                ]
                return reply_text, sources, flags, followups

            weeks = preg_data.get("gestational_age_weeks", 0)
            days = preg_data.get("gestational_age_days", 0)
            ga_disp = preg_data.get("gestational_age_display", f"{weeks} weeks")
            trimester_disp = preg_data.get("trimester_display", "1st Trimester")
            edd = preg_data.get("edd", "")
            lmp = preg_data.get("lmp", "")
            preg_num = preg_data.get("pregnancy_number", 1)

            sources.append(
                AiSourceBadge(
                    source_type=AiSourceType.ACTIVE_PREGNANCY,
                    title=f"Active Pregnancy #{preg_num}",
                    detail=f"LMP: {lmp} • Calculated EDD: {edd} • Gestational Age: {ga_disp}",
                    provenance_citation="PitPulse Authenticated Maternal Health Record",
                )
            )

            # Knowledge base context
            milestone_text = ""
            articles = kb_data.get("articles", [])
            if articles:
                art = articles[0]
                milestone_text = f"\n\n**👶 Baby & Body Development ({art['title']}):**\n{art['content']}"
                sources.append(
                    AiSourceBadge(
                        source_type=AiSourceType.CURATED_KNOWLEDGE,
                        title=art["title"],
                        detail=art["summary"],
                        provenance_citation=art.get("citation", "Clinical Antenatal Guidelines"),
                    )
                )

            reply_text = (
                f"🤰 **Your Current Pregnancy Status**\n\n"
                f"- **Current Gestational Age:** {ga_disp} ({trimester_disp})\n"
                f"- **Estimated Due Date (EDD):** {edd}\n"
                f"- **Last Menstrual Period (LMP):** {lmp}\n"
                f"- **Pregnancy Record Sequence:** #{preg_num}"
                f"{milestone_text}"
            )
            followups = [
                f"What questions should I ask my doctor for Week {weeks}?",
                "Explain my latest blood pressure and vitals",
                f"What foods are recommended in the {trimester_disp}?",
            ]
            return reply_text, sources, flags, followups

        # 2. Vitals Explanation & BP Screening
        if intent == PatientIntent.VITALS_EXPLANATION:
            vitals_data = tool_results.get("get_my_latest_vitals", {})
            screening_eval = tool_results.get("evaluate_vital_screening")
            kb_data = tool_results.get("retrieve_maternal_knowledge", {})

            # If user provided explicit numbers in query
            if screening_eval:
                is_flag = screening_eval.get("is_screening_flag", False)
                sev = screening_eval.get("severity", ScreeningSeverity.INFO)
                flags.append(
                    AiScreeningFlag(
                        severity=sev,
                        title=screening_eval.get("label", "Blood Pressure Evaluation"),
                        description=screening_eval.get("description", ""),
                        clinical_basis=screening_eval.get("clinical_basis", "ACOG / WHO Standards"),
                        recommended_action=screening_eval.get("action", "Clinical consultation recommended"),
                    )
                )
                sources.append(
                    AiSourceBadge(
                        source_type=AiSourceType.CLINICAL_SCREENING_RULE,
                        title="Blood Pressure Screening Thresholds",
                        detail=screening_eval.get("label", ""),
                        provenance_citation=screening_eval.get("clinical_basis", "WHO Maternal Health Standards"),
                    )
                )

            if not vitals_data.get("has_vitals") and not screening_eval:
                reply_text = (
                    "No vital sign records have been logged in your profile yet.\n\n"
                    "When your assigned ASHA field worker conducts a home visit or when you attend a clinical prenatal checkup, "
                    "your Blood Pressure, Weight, and Temperature observations will appear here automatically."
                )
                followups = [
                    "What is considered normal blood pressure in pregnancy?",
                    "Who is my assigned ASHA field worker?",
                ]
                return reply_text, sources, flags, followups

            vital_text = ""
            if vitals_data.get("has_vitals"):
                bp_disp = vitals_data.get("bp_display", "Not recorded")
                weight = vitals_data.get("weight_kg")
                temp = vitals_data.get("temperature_c")
                recorded_at = vitals_data.get("recorded_at", "")
                recorded_by = vitals_data.get("recorded_by_name", "Health Worker")
                notes = vitals_data.get("notes")

                sources.append(
                    AiSourceBadge(
                        source_type=AiSourceType.MATERNAL_VITALS,
                        title=f"Latest Recorded Vitals ({recorded_at[:10] if recorded_at else 'Recent'})",
                        detail=f"BP: {bp_disp} • Weight: {weight or 'N/A'} kg • Temp: {temp or 'N/A'} °C • By: {recorded_by}",
                        provenance_citation="PitPulse Field Health Telemetry",
                    )
                )

                bp_eval = vitals_data.get("bp_screening_evaluation")
                if bp_eval and bp_eval.get("is_screening_flag"):
                    flags.append(
                        AiScreeningFlag(
                            severity=bp_eval.get("severity", ScreeningSeverity.CAUTION),
                            title=bp_eval.get("label", "Elevated Blood Pressure Alert"),
                            description=bp_eval.get("description", ""),
                            clinical_basis=bp_eval.get("clinical_basis", "ACOG Standards"),
                            recommended_action=bp_eval.get("action", "Clinical follow-up recommended"),
                        )
                    )

                vital_text = (
                    f"🩺 **Your Latest Recorded Vitals Summary**\n"
                    f"*Recorded on: {recorded_at[:10] if recorded_at else 'Recent'} by {recorded_by}*\n\n"
                    f"- **Blood Pressure:** {bp_disp}\n"
                    f"- **Weight:** {f'{weight} kg' if weight else 'Not recorded'}\n"
                    f"- **Body Temperature:** {f'{temp} °C' if temp else 'Not recorded'}\n"
                    f"{f'- **Clinical Note:** \"{notes}\"\n' if notes else ''}"
                )

            # Add Knowledge Base Educational Context
            kb_text = ""
            articles = kb_data.get("articles", [])
            if articles:
                art = articles[0]
                kb_text = f"\n\n**📚 Clinical Guidance ({art['title']}):**\n{art['content']}"
                sources.append(
                    AiSourceBadge(
                        source_type=AiSourceType.CURATED_KNOWLEDGE,
                        title=art["title"],
                        detail=art["summary"],
                        provenance_citation=art.get("citation", "Clinical Antenatal Reference"),
                    )
                )

            reply_text = f"{vital_text}{kb_text}"
            followups = [
                "What should I ask my doctor about my blood pressure?",
                "What are the warning signs of preeclampsia?",
                "How often should my vitals be checked?",
            ]
            return reply_text, sources, flags, followups

        # 3. Vitals Trends / Changes Over Time
        if intent == PatientIntent.VITALS_TRENDS_CHANGE:
            history_data = tool_results.get("get_my_vitals_history", {})
            obs = history_data.get("observations", [])

            if not obs:
                reply_text = (
                    "There are not enough historical vital readings recorded in your account yet to compute trends.\n\n"
                    "As your ASHA worker or doctor records successive visits, PitPulse will track your blood pressure, "
                    "weight changes, and temperature progression here."
                )
                followups = ["What are my latest vitals?", "What is normal blood pressure?"]
                return reply_text, sources, flags, followups

            sources.append(
                AiSourceBadge(
                    source_type=AiSourceType.VITALS_HISTORY,
                    title=f"Vitals History ({len(obs)} entries)",
                    detail="Chronological telemetry records",
                    provenance_citation="PitPulse Longitudinal Health Record",
                )
            )

            lines = []
            for item in obs:
                lines.append(
                    f"- **{item['recorded_at'][:10]}:** BP: {item['bp_display']}, Weight: {item.get('weight_kg', 'N/A')} kg (By: {item.get('recorded_by', 'Health Worker')})"
                )

            history_list = "\n".join(lines)
            reply_text = (
                f"📈 **Your Recent Vitals Progression & History**\n\n"
                f"{history_list}\n\n"
                f"💡 **Clinical Review Note:** Stable blood pressure readings below 120/80 mmHg and gradual, steady weight gain "
                f"reflect optimal maternal-fetal adaptation. Any sudden spike in BP or rapid fluid weight gain should be reported to your doctor."
            )
            followups = [
                "What questions should I ask my doctor about these readings?",
                "Explain my blood pressure screening thresholds",
            ]
            return reply_text, sources, flags, followups

        # 4. Doctor Appointment Preparation
        if intent == PatientIntent.DOCTOR_APPOINTMENT_PREPARATION:
            preg_data = tool_results.get("get_my_active_pregnancy", {})
            vitals_data = tool_results.get("get_my_latest_vitals", {})
            kb_data = tool_results.get("retrieve_maternal_knowledge", {})

            weeks = preg_data.get("gestational_age_weeks", 0) if preg_data.get("has_active_pregnancy") else 0
            ga_disp = preg_data.get("gestational_age_display", "Prenatal Care") if preg_data.get("has_active_pregnancy") else "Prenatal Checkup"

            questions: List[str] = []
            if weeks <= 13:
                questions = [
                    "Is my early dating ultrasound scan on schedule?",
                    "Which prenatal vitamins and folic acid dosage are appropriate for me?",
                    "Are there any baseline blood tests (Hb, Blood Group, Thyroid, Blood Glucose) needed now?",
                    "What safe measures can I take to manage nausea or fatigue?",
                ]
            elif weeks <= 27:
                questions = [
                    "When is my Level-2 anomaly ultrasound scan scheduled?",
                    "Should I undergo the Oral Glucose Tolerance Test (OGTT) for gestational diabetes?",
                    "Is my maternal weight gain on track for my gestational age?",
                    "What normal fetal movement patterns should I expect to feel?",
                ]
            else:
                questions = [
                    "Is the baby in a head-down (cephalic) presentation?",
                    "How often should I count fetal movements and kicks daily?",
                    "What specific signs indicate I should proceed to the hospital for labor?",
                    "What is our hospital admission and emergency delivery plan?",
                ]

            if vitals_data.get("has_vitals") and vitals_data.get("systolic_bp", 0) >= 130:
                bp_disp = vitals_data.get("bp_display", "elevated")
                questions.insert(0, f"My recent blood pressure was recorded as {bp_disp} — do we need more frequent monitoring or urine protein testing?")

            q_list = "\n".join(f"• \"{q}\"" for q in questions)
            reply_text = (
                f"📋 **Doctor Consultation Preparation Guide**\n"
                f"*Tailored for your current stage ({ga_disp})*\n\n"
                f"Here are key clinical questions recommended to discuss with your obstetrician / doctor at your upcoming visit:\n\n"
                f"{q_list}\n\n"
                f"💡 **Tip:** Mention any new physical symptoms (headaches, swelling, heartburn) and bring your PitPulse Health Record Number."
            )

            sources.append(
                AiSourceBadge(
                    source_type=AiSourceType.CURATED_KNOWLEDGE,
                    title="Antenatal Consultation Protocols",
                    detail=f"Clinical discussion points for Week {weeks}",
                    provenance_citation="WHO & ACOG Antenatal Care Checklist Guidelines",
                )
            )
            followups = [
                "What are my latest vitals?",
                "How is my baby growing this week?",
            ]
            return reply_text, sources, flags, followups

        # 5. Maternal Wellness, Discomforts & Nutrition
        if intent == PatientIntent.MATERNAL_WELLNESS_NUTRITION:
            preg_data = tool_results.get("get_my_active_pregnancy", {})
            kb_data = tool_results.get("retrieve_maternal_knowledge", {})

            articles = kb_data.get("articles", [])
            article_body = ""
            for art in articles[:2]:
                article_body += f"\n\n**{art['title']}**\n{art['content']}"
                sources.append(
                    AiSourceBadge(
                        source_type=AiSourceType.CURATED_KNOWLEDGE,
                        title=art["title"],
                        detail=art["summary"],
                        provenance_citation=art.get("citation", "Evidence-Based Maternal Health Guidelines"),
                    )
                )

            weeks = preg_data.get("gestational_age_weeks") if preg_data.get("has_active_pregnancy") else None
            stage_note = f"for your current stage ({preg_data.get('gestational_age_display')})" if weeks else "during pregnancy"

            reply_text = (
                f"🌸 **Maternal Wellness & Health Guidance**\n"
                f"*Evidence-based recommendations {stage_note}:*\n"
                f"{article_body}\n\n"
                f"> Always follow individual clinical prescriptions provided by your consulting doctor."
            )
            followups = [
                "What should I ask my doctor at my next visit?",
                "Explain my blood pressure readings",
            ]
            return reply_text, sources, flags, followups

        # 6. ASHA Home Visits
        if intent == PatientIntent.ASHA_COMMUNITY_VISITS:
            visits_data = tool_results.get("get_my_recent_home_visits", {})
            visits = visits_data.get("visits", [])

            if not visits:
                reply_text = (
                    "No ASHA community home visits have been recorded in your account yet.\n\n"
                    "Once your assigned ASHA worker conducts a prenatal checkup at your residence, "
                    "the visit observations, checkup purpose, and follow-up recommendations will be logged here."
                )
                followups = ["Who is my assigned ASHA worker?", "What are my latest vitals?"]
                return reply_text, sources, flags, followups

            sources.append(
                AiSourceBadge(
                    source_type=AiSourceType.ASHA_HOME_VISIT,
                    title=f"ASHA Field Visits ({len(visits)} records)",
                    detail="Community antenatal outreach logs",
                    provenance_citation="PitPulse Field Health Worker System",
                )
            )

            visit_entries = []
            for v in visits:
                date_str = v.get("visit_date", "")[:10]
                worker = v.get("asha_worker_name", "ASHA Worker")
                purpose = v.get("purpose", "Routine checkup")
                obs = v.get("observations")
                follow_up = v.get("follow_up_required")
                entry = f"- **{date_str} by {worker}:** Purpose: {purpose}"
                if obs:
                    entry += f"\n  *Observations:* {obs}"
                if follow_up:
                    entry += f"\n  *Follow-up:* ⚠️ {v.get('follow_up_notes') or 'Action recommended'}"
                visit_entries.append(entry)

            reply_text = (
                f"🏡 **ASHA Field Care & Home Visits Summary**\n\n"
                f"{'\n\n'.join(visit_entries)}\n\n"
                f"💡 Your ASHA worker coordinates closely with primary health centers to support your antenatal journey."
            )
            followups = [
                "Explain my recorded vitals from these visits",
                "What should I ask my doctor?",
            ]
            return reply_text, sources, flags, followups

        # 7. Complete Health Summary
        if intent == PatientIntent.HEALTH_RECORD_SUMMARY:
            summary_data = tool_results.get("get_my_health_summary", {})
            patient_name = summary_data.get("patient_name", "Patient")
            hr_num = summary_data.get("health_record_number", "HR-INITIALIZING")
            blood_group = summary_data.get("blood_group", "Not recorded")
            asha_name = summary_data.get("assigned_asha_worker", "Not assigned yet")
            preg = summary_data.get("active_pregnancy")
            vitals = summary_data.get("latest_vitals")

            sources.append(
                AiSourceBadge(
                    source_type=AiSourceType.PATIENT_HEALTH_RECORD,
                    title=f"Health Profile Anchor ({hr_num})",
                    detail=f"Patient: {patient_name} • Blood Group: {blood_group}",
                    provenance_citation="PitPulse Core Health Record Anchor",
                )
            )

            preg_str = f"Active ({preg.get('gestational_age_display', 'Active')}, Due: {preg.get('edd', 'N/A')})" if preg else "No active pregnancy registered"
            vitals_str = f"BP: {vitals.get('bp_display', 'N/A')}, Weight: {vitals.get('weight_kg', 'N/A')} kg" if vitals else "No vitals logged yet"

            reply_text = (
                f"🗂️ **PitPulse Patient Health Summary**\n\n"
                f"- **Patient Name:** {patient_name}\n"
                f"- **Health Record ID:** `{hr_num}`\n"
                f"- **Blood Group:** {blood_group}\n"
                f"- **Assigned ASHA Worker:** {asha_name}\n"
                f"- **Pregnancy Status:** {preg_str}\n"
                f"- **Latest Vitals Observation:** {vitals_str}"
            )
            followups = [
                "How is my baby growing this week?",
                "What should I ask my doctor?",
            ]
            return reply_text, sources, flags, followups

        # 8. Out of Scope / Unsupported Fallback
        reply_text = (
            "I understand your question, but as a specialized **maternal health and pregnancy assistant**, I can only safely assist with:\n\n"
            "1. 🤰 **Your actual pregnancy progress**, gestational week, and EDD.\n"
            "2. 🩺 **Your recorded vitals** (Blood Pressure, Weight, Temperature) and screening rules.\n"
            "3. 🏡 **Your ASHA worker home visits** and care history.\n"
            "4. 📋 **Preparing questions** for your doctor consultation.\n"
            "5. 🥗 **Evidence-based pregnancy wellness**, nutrition, and warning sign education.\n\n"
            "I cannot diagnose medical conditions, prescribe medications, or answer queries outside maternal healthcare.\n\n"
            "Please consult your healthcare provider or obstetrician for clinical decisions."
        )
        followups = [
            "How is my baby growing this week?",
            "Explain my latest vitals",
            "What should I ask my doctor?",
        ]
        return reply_text, sources, flags, followups
