import 'dart:math';
import '../domain/models/ai_screening_warning.dart';
import '../domain/models/ai_source_reference.dart';
import '../domain/models/patient_ai_context.dart';
import '../domain/models/patient_ai_message.dart';
import 'curated_maternal_knowledge_base.dart';

enum QueryIntent {
  pregnancyProgress,
  vitalsExplanation,
  screeningWarning,
  homeVisitsSummary,
  doctorPreparation,
  maternalEducation,
  emergencyRedFlag,
  unsupportedGeneral,
}

class PatientAiEngine {
  /// Evaluates user text and returns grounded, safe structured response
  PatientAiMessage processQuery({
    required String userQuery,
    required PatientAiContext context,
  }) {
    final queryLower = userQuery.toLowerCase().trim();
    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    // 1. Safety Triage: Check for Emergency Red Flags
    final redFlag = _detectRedFlag(queryLower);
    if (redFlag != null) {
      return _generateEmergencyResponse(messageId, redFlag);
    }

    // 2. Classify User Intent
    final intent = _classifyIntent(queryLower);

    // 3. Generate Grounded Response Based on Intent & Authenticated Data
    switch (intent) {
      case QueryIntent.pregnancyProgress:
        return _handlePregnancyProgress(messageId, queryLower, context);

      case QueryIntent.vitalsExplanation:
        return _handleVitalsExplanation(messageId, queryLower, context);

      case QueryIntent.screeningWarning:
        return _handleScreeningWarning(messageId, queryLower, context);

      case QueryIntent.homeVisitsSummary:
        return _handleHomeVisitsSummary(messageId, queryLower, context);

      case QueryIntent.doctorPreparation:
        return _handleDoctorPreparation(messageId, queryLower, context);

      case QueryIntent.maternalEducation:
        return _handleMaternalEducation(messageId, queryLower, context);

      case QueryIntent.emergencyRedFlag:
        // Already handled above
        return _handleMaternalEducation(messageId, queryLower, context);

      case QueryIntent.unsupportedGeneral:
        return _handleUnsupportedQuery(messageId, userQuery, context);
    }
  }

  /// Emergency red flag detection scanner
  Map<String, dynamic>? _detectRedFlag(String query) {
    for (final flag in CuratedMaternalKnowledgeBase.redFlags) {
      final keywords = flag['keywords'] as List<String>;
      if (keywords.any((kw) => query.contains(kw))) {
        return flag;
      }
    }
    return null;
  }

  /// Emergency response generator
  PatientAiMessage _generateEmergencyResponse(String id, Map<String, dynamic> flag) {
    final title = flag['title'] as String;
    final message = flag['message'] as String;
    final action = flag['action'] as String;

    final responseText = '''
🚨 **URGENT CLINICAL ATTENTION RECOMMENDED**

**$title**
$message

**Recommended Immediate Action:**
$action

> PitPulse AI is strictly an informational assistant and cannot provide emergency diagnosis. Please reach out to your maternity center or call your local emergency medical service immediately.
''';

    return PatientAiMessage(
      id: id,
      text: responseText,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      warning: AiScreeningWarning(
        severity: WarningSeverity.emergency,
        title: title,
        message: message,
        clinicalBasis: 'Urgent obstetrical screening rule',
        recommendedAction: action,
      ),
      sources: const [
        AiSourceReference(
          type: AiSourceType.clinicalScreeningRule,
          title: 'Emergency Triage Protocol',
          detail: 'World Health Organization (WHO) & MoHFW Antenatal Danger Signs',
        ),
      ],
      suggestedQuestions: const [
        'What should I bring to the emergency maternity center?',
        'Who is my assigned ASHA contact?',
      ],
    );
  }

