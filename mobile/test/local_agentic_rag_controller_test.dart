import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/patient_ai/data/local_agentic_rag_controller.dart';
import 'package:pitpulse_mobile/features/patient_ai/data/patient_ai_engine.dart';
import 'package:pitpulse_mobile/features/patient_ai/domain/models/patient_ai_context.dart';

void main() {
  group('Patient-Facing Agentic RAG Controller Verification Tests', () {
    test('Scenario A: Greeting / Everyday Chat ("hello hello" & "Hi hello, how are you today?")', () {
      // 1. "hello hello" (exact user screenshot query)
      final state1 = LocalAgenticRagController.evaluate(rawText: 'hello hello');
      expect(state1.synthesizedResponse, contains('Hello! Vanakkam! I am your PitPulse offline maternal health assistant'));
      expect(state1.isEmergency, isFalse);

      // 2. "Hi hello, how are you today?"
      final state2 = LocalAgenticRagController.evaluate(rawText: 'Hi hello, how are you today?');
      expect(state2.synthesizedResponse, contains('I am doing well, thank you!'));
      expect(state2.isEmergency, isFalse);

      // 3. Tamil greeting "வணக்கம், நல்லா இருக்கீங்களா?"
      final state3 = LocalAgenticRagController.evaluate(rawText: 'வணக்கம், நல்லா இருக்கீங்களா?');
      expect(state3.language, equals('ta'));
      expect(state3.synthesizedResponse, contains('நான் மிகவும் நலமாக உள்ளேன், நன்றி!'));
    });

    test('Scenario B: Restricted Content Safety Override (Layer 1 Intercept)', () {
      // English illegal tablet / bypass testing query
      final stateEn = LocalAgenticRagController.evaluate(
        rawText: 'Give me a shortcut remedy to bypass clinical testing or buy illegal tablets.',
      );
      expect(stateEn.synthesizedResponse, equals('I cannot answer that.'));

      // Tamil restricted content query
      final stateTa = LocalAgenticRagController.evaluate(
        rawText: 'கருக்கலைப்பு மாத்திரை எங்கு வாங்குவது?',
      );
      expect(stateTa.language, equals('ta'));
      expect(stateTa.synthesizedResponse, equals('என்னால் அதற்குப் பதிலளிக்க முடியாது.'));
    });

    test('Scenario C: Compound Query ("Enaku 3 months aaguthu, Vellanur village. What should I eat?")', () {
      final state = LocalAgenticRagController.evaluate(
        rawText: 'Enaku 3 months aaguthu, Vellanur village. What should I eat?',
      );

      // Verifies both tools executed and merged cleanly
      expect(state.retrievedMedicalContext, isNotEmpty);
      expect(state.retrievedAshaContext, isNotEmpty);
      expect(state.extractedEntities, contains('Village: vellanur'));
      expect(state.extractedEntities, contains('Milestone: Month 3'));

      // Response contains both Diet Protocol AND ASHA details
      expect(state.synthesizedResponse, contains('3வது மாத கர்ப்ப கால உணவு முறை'));
      expect(state.synthesizedResponse, contains('போலிக் அமிலம் (Folic Acid)'));
      expect(state.synthesizedResponse, contains('செல்வி கே.'));
      expect(state.synthesizedResponse, contains('+91 94421 88301'));
      expect(state.synthesizedResponse, contains('வெள்ளனூர் அரசு ஆரம்ப சுகாதார நிலையம்'));
    });

    test('Scenario D: Emergency Red Alert Triage ("Severe bleeding and pain right now!")', () {
      final state = LocalAgenticRagController.evaluate(
        rawText: 'Severe bleeding and pain right now!',
      );

      expect(state.isEmergency, isTrue);
      expect(state.synthesizedResponse, contains('CRITICAL EMERGENCY RED ALERT'));
      expect(state.synthesizedResponse, contains('Call 108 Immediately'));
      expect(state.synthesizedResponse, contains('Proceed to the Nearest Hospital / PHC'));
    });

    test('Scenario E: ASHA Directory Lookup by Village ("Who is the ASHA worker for Vellanur?")', () {
      final state = LocalAgenticRagController.evaluate(
        rawText: 'Who is the ASHA worker for Vellanur?',
      );

      expect(state.retrievedAshaContext['village'], equals('vellanur'));
      expect(state.retrievedAshaContext['worker_name'], equals('Selvi K.'));
      expect(state.retrievedAshaContext['phone'], equals('+91 94421 88301'));
      expect(state.synthesizedResponse, contains('Selvi K.'));
      expect(state.synthesizedResponse, contains('Village Health Nurse (VHN) / ASHA Worker'));
    });

    test('Scenario F: Conversational Filler / Small Talk ("Thank you bro")', () {
      final state = LocalAgenticRagController.evaluate(
        rawText: 'Thank you bro',
      );

      expect(state.synthesizedResponse, contains('You are most welcome!'));
      expect(state.isEmergency, isFalse);
    });

    test('End-to-End Engine Integration Test (PatientAiEngine with PatientAiContext)', () {
      final engine = PatientAiEngine();
      const ctx = PatientAiContext(patientName: 'Kavitha');

      // 1. Chitchat "hello hello" produces polite warm greeting, NOT a refusal!
      final msg1 = engine.processQuery(userQuery: 'hello hello', context: ctx);
      expect(msg1.text, contains('Hello! Vanakkam! I am your PitPulse offline maternal health assistant'));
      expect(msg1.text, isNot(contains('as a specialized maternal health and pregnancy assistant, I can only safely provide guidance')));

      // 2. Diet query "I am 3 months pregnant, what should I eat?"
      final msg2 = engine.processQuery(userQuery: 'I am 3 months pregnant, what should I eat?', context: ctx);
      expect(msg2.text, contains('Month 3 Pregnancy Diet'));
      expect(msg2.text, contains('Folic Acid: Spinach'));

      // 3. Emergency red flag "I have severe stomach pain and bleeding"
      final msg3 = engine.processQuery(userQuery: 'I have severe stomach pain and bleeding', context: ctx);
      expect(msg3.warning, isNotNull);
      expect(msg3.text, contains('CRITICAL EMERGENCY RED ALERT'));
    });
  });
}
