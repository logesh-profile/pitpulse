from typing import Dict, List, Optional, Any
import re


class MaternalKnowledgeBase:
    """
    Structured, versioned maternal-health clinical knowledge base.
    Every topic contains verifiable clinical provenance (WHO, ACOG, MoHFW India).
    """
    VERSION = "2026.1-clinical-v1"

    # Gestational week-by-week milestones and developmental guidance
    GESTATIONAL_MILESTONES: Dict[int, Dict[str, Any]] = {
        4: {
            "title": "Weeks 1–4: Blastocyst Implantation & Conception",
            "trimester": 1,
            "fetal_development": "The fertilized blastocyst implants into the endometrium. The amniotic sac and primitive yolk sac establish early nutrient exchange.",
            "maternal_body": "Mild cramping or light implantation spotting may occur. Progesterone and hCG hormone rise, causing mild breast tenderness and fatigue.",
            "nutrition": "Daily 400 mcg Folic Acid supplementation to prevent neural tube defects. Optimal hydration with 8–10 glasses of water.",
            "citation": "ACOG Practice Bulletin No. 198: Prevention of Neural Tube Defects; WHO Antenatal Care Guidelines (2016).",
        },
        8: {
            "title": "Weeks 5–8: Embryonic Organogenesis",
            "trimester": 1,
            "fetal_development": "Major organ systems (brain, spinal cord, primitive heart tube) form. Cardiac activity begins around week 6 (110–160 bpm). Limb buds emerge.",
            "maternal_body": "Morning sickness, nausea, heightened olfactory sensitivity, fatigue, and urinary frequency due to expanding blood volume and pelvic congestion.",
            "nutrition": "Small, frequent meals. Ginger or Vitamin B6 (pyridoxine) to manage nausea. Avoid unpasteurized dairy and raw animal products.",
            "citation": "ACOG Practice Bulletin No. 189: Nausea and Vomiting of Pregnancy; WHO Guidelines on Antenatal Care.",
        },
        13: {
            "title": "Weeks 9–13: Fetal Transition & End of 1st Trimester",
            "trimester": 1,
            "fetal_development": "The embryo is now classified as a fetus. Digits, facial features, and vocal cords differentiate. Fetal reflexes begin.",
            "maternal_body": "Nausea often peaks and starts subsiding near week 12–13. The uterus expands out of the pelvic cavity into the lower abdomen.",
            "nutrition": "Maintain balanced protein intake (lentils, paneer, eggs, well-cooked poultry) and dietary calcium.",
            "citation": "ACOG Clinical Guidelines on Early Pregnancy Assessment; MoHFW Antenatal Protocols.",
        },
        17: {
            "title": "Weeks 14–17: Early Second Trimester Growth",
            "trimester": 2,
            "fetal_development": "Fine lanugo hair covers the skin. Fetal bones begin ossifying. The baby can swallow amniotic fluid and make facial expressions.",
            "maternal_body": "Often called the 'energy surge' phase. Abdominal expansion becomes visible. Mild round ligament stretching aches may be noted.",
            "nutrition": "Increase caloric intake by ~300 kcal/day with whole foods. Continue iron-folic acid supplementation.",
            "citation": "WHO Guidelines on Maternal Nutrition; ACOG Practice Bulletin No. 229.",
        },
        22: {
            "title": "Weeks 18–22: Mid-Pregnancy & Anomaly Scan Window",
            "trimester": 2,
            "fetal_development": "Fetal auditory system develops; baby responds to external sounds and voices. Quickening (first felt fetal kicks) typically begins between weeks 18–20.",
            "maternal_body": "Center of gravity shifts forward. Mild dependent edema in feet or ankles may occur after prolonged standing.",
            "nutrition": "Schedule the level-2 anomaly ultrasound scan with your obstetrician. Ensure adequate dietary iron (spinach, beetroot, jaggery) and calcium.",
            "citation": "ISUOG Guidelines for Mid-Trimester Anomaly Scan; MoHFW Pradhan Mantri Surakshit Matritva Abhiyan (PMSMA).",
        },
        27: {
            "title": "Weeks 23–27: End of Second Trimester",
            "trimester": 2,
            "fetal_development": "Lungs begin producing surfactant. Fetal sleep-wake cycles emerge. Rapid brain neuronal proliferation.",
            "maternal_body": "Mild gastroesophageal reflux (heartburn) and benign Braxton Hicks practice contractions may occur. Sleep on the left side is advised.",
            "nutrition": "Maintain hydration to reduce Braxton Hicks irritability and prevent constipation. Screen for gestational diabetes if ordered.",
            "citation": "ACOG Practice Bulletin No. 190: Gestational Diabetes Mellitus; WHO Antenatal Guidelines.",
        },
        32: {
            "title": "Weeks 28–32: Early Third Trimester Maturation",
            "trimester": 3,
            "fetal_development": "Rapid subcutaneous adipose tissue deposition. Eyes can open and react to light. Lungs and central nervous system continue maturing.",
            "maternal_body": "Shortness of breath as the uterine fundus reaches the epigastric region. Pelvic pressure increases.",
            "nutrition": "Daily fetal movement monitoring (kick counting: ~10 distinct movements within a 2-hour window of restful observation).",
            "citation": "ACOG Committee Opinion No. 700: Methods for Fetal Well-Being Assessment.",
        },
        36: {
            "title": "Weeks 33–36: Maturing for Delivery",
            "trimester": 3,
            "fetal_development": "Immune antibody transfer from maternal circulation peaks. Baby typically settles into a cephalic (vertex) head-down presentation.",
            "maternal_body": "Increased pelvic pressure, sleep interruptions, and frequent urination as fetal head engages near the pelvic brim.",
            "nutrition": "Finalize your hospital bag, birth plan, emergency contact numbers, and transport arrangements with your ASHA worker.",
            "citation": "MoHFW Intrapartum & Essential Newborn Care Guidelines; WHO Birth Preparedness Protocols.",
        },
        40: {
            "title": "Weeks 37–40+: Full Term & Labor Readiness",
            "trimester": 3,
            "fetal_development": "Considered full term. Pulmonary surfactant and digestive enzymes are fully mature for extrauterine survival.",
            "maternal_body": "Lightening occurs as baby descends. Cervical effacement may begin. True labor signs: rhythmic uterine contractions 5 mins apart, rupture of membranes.",
            "nutrition": "Stay calm, well-rested, and monitor for regular labor contractions or fluid leakage.",
            "citation": "ACOG Committee Opinion No. 579: Definition of Term Pregnancy; WHO Labor Care Guide.",
        },
    }

    # Curated topic repositories with clinical explanations & citations
    TOPICS: Dict[str, Dict[str, Any]] = {
        "nutrition": {
            "title": "Maternal Antenatal Nutrition Guidelines",
            "summary": "Evidence-based dietary recommendations for maternal health and fetal tissue growth.",
            "content": (
                "Key Nutritional Pillars:\n"
                "1. Iron & Folic Acid: Crucial for expanding maternal plasma volume and preventing fetal neural tube defects. Iron sources: spinach, lentils, jaggery, beetroot, fortified cereals.\n"
                "2. Protein: 75–100g daily for fetal cellular synthesis (dal, paneer, tofu, eggs, well-cooked lean poultry, nuts).\n"
                "3. Calcium & Vitamin D: 1000–1200mg calcium daily for fetal skeletal ossification (dairy, sesame seeds, ragi, fortified milk).\n"
                "4. Hydration: 2.5–3 liters of water daily to maintain amniotic volume and prevent urinary tract infections.\n"
                "Foods to Avoid: Raw/undercooked meat, unpasteurized milk/cheese, unwashed raw produce, excess caffeine (>200mg/day), alcohol, and tobacco."
            ),
            "citation": "WHO e-Library of Evidence for Nutrition Actions (eLENA); ICMR-NIN Dietary Guidelines for Indians (2024).",
        },
        "discomforts": {
            "title": "Common Benign Pregnancy Discomforts & Safe Comfort Measures",
            "summary": "Physiological changes during pregnancy and evidence-based non-pharmacological relief.",
            "content": (
                "1. Morning Sickness & Nausea: Eat small, dry snacks (crackers/toast) before getting out of bed. Sip ginger water or lemon tea. Avoid oily/spicy foods.\n"
                "2. Dependent Foot Swelling: Elevate legs when seated. Avoid prolonged standing. Sleep on the left side to relieve IVC compression.\n"
                "3. Heartburn & Acid Reflux: Eat small meals, avoid lying down immediately after eating, and avoid heavy spicy/fatty foods.\n"
                "4. Lower Back Ache: Maintain good posture, wear low-heeled supportive footwear, and perform gentle pelvic tilt stretches.\n"
                "When to Contact Doctor: If nausea prevents keeping any fluid down for 24h, or swelling is sudden and affects face/hands."
            ),
            "citation": "ACOG FAQs on Common Pregnancy Discomforts; NHS Antenatal Health Guidance.",
        },
        "doctor_prep": {
            "title": "Doctor Consultation Preparation Guide",
            "summary": "Standard clinical discussion points for prenatal visits organized by trimester.",
            "content": (
                "1st Trimester Topics:\n"
                "- Ultrasound dating scan schedule and confirmation of viable intrauterine pregnancy.\n"
                "- Baseline blood tests (CBC/Hb, Blood Group & Rh typing, Rubella, Thyroid, Hepatitis, HIV, VDRL, Blood Glucose).\n"
                "- Management of nausea/vomiting and prescription of prenatal vitamins.\n\n"
                "2nd Trimester Topics:\n"
                "- Level-2 Anomaly Ultrasound scan (typically weeks 18–22).\n"
                "- Oral Glucose Tolerance Test (OGTT) for gestational diabetes screening.\n"
                "- Maternal blood pressure and fundal height tracking.\n"
                "- Onset and frequency of fetal movements (quickening).\n\n"
                "3rd Trimester Topics:\n"
                "- Fetal presentation (cephalic vs breech) and placental maturity.\n"
                "- Blood pressure review for preeclampsia screening.\n"
                "- Hospital admission plan, emergency transport, and recognition of active labor signs."
            ),
            "citation": "WHO Recommendations on Antenatal Care for a Positive Pregnancy Experience; ACOG Antenatal Care Checklist.",
        },
        "hypertension_education": {
            "title": "Blood Pressure & Hypertensive Screening in Pregnancy",
            "summary": "Clinical rationale for regular maternal blood pressure monitoring and screening thresholds.",
            "content": (
                "Clinical Blood Pressure Benchmarks:\n"
                "- Normal Blood Pressure: Systolic < 120 mmHg and Diastolic < 80 mmHg.\n"
                "- Borderline / Pre-Hypertension: Systolic 120–139 mmHg or Diastolic 80–89 mmHg.\n"
                "- Hypertensive Screening Threshold: Systolic >= 140 mmHg or Diastolic >= 90 mmHg (measured on two occasions).\n\n"
                "Why is Blood Pressure Screened?\n"
                "Elevated blood pressure during pregnancy can indicate Gestational Hypertension or Preeclampsia. Early detection through routine screening enables timely clinical monitoring, urine protein testing, and preventive measures to ensure optimal placental blood flow."
            ),
            "citation": "ACOG Practice Bulletin No. 222: Gestational Hypertension and Preeclampsia; ISSHP Global Guidelines (2021).",
        },
        "fetal_movement": {
            "title": "Fetal Movement & Kick Count Monitoring",
            "summary": "Clinical guidance on assessing fetal vitality in the second and third trimesters.",
            "content": (
                "1. When to Expect Movements: Most first-time mothers feel initial flutters (quickening) between weeks 18–22; experienced mothers may feel them by week 16–18.\n"
                "2. Kick Count Protocol (From Week 28+): Lie comfortably on your left side in a quiet environment. Count all distinct kicks, swishes, and rolls. A healthy fetus typically registers at least 10 distinct movements within 2 hours.\n"
                "3. Reduced Movement Protocol: If baby is less active than usual, drink a glass of cold water or light fruit juice and rest on your left side for 1 hour. If movements remain distinctly reduced, visit your healthcare center promptly for non-stress test (NST) evaluation."
            ),
            "citation": "ACOG Guidelines on Fetal Movement Monitoring; RCOG Green-top Guideline No. 57: Reduced Fetal Movements.",
        },
    }

    @classmethod
    def get_milestone_for_week(cls, weeks: int) -> Dict[str, Any]:
        """Returns the appropriate milestone bracket for a given gestational week."""
        if weeks <= 0:
            return cls.GESTATIONAL_MILESTONES[4]
        for bracket in sorted(cls.GESTATIONAL_MILESTONES.keys()):
            if weeks <= bracket:
                return cls.GESTATIONAL_MILESTONES[bracket]
        return cls.GESTATIONAL_MILESTONES[40]

    @classmethod
    def search_knowledge(
        cls,
        query: str,
        topic_filter: Optional[str] = None,
        weeks: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Retrieves relevant structured knowledge articles based on query keywords and semantic context.
        """
        results: List[Dict[str, Any]] = []
        q_lower = query.lower()

        # 1. Topic-based match
        for key, item in cls.TOPICS.items():
            if topic_filter and topic_filter.lower() in key:
                results.append({"topic_key": key, **item})
                continue
            
            keywords = [
                key, item["title"].lower(), item["summary"].lower()
            ]
            if any(kw in q_lower for kw in key.split("_")) or any(word in q_lower for word in item["title"].lower().split()):
                results.append({"topic_key": key, **item})

        # 2. Week/Gestational milestone match
        if weeks is not None or any(w in q_lower for w in ["week", "month", "trimester", "stage", "gestat", "baby grow", "milestone"]):
            target_week = weeks if weeks is not None else 20
            # Extract number if in query (e.g. "week 24")
            match = re.search(r"week\s*(\d+)", q_lower)
            if match:
                target_week = int(match.group(1))
            
            milestone = cls.get_milestone_for_week(target_week)
            results.append({
                "topic_key": f"gestational_week_{target_week}",
                "title": milestone["title"],
                "summary": f"Fetal and maternal milestones for Week {target_week} ({milestone['trimester']})",
                "content": f"Fetal Development:\n{milestone['fetal_development']}\n\nMaternal Body:\n{milestone['maternal_body']}\n\nNutrition:\n{milestone['nutrition']}",
                "citation": milestone["citation"],
            })

        return results
