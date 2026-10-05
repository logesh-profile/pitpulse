// 100% Offline Fully Functional Local Agentic RAG Controller (Context-Aware)
// Built for rural maternal and general health in Tamil Nadu.
// Adheres strictly to:
// 1. Chat History & Context Stitching Engine (multi-turn memory & semantic keyword fallbacks)
// 2. Three-Layer Processing Hierarchy (Safety Override -> Chitchat/General QA -> Target Semantic RAG)
// 3. Multi-Tool SQLite Matrix Execution (Emergency, Maternal Timeline, ASHA Directory, General Health FAQ)

import 'dart:math';

/// Structural Interface Contract for the Local Agent State (Context-Aware)
class LocalAgentState {
  final String rawText;
  final String language;
  final List<String> chatHistory; // Keeps track of past user turns
  int primaryIntentId;
  List<String> extractedEntities = [];
  Map<String, dynamic> retrievedMedicalContext = {};
  Map<String, dynamic> retrievedAshaContext = {};
  List<String> executedTools = [];
  bool isEmergency = false;
  String synthesizedResponse = '';

  LocalAgentState({
    required this.rawText,
    required this.language,
    required this.chatHistory,
    this.primaryIntentId = -1,
  });
}

/// The Local Relational Database Matrix (health_knowledge.db)
/// Operates 100% in-memory/on-device with zero network latency.
class LocalHealthKnowledgeDatabase {
  // Layer 1: Restricted Content Keywords & Phrases (Safety Override)
  static const List<String> restrictedPatternsEn = [
    'bypass clinical testing',
    'buy illegal tablets',
    'illegal tablet',
    'illegal medicine',
    'illegal drug',
    'abortifacient',
    'abortion pill',
    'abort pills',
    'terminate pregnancy at home',
    'unverified home remedy to abort',
    'how to abort',
    'pills to terminate',
    'self harm',
    'harm myself',
    'kill myself',
    'suicide',
    'poison',
    'homemade abortion',
    'shortcut remedy to bypass',
    'write code',
    'python code',
    'blockchain',
    'hack',
  ];

  static const List<String> restrictedPatternsTa = [
    'கருக்கலைப்பு மாத்திரை',
    'சட்டவிரோத',
    'தற்கொலை',
    'விஷம்',
    'மருத்துவ பரிசோதனையை தவிர்க்க',
    'வீட்டிலேயே கருக்கலைப்பு',
    'தானாக கருவை அழிக்க',
  ];