  /// Classifies user input into domain intents with English & Tamil bilingual NLU
  QueryIntent _classifyIntent(String q) {
    if (q.contains('doctor') || q.contains('ask') || q.contains('consult') || q.contains('மருத்துவர்') || q.contains('டாக்டர்')) {
      return QueryIntent.doctorPreparation;
    }
    if (q.contains('food') || q.contains('diet') || q.contains('eat') || q.contains('nutrition') || q.contains('nausea') || q.contains('vomit') || q.contains('morning sickness') || q.contains('exercise') || q.contains('sleep') || q.contains('iron') || q.contains('folic') || q.contains('calcium') || q.contains('supplement') || q.contains('water') || q.contains('cramp') || q.contains('heartburn') || q.contains('உணவு') || q.contains('சாப்பிடு') || q.contains('வாந்தி') || q.contains('மயக்கம்') || q.contains('இரும்பு') || q.contains('போலிக்')) {
      return QueryIntent.maternalEducation;
    }
    if (q.contains('bp') || q.contains('blood pressure') || q.contains('vital') || q.contains('pulse') || q.contains('heart rate') || q.contains('temperature') || q.contains('weight') || q.contains('fever') || q.contains('பிபி') || q.contains('இரத்த அழுத்தம்') || q.contains('காய்ச்சல்')) {
      return QueryIntent.vitalsExplanation;
    }
    if (q.contains('alert') || q.contains('screen') || q.contains('high risk') || q.contains('danger') || q.contains('warn') || q.contains('அபாயம்') || q.contains('எச்சரிக்கை')) {
      return QueryIntent.screeningWarning;
    }
    if (q.contains('asha') || q.contains('home visit') || q.contains('worker') || q.contains('checkup') || q.contains('last visit') || q.contains('ஆஷா') || q.contains('வீட்டு வருகை')) {
      return QueryIntent.homeVisitsSummary;
    }
    if (q.contains('week') || q.contains('due date') || q.contains('edd') || q.contains('trimester') || q.contains('gestat') || q.contains('baby') || q.contains('baby grow') || q.contains('fetus') || q.contains('how far') || q.contains('lmp') || q.contains('how big') || q.contains('pregnancy') || q.contains('மாதம்') || q.contains('வாரம்') || q.contains('குழந்தை')) {
      return QueryIntent.pregnancyProgress;
    }
    return QueryIntent.unsupportedGeneral;
  }


  /// 1. Pregnancy Progress Handler
  PatientAiMessage _handlePregnancyProgress(String id, String query, PatientAiContext ctx) {
    if (!ctx.hasActivePregnancy) {
      return PatientAiMessage(
        id: id,
        text: 'You do not have an active pregnancy record registered in your account yet. You can register your pregnancy from your Health Dashboard by entering your Last Menstrual Period (LMP) date to automatically calculate your gestational age and Estimated Due Date (EDD).',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestedQuestions: const [
          'How do I register my pregnancy?',
          'What is LMP and EDD?',
        ],
      );
    }

    final preg = ctx.activePregnancy!;
    final weeks = preg.gestationalAgeWeeks;
    final trimester = preg.trimesterDisplay;
    final eddStr = '${preg.edd.day}/${preg.edd.month}/${preg.edd.year}';
    final lmpStr = '${preg.lmp.day}/${preg.lmp.month}/${preg.lmp.year}';
    final milestone = CuratedMaternalKnowledgeBase.getGestationalMilestone(weeks);

    final responseText = '''
🤰 **Your Pregnancy Journey & Progress**

- **Current Gestational Age:** ${preg.gestationalAgeDisplay} ($trimester)
- **Estimated Due Date (EDD):** $eddStr
- **Last Menstrual Period (LMP):** $lmpStr

**👶 Baby Development (${milestone['title']}):**
${milestone['fetalDevelopment']}

**🌸 Maternal Body & Wellness:**
${milestone['maternalBody']}

**🥗 Recommended Nutrition:**
${milestone['nutritionAdvice']}
''';

    return PatientAiMessage(
      id: id,
      text: responseText,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      sources: [
        AiSourceReference(
          type: AiSourceType.pregnancyRecord,
          title: 'Active Pregnancy Record (#${preg.pregnancyNumber})',
          detail: 'LMP: $lmpStr • Calculated EDD: $eddStr • GA: ${preg.gestationalAgeDisplay}',
        ),
        AiSourceReference(
          type: AiSourceType.curatedKnowledgeBase,
          title: 'Maternal Health Guidelines',
          detail: 'Gestational milestones for Week $weeks',
        ),
      ],
      suggestedQuestions: [
        'What questions should I ask my doctor for Week $weeks?',
        'Explain my latest blood pressure and vitals',
        'What foods should I eat during the $trimester?',
      ],
    );
  }

