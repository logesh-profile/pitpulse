import 'dart:math';
import '../domain/models/ai_screening_warning.dart';
import '../domain/models/ai_source_reference.dart';
import '../domain/models/patient_ai_context.dart';
import '../domain/models/patient_ai_message.dart';
import 'curated_maternal_knowledge_base.dart';
import 'local_agentic_rag_controller.dart';

class PatientAiEngine {
  /// Evaluates user text and returns grounded, safe structured response using the Agentic RAG Controller
  PatientAiMessage processQuery({
    required String userQuery,
    required PatientAiContext context,
  }) {
    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final weeks = context.hasActivePregnancy ? context.activePregnancy!.gestationalAgeWeeks : 12;

    // Execute Three-Layer Agentic RAG Evaluation
    final agentState = LocalAgenticRagController.evaluate(
      rawText: userQuery,
      gestationalWeeks: weeks,
    );

    final isTa = agentState.language == 'ta';

    final qLower = userQuery.toLowerCase().trim();

    // 1. Layer 1 Safety Override OR Emergency Alert OR Layer 2 Chitchat
    final isLayer1OrLayer2 = agentState.synthesizedResponse == 'I cannot answer that.' ||
        agentState.synthesizedResponse == 'என்னால் அதற்குப் பதிலளிக்க முடியாது.' ||
        agentState.primaryIntentId >= 10;

    if (agentState.isEmergency || isLayer1OrLayer2) {
      return PatientAiMessage(
        id: messageId,
        text: agentState.synthesizedResponse,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isTamil: isTa,
        warning: agentState.isEmergency
            ? AiScreeningWarning(
                severity: WarningSeverity.emergency,
                title: isTa ? 'அவசர மருத்துவ எச்சரிக்கை' : 'Emergency Red Flag Alert',
                message: isTa
                    ? 'கர்ப்ப காலத்தில் இந்த அறிகுறி தோன்றினால் உடனடியாக மருத்துவ ஆலோசனை பெற வேண்டும்.'
                    : 'This symptom requires immediate emergency obstetrical assessment.',
                clinicalBasis: 'WHO / MoHFW Antenatal Danger Signs Protocol',
                recommendedAction: isTa
                    ? 'உடனடியாக 108 அழைக்கவும் அல்லது மருத்துவமனைக்கு செல்லவும்.'
                    : 'Call 108 immediately or proceed to the nearest PHC / Hospital.',
              )
            : null,
        sources: [
          AiSourceReference(
            type: AiSourceType.curatedKnowledgeBase,
            title: isTa ? 'உள்ளூர் தாய்-சேய் சுகாதார களஞ்சியம்' : 'Local Maternal Knowledge Matrix',
            detail: isTa ? 'தமிழ்நாடு பொது சுகாதார வழிகாட்டி' : 'TN Health Dept & WHO Clinical Protocols',
          ),
        ],
        suggestedQuestions: isTa
            ? [
                '3வது மாத கர்ப்ப கால உணவு முறை',
                'வெள்ளனூர் ஆஷா பணியாளர் யார்?',
                'டாக்டரிடம் கேட்க வேண்டிய கேள்விகள்',
              ]
            : [
                'I am 3 months pregnant, what should I eat?',
                'Who is the ASHA worker for Vellanur?',
                'What questions should I ask my doctor?',
              ],
      );
    }

    // 2. Personalized Context Handlers (Doctor Prep, Home Visits, Vitals, Milestones)
    if (qLower.contains('doctor') || qLower.contains('consult') || qLower.contains('மருத்துவர்') || qLower.contains('டாக்டர்')) {
      return _handleDoctorPreparation(messageId, qLower, context, isTa: isTa);
    }
    if (qLower.contains('visit') || qLower.contains('history') || qLower.contains('checkup') || qLower.contains('வீட்டு வருகை')) {
      return _handleHomeVisitsSummary(messageId, qLower, context, isTa: isTa);
    }
    if (qLower.contains('bp') || qLower.contains('blood pressure') || qLower.contains('vital') || qLower.contains('pulse') || qLower.contains('இரத்த அழுத்தம்')) {
      return _handleVitalsExplanation(messageId, qLower, context, isTa: isTa);
    }
    if (qLower.contains('growth') || qLower.contains('progress') || qLower.contains('edd') || qLower.contains('due date') || qLower.contains('வளர்ச்சி') || (qLower.contains('week') && !qLower.contains('eat') && !qLower.contains('diet'))) {
      return _handlePregnancyProgress(messageId, qLower, context, isTa: isTa);
    }
    if (qLower.contains('alert') || qLower.contains('danger') || qLower.contains('warning') || qLower.contains('எச்சரிக்கை')) {
      return _handleScreeningWarning(messageId, qLower, context);
    }

    // 3. Agentic RAG Multi-Tool Response (Diet, ASHA Directory, General Care)
    return PatientAiMessage(
      id: messageId,
      text: agentState.synthesizedResponse,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isTamil: isTa,
      sources: const [
        AiSourceReference(
          type: AiSourceType.curatedKnowledgeBase,
          title: 'Local Maternal Knowledge Matrix',
          detail: 'Tamil Nadu Health Dept & WHO Clinical Protocols',
        ),
      ],
      suggestedQuestions: isTa
          ? [
              '3வது மாத கர்ப்ப கால உணவு முறை',
              'வெள்ளனூர் ஆஷா பணியாளர் யார்?',
              'டாக்டரிடம் கேட்க வேண்டிய கேள்விகள்',
            ]
          : [
              'I am 3 months pregnant, what should I eat?',
              'Who is the ASHA worker for Vellanur?',
              'What questions should I ask my doctor?',
            ],
    );
  }