  // Layer 2: General Health FAQ Table (Handles unexpected freeform wellness topics like stress, sleep, etc.)
  static const Map<String, Map<String, dynamic>> generalHealthFaq = {
    'stress': {
      'keywords': ['stress', 'tension', 'anxiety', 'worried', 'worry', 'panic', 'depress', 'கவலை', 'மன அழுத்தம்', 'பயம்', 'பதற்றம்', 'மன உளைச்சல்'],
      'en': '''🧘‍♀️ **Maternal Stress & Emotional Wellness Guide**

Pregnancy can bring emotional changes and stress. Here are evidence-based steps to manage anxiety safely:
1. 🌬️ **Deep Breathing & Relaxation:** Sit comfortably, inhale slowly through your nose for 4 seconds, hold for 2 seconds, and exhale gently for 6 seconds. Repeat for 5–10 minutes.
2. 💧 **Hydration & Gentle Movement:** Drink a tall glass of fresh water and take a slow 15-minute walk in fresh air.
3. 🛌 **Adequate Rest:** Sleep on your left side with pillow support between your knees to relieve pelvic pressure.
4. 📞 **Talk to Your ASHA Worker / Doctor:** Emotional well-being is vital for baby's health. Discuss persistent anxiety with your local Village Health Nurse or doctor.''',
      'ta': '''🧘‍♀️ **கர்ப்ப கால மன அழுத்தம் & மன அமைதிக்கான வழிகாட்டல்**

கர்ப்ப காலத்தில் ஏற்படும் ஹார்மோன் மாற்றங்களால் மன அழுத்தமும் பதற்றமும் ஏற்படுவது இயல்பானது. இதனை கட்டுப்படுத்த:
1. 🌬️ **ஆழ்ந்த மூச்சுப் பயிற்சி:** அமைதியான இடத்தில் அமர்ந்து, 4 நொடிகள் மூச்சை மெதுவாக உள்ளிழுத்து, 6 நொடிகள் மெதுவாக வெளிவிடவும் (5-10 நிமிடங்கள்).
2. 💧 **நீர்ச்சத்து & நடைப்பயிற்சி:** ஒரு டம்ளர் குளிர்ந்த நீர் குடித்துவிட்டு, 15 நிமிடங்கள் நிதானமாக நடைப்பயிற்சி செய்யவும்.
3. 🛌 **இடதுபுற ஓய்வு:** தூங்கும் போது இடது பக்கமாக ஒருக்களித்து படுத்து தலையணை ஆதரவை பயன்படுத்தவும்.
4. 📞 **ஆஷா பணியாளரிடம் பகிருங்கள்:** உங்கள் கவலைகள் மற்றும் பயங்களை உங்கள் பகுதி ஆஷா பணியாளர் அல்லது ஆரம்ப சுகாதார நிலைய மருத்துவரிடம் தயங்காமல் தெரிவிக்கவும்.''',
    },
    'sleep': {
      'keywords': ['sleep', 'insomnia', 'cant sleep', 'night sleep', 'தூக்கம்', 'தூக்கமின்மை', 'உறக்கம்'],
      'en': '''🛌 **Pregnancy Sleep & Rest Guidelines**

1. **Sleep Position:** Always sleep on your left side to optimize blood and oxygen flow to the placenta.
2. **Support Pillows:** Place a pillow between your knees and another supporting your belly/lower back.
3. **Bedtime Routine:** Avoid mobile screens 1 hour before sleep; drink a warm cup of milk.
4. **Daytime Naps:** Take a brief 30-minute afternoon rest to reduce maternal fatigue.''',
      'ta': '''🛌 **கர்ப்ப கால உறக்கம் மற்றும் ஓய்வு வழிகாட்டல்**

1. **தூங்கும் நிலை:** நஞ்சுக்கொடிக்கு ரத்த ஓட்டம் சீராக செல்ல எப்போதும் இடது பக்கமாக ஒருக்களித்து படுக்கவும்.
2. **தலையணை ஆதரவு:** கால்களுக்கு நடுவிலும், வயிற்றுக்கு ஆதரவாகவும் சிறிய தலையணைகளை வைக்கவும்.
3. **தூக்கத்திற்கு முன்:** படுக்கைக்கு செல்லும் 1 மணி நேரத்திற்கு முன் செல்போன் பார்ப்பதை தவிர்க்கவும்; மிதமான சூடான பால் குடிக்கலாம்.
4. **மதிய ஓய்வு:** பகலில் 30 நிமிடங்கள் சிறிய ஓய்வு எடுப்பது உடலுக்கு புத்துணர்ச்சி தரும்.''',
    },
    'fatigue': {
      'keywords': ['fatigue', 'exhausted', 'weak', 'weakness', 'tiredness', 'energy', 'சோர்வு', 'அயர்வு', 'பலவீனம்'],
      'en': '''⚡ **Managing Pregnancy Fatigue & Low Energy**

1. **Check Iron Intake:** Ensure you take your prescribed daily Iron & Folic Acid (IFA) tablets after meals.
2. **Iron-Rich Foods:** Eat spinach, moringa leaves, dates, pomegranate, and boiled eggs.
3. **Hydration:** Dehydration is a primary cause of maternal fatigue. Drink 2.5–3 liters of water daily.
4. **Rest:** Listen to your body and take short resting breaks throughout the day.''',
      'ta': '''⚡ **கர்ப்ப கால சோர்வை சமாளிக்கும் வழிகள்**

1. **இரும்புச்சத்து மாத்திரைகள்:** மருத்துவர் பரிந்துரைத்த இரும்புச்சத்து மற்றும் போலிக் அமில மாத்திரைகளை தவறாமல் உட்கொள்ளவும்.
2. **சத்தான உணவுகள்:** முருங்கைக்கீரை, பேரீச்சம்பழம், மாதுளை, சுண்டல், அவித்த முட்டை ஆகியவற்றை உணவில் சேர்க்கவும்.
3. **நீர்ச்சத்து:** உடலில் நீர் குறையாமல் இருக்க தினமும் 8-10 டம்ளர் தண்ணீர், இளநீர் அல்லது மோர் குடிக்கவும்.
4. **ஓய்வு:** உடல் சோர்வாக இருக்கும் போது வேலைகளை குறைத்து போதிய ஓய்வெடுக்கவும்.''',
    },
    'headache': {
      'keywords': ['headache', 'head pain', 'தலைவலி', 'தலை பாரம்'],
      'en': '''🤕 **Pregnancy Headache & Relief Guidance**

1. **Rest in a Quiet, Dark Room:** Lie down with a cool, damp cloth on your forehead.
2. **Hydrate Immediately:** Drink 2 large glasses of water; dehydration commonly causes headaches.
3. **Never Self-Medicate:** Avoid taking painkiller tablets without consulting your doctor.
4. ⚠️ **Critical Warning:** If headache is severe with blurred vision or face swelling, get your Blood Pressure checked immediately at the PHC (sign of preeclampsia).''',
      'ta': '''🤕 **கர்ப்ப கால தலைவலி நிவாரண வழிகாட்டல்**

1. **அமைதியான ஓய்வு:** வெளிச்சம் குறைந்த அமைதியான அறையில் படுத்து நெற்றியில் குளிர்ந்த துணியை வைக்கவும்.
2. **உடனே தண்ணீர் குடிக்கவும்:** நீர்ச்சத்து குறைபாட்டால் தலைவலி வரலாம், 2 டம்ளர் தண்ணீர் குடிக்கவும்.
3. **சுய மருத்துவம் வேண்டாம்:** மருத்துவர் அனுமதி இல்லாமல் எந்த வலி நிவாரணி மாத்திரைகளையும் சாப்பிடக் கூடாது.
4. ⚠️ **எச்சரிக்கை:** தலைவலியுடன் கண் மங்கலாக தெரிவது அல்லது முகத்தில் வீக்கம் இருந்தால், உடனடியாக ஆரம்ப சுகாதார நிலையத்திற்கு சென்று இரத்த அழுத்தத்தை (BP) பரிசோதிக்கவும்.''',
    },
    'nausea': {
      'keywords': ['nausea', 'vomit', 'vomiting', 'morning sickness', 'வாந்தி', 'மயக்கம்', 'குமட்டல்'],
      'en': '''🍋 **Managing Nausea & Morning Sickness**

1. **Small Frequent Meals:** Never leave your stomach empty. Eat a light meal every 2–3 hours.
2. **Bedside Crackers:** Eat a dry biscuit or rusk before getting out of bed in the morning.
3. **Ginger & Lemon:** Sip warm ginger tea or fresh lemon water to soothe stomach acidity.
4. **Avoid Triggers:** Stay away from strong cooking odors, oily fried foods, and heavy spices.''',
      'ta': '''🍋 **கர்ப்ப கால வாந்தி & மயக்கத்திற்கான தீர்வுகள்**

1. **சிறிய இடைவெளியில் உணவு:** வெறும் வயிற்றில் இருக்க வேண்டாம்; 2-3 மணி நேரத்திற்கு ஒரு முறை சிறிது சத்தான உணவு சாப்பிடவும்.
2. **காலையில் பிஸ்கட்:** காலையில் படுக்கையை விட்டு எழுந்திருக்கும் முன் ஒரு உலர் பிஸ்கட் அல்லது ரஸ்க் சாப்பிடவும்.
3. **இஞ்சி & எலுமிச்சை:** இஞ்சி டீ அல்லது எலுமிச்சை சாறு அருந்துவது வாந்தி உணர்வை கட்டுப்படுத்தும்.
4. **கார உணவுகள் தவிர்த்தல்:** அதிக எண்ணெய், மசாலா மற்றும் வாசனை மிகுந்த உணவுகளை தவிர்க்கவும்.''',
    },
    'fever_cold': {
      'keywords': ['fever', 'cold', 'cough', 'flu', 'காய்ச்சல்', 'இருமல்', 'சளி'],
      'en': '''🌡️ **Cold, Cough & Fever Precautions**

1. **Warm Saline Gargle:** Gargle with warm salt water for throat irritation.
2. **Steam Inhalation:** Inhale plain steam for 5–10 minutes to clear nasal congestion.
3. **Rest & Fluids:** Drink warm water, clear soups, and keep yourself warm.
4. ⚠️ **Doctor Consultation:** If your temperature exceeds 100°F (37.8°C), visit your PHC doctor immediately. Do not consume over-the-counter antibiotics.''',
      'ta': '''🌡️ **சளி, இருமல் மற்றும் காய்ச்சல் முன்னெச்சரிக்கைகள்**

1. **உப்பு நீர் கொப்பளிப்பு:** தொண்டை கரகரப்பிற்கு வெதுவெதுப்பான உப்பு நீரில் வாய் கொப்பளிக்கவும்.
2. **நீராவி பிடித்தல்:** மூக்கடைப்பிற்கு 5-10 நிமிடங்கள் சாதாரண நீராவி பிடிக்கவும்.
3. **சூடான திரவங்கள்:** மிதமான சுடுதண்ணீர், சூப் குடித்து நன்கு ஓய்வெடுக்கவும்.
4. ⚠️ **மருத்துவரை அணுகவும்:** உடல் வெப்பநிலை 100°F க்கு மேல் இருந்தால் உடனே ஆரம்ப சுகாதார நிலைய மருத்துவரிடம் ஆலோசனை பெறவும். சுய மருத்துவம் செய்ய வேண்டாம்.''',
    },
  };

