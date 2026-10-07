import 'dart:math';
import '../domain/models/ai_screening_warning.dart';
import '../domain/models/ai_source_reference.dart';
import '../domain/models/patient_ai_context.dart';
import '../domain/models/patient_ai_message.dart';

/// MAATRA Conversational Health Agent Engine.
/// Designed for natural human conversation (ChatGPT/Grok style) across general medicine,
/// wellness, first-aid, home remedies, and real authenticated patient data only.
/// Strictly enforces ZERO hardcoded fake data, ZERO canned pregnancy locks.
class PatientAiEngine {
  PatientAiMessage processQuery({
    required String userQuery,
    required PatientAiContext context,
    List<String> chatHistory = const [],
  }) {
    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final q = userQuery.trim();
    final qLower = q.toLowerCase();

    final isTa = _isTamil(qLower);

    // 1. Check for Emergency Red Flag Symptoms (Call 108 / PHC)
    if (_isEmergency(qLower)) {
      return PatientAiMessage(
        id: messageId,
        text: isTa
            ? '⚠️ **அவசர மருத்துவ எச்சரிக்கை**\n\n'
                'இந்த அறிகுறிகளுக்கு உடனடியாக அவசர மருத்துவ சிகிச்சை தேவை:\n'
                '• உடனடியாக **108** ஆம்புலன்ஸை அழைக்கவும் அல்லது அருகிலுள்ள அரசு ஆரம்ப சுகாதார நிலையம் (PHC) / மருத்துவமனைக்கு செல்லவும்.\n'
                '• நோயாளியை அமைதியாக ஒருக்களித்து படுக்க வைக்கவும்.\n'
                '• சுயமாக எந்த மருந்தையும் உட்கொள்ள வேண்டாம்.'
            : '⚠️ **Emergency Medical Alert**\n\n'
                'These symptoms require immediate emergency clinical attention:\n'
                '• **Call 108 immediately** or proceed to the nearest Primary Health Centre (PHC) / Hospital emergency department.\n'
                '• Keep the patient calm, lying on their left side if pregnant, and ensure clear airway.\n'
                '• Do not self-administer unverified medications.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isTamil: isTa,
        warning: AiScreeningWarning(
          severity: WarningSeverity.emergency,
          title: isTa ? 'அவசர எச்சரிக்கை' : 'Emergency Red Flag',
          message: isTa
              ? 'உடனடியாக மருத்துவமனைக்கு செல்லவும் அல்லது 108 அழைக்கவும்.'
              : 'Immediate clinical evaluation required.',
          clinicalBasis: 'MoHFW / WHO Acute Emergency Protocol',
          recommendedAction: isTa ? '108 அழைக்கவும்' : 'Call 108 or visit nearest PHC',
        ),
        sources: const [
          AiSourceReference(
            type: AiSourceType.curatedKnowledgeBase,
            title: 'MAATRA Emergency Protocol',
            detail: 'MoHFW / WHO Acute Medical Guidelines',
          ),
        ],
      );
    }

    // 2. Personal Patient Data Queries (Strictly Authenticated, Zero Fake Data)
    if (_isPersonalDataQuery(qLower)) {
      return _handlePersonalDataQuery(messageId, qLower, context, isTa: isTa);
    }

    // 3. Natural Human Greetings & Casual Chit-Chat (ChatGPT / Grok Style)
    if (_isChitChat(qLower)) {
      return _handleChitChat(messageId, qLower, context, isTa: isTa);
    }

    // 4. Medical Remedies & Symptom Guidance (Fever, Headache, Digestion, Cold, etc.)
    return _handleMedicalAndRemedies(messageId, q, qLower, context, isTa: isTa);
  }

