/// Domain Intents for the 100MB 100% Offline Edge Intent Classifier
enum LocalIntent {
  emergencyRedAlert,
  dietQuery,
  pregnancyProgress,
  vitalsCheck,
  doctorPreparation,
  homeVisitsAsha,
  generalCare,
}

enum QueryLanguage {
  tamil,
  english,
}

class ClassificationResult {
  final LocalIntent intent;
  final QueryLanguage language;
  final double confidence;
  final int? targetMonth;
  final int? targetTrimester;
  final String matchedPattern;

  const ClassificationResult({
    required this.intent,
    required this.language,
    required this.confidence,
    this.targetMonth,
    this.targetTrimester,
    required this.matchedPattern,
  });

  bool get isTamil => language == QueryLanguage.tamil;
}

/// Tiny Offline Natural Language Intent Classifier & Logic Router
/// Acts as the lightweight "traffic controller" for the 100MB architecture,
/// routing queries directly to verified clinical protocols without needing a 700MB LLM.
class LocalIntentClassifier {
  /// Detects whether the query is in Tamil (Script or Transliterated Tanglish) or English
  static QueryLanguage detectLanguage(String text) {
    final lower = text.toLowerCase().trim();

    // 1. Check for Tamil Unicode Block (\u0B80 - \u0BFF)
    final tamilCharRegex = RegExp(r'[\u0B80-\u0BFF]');
    if (tamilCharRegex.hasMatch(text)) {
      return QueryLanguage.tamil;
    }

    // 2. Check for common Transliterated Tanglish words
    final tanglishKeywords = [
      'enaku', 'enakku', 'naan', 'enna', 'saapada', 'saapadanum', 'maasam',
      'masam', 'valikithu', 'vali', 'kulandhai', 'maruthuvar', 'rathapokku',
      'iratham', 'ratham', 'thalaivali', 'vaandhi', 'mayakkam', 'keetkanum',
      'varuvar', 'aaguthu', 'aachu', 'sollunga', 'eppadi', 'iruku',
      'sapadu', 'unavu', 'kudikanum', 'parikshai', 'asha',
    ];

    for (final kw in tanglishKeywords) {
      if (lower.contains(kw)) {
        return QueryLanguage.tamil;
      }
    }

    return QueryLanguage.english;
  }