  // Layer 3: ASHA Directory Table
  static const List<Map<String, dynamic>> ashaDirectory = [
    {
      'village': 'vellanur',
      'village_ta': 'வெள்ளனூர்',
      'aliases': ['vellanur', 'velanur', 'vellanoor', 'வெள்ளனூர்', 'வெள்ளனுர்'],
      'worker_name': 'Selvi K.',
      'worker_name_ta': 'செல்வி கே.',
      'designation': 'Village Health Nurse (VHN) / ASHA Worker',
      'designation_ta': 'கிராம சுகாதார செவிலியர் / ஆஷா பணியாளர்',
      'phone': '+91 94421 88301',
      'phc': 'Vellanur Primary Health Centre, Pudukkottai',
      'phc_ta': 'வெள்ளனூர் அரசு ஆரம்ப சுகாதார நிலையம், புதுக்கோட்டை',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'keeranur',
      'village_ta': 'கீரனூர்',
      'aliases': ['keeranur', 'kiranur', 'keeranoor', 'கீரனூர்', 'கீரனுர்'],
      'worker_name': 'Meena R.',
      'worker_name_ta': 'மீனா ஆர்.',
      'designation': 'Village Health Nurse (VHN)',
      'designation_ta': 'கிராம சுகாதார செவிலியர்',
      'phone': '+91 94421 88302',
      'phc': 'Keeranur Community Health Centre, Pudukkottai',
      'phc_ta': 'கீரனூர் சமுதாய சுகாதார நிலையம்',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'annavasal',
      'village_ta': 'அன்னவாசல்',
      'aliases': ['annavasal', 'anavasal', 'அன்னவாசல்'],
      'worker_name': 'Lakshmi S.',
      'worker_name_ta': 'லட்சுமி எஸ்.',
      'designation': 'ASHA Facilitator / VHN',
      'designation_ta': 'ஆஷா ஒருங்கிணைப்பாளர்',
      'phone': '+91 94421 88303',
      'phc': 'Annavasal Upgraded Primary Health Centre',
      'phc_ta': 'அன்னவாசல் மேம்படுத்தப்பட்ட அரசு ஆரம்ப சுகாதார நிலையம்',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'viralimalai',
      'village_ta': 'விராலிமலை',
      'aliases': ['viralimalai', 'viralimalay', 'விராலிமலை'],
      'worker_name': 'Revathi M.',
      'worker_name_ta': 'ரேவதி எம்.',
      'designation': 'Village Health Nurse (VHN)',
      'designation_ta': 'கிராம சுகாதார செவிலியர்',
      'phone': '+91 94421 88304',
      'phc': 'Viralimalai Government Hospital & PHC',
      'phc_ta': 'விராலிமலை அரசு மருத்துவமனை & PHC',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'pudukkottai',
      'village_ta': 'புதுக்கோட்டை',
      'aliases': ['pudukkottai', 'pudukottai', 'pudukai', 'புதுக்கோட்டை'],
      'worker_name': 'Thangam P.',
      'worker_name_ta': 'தங்கம் பி.',
      'designation': 'Urban Primary Health Worker / ASHA',
      'designation_ta': 'நகர்ப்புற சுகாதார பணியாளர் / ஆஷா',
      'phone': '+91 94421 88305',
      'phc': 'Pudukkottai Urban PHC & Medical College Hospital',
      'phc_ta': 'புதுக்கோட்டை அரசு மருத்துவக் கல்லூரி மருத்துவமனை & நகர்ப்புற PHC',
      'timings': 'Mon - Sat: 9:00 AM - 5:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 5:00',
    },
    {
      'village': 'alangudi',
      'village_ta': 'ஆலங்குடி',
      'aliases': ['alangudi', 'alankudi', 'ஆலங்குடி'],
      'worker_name': 'Kalaiyarasi T.',
      'worker_name_ta': 'கலையரசி டி.',
      'designation': 'Village Health Nurse (VHN)',
      'designation_ta': 'கிராம சுகாதார செவிலியர்',
      'phone': '+91 94421 88306',
      'phc': 'Alangudi Taluk Hospital & PHC',
      'phc_ta': 'ஆலங்குடி அரசு தாலுகா மருத்துவமனை',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'gandarvakottai',
      'village_ta': 'கந்தர்வக்கோட்டை',
      'aliases': ['gandarvakottai', 'gandarvakotta', 'கந்தர்வக்கோட்டை'],
      'worker_name': 'Parvathi N.',
      'worker_name_ta': 'பார்வதி என்.',
      'designation': 'Village Health Nurse (VHN)',
      'designation_ta': 'கிராம சுகாதார செவிலியர்',
      'phone': '+91 94421 88307',
      'phc': 'Gandarvakottai Primary Health Centre',
      'phc_ta': 'கந்தர்வக்கோட்டை அரசு ஆரம்ப சுகாதார நிலையம்',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'aranthangi',
      'village_ta': 'அறந்தாங்கி',
      'aliases': ['aranthangi', 'aranthangy', 'அறந்தாங்கி'],
      'worker_name': 'Bhuvaneshwari A.',
      'worker_name_ta': 'புவனேஸ்வரி ஏ.',
      'designation': 'Village Health Nurse (VHN)',
      'designation_ta': 'கிராம சுகாதார செவிலியர்',
      'phone': '+91 94421 88308',
      'phc': 'Aranthangi Government District Headquarters Hospital',
      'phc_ta': 'அறந்தாங்கி அரசு தலைமை மருத்துவமனை',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'karambakkudi',
      'village_ta': 'கறம்பக்குடி',
      'aliases': ['karambakkudi', 'karambakudi', 'கறம்பக்குடி'],
      'worker_name': 'Saranya D.',
      'worker_name_ta': 'சரண்யா டி.',
      'designation': 'ASHA Public Health Worker',
      'designation_ta': 'ஆஷா களப்பணியாளர்',
      'phone': '+91 94421 88309',
      'phc': 'Karambakkudi Primary Health Centre',
      'phc_ta': 'கறம்பக்குடி அரசு ஆரம்ப சுகாதார நிலையம்',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'illuppur',
      'village_ta': 'இலுப்பூர்',
      'aliases': ['illuppur', 'iluppur', 'இலுப்பூர்'],
      'worker_name': 'Valli M.',
      'worker_name_ta': 'வள்ளி எம்.',
      'designation': 'Village Health Nurse (VHN)',
      'designation_ta': 'கிராம சுகாதார செவிலியர்',
      'phone': '+91 94421 88310',
      'phc': 'Illuppur Government Taluk Hospital & PHC',
      'phc_ta': 'இலுப்பூர் அரசு தாலுகா மருத்துவமனை',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
    {
      'village': 'thirumayam',
      'village_ta': 'திருமயம்',
      'aliases': ['thirumayam', 'tirumayam', 'திருமயம்'],
      'worker_name': 'Muthulakshmi R.',
      'worker_name_ta': 'முத்துலட்சுமி ஆர்.',
      'designation': 'Village Health Nurse (VHN)',
      'designation_ta': 'கிராம சுகாதார செவிலியர்',
      'phone': '+91 94421 88311',
      'phc': 'Thirumayam Primary Health Centre',
      'phc_ta': 'திருமயம் அரசு ஆரம்ப சுகாதார நிலையம்',
      'timings': 'Mon - Sat: 9:00 AM - 4:00 PM',
      'timings_ta': 'திங்கள் - சனி: காலை 9:00 - மாலை 4:00',
    },
  ];

  // Layer 2: Chitchat Responses Table
  static const Map<String, Map<String, String>> chitchatTable = {
    'GREETING_HELLO': {
      'en': 'Hello! Vanakkam! I am your PitPulse offline maternal health assistant. How can I help you and your baby today? Feel free to ask about your pregnancy diet, vitals, doctor visits, or local ASHA support.',
      'ta': 'வணக்கம்! நான் உங்கள் பிட்பல்ஸ் (PitPulse) தாய்-சேய் நல உதவியாளர். இன்று உங்களுக்கு நான் எவ்வாறு உதவ வேண்டும்? உங்கள் கர்ப்ப கால உணவு, ரத்த அழுத்தம், மருத்துவ பரிசோதனை அல்லது ஆஷா பணியாளர் விவரங்களை நீங்கள் கேட்கலாம்.',
    },
    'GREETING_STATUS': {
      'en': 'I am doing well, thank you! Ready to support you with your pregnancy health, diet, or ASHA contact details. How are you and your baby feeling today?',
      'ta': 'நான் மிகவும் நலமாக உள்ளேன், நன்றி! உங்கள் கர்ப்ப கால நலம், உணவு முறை அல்லது ஆஷா விவரங்களுக்கு உதவ தயாராக உள்ளேன். நீங்கள் மற்றும் உங்கள் குழந்தை இன்று எப்படி உள்ளீர்கள்?',
    },
    'GREETING_THANKS': {
      'en': 'You are most welcome! Take good care of yourself and your little one. Drink plenty of water and rest well. Let me know if you need any other guidance!',
      'ta': 'மிக்க மகிழ்ச்சி! நன்றி! உங்கள் உடல் நலனையும் குழந்தையின் வளர்ச்சியையும் நன்றாக கவனித்துக் கொள்ளுங்கள். போதுமான தண்ணீர் குடித்து நன்கு ஓய்வெடுக்கவும். வேறு ஏதேனும் தகவல் தேவைப்பட்டால் தயங்காமல் கேளுங்கள்!',
    },
    'GREETING_BYE': {
      'en': 'Take care! Wishing you and your baby good health and happiness. Feel free to reach out anytime!',
      'ta': 'நலமாக இருங்கள்! உங்களுக்கும் உங்கள் குழந்தைக்கும் ஆரோக்கியமும் மகிழ்ச்சியும் கிடைக்க வாழ்த்துகள். எப்போது வேண்டுமானாலும் என்னிடம் கேட்கலாம்!',
    },
    'CHITCHAT_GENERAL': {
      'en': 'Vanakkam! I am here to help you through every step of your pregnancy journey. What would you like to know today?',
      'ta': 'வணக்கம்! உங்கள் கர்ப்ப கால பயணத்தின் ஒவ்வொரு நிலையிலும் வழிகாட்ட நான் இங்கே உள்ளேன். இன்று நீங்கள் என்ன தெரிந்து கொள்ள விரும்புகிறீர்கள்?',
    },
  };

  // Layer 3: Emergency Protocol Table
  static const Map<String, String> emergencyProtocols = {
    'en': '''🚨 **CRITICAL EMERGENCY RED ALERT (உடனடி அவசர எச்சரிக்கை)**

⚠️ **Immediate Medical Attention Required:**
The symptoms you described indicate a potential obstetrical danger sign that requires immediate clinical evaluation.

**Action Steps Right Now:**
1. 🚑 **Call 108 Immediately** for free emergency ambulance transport.
2. 🏥 **Proceed to the Nearest Hospital / PHC:** Do not wait or self-medicate. Lie down on your left side while transport is arranged.
3. 📞 **Alert Your ASHA Worker / VHN:** Inform your family and community health worker immediately.

*Note: PitPulse is an offline educational screener. Please seek direct in-person medical care immediately.*''',

    'ta': '''🚨 **அவசர மருத்துவ எச்சரிக்கை (Instant Emergency Red Alert)**

⚠️ **உடனடி மருத்துவ கவனிப்பு அவசியம்:**
நீங்கள் கூறிய அறிகுறிகள் கர்ப்ப கால அவசர சிகிச்சை தேவைப்படும் எச்சரிக்கை அறிகுறியாகும்.

**உடனடி நடவடிக்கைகள்:**
1. 🚑 **உடனே 108 ஆம்புலன்ஸை அழைக்கவும்** (இலவச அவசர ஊர்தி).
2. 🏥 **அருகிலுள்ள அரசு மருத்துவமனை / ஆரம்ப சுகாதார நிலையத்திற்கு (PHC) செல்லவும்:** சுயமாக மாத்திரை சாப்பிட வேண்டாம். இடது பக்கமாக படுத்து ஓய்வெடுங்கள்.
3. 📞 **உங்கள் ஆஷா பணியாளர் / கிராம சுகாதார செவிலியருக்கு உடனடியாக தகவல் தெரிவிக்கவும்.**

*குறிப்பு: பிட்பல்ஸ் ஒரு தகவல் வழிகாட்டி மட்டுமே. காலதாமதம் செய்யாமல் உடனடியாக மருத்துவமனைக்கு செல்லவும்.*''',
  };
}

/// Central Agentic Orchestration Layer with Multi-Turn Context Stitching
class LocalAgenticRagController {
  /// Evaluates patient input using the Three-Layer Processing Hierarchy with Chat History
  static LocalAgentState evaluate({
    required String rawText,
    List<String> chatHistory = const [],
    int? primaryIntentId,
    int gestationalWeeks = 12,
  }) {
    final lang = _detectLanguage(rawText);
    final state = LocalAgentState(
      rawText: rawText,
      language: lang,
      chatHistory: chatHistory,
      primaryIntentId: primaryIntentId ?? _estimateIntentId(rawText),
    );

    // =========================================================================
    // LAYER 1: The Safety Override (Restricted Content Check)
    // =========================================================================
    if (_checkLayer1SafetyOverride(rawText)) {
      state.executedTools.add('Tool_Layer1_Safety_Intercept');
      state.synthesizedResponse = lang == 'ta'
          ? 'என்னால் அதற்குப் பதிலளிக்க முடியாது.'
          : 'I cannot answer that.';
      return state;
    }

    // =========================================================================
    // CONTEXT STITCHING ENGINE: Semantic Health Keywords Override
    // =========================================================================
    // If the classifier defaulted to a generic greeting or fallback, but the text
    // contains high-value health terms (stress, sleep, fatigue, headache, nausea),
    // override and route immediately to the General Health FAQ tool!
    final matchedFaqKey = _matchGeneralHealthFaq(rawText);
    if (matchedFaqKey != null) {
      state.executedTools.add('Tool_General_Health_FAQ');
      state.primaryIntentId = 8; // GENERAL_MED_QA
      state.synthesizedResponse = toolGeneralHealthFaq(
        topicKey: matchedFaqKey,
        language: lang,
      );
      return state;
    }

    // =========================================================================
    // LAYER 2: Universal Conversational Flexibility (Everyday Chats / Small Talk)
    // =========================================================================
    final chitchatCategory = _detectChitchatCategory(rawText, state.primaryIntentId);
    if (chitchatCategory != null) {
      state.executedTools.add('Tool_Conversational_Chitchat');
      state.primaryIntentId = max(state.primaryIntentId, 10);
      state.synthesizedResponse = toolConversationalChitchat(
        category: chitchatCategory,
        language: lang,
      );
      return state;
    }

    // =========================================================================
    // LAYER 3: Target Semantic Retrieval (Medical Agentic RAG)
    // =========================================================================
    // Step 1: Emergency Risk Scanner (High Priority)
    final isEmergency = toolEmergencyTriage(rawText);
    state.isEmergency = isEmergency;

    // Step 2: Multi-Turn History Stitching (Entity Scraping across Turns)
    // Carry over village or milestone month from chatHistory if not in current turn
    String? detectedVillage = _extractVillageEntity(rawText);
    int? milestoneMonth = _extractMilestoneMonth(rawText);

    if (detectedVillage == null && chatHistory.isNotEmpty) {
      for (final pastMsg in chatHistory.reversed) {
        final found = _extractVillageEntity(pastMsg);
        if (found != null) {
          detectedVillage = found;
          state.extractedEntities.add('Stitched Village: $detectedVillage');
          break;
        }
      }
    }

    if (milestoneMonth == null && chatHistory.isNotEmpty) {
      for (final pastMsg in chatHistory.reversed) {
        final found = _extractMilestoneMonth(pastMsg);
        if (found != null) {
          milestoneMonth = found;
          state.extractedEntities.add('Stitched Milestone: Month $milestoneMonth');
          break;
        }
      }
    }

    final finalMonth = milestoneMonth ?? ((gestationalWeeks / 4.3).clamp(1, 9).round());

    if (detectedVillage != null) {
      state.extractedEntities.add('Village: $detectedVillage');
    }
    if (_hasMilestoneQuery(rawText) || milestoneMonth != null) {
      state.extractedEntities.add('Milestone: Month $finalMonth');
    }

    // Step 3: Tool Execution (Parallel / Sequential Multi-Tool Pipeline)
    Map<String, dynamic>? medicalData;
    Map<String, dynamic>? ashaData;

    if (isEmergency) {
      state.executedTools.add('Tool_Emergency_Triage');
    }

    // Trigger Tool_Maternal_Timeline_Lookup if diet or pregnancy progress query
    if (_isDietOrMilestoneQuery(rawText, state.primaryIntentId) || (milestoneMonth != null && _isFoodQuery(rawText))) {
      state.executedTools.add('Tool_Maternal_Timeline_Lookup');
      medicalData = toolMaternalTimelineLookup(
        timelineMonths: finalMonth,
        language: lang,
      );
      state.retrievedMedicalContext = medicalData;
    }

    // Trigger Tool_ASHA_Directory_Fetch if village detected or ASHA mentioned
    if (detectedVillage != null || _isAshaQuery(rawText, state.primaryIntentId)) {
      state.executedTools.add('Tool_ASHA_Directory_Fetch');
      ashaData = toolAshaDirectoryFetch(
        villageName: detectedVillage ?? 'vellanur',
        language: lang,
      );
      state.retrievedAshaContext = ashaData;
    }

    if (state.executedTools.isEmpty) {
      state.executedTools.add('Tool_Semantic_RAG_Fallback');
    }

    // Step 4: Output Assembly & TTS Synthesis
    state.synthesizedResponse = _synthesizeResponse(
      state: state,
      isEmergency: isEmergency,
      medicalData: medicalData,
      ashaData: ashaData,
      month: finalMonth,
      language: lang,
    );

    return state;
  }

