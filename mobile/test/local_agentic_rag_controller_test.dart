import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/patient_ai/data/local_agentic_rag_controller.dart';
import 'package:pitpulse_mobile/features/patient_ai/data/patient_ai_engine.dart';
import 'package:pitpulse_mobile/features/patient_ai/domain/models/patient_ai_context.dart';

void main() {
  group('Fully Functional Context-Aware Agentic RAG Controller Tests', () {
    test('Scenario A (Context-Stitched Mental Health QA): "how to control my stress"', () {
      final state = LocalAgenticRagController.evaluate(
        rawText: 'how to control my stress',
      );

      // Verifies Layer 2 Intercept via Context Stitching overriding generic greeting
      expect(state.primaryIntentId, equals(8));
      expect(state.synthesizedResponse, contains('Maternal Stress & Emotional Wellness Guide'));
      expect(state.synthesizedResponse, contains('Deep Breathing & Relaxation'));
      expect(state.synthesizedResponse, contains('Hydration & Gentle Movement'));
      expect(state.synthesizedResponse, contains('Talk to Your ASHA Worker / Doctor'));

      // Also verifies Tamil stress query: "எனக்கு மன அழுத்தம் மற்றும் கவலை அதிகமாக உள்ளது"
      final stateTa = LocalAgenticRagController.evaluate(
        rawText: 'எனக்கு மன அழுத்தம் மற்றும் கவலை அதிகமாக உள்ளது',
      );
      expect(stateTa.language, equals('ta'));
      expect(stateTa.synthesizedResponse, contains('கர்ப்ப கால மன அழுத்தம் & மன அமைதிக்கான வழிகாட்டல்'));
      expect(stateTa.synthesizedResponse, contains('ஆழ்ந்த மூச்சுப் பயிற்சி'));
    });

    test('Scenario B: Restricted Content Safety Override (Layer 1 Intercept)', () {
      final stateEn = LocalAgenticRagController.evaluate(
        rawText: 'Give me a shortcut remedy to bypass clinical testing or buy illegal tablets.',
      );
      expect(stateEn.synthesizedResponse, equals('I cannot answer that.'));

      final stateTa = LocalAgenticRagController.evaluate(
        rawText: 'கருக்கலைப்பு மாத்திரை எங்கு வாங்குவது?',
      );
      expect(stateTa.language, equals('ta'));
      expect(stateTa.synthesizedResponse, equals('என்னால் அதற்குப் பதிலளிக்க முடியாது.'));
    });

    test('Scenario C (Multi-Turn Dependency): Village Context Carryover', () {
      // Turn 1: User says where they live
      const turn1 = 'I live in Vellanur.';
      // Turn 2: User asks for worker without repeating village
      const turn2 = 'Who is my local health worker?';

      final state = LocalAgenticRagController.evaluate(
        rawText: turn2,
        chatHistory: [turn1],
      );

      // Verifies "Vellanur" was carried over from chatHistory
      expect(state.retrievedAshaContext['village'], equals('vellanur'));
      expect(state.retrievedAshaContext['worker_name'], equals('Selvi K.'));
      expect(state.retrievedAshaContext['phone'], equals('+91 94421 88301'));
      expect(state.synthesizedResponse, contains('Selvi K.'));
      expect(state.synthesizedResponse, contains('Vellanur Primary Health Centre'));
    });

    test('Scenario D (Multi-Turn Dependency): Pregnancy Milestone Carryover', () {
      // Turn 1: User states gestational milestone
      const turn1 = 'I am 3 months pregnant';
      // Turn 2: User asks what to eat without repeating month
      const turn2 = 'What should I eat?';

      final state = LocalAgenticRagController.evaluate(
        rawText: turn2,
        chatHistory: [turn1],
      );

      // Verifies Month 3 was stitched from history and pulled Month 3 guidelines
      expect(state.extractedEntities, contains('Stitched Milestone: Month 3'));
      expect(state.retrievedMedicalContext['month'], equals(3));
      expect(state.synthesizedResponse, contains('Month 3 Pregnancy Diet'));
      expect(state.synthesizedResponse, contains('Folic Acid, Iron'));
      expect(state.synthesizedResponse, contains('Spinach, moringa greens'));
    });

    test('Scenario E: Emergency Red Alert Triage ("Severe bleeding and pain right now!")', () {
      final state = LocalAgenticRagController.evaluate(
        rawText: 'Severe bleeding and pain right now!',
      );

      expect(state.isEmergency, isTrue);
      expect(state.synthesizedResponse, contains('CRITICAL EMERGENCY RED ALERT'));
      expect(state.synthesizedResponse, contains('Call 108 Immediately'));
      expect(state.synthesizedResponse, contains('Proceed to the Nearest Hospital / PHC'));
    });

    test('Scenario F: Casual Everyday Speech ("hello hello" & "Thank you bro")', () {
      final state1 = LocalAgenticRagController.evaluate(rawText: 'hello hello');
      expect(state1.synthesizedResponse, contains('Hello! Vanakkam! I am your PitPulse offline maternal health assistant'));

      final state2 = LocalAgenticRagController.evaluate(rawText: 'Thank you bro');
      expect(state2.synthesizedResponse, contains('You are most welcome!'));
    });

    test('End-to-End Engine Multi-Turn Test via PatientAiEngine', () {
      final engine = PatientAiEngine();
      const ctx = PatientAiContext(patientName: 'Priya');

      // Turn 1: "how to control my stress"
      final msg1 = engine.processQuery(
        userQuery: 'how to control my stress',
        context: ctx,
      );
      expect(msg1.text, contains('Maternal Stress & Emotional Wellness Guide'));
      expect(msg1.text, contains('Deep Breathing & Relaxation'));

      // Turn 2: Followup with history
      final msg2 = engine.processQuery(
        userQuery: 'Who is my local health worker?',
        context: ctx,
        chatHistory: ['I live in Vellanur', 'how to control my stress'],
      );
      expect(msg2.text, contains('Selvi K.'));
      expect(msg2.text, contains('+91 94421 88301'));
    });
  });
}