  /// 1. Pregnancy Progress Handler
  PatientAiMessage _handlePregnancyProgress(String id, String query, PatientAiContext ctx, {bool isTa = false}) {
    if (!ctx.hasActivePregnancy) {
      return PatientAiMessage(
        id: id,
        text: isTa
            ? 'உங்கள் கணக்கில் இன்னும் கர்ப்ப பதிவு சேர்க்கப்படவில்லை. உங்கள் கடைசி மாதவிடாய் (LMP) தேதியை உள்ளிட்டு எளிதாக கர்ப்ப பதிவை தொடங்கலாம்.'
            : 'You do not have an active pregnancy record registered in your account yet. You can register your pregnancy from your Health Dashboard by entering your Last Menstrual Period (LMP) date to automatically calculate your gestational age and Estimated Due Date (EDD).',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isTamil: isTa,
        suggestedQuestions: isTa
            ? ['கர்ப்பத்தை எவ்வாறு பதிவு செய்வது?', 'LMP மற்றும் EDD என்றால் என்ன?']
            : [
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
      isTamil: isTa,
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
  PatientAiMessage _handleVitalsExplanation(String id, String query, PatientAiContext ctx, {bool isTa = false}) {
    if (!ctx.hasVitals) {
      return PatientAiMessage(
        id: id,
        text: isTa
            ? 'உங்கள் கணக்கில் இன்னும் முக்கிய உடல் குறிகாட்டிகள் (Vitals) பதிவு செய்யப்படவில்லை. உங்கள் ஆஷா பணியாளர் அல்லது மருத்துவர் பரிசோதிக்கும் போது இரத்த அழுத்தம், எடை ஆகியவை இங்கு காண்பிக்கப்படும்.'
            : 'No vital signs have been recorded in your profile yet. When your assigned ASHA worker conducts a home visit or when you attend a clinical checkup, your Blood Pressure, Weight, and Temperature will be logged here.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isTamil: isTa,
        suggestedQuestions: isTa
            ? ['எனக்கு நியமிக்கப்பட்ட ஆஷா பணியாளர் யார்?', 'கர்ப்ப காலத்தில் இயல்பான இரத்த அழுத்தம் என்ன?']
            : [
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
          title: isTa ? 'உயர் இரத்த அழுத்த எச்சரிக்கை' : 'Elevated Blood Pressure Alert',
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
      isTamil: isTa,
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
  PatientAiMessage _handleHomeVisitsSummary(String id, String query, PatientAiContext ctx, {bool isTa = false}) {
    if (!ctx.hasHomeVisits) {
      final ashaName = ctx.assignedAshaName ?? 'an ASHA worker';
      return PatientAiMessage(
        id: id,
        text: isTa
            ? 'உங்கள் கணக்கில் ஆஷா பணியாளர் வீட்டு வருகை பதிவுகள் எதுவும் இன்னும் இல்லை. $ashaName உங்கள் பகுதிக்கு வந்து பரிசோதித்ததும் விவரங்கள் இங்கு தோன்றும்.'
            : 'You have no home visit records logged yet. Once $ashaName conducts a field visit in your locality, the visit notes, checkup purpose, and follow-up guidance will appear here.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isTamil: isTa,
        suggestedQuestions: isTa
            ? ['ஆஷா பணியாளரின் பணி என்ன?', 'மருத்துவரை எவ்வாறு தொடர்பு கொள்வது?']
            : [
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
      isTamil: isTa,
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
  PatientAiMessage _handleDoctorPreparation(String id, String query, PatientAiContext ctx, {bool isTa = false}) {
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
      isTamil: isTa,
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
}