  // ===========================================================================
  // LOCAL TOOLS (SQL Data Matrix Capabilities)
  // ===========================================================================

  /// Tool 1: Emergency Triage Scanner
  static bool toolEmergencyTriage(String text) {
    final lower = text.toLowerCase();
    const emergencyTokens = [
      'severe bleeding',
      'bleeding',
      'vaginal bleeding',
      'loss of blood',
      'blood discharge',
      'severe stomach pain',
      'severe cramps',
      'extreme pain',
      'heavy bleeding',
      'fluid leak',
      'water broke',
      'convulsion',
      'fits',
      'இரத்தப்போக்கு',
      'இரத்தக்கசிவு',
      'அதிக இரத்தம்',
      'கடுமையான வலி',
      'கடுமையான வயிற்று வலி',
      'வயிற்றில் பலத்த வலி',
      'வலிப்பு',
    ];

    for (final token in emergencyTokens) {
      if (lower.contains(token)) {
        return true;
      }
    }
    return false;
  }

  /// Tool 2: Maternal Timeline Lookup (Pregnancy Guidelines Table)
  static Map<String, dynamic> toolMaternalTimelineLookup({
    required int timelineMonths,
    required String language,
  }) {
    final isTa = language == 'ta';
    final month = timelineMonths.clamp(1, 9);

    if (isTa) {
      if (month <= 3) {
        return {
          'month': month,
          'title': '$monthவது மாத கர்ப்ப கால உணவு முறை & ஊட்டச்சத்து வழிகாட்டல்',
          'core_nutrients': 'போலிக் அமிலம் (Folic Acid), இரும்புச்சத்து (Iron), வைட்டமின் B6',
          'foods': [
            'கீரைகள் (முருங்கைக்கீரை, பசலைக்கீரை), பருப்பு வகைகள், சுண்டல்',
            'பேரீச்சம்பழம், மாதுளை, உலர் திராட்சை (இரத்த சோகை தடுக்கும்)',
            'பால், தயிர், முட்டை, ராகி களி அல்லது கஞ்சி',
            'இளநீர், எலுமிச்சை சாறு, மோர் (வாந்தி மற்றும் நீர்ச்சத்து குறைபாட்டிற்கு)',
          ],
          'precautions': 'பப்பாளி, அன்னாசி, அதிக காரம், எண்ணெய் பலகாரங்களை தவிர்க்கவும். வெறும் வயிற்றில் இருக்க வேண்டாம் — 2-3 மணி நேரத்திற்கு ஒரு முறை சிறிது சத்தான உணவை உட்கொள்ளவும்.',
        };
      } else if (month <= 6) {
        return {
          'month': month,
          'title': '$monthவது மாத கர்ப்ப கால உணவு & எலும்பு வளர்ச்சி வழிகாட்டல்',
          'core_nutrients': 'கால்சியம் (Calcium), புரதம் (Protein), இரும்புச்சத்து',
          'foods': [
            'பால், தயிர், கேழ்வரகு (ராகி), எள், சுண்டைக்காய்',
            'முட்டை, கொண்டைக்கடலை, பாசிப்பயறு, சோயா',
            'முருங்கைக்கீரை, மாதுளை, பீட்ரூட்',
            'ஆரஞ்சு, நெல்லிக்காய் (வைட்டமின் சி இரும்புச்சத்தை உறிஞ்ச உதவும்)',
          ],
          'precautions': 'அதிக இனிப்பு, துரித உணவுகளை தவிர்க்கவும். தினமும் 2.5-3 லிட்டர் தண்ணீர் குடிக்கவும்.',
        };
      } else {
        return {
          'month': month,
          'title': '$monthவது மாத பிரசவ கால தயாரிப்பு & சத்தான உணவு முறை',
          'core_nutrients': 'நார்ச்சத்து (Fiber), ஒமேகா-3 கொழுப்பு அமிலங்கள், ஆற்றல்',
          'foods': [
            'முழு தானியங்கள், ஓட்ஸ், பருப்பு சாதம்',
            'கொய்யா, ஆப்பிள், பச்சை காய்கறிகள் (மலச்சிக்கல் தடுக்கும்)',
            'பாதாம், அக்ரூட் (வால்நட்), ஆளி விதை',
            'இளநீர், சூப், மோர்',
          ],
          'precautions': 'அதிக உப்பு மற்றும் இரவு நேர கனமான உணவுகளை தவிர்க்கவும். இடது பக்கமாக ஒருக்களித்து படுக்கவும்.',
        };
      }
    } else {
      if (month <= 3) {
        return {
          'month': month,
          'title': 'Month $month Pregnancy Diet & Clinical Nutrition Protocol',
          'core_nutrients': 'Folic Acid, Iron, Vitamin B6, Gentle Hydration',
          'foods': [
            'Folic Acid: Spinach, moringa greens, lentils, sprouted pulses',
            'Iron: Pomegranate, dates, raisins, boiled eggs, chickpeas',
            'Calcium & Protein: Milk, curd, paneer, ragi porridge',
            'Hydration: Tender coconut, buttermilk, ginger tea for morning sickness',
          ],
          'precautions': 'Avoid unripe papaya, pineapple, excess caffeine, and deep-fried oily foods. Eat small, frequent meals every 2-3 hours.',
        };
      } else if (month <= 6) {
        return {
          'month': month,
          'title': 'Month $month Pregnancy Diet & Bone Development Protocol',
          'core_nutrients': 'Calcium, Protein, Iron, Vitamin C',
          'foods': [
            'Calcium: Milk, yogurt, ragi, sesame seeds, dark leafy greens',
            'Protein: Boiled eggs, legumes, beans, paneer',
            'Iron: Beetroot, dates, moringa, jaggery with citrus fruits for absorption',
            'Hydration: 8-10 glasses of clean drinking water daily',
          ],
          'precautions': 'Limit high-sugar snacks and processed items. Maintain consistent maternal walking.',
        };
      } else {
        return {
          'month': month,
          'title': 'Month $month Third Trimester Nutrition & Delivery Preparation',
          'core_nutrients': 'Dietary Fiber, Omega-3 Fatty Acids, High Energy',
          'foods': [
            'Energy & Digestion: Whole wheat, oats, lentils, green vegetables',
            'Constipation Relief: Guava, apples, papaya (ripe only in moderation if cleared), greens',
            'Fetal Brain Growth: Soaked almonds, walnuts, flaxseeds',
            'Fluids: Tender coconut, vegetable soups, buttermilk',
          ],
          'precautions': 'Avoid excess salt to prevent severe foot swelling. Sleep on your left side.',
        };
      }
    }
  }

