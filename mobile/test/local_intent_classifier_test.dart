import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/patient_ai/data/local_intent_classifier.dart';

void main() {
  group('100MB 100% Offline Local Intent Classifier Tests', () {
    test('Correctly classifies Tamil transliterated voice query: "Enaku moonu maasam aaguthu, naan enna saapadanum?"', () {
      const userVoiceQuery = 'Enaku moonu maasam aaguthu, naan enna saapadanum?';

      final classification = LocalIntentClassifier.classify(userVoiceQuery);

      expect(classification.intent, equals(LocalIntent.dietQuery));
      expect(classification.language, equals(QueryLanguage.tamil));
      expect(classification.targetMonth, equals(3));

      final response = LocalIntentClassifier.getVerifiedResponse(
        classification: classification,
        gestationalWeeks: 12,
      );

      // Verifies exact Tamil maternal nutrition advice
      expect(response, contains('3வது மாத கர்ப்ப கால உணவு முறை'));
      expect(response, contains('போலிக் அமிலம்'));
      expect(response, contains('இரும்புச்சத்து'));
      expect(response, contains('பப்பாளி, அன்னாசி'));
    });

    test('Classifies direct Tamil script: "கர்ப்ப கால உணவு என்ன சாப்பிட வேண்டும்?"', () {
      const userQuery = 'கர்ப்ப கால உணவு என்ன சாப்பிட வேண்டும்?';

      final classification = LocalIntentClassifier.classify(userQuery);

      expect(classification.intent, equals(LocalIntent.dietQuery));
      expect(classification.language, equals(QueryLanguage.tamil));
    });

    test('Classifies English query: "What should I eat during the 3rd month?"', () {
      const userQuery = 'What should I eat during the 3rd month?';

      final classification = LocalIntentClassifier.classify(userQuery);

      expect(classification.intent, equals(LocalIntent.dietQuery));
      expect(classification.language, equals(QueryLanguage.english));
      expect(classification.targetMonth, equals(3));

      final response = LocalIntentClassifier.getVerifiedResponse(
        classification: classification,
        gestationalWeeks: 12,
      );

      expect(response, contains('3rd Month Pregnancy Diet'));
      expect(response, contains('Folic Acid & Iron'));
    });

    test('Instant Emergency Red Flag Triage: "எனக்கு இரத்தப்போக்கு ஏற்படுகிறது"', () {
      const emergencyQuery = 'எனக்கு இரத்தப்போக்கு ஏற்படுகிறது';

      final classification = LocalIntentClassifier.classify(emergencyQuery);

      expect(classification.intent, equals(LocalIntent.emergencyRedAlert));
      expect(classification.language, equals(QueryLanguage.tamil));

      final response = LocalIntentClassifier.getVerifiedResponse(
        classification: classification,
        gestationalWeeks: 20,
      );

      expect(response, contains('அவசர மருத்துவ உதவி தேவை'));
      expect(response, contains('ஆரம்ப சுகாதார நிலையம்'));
    });

    test('Classifies Vitals BP check: "என் இரத்த அழுத்தம் (BP) இயல்பாக உள்ளதா?"', () {
      const bpQuery = 'என் இரத்த அழுத்தம் (BP) இயல்பாக உள்ளதா?';

      final classification = LocalIntentClassifier.classify(bpQuery);

      expect(classification.intent, equals(LocalIntent.vitalsCheck));
      expect(classification.language, equals(QueryLanguage.tamil));
    });

    test('Classifies Doctor consultation checklist: "டாக்டரிடம் நான் என்ன கேட்க வேண்டும்?"', () {
      const docQuery = 'டாக்டரிடம் நான் என்ன கேட்க வேண்டும்?';

      final classification = LocalIntentClassifier.classify(docQuery);

      expect(classification.intent, equals(LocalIntent.doctorPreparation));
      expect(classification.language, equals(QueryLanguage.tamil));
    });
  });
}