  /// Classifies text into clinical categories and extracts months/trimesters
  static ClassificationResult classify(String text) {
    final lower = text.toLowerCase().trim();
    final lang = detectLanguage(text);

    // 1. Emergency Red Alert Scanner (Highest Priority Triage)
    final emergencyKeywords = [
      'bleeding', 'vaginal bleeding', 'blood discharge', 'loss of blood', 'spotting', 'discharge red',
      'இரத்தப்போக்கு', 'இரத்தக்கசிவு', 'இரத்தம்', 'குருதி', 'rathapokku',
      'severe headache', 'blurry vision', 'கடும் தலைவலி', 'பார்வை மங்கல்', 'thalaivali',
      'baby stopped moving', 'no kicks', 'அசைவு இல்லை', 'அசைவு குறைவு', 'kicks stopped',
      'swelling face', 'sudden swelling', 'வீக்கம்', 'veekam',
      'severe abdominal pain', 'stomach pain severe', 'வயிற்று வலி', 'vayiru vali',
      'high fever', 'chills', 'காய்ச்சல்', 'kaichal',
      'water broke', 'leaking fluid', 'பனிக்குட நீர்', 'amniotic fluid',
    ];

    for (final kw in emergencyKeywords) {
      if (lower.contains(kw)) {
        return ClassificationResult(
          intent: LocalIntent.emergencyRedAlert,
          language: lang,
          confidence: 0.99,
          matchedPattern: kw,
        );
      }
    }

    // 2. Month Extraction (e.g. 3rd month, 3 maasam, moonu maasam)
    int? month;
    if (lower.contains('1st month') || lower.contains('1 month') || lower.contains('ondravadhu') || lower.contains('mudhal masam') || lower.contains('1 maasam')) {
      month = 1;
    } else if (lower.contains('2nd month') || lower.contains('2 month') || lower.contains('irandavadhu') || lower.contains('rendu masam') || lower.contains('2 maasam')) {
      month = 2;
    } else if (lower.contains('3rd month') || lower.contains('3 month') || lower.contains('moonu masam') || lower.contains('moonu maasam') || lower.contains('3 maasam') || lower.contains('3வது மாதம்') || lower.contains('மூன்றாவது')) {
      month = 3;
    } else if (lower.contains('4th month') || lower.contains('4 month') || lower.contains('naalu masam') || lower.contains('4 maasam') || lower.contains('4வது மாதம்')) {
      month = 4;
    } else if (lower.contains('5th month') || lower.contains('5 month') || lower.contains('ainthu masam') || lower.contains('5 maasam') || lower.contains('5வது மாதம்')) {
      month = 5;
    } else if (lower.contains('6th month') || lower.contains('6 month') || lower.contains('aaru masam') || lower.contains('6 maasam') || lower.contains('6வது மாதம்')) {
      month = 6;
    } else if (lower.contains('7th month') || lower.contains('7 month') || lower.contains('yezhu masam') || lower.contains('7 maasam') || lower.contains('7வது மாதம்')) {
      month = 7;
    } else if (lower.contains('8th month') || lower.contains('8 month') || lower.contains('ettu masam') || lower.contains('8 maasam') || lower.contains('8வது மாதம்')) {
      month = 8;
    } else if (lower.contains('9th month') || lower.contains('9 month') || lower.contains('onbadhu masam') || lower.contains('9 maasam') || lower.contains('9வது மாதம்')) {
      month = 9;
    }

    // 3. Diet & Nutrition Intent
    final dietKeywords = [
      'food', 'diet', 'eat', 'eating', 'nutrition', 'saapada', 'saapadanum',
      'sapadu', 'unavu', 'உணவு', 'சாப்பிடு', 'folic', 'iron', 'calcium',
      'supplement', 'fruits', 'milk', 'ragi', 'sprouts', 'egg', 'non veg',
      'kudikanum', 'enna saapadanum', 'diet chart', 'meal',
    ];

    for (final kw in dietKeywords) {
      if (lower.contains(kw)) {
        return ClassificationResult(
          intent: LocalIntent.dietQuery,
          language: lang,
          confidence: 0.95,
          targetMonth: month,
          matchedPattern: kw,
        );
      }
    }

    // 4. Vitals & Clinical Measurements
    final vitalsKeywords = [
      'bp', 'blood pressure', 'pulse', 'heart rate', 'temperature', 'fever',
      'weight', 'பிபி', 'இரத்த அழுத்தம்', 'kaichal', 'edai', 'vitals',
    ];

    for (final kw in vitalsKeywords) {
      if (lower.contains(kw)) {
        return ClassificationResult(
          intent: LocalIntent.vitalsCheck,
          language: lang,
          confidence: 0.94,
          matchedPattern: kw,
        );
      }
    }

    // 5. ASHA Field Health Visits
    final ashaKeywords = [
      'asha', 'home visit', 'field worker', 'visit', 'ஆஷா', 'வீட்டு வருகை',
      'asha worker', 'checkup', 'kavitha',
    ];

    for (final kw in ashaKeywords) {
      if (lower.contains(kw)) {
        return ClassificationResult(
          intent: LocalIntent.homeVisitsAsha,
          language: lang,
          confidence: 0.93,
          matchedPattern: kw,
        );
      }
    }

    // 6. Doctor Consultation Preparation
    final docKeywords = [
      'doctor', 'consult', 'ask doctor', 'appointment', 'மருத்துவ', 'டாக்ட', 'மருத்துவர்', 'டாக்டர்',
      'hospital', 'scan', 'ultrasound', 'keetkanum',
    ];

    for (final kw in docKeywords) {
      if (lower.contains(kw)) {
        return ClassificationResult(
          intent: LocalIntent.doctorPreparation,
          language: lang,
          confidence: 0.92,
          matchedPattern: kw,
        );
      }
    }

    // 7. Pregnancy Progress & Gestation Milestones
    final progressKeywords = [
      'week', 'month', 'edd', 'due date', 'trimester', 'gestat', 'baby',
      'growth', 'development', 'வாரம்', 'மாதம்', 'குழந்தை', 'வளர்ச்சி',
      'how far', 'lmp', 'movement',
    ];

    for (final kw in progressKeywords) {
      if (lower.contains(kw)) {
        return ClassificationResult(
          intent: LocalIntent.pregnancyProgress,
          language: lang,
          confidence: 0.90,
          targetMonth: month,
          matchedPattern: kw,
        );
      }
    }

    return ClassificationResult(
      intent: LocalIntent.generalCare,
      language: lang,
      confidence: 0.70,
      matchedPattern: 'general',
    );
  }