  /// Tool 3: ASHA Directory Fetch (Geographical Entity / Positional Query)
  static Map<String, dynamic> toolAshaDirectoryFetch({
    required String villageName,
    required String language,
  }) {
    final query = villageName.toLowerCase().trim();

    // 1. Direct match or alias match
    for (final record in LocalHealthKnowledgeDatabase.ashaDirectory) {
      final List<String> aliases = (record['aliases'] as List<dynamic>).cast<String>();
      if (aliases.any((alias) => query.contains(alias) || alias.contains(query))) {
        return record;
      }
    }

    // 2. Fuzzy match based on Levenshtein-like character overlap
    Map<String, dynamic>? bestMatch;
    int maxOverlap = 0;

    for (final record in LocalHealthKnowledgeDatabase.ashaDirectory) {
      final vName = (record['village'] as String).toLowerCase();
      int overlap = 0;
      for (int i = 0; i < query.length - 2; i++) {
        final sub = query.substring(i, i + 3);
        if (vName.contains(sub)) {
          overlap++;
        }
      }
      if (overlap > maxOverlap) {
        maxOverlap = overlap;
        bestMatch = record;
      }
    }

    if (bestMatch != null && maxOverlap >= 2) {
      return bestMatch;
    }

    // Default fallback to central primary village
    return LocalHealthKnowledgeDatabase.ashaDirectory.first;
  }