  /// 2. Vitals Explanation Handler
  PatientAiMessage _handleVitalsExplanation(String id, String query, PatientAiContext ctx) {
    if (!ctx.hasVitals) {
      return PatientAiMessage(
        id: id,
        text: 'No vital signs have been recorded in your profile yet. When your assigned ASHA worker conducts a home visit or when you attend a clinical checkup, your Blood Pressure, Weight, and Temperature will be logged here.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestedQuestions: const [
          'Who is my assigned ASHA worker?',
          'What is normal blood pressure in pregnancy?',
        ],
      );
    }

    final latest = ctx.latestVitals!;
    final recordedDate = '${latest.recordedAt.day}/${latest.recordedAt.month}/${latest.recordedAt.year}';
    AiScreeningWarning? warning;

    String bpAnalysis = 'No Blood Pressure recorded in the latest entry.';
    if (latest.hasBp) {
      final eval = CuratedMaternalKnowledgeBase.evaluateBloodPressure(latest.systolicBp!, latest.diastolicBp!);
      final isHigh = eval['isHigh'] as bool;
      bpAnalysis = '''
- **Blood Pressure:** ${latest.bpDisplay} (${eval['label']})
  ${eval['explanation']}
  *Action:* ${eval['guidance']}
''';

      if (isHigh) {
        warning = AiScreeningWarning(
          severity: WarningSeverity.caution,
          title: 'Elevated Blood Pressure Alert',
          message: 'Your recorded BP (${latest.bpDisplay}) is at or above the 140/90 threshold.',
          clinicalBasis: 'ACOG / WHO Antenatal Hypertensive Screening Criteria',
          recommendedAction: 'Contact your doctor or ASHA worker for clinical verification and monitoring.',
        );
      }
    }

    String weightAnalysis = latest.weightKg != null ? '- **Weight:** ${latest.weightDisplay}' : '';
    String tempAnalysis = latest.temperatureC != null ? '- **Body Temperature:** ${latest.temperatureDisplay}' : '';

    final responseText = '''
🩺 **Your Latest Recorded Vitals Summary**
*Recorded on: $recordedDate by ${latest.recordedByName} (${latest.recordedByRole})*

$bpAnalysis
$weightAnalysis
$tempAnalysis
${latest.notes != null && latest.notes!.isNotEmpty ? '\n*Clinical Note:* "${latest.notes}"' : ''}
''';