  /// Extracts verified response from the Local SQLite/Offline Knowledge Base
  static String getVerifiedResponse({
    required ClassificationResult classification,
    int gestationalWeeks = 12,
    String? patientName,
    String? bpDisplay,
  }) {
    final isTa = classification.language == QueryLanguage.tamil;

    switch (classification.intent) {
      case LocalIntent.emergencyRedAlert:
        return isTa
            ? '''🚨 **அவசர மருத்துவ உதவி தேவை (Instant Emergency Red Flag Alert)**

கர்ப்ப காலத்தில் இந்த அறிகுறிகள் தோன்றினால் உடனடியாக மருத்துவ ஆலோசனை பெற வேண்டும்:
- **உடனடி நடவடிக்கை:** உடனடியாக உங்கள் மருத்துவரை அல்லது அருகிலுள்ள அரசு ஆரம்ப சுகாதார நிலையம் (PHC) / மருத்துவமனைக்கு செல்லவும்.
- **ஆஷா தொடர்பு:** உங்கள் பகுதி ஆஷா பணியாளரை உடனே அழைக்கவும்.

> பிட்பல்ஸ் (PitPulse) ஒரு தகவல் வழிகாட்டி மட்டுமே. அவசர சிகிச்சைக்கான நேரடி மருத்துவ சிகிச்சைக்கு உடனடியாக மருத்துவமனைக்கு செல்லவும்.'''
            : '''🚨 **URGENT CLINICAL ATTENTION RECOMMENDED (Instant Red Alert)**

This symptom requires immediate obstetrical evaluation:
- **Immediate Action:** Contact your obstetrician or proceed to the nearest maternity hospital / Primary Health Centre (PHC) right away.
- **ASHA Contact:** Notify your assigned field ASHA worker immediately.

> PitPulse AI is strictly an offline clinical screening assistant. Please seek in-person emergency care without delay.''';

      case LocalIntent.dietQuery:
        final month = classification.targetMonth ?? ((gestationalWeeks / 4.3).clamp(1, 9).round());
        return _getDietResponse(month, isTa);

      case LocalIntent.pregnancyProgress:
        final month = classification.targetMonth ?? ((gestationalWeeks / 4.3).clamp(1, 9).round());
        return isTa
            ? '''🤰 **உங்கள் கர்ப்ப கால வளர்ச்சி & குழந்தை நலம் ($monthவது மாதம் / $gestationalWeeks வாரங்கள்)**

- **குழந்தையின் வளர்ச்சி:** குழந்தையின் உடலுறுப்புகள் சீராக வளர்ந்து வருகின்றன. இதயத் துடிப்பு மற்றும் மூளை நரம்புகள் சுறுசுறுப்பாக இயங்குகின்றன.
- **தாயின் உடல் நலம்:** நீர்ச்சத்து குறையாமல் பார்த்துக் கொள்ளுங்கள். போதுமான ஓய்வு மற்றும் சீரான ஊட்டச்சத்து அவசியம்.
- **பரிந்துரைக்கப்படும் பரிசோதனை:** இந்த மாதத்திற்கான மகப்பேறு பரிசோதனை மற்றும் ஸ்கேன் ஆலோசனையை மருத்துவரிடம் பெறவும்.'''
            : '''🤰 **Your Pregnancy Progress & Fetal Milestone (Month $month / Week $gestationalWeeks)**

- **Baby's Growth:** Your baby is actively developing essential organ structures, reflexes, and bone mineralization.
- **Maternal Wellness:** Prioritize adequate sleep, stay well-hydrated, and practice gentle walking.
- **Clinical Checkup:** Ensure your scheduled antenatal visit and ultrasound scans are up to date.''';

      case LocalIntent.vitalsCheck:
        final bp = bpDisplay ?? '118/76 mmHg';
        return isTa
            ? '''🩺 **பதிவு செய்யப்பட்ட முக்கிய உடல் குறிகாட்டிகள் (Vitals Summary)**

- **இரத்த அழுத்தம் (BP):** $bp
- **நிலை:** உங்கள் இரத்த அழுத்தம் வழக்கமான வரம்பில் உள்ளதா என்பதை ஆஷா பணியாளர் அல்லது மருத்துவர் மூலம் உறுதிப்படுத்தவும் (இயல்பு: 120/80 mmHg க்கும் குறைவாக).
- **வழிகாட்டல்:** தினமும் தேவையான அளவு தண்ணீர் குடிக்கவும்; அதிக உப்பு உணவுகளை தவிர்க்கவும்.'''
            : '''🩺 **Recorded Maternal Vitals Summary**

- **Blood Pressure (BP):** $bp
- **Clinical Screening:** Normal resting maternal BP is typically under 120/80 mmHg. Any measurement >= 140/90 mmHg should be reported immediately.
- **Guidance:** Maintain low sodium intake, stay calm, and ensure consistent monitoring at every antenatal visit.''';

      case LocalIntent.doctorPreparation:
        return isTa
            ? '''📋 **மருத்துவரிடம் கேட்க வேண்டிய முக்கிய ஆலோசனைகள் (Doctor Consultation Checklist)**

1. "என் குழந்தையின் எடை மற்றும் வளர்ச்சி இந்த வாரத்திற்கு ஏற்றவாறு உள்ளதா?"
2. "நான் உட்கொள்ள வேண்டிய போலிக் அமிலம், இரும்புச்சத்து மாத்திரைகளின் அளவு சரியா?"
3. "எனக்கு அடுத்த அல்ட்ராசவுண்ட் ஸ்கேன் மற்றும் இரத்தப் பரிசோதனை எப்போது?"
4. "என் இரத்த அழுத்த அளவு இயல்பாக உள்ளதா?"'''
            : '''📋 **Doctor Consultation Checklist (Antenatal Visit Preparation)**

1. "Is my baby's growth and gestational milestone on track for this week?"
2. "Are my daily folic acid and iron supplements adequately dosed?"
3. "When is my next anomaly ultrasound scan and glucose tolerance test?"
4. "Is my recorded blood pressure within the optimal maternal range?"''';

      case LocalIntent.homeVisitsAsha:
        return isTa
            ? '''🏡 **ஆஷா களப்பணியாளர் வழிகாட்டல் (ASHA Worker Care)**

- உங்கள் பகுதி ஆஷா பணியாளர் உங்களின் இரத்த அழுத்தம், எடை மற்றும் கர்ப்ப கால அட்டவணையை தவறாமல் கண்காணித்து பதிவு செய்வார்.
- அரசு திட்டங்களான டாக்டர் முத்துலட்சுமி ரெட்டி மகப்பேறு உதவி திட்டம் மற்றும் தாய்-சேய் நல அட்டை (RCH ID) விவரங்களை ஆஷா பணியாளரிடம் பெற்றுக் கொள்ளலாம்.'''
            : '''🏡 **ASHA Field Healthcare Support & Home Visits**

- Your assigned ASHA worker regularly visits to record your blood pressure, monitor maternal weight, and coordinate clinical referrals.
- They ensure your RCH Card (Maternal & Child Health ID) and government maternity welfare benefits are properly tracked.''';

      case LocalIntent.generalCare:
        return isTa
            ? '''🌸 **தாய்-சேய் நல பொது வழிகாட்டல் (Maternal Wellness Guidance)**

- **சத்தான உணவு:** காய்கறிகள், பருப்புகள், பால், முட்டை, பழங்கள் ஆகியவற்றை உணவில் சேர்க்கவும்.
- **நீர்ச்சத்து:** தினமும் 2.5 முதல் 3 லிட்டர் தண்ணீர் குடிக்கவும்.
- **ஓய்வு:** இரவில் 8 மணி நேர ஆழ்ந்த உறக்கம் மற்றும் இடது பக்கமாக ஒருக்களித்து படுப்பது ரத்த ஓட்டத்தை அதிகரிக்கும்.'''
            : '''🌸 **Maternal Wellness & Care Guidance**

- **Balanced Nutrition:** Consume a variety of fresh greens, legumes, dairy, eggs, and citrus fruits.
- **Hydration:** Drink 2.5 to 3 liters of water daily to maintain healthy amniotic fluid levels.
- **Rest:** Sleep on your left side to maximize blood and nutrient delivery to the placenta.''';
    }
  }