  /// Tool 4: Conversational Chitchat (Small Talk Router)
  static String toolConversationalChitchat({
    required String category,
    required String language,
  }) {
    final isTa = language == 'ta';
    final entry = LocalHealthKnowledgeDatabase.chitchatTable[category] ??
        LocalHealthKnowledgeDatabase.chitchatTable['GREETING_HELLO']!;

    return isTa ? entry['ta']! : entry['en']!;
  }

  /// Tool 5: General Health FAQ Tool (Handles Freeform Wellness Questions)
  static String toolGeneralHealthFaq({
    required String topicKey,
    required String language,
  }) {
    final isTa = language == 'ta';
    final faq = LocalHealthKnowledgeDatabase.generalHealthFaq[topicKey];
    if (faq == null) {
      return isTa
          ? 'உங்கள் ஆரோக்கிய சந்தேகங்களுக்கு உங்கள் பகுதி ஆஷா பணியாளர் அல்லது ஆரம்ப சுகாதார நிலைய மருத்துவரை அணுகவும்.'
          : 'For medical questions, please consult your assigned ASHA worker or local Primary Health Centre (PHC) doctor.';
    }
    return isTa ? faq['ta'] as String : faq['en'] as String;
  }

  // ===========================================================================
  // INTERNAL HELPERS & AGENTIC LOGIC
  // ===========================================================================

