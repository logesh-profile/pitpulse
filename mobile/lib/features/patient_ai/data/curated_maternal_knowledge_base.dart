class CuratedMaternalKnowledgeBase {
  static const String disclaimerNotice =
      'Important: PitPulse AI provides informational guidance based on clinical maternal protocols and your health records. It is not a medical diagnosis or treatment prescription. Always consult your obstetrician or ASHA worker for clinical evaluation.';

  /// Gestational age weekly milestone details
  static Map<String, String> getGestationalMilestone(int weeks) {
    if (weeks <= 4) {
      return {
        'title': 'Early Conception & Implantation (Weeks 1–4)',
        'trimester': '1st Trimester',
        'fetalDevelopment': 'The fertilized egg forms a blastocyst and implants into the uterine lining. The amniotic sac and early placenta begin developing.',
        'maternalBody': 'You might experience mild cramping or spotting, fatigue, and breast tenderness as hCG hormone levels rise.',
        'nutritionAdvice': 'Start taking 400 mcg of Folic Acid daily to prevent neural tube defects. Stay well-hydrated.',
      };
    } else if (weeks <= 8) {
      return {
        'title': 'Embryonic Organogenesis (Weeks 5–8)',
        'trimester': '1st Trimester',
        'fetalDevelopment': 'The neural tube, heart, brain, and tiny limb buds are forming. The heart starts beating around week 6.',
        'maternalBody': 'Morning sickness, heightened sense of smell, fatigue, and frequent urination are common.',
        'nutritionAdvice': 'Eat small, frequent meals with ginger or vitamin B6 rich foods to ease nausea. Avoid raw/undercooked foods.',
      };
    } else if (weeks <= 13) {
      return {
        'title': 'End of First Trimester (Weeks 9–13)',
        'trimester': '1st Trimester',
        'fetalDevelopment': 'The baby is now a fetus! Fingers, toes, and facial features are distinct. Reflexes and vocal cords develop.',
        'maternalBody': 'Nausea may begin to subside towards week 12–13. Uterus is the size of a grapefruit.',
        'nutritionAdvice': 'Ensure adequate calcium (dairy/greens) and iron intake for growing blood volume.',
      };
    } else if (weeks <= 17) {
      return {
        'title': 'Early Second Trimester (Weeks 14–17)',
        'trimester': '2nd Trimester',
        'fetalDevelopment': 'Baby can make facial expressions and suck their thumb. Lanugo (fine hair) covers the body.',
        'maternalBody': 'The "honeymoon phase" often begins with increased energy and a visible pregnancy bump.',
        'nutritionAdvice': 'Increase daily calorie intake by ~300 kcal with protein-rich foods (lentils, eggs, nuts, milk).',
      };
    } else if (weeks <= 22) {
      return {
        'title': 'Mid-Pregnancy & Anomaly Scan (Weeks 18–22)',
        'trimester': '2nd Trimester',
        'fetalDevelopment': 'Baby is hearing sounds from outside the womb! Quickening (first flutter kicks) is often felt.',
        'maternalBody': 'Mild swelling in feet, round ligament aches, and glowing skin are typical.',
        'nutritionAdvice': 'Schedule your 2nd trimester anomaly ultrasound scan with your doctor. Continue iron & calcium tablets.',
      };
    } else if (weeks <= 27) {
      return {
        'title': 'End of Second Trimester (Weeks 23–27)',
        'trimester': '2nd Trimester',
        'fetalDevelopment': 'Lungs develop surfactant. Baby has sleep and wake cycles and responds to your voice.',
        'maternalBody': 'You may experience mild heartburn, Braxton Hicks (practice contractions), and leg cramps.',
        'nutritionAdvice': 'Stay well-hydrated, sleep on your left side to maximize blood flow to the placenta.',
      };
    } else if (weeks <= 32) {
      return {
        'title': 'Early Third Trimester (Weeks 28–32)',
        'trimester': '3rd Trimester',
        'fetalDevelopment': 'Rapid brain growth and weight gain. Baby can open their eyes and sense light.',
        'maternalBody': 'Shortness of breath as the uterus presses against the diaphragm. Increased pelvic pressure.',
        'nutritionAdvice': 'Track fetal movements daily (kick counts: ~10 movements within 2 hours of active rest).',
      };
    } else if (weeks <= 36) {
      return {
        'title': 'Maturing for Birth (Weeks 33–36)',
        'trimester': '3rd Trimester',
        'fetalDevelopment': 'Bones harden (except skull plates). Baby settles into a cephalic (head-down) position.',
        'maternalBody': 'Frequent Braxton Hicks, back pressure, and frequent bathroom trips.',
        'nutritionAdvice': 'Prepare your hospital bag and review birth plan with your doctor and ASHA worker.',
      };
    } else {
      return {
        'title': 'Full Term & Labor Readiness (Weeks 37–40+)',
        'trimester': '3rd Trimester (Full Term)',
        'fetalDevelopment': 'Baby is considered full term! Lungs and digestive system are completely mature.',
        'maternalBody': 'Lightening (baby drops into pelvis). Mucus plug or show may discharge prior to labor.',
        'nutritionAdvice': 'Watch for true labor signs: regular contractions 5 mins apart, rupture of membranes (water breaking).',
      };
    }
  }

  /// Clinical blood pressure guideline explanations
  static Map<String, dynamic> evaluateBloodPressure(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) {
      return {
        'status': 'HYPERTENSIVE',
        'isHigh': true,
        'label': 'Elevated / High Blood Pressure',
        'explanation':
            'A reading of $systolic/$diastolic mmHg is at or above the 140/90 clinical screening threshold for maternal hypertension. During pregnancy, elevated blood pressure requires prompt clinical monitoring to screen for preeclampsia and ensure placental health.',
        'guidance':
            'Please contact your doctor or ASHA worker for a clinical recheck. Watch out for warning symptoms such as severe headaches, vision changes, or upper stomach pain.',
      };
    } else if (systolic >= 120 || diastolic >= 80) {
      return {
        'status': 'PRE_HYPERTENSIVE',
        'isHigh': false,
        'label': 'Borderline / Mildly Elevated Blood Pressure',
        'explanation':
            'A reading of $systolic/$diastolic mmHg is in the pre-hypertensive range. Normal maternal resting BP is usually below 120/80 mmHg.',
        'guidance':
            'Maintain low dietary sodium, stay calm, drink plenty of water, and ensure regular checks at your next prenatal visit.',
      };
    } else {
      return {
        'status': 'NORMAL',
        'isHigh': false,
        'label': 'Normal Maternal Blood Pressure',
        'explanation':
            'Your reading of $systolic/$diastolic mmHg is within the optimal healthy range for maternal and fetal circulation.',
        'guidance':
            'Continue your regular prenatal routine, balanced nutrition, and stay active as advised by your healthcare provider.',
      };
    }
  }

  /// Emergency Red Flag Symptoms & Safe Escalation Protocol
  static const List<Map<String, dynamic>> redFlags = [
    {
      'keywords': ['bleeding', 'vaginal bleeding', 'spotting heavy', 'discharge red', 'blood discharge', 'loss of blood'],
      'title': 'Vaginal Bleeding Warning',
      'message': 'Any active vaginal bleeding during pregnancy requires urgent medical assessment.',
      'action': 'Contact your doctor immediately or proceed to the nearest maternity emergency center.',
    },
    {
      'keywords': ['severe headache', 'blurry vision', 'blurred vision', 'flashing lights', 'spots in eyes'],
      'title': 'Preeclampsia Warning Sign',
      'message': 'Severe headaches with visual disturbances can indicate elevated blood pressure or preeclampsia.',
      'action': 'Seek same-day medical attention and have your blood pressure and urine protein checked.',
    },
    {
      'keywords': ['swelling face', 'sudden swelling', 'swollen hands', 'swollen eyes', 'puffy face'],
      'title': 'Sudden Severe Edema Alert',
      'message': 'Sudden, rapid swelling in the face, eyes, or hands is a key clinical indicator that needs evaluation.',
      'action': 'Notify your doctor or ASHA worker promptly for blood pressure screening.',
    },
    {
      'keywords': ['baby stopped moving', 'no kicks', 'reduced movement', 'less movement', 'fewer kicks'],
      'title': 'Fetal Movement Concern',
      'message': 'A noticeable decrease or cessation in baby movements after 24 weeks requires immediate monitoring.',
      'action': 'Drink cold water, lie on your left side for 1 hour. If you feel fewer than 4-5 kicks, go to the maternity center for a fetal heart rate check.',
    },
    {
      'keywords': ['severe abdominal pain', 'stomach pain severe', 'sharp pain right side', 'epigastric pain'],
      'title': 'Severe Abdominal Pain Alert',
      'message': 'Sharp or persistent upper right abdominal pain can indicate liver/placental involvement.',
      'action': 'Seek urgent clinical evaluation at your healthcare facility.',
    },
    {
      'keywords': ['high fever', 'chills', 'fever over 38', 'shivering with fever'],
      'title': 'Maternal Fever Alert',
      'message': 'Maternal body temperatures above 38°C (100.4°F) can affect fetal development and require diagnosis.',
      'action': 'Consult your doctor promptly to identify and safely treat the underlying infection.',
    },
    {
      'keywords': ['water broke', 'leaking fluid', 'amniotic fluid', 'gush of water'],
      'title': 'Possible Rupture of Membranes',
      'message': 'A continuous trickle or sudden gush of clear fluid indicates your water may have broken.',
      'action': 'Note the color and time, avoid inserting anything into the vagina, and head to your delivery hospital.',
    },
  ];
}