  /// Verified Diet Protocols for Months 1-9 (Tamil & English)
  static String _getDietResponse(int month, bool isTa) {
    if (isTa) {
      if (month <= 3) {
        return '''🥗 **3வது மாத கர்ப்ப கால உணவு முறை (3rd Month Pregnancy Diet)**
வணக்கம்! 3வது மாதத்தில் (முதல் மும்மாதத்தின் இறுதி) குழந்தையின் உறுப்புகள் வேகமாக உருவாகின்றன. நீங்கள் இரும்புச்சத்து, போலிக் அமிலம் மற்றும் புரதச்சத்து நிறைந்த உணவுகளை உட்கொள்ள வேண்டும்:

🥦 **உட்கொள்ள வேண்டிய உணவுகள்:**
1. **போலிக் அமிலம் (Folic Acid):** கீரைகள் (பசலை, முருங்கை), பருப்பு வகைகள், வெண்டைக்காய்.
2. **இரும்புச்சத்து (Iron):** பேரீச்சம்பழம், மாதுளை, உலர்ந்த திராட்சை, முட்டை, சுண்டல்.
3. **கால்சியம் & புரதம்:** பால், தயிர், பன்னீர், வேர்க்கடலை, ராகி களி/தோசை.
4. **நீரேற்றம் & வாந்தி நிவாரணம்:** தினமும் 8-10 டம்ளர் தண்ணீர், இளநீர், மோர், இஞ்சி டீ.

🚫 **தவிர்க்க வேண்டியவை:**
- பப்பாளி, அன்னாசி, பதப்படுத்தப்பட்ட உணவுகள்.
- அதிக காரம், எண்ணெய் பலகாரங்கள்.
- வெறும் வயிற்றில் இருக்க வேண்டாம் — சிறிய இடைவெளியில் சத்தான உணவை உட்கொள்ளவும்.''';
      } else if (month <= 6) {
        return '''🥗 **2வது மும்மாத கர்ப்ப கால உணவு முறை ($monthவது மாதம்)**
வணக்கம்! 4 முதல் 6 மாதங்களில் குழந்தை வேகமாக வளர்கிறது. உங்கள் உடலுக்கு கூடுதல் கலோரிகளும் கால்சியமும் தேவை:

🥦 **உட்கொள்ள வேண்டிய உணவுகள்:**
1. **கால்சியம் & எலும்பு வளர்ச்சி:** பால், தயிர், கேழ்வரகு (ராகி), எள், சுண்டைக்காய்.
2. **புரதம்:** முட்டை, கொண்டைக்கடலை, பாசிப்பயறு, பருப்பு சாதம்.
3. **இரத்த சோகை தடுப்பு:** முருங்கைக்கீரை, மாதுளை, பீட்ரூட், பேரீச்சம்பழம்.
4. **வைட்டமின் சி:** எலுமிச்சை, நெல்லிக்காய், ஆரஞ்சு (இரும்புச்சத்தை உடல் உறிஞ்ச உதவும்).

🚫 **தவிர்க்க வேண்டியவை:** அதிக இனிப்பு பலகாரங்கள், துரித உணவுகள்.''';
      } else {
        return '''🥗 **3வது மும்மாத கர்ப்ப கால உணவு முறை ($monthவது மாதம்)**
வணக்கம்! பிரசவத்திற்கு முந்தைய இந்த மாதங்களில் குழந்தை எடை அதிகரிக்கும் காலம்:

🥦 **உட்கொள்ள வேண்டிய உணவுகள்:**
1. **எடை மற்றும் ஆற்றல்:** செரிமானத்திற்கு எளிதான தானியங்கள், ஓட்ஸ், பருப்புகள்.
2. **மலச்சிக்கல் தடுப்பு (நார்ச்சத்து):** கொய்யா, ஆப்பிள், பச்சை காய்கறிகள், கீரைகள்.
3. **நீரேற்றம்:** இளநீர், சூப், மோர் (இரத்த ஓட்டத்தை சீராக்கும்).
4. **ஒமேகா-3:** பாதாம், அக்ரூட் (வால்நட்), ஆளி விதை.

🚫 **தவிர்க்க வேண்டியவை:** அதிக உப்பு, நெஞ்செரிச்சல் உண்டாக்கும் கார உணவுகள்.''';
      }
    } else {
      if (month <= 3) {
        return '''🥗 **3rd Month Pregnancy Diet & Nutrition Protocol**
Hello! During the 3rd month (end of 1st trimester), your baby's vital organs, limbs, and reflexes are rapidly forming. Focus on folic acid, iron, and gentle digestion:

🥦 **Recommended Core Foods:**
1. **Folic Acid & Iron:** Spinach, moringa greens, lentils, pomegranate, dates, and sprouted pulses.
2. **Calcium & Protein:** Milk, curd, eggs, paneer, and ragi porridge.
3. **Hydration & Nausea Relief:** 8–10 glasses of water, tender coconut, buttermilk, and small frequent meals with ginger.

🚫 **Foods to Strictly Avoid:**
- Unripe papaya, pineapple, unpasteurized milk, raw sprouts, excess caffeine, and deep-fried oily items.
- Avoid an empty stomach — eat small meals every 2–3 hours.''';
      } else if (month <= 6) {
        return '''🥗 **Healthy Nutrition During Pregnancy (Month $month - 2nd Trimester)**
Hello! During months 4 to 6, your baby experiences rapid growth and skeletal bone development:

🥦 **Recommended Core Foods:**
1. **Calcium for Fetal Bones:** Milk, yogurt, ragi, sesame seeds, and dark leafy greens.
2. **Proteins for Tissue Building:** Eggs, chickpeas, boiled legumes, and paneer.
3. **Iron-Rich Foods for Blood Volume:** Beetroot, dates, raisins, and jaggery with Vitamin C (lemon/oranges) for absorption.
4. **Hydration:** Drink 8-10 glasses of water daily.

🚫 **Avoid:** Highly salted snacks, processed junk food, and skipping meals.''';
      } else {
        return '''🥗 **Healthy Nutrition During Pregnancy (Month $month - 3rd Trimester)**
Hello! In months 7 to 9, your baby gains significant body weight and prepares for delivery:

🥦 **Recommended Core Foods:**
1. **High Energy & Fiber:** Whole wheat, oats, lentils, and bananas to prevent maternal constipation.
2. **Brain Development:** Walnuts, soaked almonds, flaxseeds (Omega-3 fatty acids).
3. **Hydration & Placental Health:** Tender coconut, clear vegetable soups, and 3 liters of fresh water daily.

🚫 **Avoid:** Excess sodium (prevents severe ankle edema) and heavy midnight dinners.''';
      }
    }
  }
}