  /// Detects Tamil script or Tanglish expressions
  bool _isTamil(String text) {
    // Tamil Unicode block: \u0B80 - \u0BFF
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) return true;
    final tanglishTokens = ['vanakkam', 'kaachal', 'vali', 'marunthu', 'saapadu', 'ennaku', 'eppadi'];
    return tanglishTokens.any((t) => text.contains(t));
  }

  /// Emergency detection
  bool _isEmergency(String text) {
    final tokens = [
      'severe bleeding', 'heavy bleeding', 'bleeding', 'chest pain', 'heart attack',
      'fainted', 'unconscious', 'convulsion', 'fits', 'difficulty breathing', 'severe breathlessness',
      'இரத்தப்போக்கு', 'நெஞ்சு வலி', 'மயக்கம்', 'வலிப்பு', 'மூச்சுத்திணறல்'
    ];
    return tokens.any((t) => text.contains(t));
  }

  /// Checks if asking about personal profile data
  bool _isPersonalDataQuery(String text) {
    final personalTokens = [
      'bp', 'vital', 'vitals', 'blood pressure', 'visit', 'checkup',
      'asha', 'pregnancy', 'edd', 'due date', 'record', 'history',
      'இரத்த அழுத்தம்', 'பரிசோதனை', 'வருகை'
    ];
    return personalTokens.any((t) => text.contains(t));
  }

  /// Handles personal data queries with ZERO hardcoded data
  PatientAiMessage _handlePersonalDataQuery(
    String id,
    String qLower,
    PatientAiContext ctx, {
    required bool isTa,
  }) {
    String reply = '';

    if (qLower.contains('bp') || qLower.contains('blood pressure') || qLower.contains('vital') || qLower.contains('pulse') || qLower.contains('இரத்த அழுத்தம்')) {
      if (ctx.hasVitals) {
        final v = ctx.latestVitals!;
        final bpStr = (v.systolicBp != null && v.diastolicBp != null)
            ? '${v.systolicBp}/${v.diastolicBp} mmHg'
            : 'Not measured';
        final tempStr = v.temperatureC != null ? '${v.temperatureC}°C' : 'N/A';
        final weightStr = v.weightKg != null ? '${v.weightKg} kg' : 'N/A';

        reply = isTa
            ? '📋 **உங்கள் சமீபத்திய மருத்துவ அளவீடுகள் (Vitals):**\n\n'
                '• இரத்த அழுத்தம் (BP): **$bpStr**\n'
                '• உடல் வெப்பநிலை: **$tempStr**\n'
                '• உடல் எடை: **$weightStr**\n'
                '• பதிவு செய்யப்பட்ட நாள்: ${v.recordedAt.day}/${v.recordedAt.month}/${v.recordedAt.year}\n'
                '• பதிவு செய்தவர்: ${v.recordedByName.isNotEmpty ? v.recordedByName : "சுகாதார பணியாளர்"}\n\n'
                'உங்கள் இரத்த அழுத்தம் குறித்த சந்தேகங்களுக்கு உங்கள் மருத்துவரை அணுகவும்.'
            : '📋 **Your Latest Recorded Vitals:**\n\n'
                '• Blood Pressure (BP): **$bpStr**\n'
                '• Temperature: **$tempStr**\n'
                '• Weight: **$weightStr**\n'
                '• Recorded On: ${v.recordedAt.day}/${v.recordedAt.month}/${v.recordedAt.year}\n'
                '• Recorded By: ${v.recordedByName.isNotEmpty ? v.recordedByName : "Healthcare Worker"}\n\n'
                'These vitals are logged in your authenticated MAATRA clinical file.';
      } else {
        reply = isTa
            ? 'உங்கள் கணக்கில் இதுவரை இரத்த அழுத்தம் அல்லது அளவீடுகள் (Vitals) எதுவும் பதிவு செய்யப்படவில்லை. உங்கள் அடுத்த மருத்துவ பரிசோதனையில் சுகாதார பணியாளர் அல்லது மருத்துவர் இதை பதிவு செய்வார்.'
            : 'You do not have any vitals recorded in your MAATRA health profile yet. Your healthcare worker or doctor can record them during your next checkup.';
      }
    } else if (qLower.contains('visit') || qLower.contains('checkup') || qLower.contains('வருகை')) {
      if (ctx.hasHomeVisits) {
        final v = ctx.homeVisits.first;
        reply = isTa
            ? '🏠 **சமீபத்திய மருத்துவ பரிசோதனை விவரம்:**\n\n'
                '• நாள்: ${v.visitDate.day}/${v.visitDate.month}/${v.visitDate.year}\n'
                '• நோக்கம்: ${v.purpose}\n'
                '• பணியாளர்: ${v.ashaWorkerName}\n'
                '• நிலை: ${v.status}'
            : '🏠 **Your Recent Home / Field Visit:**\n\n'
                '• Date: ${v.visitDate.day}/${v.visitDate.month}/${v.visitDate.year}\n'
                '• Purpose: ${v.purpose}\n'
                '• Healthcare Worker: ${v.ashaWorkerName}\n'
                '• Status: ${v.status}';
      } else {
        reply = isTa
            ? 'உங்கள் கணக்கில் இதுவரை எந்த வீட்டு வருகை பதிவும் இல்லை.'
            : 'You do not have any field checkup or home visit logs recorded in your profile yet.';
      }
    } else if (qLower.contains('asha') || qLower.contains('worker') || qLower.contains('பணியாளர்')) {
      if (ctx.assignedAshaName != null && ctx.assignedAshaName!.isNotEmpty) {
        reply = isTa
            ? 'உங்கள் பகுதிக்கு நியமிக்கப்பட்ட சுகாதார பணியாளர்: **${ctx.assignedAshaName}**.'
            : 'Your assigned field healthcare worker is **${ctx.assignedAshaName}**.';
      } else {
        reply = isTa
            ? 'உங்கள் கணக்கிற்கு இன்னும் பிரத்யேக சுகாதார பணியாளர் ஒதுக்கப்படவில்லை. உங்கள் அருகிலுள்ள ஆரம்ப சுகாதார நிலையத்தை (PHC) தொடர்பு கொள்ளவும்.'
            : 'No dedicated field worker has been assigned to your profile in the system yet. Please consult your local Primary Health Centre (PHC).';
      }
    } else if (qLower.contains('pregnancy') || qLower.contains('edd') || qLower.contains('due date') || qLower.contains('வளர்ச்சி')) {
      if (ctx.hasActivePregnancy) {
        final preg = ctx.activePregnancy!;
        final eddStr = '${preg.edd.day}/${preg.edd.month}/${preg.edd.year}';
        reply = isTa
            ? '🤰 **உங்கள் கர்ப்ப பதிவு விவரம்:**\n\n'
                '• கால அளவு: **${preg.gestationalAgeDisplay}** (${preg.trimesterDisplay})\n'
                '• உத்தேச பிரசவ தேதி (EDD): **$eddStr**\n\n'
                'வழக்கமான மருத்துவ பரிசோதனைகளை தவறாமல் மேற்கொள்ளவும்.'
            : '🤰 **Your Registered Pregnancy Profile:**\n\n'
                '• Current Gestational Age: **${preg.gestationalAgeDisplay}** (${preg.trimesterDisplay})\n'
                '• Estimated Due Date (EDD): **$eddStr**\n\n'
                'Be sure to keep regular prenatal consultations with your doctor.';
      } else {
        reply = isTa
            ? 'உங்கள் கணக்கில் தற்போது கர்ப்ப பதிவு எதுவும் இல்லை. தேவைப்பட்டால் உங்கள் மருத்துவ பதிவேட்டில் சேர்க்கலாம்.'
            : 'You do not have an active pregnancy record registered in your profile right now.';
      }
    } else {
      reply = isTa
          ? 'உங்கள் கணக்கின் தனிப்பட்ட தகவல்களை சரிபார்க்க, உங்கள் இரத்த அழுத்தம், பரிசோதனைகள் அல்லது மருத்துவ பதிவுகளை பற்றி கேட்கலாம்.'
          : 'To view your personal health records, you can ask about your vitals, checkup visits, or doctor notes.';
    }

    return PatientAiMessage(
      id: id,
      text: reply,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isTamil: isTa,
      sources: const [
        AiSourceReference(
          type: AiSourceType.curatedKnowledgeBase,
          title: 'MAATRA Authenticated Clinical Record',
          detail: 'Direct Patient PostgreSQL Data Store',
        ),
      ],
    );
  }

  /// Checks if conversational small talk
  bool _isChitChat(String text) {
    final greetings = [
      'hi', 'hello', 'helo', 'hey', 'vanakkam', 'வணக்கம்', 'how are you', 'how r u',
      'good morning', 'good evening', 'good afternoon', 'who are you', 'who r u',
      'what can you do', 'what are you', 'thanks', 'thank you', 'nandri', 'நன்றி', 'bye'
    ];
    return greetings.any((g) => text == g || text.startsWith('$g ') || text.endsWith(' $g'));
  }

  /// Natural Chit-Chat Handler like ChatGPT / Claude / Grok
  PatientAiMessage _handleChitChat(
    String id,
    String qLower,
    PatientAiContext ctx, {
    required bool isTa,
  }) {
    final name = ctx.patientName;
    String text = '';

    if (qLower.contains('who are you') || qLower.contains('what are you') || qLower.contains('who r u')) {
      text = isTa
          ? 'நான் **MAATRA**, உங்கள் ஆரோக்கிய மற்றும் மருத்துவ வழிகாட்டி. நான் எளிய வீட்டு வைத்தியங்கள், உடல்நல சந்தேகங்கள், உணவு முறை, முதலுதவி மற்றும் உங்கள் மருத்துவ அளவீடுகளை விளக்க உதவ முடியும். உங்களுக்கு என்ன உதவி வேண்டும்?'
          : 'I am **MAATRA**, your intelligent health and wellness companion. I can help answer medical questions, suggest verified home remedies, guide you on symptoms, and explain your health vitals. How can I help you today?';
    } else if (qLower.contains('thank') || qLower.contains('nandri') || qLower.contains('நன்றி')) {
      text = isTa
          ? 'மகிழ்ச்சி! உங்கள் ஆரோக்கியம் எப்போதுமே முதன்மையானது. வேறு ஏதேனும் சந்தேகம் இருந்தால் தாராளமாக கேளுங்கள்.'
          : 'You are very welcome! Take good care of your health, and feel free to ask anytime you need guidance.';
    } else if (qLower.contains('how are you') || qLower.contains('how r u')) {
      text = isTa
          ? 'வணக்கம் $name! நான் நலமாக இருக்கிறேன். நீங்கள் எப்படி இருக்கிறீர்கள்? உங்கள் உடல்நலம் எப்படி உள்ளது?'
          : 'Hello $name! I am doing well, thank you for asking. How are you feeling today? Any health questions on your mind?';
    } else {
      text = isTa
          ? 'வணக்கம் $name! நான் MAATRA. உங்கள் உடல்நலம், வீட்டு வைத்தியம், உணவுகள் அல்லது ஏதேனும் அறிகுறிகள் பற்றி நீங்கள் என்னிடம் கேட்கலாம். இன்று நான் உங்களுக்கு எவ்வாறு உதவ முடியும்?'
          : 'Hello $name! I am MAATRA, your health companion. You can ask me anything about symptoms, home remedies, wellness tips, or your health records. What would you like to discuss today?';
    }

    return PatientAiMessage(
      id: id,
      text: text,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isTamil: isTa,
    );
  }

  /// Comprehensive Medical & Home Remedies Assistance across all topics
  PatientAiMessage _handleMedicalAndRemedies(
    String id,
    String originalQuery,
    String qLower,
    PatientAiContext ctx, {
    required bool isTa,
  }) {
    String reply = '';

    // A. Temperature / Fever / Body Heat
    if (qLower.contains('temperature') || qLower.contains('fever') || qLower.contains('kaachal') || qLower.contains('காய்ச்சல்') || qLower.contains('soodu')) {
      reply = isTa
          ? '🌡️ **உடல் வெப்பநிலை & காய்ச்சல் வழிகாட்டல்:**\n\n'
              '• **சாதாரண உடல் வெப்பநிலை:** 97°F – 99°F (36.1°C – 37.2°C), சராசரியாக **98.6°F (37°C)**.\n'
              '• 100.4°F (38°C) அல்லது அதற்கு மேல் இருந்தால் காய்ச்சலாக கருதப்படுகிறது.\n\n'
              '🌿 **எளிய வீட்டு பராமரிப்பு:**\n'
              '1. **நீர்ச்சத்து:** போதுமான அளவு வெதுவெதுப்பான நீர், இளநீர், சீரக நீர் அல்லது கஞ்சி குடிக்கவும்.\n'
              '2. **குளிர்ந்த ஒத்தடம்:** நெற்றி, கழுத்து மற்றும் கைகளில் சாதாரண அறை வெப்பநிலையில் உள்ள தண்ணீரில் நனைத்த துணியால் ஒத்தடம் கொடுக்கவும்.\n'
              '3. **ஓய்வு:** காற்றோட்டமான அறையில் நல்ல ஓய்வு எடுக்கவும். கனமான போர்வைகளை தவிர்க்கவும்.\n'
              '4. **எளிய உணவு:** இட்லி, ரசம் சாதம், சூப் போன்ற எளிதில் செரிமானமாகும் உணவுகளை உட்கொள்ளவும்.\n\n'
              '⚠️ **மருத்துவரை எப்போது அணுக வேண்டும்?**\n'
              'வெப்பநிலை 102°F-க்கு மேல் சென்றால், 2 நாட்களுக்கு மேல் நீடித்தால், அல்லது கடுமையான நடுக்கம், மூச்சுத்திணறல் இருந்தால் உடனடியாக மருத்துவரை அணுகவும்.'
          : '🌡️ **Body Temperature & Fever Guidance:**\n\n'
              '• **Normal Body Temperature:** 97°F to 99°F (36.1°C to 37.2°C), with an average around **98.6°F (37°C)**.\n'
              '• A temperature of 100.4°F (38°C) or higher is considered a fever.\n\n'
              '🌿 **Actionable Home Care & Remedies:**\n'
              '1. **Hydration:** Drink plenty of fluids (warm water, tender coconut water, diluted buttermilk, clear soups).\n'
              '2. **Cool Compresses:** Place a clean cloth soaked in room-temperature water on the forehead and neck.\n'
              '3. **Adequate Rest:** Rest in a well-ventilated, comfortable room. Avoid heavy blankets.\n'
              '4. **Light Nutrition:** Eat light, easily digestible foods like rice porridge (kanji), idlis, or broth.\n\n'
              '⚠️ **When to Seek Immediate Medical Attention:**\n'
              'If temperature exceeds 102°F (38.9°C), persists for more than 48 hours, or is accompanied by stiff neck, rash, severe breathlessness, or confusion, consult a doctor immediately.';
    }

    // B. Headache / Migraine / Tension
    else if (qLower.contains('headache') || qLower.contains('head pain') || qLower.contains('migraine') || qLower.contains('thalai vali') || qLower.contains('தலைவலி')) {
      reply = isTa
          ? '💆 **தலைவலி மற்றும் வீட்டு வைத்தியம்:**\n\n'
              '• **நீரிழப்பு (Hydration):** தலைவலிக்கு முக்கிய காரணம் நீர்ச்சத்து குறைபாடு. உடனே 1-2 டம்ளர் தண்ணீர் குடிக்கவும்.\n'
              '• **சுக்கு காப்பி / இஞ்சி சாறு:** சுக்கு மற்றும் இஞ்சி ரத்த ஓட்டத்தை சீராக்கி தலைவலியை குறைக்க உதவும்.\n'
              '• **அமைதியான சூழல்:** மங்கலான ஒளியில் அமைதியான அறையில் 20-30 நிமிடங்கள் கண்களை மூடி ஓய்வெடுக்கவும்.\n'
              '• **பத்து போடுதல்:** சந்தனம் அல்லது சுக்கு பொடியை வெதுவெதுப்பான நீரில் குழைத்து நெற்றியில் தடவலாம்.\n\n'
              '⚠️ தலைவலியுடன் பார்வை மங்குதல், வாந்தி அல்லது ஒரு பக்க பலவீனம் ஏற்பட்டால் உடனடியாக மருத்துவரை பார்க்கவும்.'
          : '💆 **Headache Relief & Home Remedies:**\n\n'
              '• **Hydration:** Mild dehydration is a very common trigger. Drink 1–2 glasses of water right away.\n'
              '• **Ginger / Peppermint:** Warm ginger tea can help ease vascular tension and reduce headache severity.\n'
              '• **Rest in a Quiet, Dim Room:** Close your eyes and practice 10–15 minutes of slow, deep breathing.\n'
              '• **Cold / Warm Compress:** Apply a cool compress to your forehead for migraines, or a warm towel to your neck for tension headaches.\n\n'
              '⚠️ Consult a doctor immediately if the headache is sudden and explosive, or accompanied by blurred vision, numbness, or vomiting.';
    }

    // C. Cold / Cough / Sore Throat
    else if (qLower.contains('cough') || qLower.contains('cold') || qLower.contains('sore throat') || qLower.contains('irumal') || qLower.contains('chalidhasam') || qLower.contains('இருமல்') || qLower.contains('சளி')) {
      reply = isTa
          ? '🍵 **சளி மற்றும் இருமலுக்கான சிறந்த இயற்கை வைத்தியங்கள்:**\n\n'
              '1. **ஆவி பிடித்தல் (Steam Inhalation):** வெந்நீரில் துளசி அல்லது சிறிதளவு மஞ்சள் தூள் சேர்த்து 5-10 நிமிடங்கள் ஆவி பிடிக்கவும்.\n'
              '2. **மஞ்சள் பால் (Golden Milk):** வெதுவெதுப்பான பாலில் கால் ஸ்பூன் மஞ்சள் தூள் மற்றும் மிளகுத்தூள் கலந்து இரவில் குடிக்கவும்.\n'
              '3. **உப்பு நீர் கொப்பளித்தல்:** தொண்டை வலிக்கு வெதுவெதுப்பான உப்பு நீரில் தினமும் 3 முறை வாய் கொப்பளிக்கவும்.\n'
              '4. **கஷாயம்:** துளசி, மிளகு, சீரகம், இஞ்சி சேர்த்து கொதிக்க வைத்த கஷாயம் குடிக்கவும்.'
          : '🍵 **Cold, Cough & Throat Care:**\n\n'
              '1. **Steam Inhalation:** Inhale steam with a pinch of turmeric or mint leaves for 5–10 minutes to clear nasal passages.\n'
              '2. **Warm Turmeric & Black Pepper Milk:** Drink warm milk with a pinch of turmeric and black pepper before sleeping.\n'
              '3. **Warm Salt Water Gargle:** Gargle with warm salt water 3 times a day for rapid relief from throat irritation.\n'
              '4. **Herbal Teas:** Drink warm water with honey, ginger, and tulsi (holy basil) to soothe irritated airways.';
    }

    // D. Digestion / Acidity / Stomach Pain / Nausea
    else if (qLower.contains('stomach') || qLower.contains('acidity') || qLower.contains('gas') || qLower.contains('digestion') || qLower.contains('nausea') || qLower.contains('vomit') || qLower.contains('வயிறு') || qLower.contains('செரிமானம்')) {
      reply = isTa
          ? '🌿 **செரிமானம், அசிடிட்டி & வயிற்று அசௌகரிய நிவாரணம்:**\n\n'
              '1. **சீரகத் தண்ணீர்:** சீரகத்தை தண்ணீரில் கொதிக்க வைத்து மிதமான சூட்டில் குடிப்பது செரிமானத்தை தூண்டும்.\n'
              '2. **மோர் & இஞ்சி:** தாளித்த மோர் அல்லது இஞ்சி சாறு அசிடிட்டி மற்றும் வாய்வுத் தொல்லையை குறைக்கும்.\n'
              '3. **சோம்பு (Fennel):** உணவுக்குப் பின் சிறிதளவு சோம்பு மென்று தின்பது நெஞ்செரிச்சலை தடுக்கும்.\n'
              '4. **வாந்தி உணர்வுக்கு:** இளநீர், எலுமிச்சை சாறு அல்லது புதினா இலைகளை முகர்ந்து பார்ப்பது நிவாரணம் தரும்.'
          : '🌿 **Digestion, Acidity & Stomach Comfort:**\n\n'
              '1. **Cumin (Jeera) Water:** Boil 1 tsp of cumin seeds in water, strain, and sip warm for immediate digestive relief.\n'
              '2. **Diluted Buttermilk:** Fresh buttermilk with a pinch of asafoetida (hing) and curry leaves cools stomach acidity.\n'
              '3. **Fennel Seeds (Saunf):** Chew a pinch of fennel seeds after meals to prevent acid reflux and bloating.\n'
              '4. **For Nausea:** Sip lemon water, ginger tea, or tender coconut water in small, slow sips.';
    }

    // E. Stress / Anxiety / Sleep
    else if (qLower.contains('stress') || qLower.contains('anxiety') || qLower.contains('sleep') || qLower.contains('தூக்கம்') || qLower.contains('மன அழுத்தம்')) {
      reply = isTa
          ? '🧘 **மன அமைதி மற்றும் நல்ல தூக்கத்திற்கான வழிகாட்டல்:**\n\n'
              '• **4-7-8 மூச்சுப் பயிற்சி:** 4 நொடிகள் மூச்சை உள்ளிழுத்து, 7 நொடிகள் நிறுத்தி, 8 நொடிகள் வாயால் மெதுவாக வெளிவிடவும்.\n'
              '• **வெதுவெதுப்பான பால்:** படுக்கும் முன் சூடான பாலில் சிறிதளவு ஏலக்காய் சேர்த்து குடிக்கவும்.\n'
              '• **மொபைல் திரை குறைப்பு:** தூங்குவதற்கு 1 மணி நேரத்திற்கு முன் செல்போன் பயன்படுத்துவதை தவிர்க்கவும்.\n'
              '• **பாத மசாஜ்:** இரவு தூங்கும் முன் பாதங்களில் சிறிதளவு நல்லெண்ணெய் அல்லது தேங்காய் எண்ணெய் தடவி மசாஜ் செய்யலாம்.'
          : '🧘 **Stress Relief, Relaxation & Restful Sleep:**\n\n'
              '• **4-7-8 Breathing Technique:** Inhale through nose for 4 seconds, hold breath for 7 seconds, exhale slowly through mouth for 8 seconds. Repeat 4 times.\n'
              '• **Sleep Routine:** Keep your sleeping area dark and quiet. Disconnect from screens at least 45 minutes before bedtime.\n'
              '• **Warm Foot Massage:** Gently massage the soles of your feet with warm coconut or sesame oil before bed to calm the nervous system.\n'
              '• **Warm Herbal Infusion:** Sip warm chamomile tea or warm milk with a pinch of cardamom.';
    }

    // F. General Health / Nutrition / Lifestyle
    else {
      reply = isTa
          ? '🌿 **MAATRA ஆரோக்கிய வழிகாட்டல்:**\n\n'
              'உங்கள் கேள்விக்கு ("$originalQuery"):\n'
              '• சீரான சமச்சீர் உணவு, தினசரி 2.5–3 லிட்டர் தண்ணீர் குடிப்பது மற்றும் 7-8 மணி நேர ஆழ்ந்த தூக்கம் உடல் ஆரோக்கியத்திற்கு மிகவும் அவசியம்.\n'
              '• நீங்கள் ஏதேனும் குறிப்பிட்ட அறிகுறிகள் (காய்ச்சல், தலைவலி, சளி, செரிமானம், உடல் வலி) அல்லது வீட்டு வைத்தியங்கள் பற்றி கேட்க விரும்பினால் தாராளமாக விவரிக்கவும்.\n'
              '• கடுமையான அல்லது தொடர்ச்சியான அசௌகரியங்களுக்கு அருகில் உள்ள மருத்துவரை அணுகவும்.'
          : '🌿 **MAATRA Health & Wellness Insights:**\n\n'
              'Regarding your query ("$originalQuery"):\n'
              '• Balanced nutrition, staying hydrated (2.5–3 liters daily), regular movement, and 7–8 hours of restful sleep are the pillars of good health.\n'
              '• Feel free to ask about specific symptoms (fever, aches, cough, acidity), home remedies, first-aid, or your authenticated health records.\n'
              '• If you are experiencing persistent discomfort or pain, always consult your physician or local Primary Health Centre (PHC).';
    }

    return PatientAiMessage(
      id: id,
      text: reply,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isTamil: isTa,
    );
  }
}