  /// Layer 1 Safety Filter
  static bool _checkLayer1SafetyOverride(String text) {
    final lower = text.toLowerCase();

    for (final pattern in LocalHealthKnowledgeDatabase.restrictedPatternsEn) {
      if (lower.contains(pattern)) return true;
    }
    for (final pattern in LocalHealthKnowledgeDatabase.restrictedPatternsTa) {
      if (lower.contains(pattern)) return true;
    }
    return false;
  }

  /// Matches text against General Health FAQ keywords (e.g. stress, sleep, fatigue)
  static String? _matchGeneralHealthFaq(String text) {
    final lower = text.toLowerCase();

    for (final entry in LocalHealthKnowledgeDatabase.generalHealthFaq.entries) {
      final keywords = (entry.value['keywords'] as List<dynamic>).cast<String>();
      for (final kw in keywords) {
        if (lower.contains(kw)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// Detects casual small talk categories (Layer 2)
  static String? _detectChitchatCategory(String text, int primaryIntentId) {
    final lower = text.toLowerCase().trim();

    final helloPatterns = [
      'hello',
      'hi',
      'hey',
      'vanakkam',
      'வணக்கம்',
      'good morning',
      'good afternoon',
      'good evening',
    ];

    final statusPatterns = [
      'how are you',
      'how r u',
      'how are you today',
      'nalla irukkeengala',
      'nallா irukingala',
      'நல்லா இருக்கீங்களா',
      'எப்படி இருக்கீங்க',
      'eppadi irukkeenga',
    ];

    final thanksPatterns = [
      'thank you',
      'thanks',
      'thank you bro',
      'thx',
      'nandri',
      'நன்றி',
      'ரொம்ப நன்றி',
    ];

    final byePatterns = [
      'bye',
      'goodbye',
      'see you',
      'போயிட்டு வரேன்',
      'போய் வருகிறேன்',
    ];

    // 1. Status Check
    for (final p in statusPatterns) {
      if (lower.contains(p)) return 'GREETING_STATUS';
    }

    // 2. Thanks Check
    for (final p in thanksPatterns) {
      if (lower.contains(p)) return 'GREETING_THANKS';
    }

    // 3. Bye Check
    for (final p in byePatterns) {
      if (lower.contains(p)) return 'GREETING_BYE';
    }

    // 4. Exact or near-exact Hello Check
    final isHelloMatch = helloPatterns.any((p) => lower == p || lower.startsWith('$p '));

    final hasHealthKeywords = lower.contains('eat') ||
        lower.contains('diet') ||
        lower.contains('food') ||
        lower.contains('month') ||
        lower.contains('pregnant') ||
        lower.contains('pain') ||
        lower.contains('bleed') ||
        lower.contains('doctor') ||
        lower.contains('asha') ||
        lower.contains('vellanur') ||
        lower.contains('stress') ||
        lower.contains('tension') ||
        lower.contains('sleep') ||
        lower.contains('fatigue') ||
        lower.contains('உணவு') ||
        lower.contains('மாதம்') ||
        lower.contains('வலி') ||
        lower.contains('கவலை');

    if (isHelloMatch && !hasHealthKeywords) {
      return 'GREETING_HELLO';
    }

    if (primaryIntentId >= 10 && !hasHealthKeywords) {
      return 'CHITCHAT_GENERAL';
    }

    return null;
  }

  /// Extracts numeric milestone month (1-9) from English, Tamil, or Tanglish
  static int? _extractMilestoneMonth(String text) {
    final lower = text.toLowerCase();

    final regDigit = RegExp(r'(\d+)\s*(?:st|nd|rd|th)?\s*(?:month|months|மாதம்|மாசம்|maasam|masam)');
    final match = regDigit.firstMatch(lower);
    if (match != null) {
      final val = int.tryParse(match.group(1)!);
      if (val != null && val >= 1 && val <= 9) return val;
    }

    if (lower.contains('first month') || lower.contains('1st month') || lower.contains('oru maasam') || lower.contains('1 மாசம்')) return 1;
    if (lower.contains('second month') || lower.contains('2nd month') || lower.contains('rendu maasam') || lower.contains('2 மாசம்')) return 2;
    if (lower.contains('third month') || lower.contains('3rd month') || lower.contains('3 months') || lower.contains('moonu maasam') || lower.contains('3 மாசம்') || lower.contains('3வது மாதம்')) return 3;
    if (lower.contains('fourth month') || lower.contains('4th month') || lower.contains('4 months') || lower.contains('naalu maasam') || lower.contains('4 மாசம்') || lower.contains('4வது மாதம்')) return 4;
    if (lower.contains('fifth month') || lower.contains('5th month') || lower.contains('5 months') || lower.contains('ainthu maasam') || lower.contains('5 மாசம்') || lower.contains('5வது மாதம்')) return 5;
    if (lower.contains('sixth month') || lower.contains('6th month') || lower.contains('6 months') || lower.contains('aaru maasam') || lower.contains('6 மாசம்') || lower.contains('6வது மாதம்')) return 6;
    if (lower.contains('seventh month') || lower.contains('7th month') || lower.contains('7 months') || lower.contains('yezhu maasam') || lower.contains('7 மாசம்') || lower.contains('7வது மாதம்')) return 7;
    if (lower.contains('eighth month') || lower.contains('8th month') || lower.contains('8 months') || lower.contains('ettu maasam') || lower.contains('8 மாசம்') || lower.contains('8வது மாதம்')) return 8;
    if (lower.contains('ninth month') || lower.contains('9th month') || lower.contains('9 months') || lower.contains('onpathu maasam') || lower.contains('9 மாசம்') || lower.contains('9வது மாதம்')) return 9;

    return null;
  }

  /// Extracts village name entity from string
  static String? _extractVillageEntity(String text) {
    final lower = text.toLowerCase();

    for (final record in LocalHealthKnowledgeDatabase.ashaDirectory) {
      final List<String> aliases = (record['aliases'] as List<dynamic>).cast<String>();
      for (final alias in aliases) {
        if (lower.contains(alias)) {
          return record['village'] as String;
        }
      }
    }
    return null;
  }

  static bool _hasMilestoneQuery(String text) {
    final lower = text.toLowerCase();
    return lower.contains('month') ||
        lower.contains('maasam') ||
        lower.contains('மாதம்') ||
        lower.contains('மாசம்') ||
        lower.contains('week') ||
        lower.contains('வாரம்');
  }

  static bool _isFoodQuery(String text) {
    final lower = text.toLowerCase();
    return lower.contains('eat') ||
        lower.contains('diet') ||
        lower.contains('food') ||
        lower.contains('nutrition') ||
        lower.contains('saapadanum') ||
        lower.contains('sappad') ||
        lower.contains('உணவு') ||
        lower.contains('சாப்பிட') ||
        lower.contains('பத்தியம்');
  }

  static bool _isDietOrMilestoneQuery(String text, int intentId) {
    final lower = text.toLowerCase();
    return intentId == 1 ||
        _isFoodQuery(lower) ||
        lower.contains('month') ||
        lower.contains('மாதம்');
  }

  static bool _isAshaQuery(String text, int intentId) {
    final lower = text.toLowerCase();
    return intentId == 2 ||
        lower.contains('asha') ||
        lower.contains('vhn') ||
        lower.contains('nurse') ||
        lower.contains('worker') ||
        lower.contains('health worker') ||
        lower.contains('village') ||
        lower.contains('ஆஷா') ||
        lower.contains('செவிலியர்') ||
        lower.contains('பணியாளர்') ||
        lower.contains('ஊர்');
  }

  static int _estimateIntentId(String text) {
    final lower = text.toLowerCase();
    if (toolEmergencyTriage(lower)) return 0;
    if (_isDietOrMilestoneQuery(lower, -1)) return 1;
    if (_isAshaQuery(lower, -1)) return 2;
    if (lower.contains('bp') || lower.contains('blood pressure') || lower.contains('vital') || lower.contains('pulse') || lower.contains('heart rate') || lower.contains('temperature') || lower.contains('weight') || lower.contains('இரத்த அழுத்தம்')) return 3;
    if (lower.contains('doctor') || lower.contains('consult') || lower.contains('மருத்துவர்') || lower.contains('டாக்டர்')) return 4;
    if (lower.contains('week') || lower.contains('edd') || lower.contains('due date') || lower.contains('gestat') || lower.contains('growth') || lower.contains('lmp') || lower.contains('baby') || lower.contains('வாரம்') || lower.contains('வளர்ச்சி')) return 5;
    if (lower.contains('alert') || lower.contains('warning') || lower.contains('danger') || lower.contains('screening') || lower.contains('அபாயம்') || lower.contains('எச்சரிக்கை')) return 6;
    if (lower.contains('visit') || lower.contains('history') || lower.contains('வருகை')) return 7;
    if (_matchGeneralHealthFaq(lower) != null) return 8; // GENERAL_MED_QA
    return 10; // Casual / Chitchat
  }

  static String _detectLanguage(String text) {
    final tamilRegExp = RegExp(r'[\u0B80-\u0BFF]');
    if (tamilRegExp.hasMatch(text)) return 'ta';

    final tanglishRegExp = RegExp(r'\b(enaku|enakku|naan|enna|saapadanum|sappadu|iruku|illai|maasam|aaguthu|panradhu|romba|nalla|vanakkam|nandri|kavala|bayam)\b', caseSensitive: false);
    if (tanglishRegExp.hasMatch(text)) return 'ta';

    return 'en';
  }

  /// Synthesizes verified multi-tool responses into a cohesive, zero-hallucination block
  static String _synthesizeResponse({
    required LocalAgentState state,
    required bool isEmergency,
    required Map<String, dynamic>? medicalData,
    required Map<String, dynamic>? ashaData,
    required int month,
    required String language,
  }) {
    final isTa = language == 'ta';
    final buffer = StringBuffer();

    // 1. Emergency Banner (Pre-pended immediately if emergency is triggered)
    if (isEmergency) {
      buffer.writeln(LocalHealthKnowledgeDatabase.emergencyProtocols[isTa ? 'ta' : 'en']);
      buffer.writeln();
    }

    // 2. Medical / Diet Matrix Payload
    if (medicalData != null) {
      final title = medicalData['title'] as String;
      final coreNutrients = medicalData['core_nutrients'] as String;
      final foods = (medicalData['foods'] as List<dynamic>).cast<String>();
      final precautions = medicalData['precautions'] as String;

      buffer.writeln('🥗 **$title**');
      buffer.writeln(isTa ? '**முக்கிய ஊட்டச்சத்துக்கள்:** $coreNutrients' : '**Core Nutrients:** $coreNutrients');
      buffer.writeln();
      buffer.writeln(isTa ? '🥦 **பரிந்துரைக்கப்படும் உணவுகள்:**' : '🥦 **Recommended Core Foods:**');
      for (int i = 0; i < foods.length; i++) {
        buffer.writeln('${i + 1}. ${foods[i]}');
      }
      buffer.writeln();
      buffer.writeln(isTa ? '🚫 **கவனிக்க வேண்டியவை:** $precautions' : '🚫 **Precautions & Foods to Avoid:** $precautions');
    }

    // 3. ASHA Directory Matrix Payload (Seamlessly merged for compound queries!)
    if (ashaData != null) {
      if (medicalData != null) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }

      final workerName = isTa ? ashaData['worker_name_ta'] : ashaData['worker_name'];
      final designation = isTa ? ashaData['designation_ta'] : ashaData['designation'];
      final villageName = isTa ? ashaData['village_ta'] : ashaData['village'].toString().toUpperCase();
      final phone = ashaData['phone'] as String;
      final phc = isTa ? ashaData['phc_ta'] : ashaData['phc'];
      final timings = isTa ? ashaData['timings_ta'] : ashaData['timings'];

      buffer.writeln('🏡 **${isTa ? "உங்கள் பகுதி ஆஷா பணியாளர் தகவல் ($villageName)" : "Assigned Public Health Worker Details ($villageName)"}**');
      buffer.writeln('- **${isTa ? "பணியாளர் பெயர்:" : "Worker Name:"}** $workerName');
      buffer.writeln('- **${isTa ? "பதவி:" : "Designation:"}** $designation');
      buffer.writeln('- **${isTa ? "தொடர்பு எண்:" : "Direct Contact Phone:"}** $phone');
      buffer.writeln('- **${isTa ? "ஆரம்ப சுகாதார நிலையம்:" : "Attached PHC / Sub-Centre:"}** $phc');
      buffer.writeln('- **${isTa ? "சேவை நேரம்:" : "Service Hours:"}** $timings');
    }

    // 4. Fallback if neither medical nor ASHA was triggered
    if (medicalData == null && ashaData == null && !isEmergency) {
      buffer.writeln(
        isTa
            ? '''🌸 **தாய்-சேய் நல பொது வழிகாட்டல்**
கர்ப்ப காலத்தில் சத்தான உணவு, போதிய ஓய்வு மற்றும் வழக்கமான மருத்துவ பரிசோதனை மிகவும் அவசியம்.
- உங்கள் கர்ப்ப கால மாதம் அல்லது கிராமத்தின் பெயரை குறிப்பிட்டால் (எ.கா: "3வது மாதம் உணவு" அல்லது "வெள்ளனூர் ஆஷா பணியாளர்") துல்லியமான தகவலை உடனே பெறலாம்.'''
            : '''🌸 **Maternal Wellness & Care Guidance**
Balanced nutrition, hydration, adequate rest, and routine antenatal checkups are essential for healthy pregnancy.
- Mention your current pregnancy month or village name (e.g., "3rd month diet" or "ASHA worker for Vellanur") to retrieve exact verified protocols.''',
      );
    }

    return buffer.toString().trim();
  }
}