    return PatientAiMessage(
      id: id,
      text: responseText,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      warning: warning,
      sources: [
        AiSourceReference(
          type: AiSourceType.maternalVitals,
          title: 'Vital Sign Log ($recordedDate)',
          detail: 'BP: ${latest.bpDisplay}, Weight: ${latest.weightDisplay}, Temp: ${latest.temperatureDisplay}',
        ),
        AiSourceReference(
          type: AiSourceType.clinicalScreeningRule,
          title: 'Obstetrical Vitals Standards',
          detail: 'WHO Maternal Vitals Normal vs Hypertensive Ranges',
        ),
      ],
      suggestedQuestions: const [
        'What is considered high blood pressure in pregnancy?',
        'How can I prepare questions for my doctor about my vitals?',
        'How often should my ASHA worker check my vitals?',
      ],
    );
  }

  /// 3. Screening Warning Handler
  PatientAiMessage _handleScreeningWarning(String id, String query, PatientAiContext ctx) {
    if (ctx.hasVitals && ctx.latestVitals!.hasBp) {
      final latest = ctx.latestVitals!;
      final eval = CuratedMaternalKnowledgeBase.evaluateBloodPressure(latest.systolicBp!, latest.diastolicBp!);
      final isHigh = eval['isHigh'] as bool;

      if (isHigh) {
        return PatientAiMessage(
          id: id,
          text: '''
⚠️ **Screening Rule Analysis: Blood Pressure**

Your recent blood pressure observation was **${latest.bpDisplay}**.

**Why is this flagged?**
In prenatal care, blood pressure ≥ 140 mmHg systolic or ≥ 90 mmHg diastolic is screened to detect gestational hypertension or early preeclampsia.

**Clinical Recommendations:**
1. Avoid excess salt, stress, and strenuous exertion.
2. Rest on your left side to maximize placental blood flow.
3. Have your blood pressure re-checked within 24–48 hours by your healthcare provider.
4. Watch for danger symptoms: severe headaches, blurred vision, sudden facial swelling, or upper belly pain.
''',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          warning: AiScreeningWarning(
            severity: WarningSeverity.caution,
            title: 'Hypertension Screening Flag',
            message: 'Blood pressure exceeds standard 140/90 baseline.',
            clinicalBasis: 'WHO Maternal Health Guidelines',
            recommendedAction: 'Schedule follow-up check with Doctor / ASHA worker.',
          ),
          sources: [
            AiSourceReference(
              type: AiSourceType.clinicalScreeningRule,
              title: 'Maternal Hypertension Screening Rule',
              detail: 'Systolic >= 140 or Diastolic >= 90 mmHg',
            ),
          ],
          suggestedQuestions: const [
            'What should I ask my doctor about my blood pressure?',
            'What are the symptoms of preeclampsia?',
          ],
        );
      }
    }

    return PatientAiMessage(
      id: id,
      text: '''
✅ **Screening & Risk Status: Normal**

Based on your active records in PitPulse, there are currently no high-risk screening flags triggered.

- **Vitals Status:** ${ctx.hasVitals ? 'All latest parameters within expected ranges.' : 'No recent vitals logged.'}
- **Pregnancy Status:** ${ctx.hasActivePregnancy ? 'Active gestational tracking (${ctx.activePregnancy!.gestationalAgeDisplay}).' : 'No active pregnancy registered.'}

Continue your scheduled antenatal visits and immediately report any unexpected symptoms (bleeding, sudden swelling, or severe headaches) to your doctor.
''',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      sources: const [
        AiSourceReference(
          type: AiSourceType.clinicalScreeningRule,
          title: 'Maternal Screening Thresholds',
          detail: 'Automated clinical threshold validation against active records',
        ),
      ],
      suggestedQuestions: const [
        'How is my baby growing this week?',
        'What should I ask my doctor at my next visit?',
      ],
    );
  }

  /// 4. Home Visits Summary Handler
  PatientAiMessage _handleHomeVisitsSummary(String id, String query, PatientAiContext ctx) {
    if (!ctx.hasHomeVisits) {
      final ashaName = ctx.assignedAshaName ?? 'an ASHA worker';
      return PatientAiMessage(
        id: id,
        text: 'You have no home visit records logged yet. Once $ashaName conducts a field visit in your locality, the visit notes, checkup purpose, and follow-up guidance will appear here.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestedQuestions: const [
          'What is the role of an ASHA worker?',
          'How do I contact my healthcare provider?',
        ],
      );
    }

    final latest = ctx.latestHomeVisit!;
    final visitDate = '${latest.visitDate.day}/${latest.visitDate.month}/${latest.visitDate.year}';

    final responseText = '''
🏡 **ASHA Field Care Summary**
*Total Home Visits Recorded: ${ctx.homeVisits.length}*

**Latest Visit Details ($visitDate):**
- **ASHA Worker:** ${latest.ashaWorkerName}
- **Purpose:** ${latest.purpose}
- **Status:** ${latest.status}
${latest.observations != null && latest.observations!.isNotEmpty ? '- **Observations:** ${latest.observations}\n' : ''}${latest.notes != null && latest.notes!.isNotEmpty ? '- **Notes:** ${latest.notes}\n' : ''}${latest.followUpRequired ? '- **Follow-up:** ⚠️ ${latest.followUpNotes ?? 'Clinical follow-up required'}\n' : ''}
''';

    return PatientAiMessage(
      id: id,
      text: responseText,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      sources: [
        AiSourceReference(
          type: AiSourceType.ashaHomeVisit,
          title: 'ASHA Home Visit Record ($visitDate)',
          detail: 'Conducted by ${latest.ashaWorkerName} • Purpose: ${latest.purpose}',
        ),
      ],
      suggestedQuestions: const [
        'Explain my recorded vitals from this visit',
        'What questions should I ask my doctor?',
      ],
    );
  }

  /// 5. Doctor Preparation Handler
  PatientAiMessage _handleDoctorPreparation(String id, String query, PatientAiContext ctx) {
    final weeks = ctx.hasActivePregnancy ? ctx.activePregnancy!.gestationalAgeWeeks : 0;
    final questions = <String>[];

    if (weeks <= 13) {
      questions.addAll([
        'Is my early ultrasound and dating scan on schedule?',
        'Which prenatal vitamins and folic acid dosage should I take?',
        'How can I safely manage my morning sickness and fatigue?',
        'Are there any blood tests (hemoglobin, blood group, thyroid) I need now?',
      ]);
    } else if (weeks <= 27) {
      questions.addAll([
        'When is my 2nd trimester anomaly ultrasound scan scheduled?',
        'Is my maternal weight gain on track for my gestational age?',
        'Should I undergo the oral glucose screening test for gestational diabetes?',
        'What normal fetal movement patterns should I expect to feel?',
      ]);
    } else {
      questions.addAll([
        'Is the baby in a head-down (cephalic) presentation?',
        'What are the specific signs that indicate I am in early labor?',
        'What is our birth plan and when should I head to the hospital?',
        'How often should I count baby kicks every day?',
      ]);
    }

    if (ctx.hasVitals && ctx.latestVitals!.hasBp && ctx.latestVitals!.systolicBp! >= 130) {
      questions.insert(0, 'My recent blood pressure was ${ctx.latestVitals!.bpDisplay} — do we need more frequent monitoring or blood tests?');
    }

    final questionsText = questions.map((q) => '• "$q"').join('\n');

    final responseText = '''
📋 **Doctor Consultation Preparation Guide**
*Customized for your current stage (${ctx.hasActivePregnancy ? ctx.activePregnancy!.gestationalAgeDisplay : 'Prenatal Care'})*

Here are recommended questions to discuss with your obstetrician / doctor at your next appointment:

$questionsText

💡 **Tip:** Mention your latest recorded vitals (${ctx.hasVitals ? ctx.latestVitals!.bpDisplay : 'None recorded'}) and any new physical symptoms you have observed.
''';

    return PatientAiMessage(
      id: id,
      text: responseText,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      sources: [
        if (ctx.hasActivePregnancy)
          AiSourceReference(
            type: AiSourceType.pregnancyRecord,
            title: 'Active Gestational Stage',
            detail: 'Week $weeks (${ctx.activePregnancy!.trimesterDisplay})',
          ),
        AiSourceReference(
          type: AiSourceType.curatedKnowledgeBase,
          title: 'Clinical Consultation Guide',
          detail: 'Recommended WHO/ACOG Prenatal Discussion Points',
        ),
      ],
      suggestedQuestions: [
        'How is my baby growing in Week $weeks?',
        'Explain my latest vitals',
      ],
    );
  }

  /// 6. Maternal Health Education Handler
  PatientAiMessage _handleMaternalEducation(String id, String query, PatientAiContext ctx) {
    String topicTitle = 'Maternal Health & Wellness';
    String content = '';

    if (query.contains('food') || query.contains('diet') || query.contains('eat') || query.contains('nutrition')) {
      topicTitle = 'Healthy Nutrition During Pregnancy';
      content = '''
**Recommended Foods:**
- **Proteins:** Eggs, lentils (dal), paneer, tofu, well-cooked lean poultry, and nuts for tissue growth.
- **Iron-Rich Foods:** Spinach, jaggery, beetroot, fortified grains to support expanding maternal blood volume.
- **Calcium:** Milk, yogurt, dark leafy greens for fetal bone and tooth development.
- **Hydration:** Drink 8–10 glasses of water daily to maintain amniotic fluid and prevent urinary infections.

**Foods to Strictly Avoid:**
- Raw or undercooked meat, unpasteurized milk/cheese, raw sprouts, unwashed produce, and high-mercury fish.
- Excess caffeine (> 200mg/day) and all alcohol or tobacco products.
''';
    } else if (query.contains('nausea') || query.contains('vomit') || query.contains('morning sickness')) {
      topicTitle = 'Managing Morning Sickness & Nausea';
      content = '''
**Comfort Remedies:**
- Eat small, frequent meals rather than large meals.
- Keep plain crackers or dry toast by your bedside and eat a few before getting up.
- Drink ginger tea or water with fresh lemon slices.
- Avoid greasy, spicy, or strongly scented foods.
- If vomiting prevents you from keeping fluids down for over 24 hours, consult your doctor to prevent dehydration.
''';
    } else if (query.contains('iron') || query.contains('folic') || query.contains('supplement') || query.contains('calcium')) {
      topicTitle = 'Prenatal Supplementation Guidelines';
      content = '''
**Standard Maternal Supplements:**
- **Folic Acid (400 mcg daily):** Crucial during the first trimester for neural tube and brain development.
- **Iron Tablets:** Recommended from 2nd trimester to prevent maternal anemia and low birth weight. Take with vitamin C (orange/lemon juice) for better absorption; avoid taking with calcium/milk simultaneously.
- **Calcium & Vitamin D:** Supports baby's skeletal mineralization.
''';
    } else {
      topicTitle = 'General Maternal Health Guidelines';
      content = '''
**Core Healthy Pregnancy Habits:**
1. **Sleep Position:** From the 2nd trimester onwards, sleep on your left side to optimize blood and nutrient flow to the placenta.
2. **Light Physical Activity:** 20–30 minutes of daily walking or prenatal yoga (unless contraindicated by your doctor).
3. **Regular Prenatal Visits:** Attend all scheduled doctor appointments and ASHA checkups.
4. **Mental Wellness:** Practice calm breathing exercises and rest whenever you feel fatigued.
''';
    }

    final responseText = '''
📚 **$topicTitle**

$content

> Always follow the specific clinical diet and supplement plan prescribed by your doctor.
''';

    return PatientAiMessage(
      id: id,
      text: responseText,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      sources: const [
        AiSourceReference(
          type: AiSourceType.curatedKnowledgeBase,
          title: 'Evidence-Based Maternal Health Guidelines',
          detail: 'Standard Clinical Antenatal Nutrition & Lifestyle Protocols',
        ),
      ],
      suggestedQuestions: const [
        'How is my baby developing this week?',
        'What questions should I ask my doctor?',
      ],
    );
  }

  /// 7. Unsupported / Out-of-Scope Handler
  PatientAiMessage _handleUnsupportedQuery(String id, String userQuery, PatientAiContext ctx) {
    return PatientAiMessage(
      id: id,
      text: '''
I understand your question, but as a specialized **maternal health and pregnancy assistant**, I can only safely provide guidance regarding:

1. 🤰 **Your actual pregnancy progress**, gestational week, and EDD.
2. 🩺 **Your recorded vitals** (Blood Pressure, Weight, Temperature) and screening rules.
3. 🏡 **Your ASHA worker home visits** and care history.
4. 📋 **Preparing questions** for your doctor consultation.
5. 🥗 **Evidence-based pregnancy wellness**, nutrition, and warning sign education.

I cannot diagnose medical conditions, prescribe medications, or answer non-healthcare queries.

Please consult your healthcare provider or obstetrician for direct clinical decisions.
''',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      suggestedQuestions: const [
        'How is my baby growing this week?',
        'Explain my recorded vitals',
        'What should I ask my doctor?',
      ],
    );
  }
}
