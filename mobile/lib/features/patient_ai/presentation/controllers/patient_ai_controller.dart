import 'package:flutter/foundation.dart';
import '../../data/patient_ai_engine.dart';
import '../../domain/models/patient_ai_context.dart';
import '../../domain/models/patient_ai_message.dart';

class PatientAiController extends ChangeNotifier {
  final PatientAiEngine _engine;
  PatientAiContext _context;

  final List<PatientAiMessage> _messages = [];
  bool _isTyping = false;
  final bool _isOfflineReady = true;

  PatientAiController({
    PatientAiEngine? engine,
    PatientAiContext? context,
  })  : _engine = engine ?? PatientAiEngine(),
        _context = context ?? const PatientAiContext(patientName: 'Patient') {
    _initWelcomeMessage();
  }

  List<PatientAiMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isOfflineReady => _isOfflineReady;
  PatientAiContext get context => _context;

  List<String> get quickPromptChips {
    final prompts = <String>[];
    if (_context.hasActivePregnancy) {
      prompts.add('How is my baby growing this week?');
      prompts.add('When is my Estimated Due Date (EDD)?');
      prompts.add('What should I ask my doctor for Week ${_context.activePregnancy!.gestationalAgeWeeks}?');
    } else {
      prompts.add('How do I track my pregnancy progress?');
    }

    if (_context.hasVitals) {
      prompts.add('Explain my latest blood pressure and vitals');
    }

    if (_context.hasHomeVisits) {
      prompts.add('Summarize my recent ASHA home visits');
    }

    prompts.add('What foods are healthy during pregnancy?');
    prompts.add('What are the critical danger signs to watch for?');

    return prompts;
  }

  void updateContext(PatientAiContext newContext) {
    _context = newContext;
    notifyListeners();
  }

  void _initWelcomeMessage() {
    final patientName = _context.patientName;
    String greeting = 'Hello $patientName! I am your **PitPulse Maternal AI Guide**.';

    if (_context.hasActivePregnancy) {
      final preg = _context.activePregnancy!;
      greeting += '\n\nI see you are currently in **${preg.gestationalAgeDisplay}** (${preg.trimesterDisplay}). I can explain your fetal development, interpret your recorded vitals, help prepare questions for your doctor, and guide you on prenatal wellness.';
    } else {
      greeting += '\n\nI can help you understand pregnancy milestones, explain recorded health vitals, summarize field checkups, and prepare questions for your doctor.';
    }

    _messages.add(
      PatientAiMessage(
        id: 'welcome_init',
        text: greeting,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestedQuestions: quickPromptChips.take(3).toList(),
      ),
    );
  }

  Future<void> sendUserMessage(String userText) async {
    final trimmed = userText.trim();
    if (trimmed.isEmpty) return;

    // 1. Add User message
    final userMsg = PatientAiMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    // 2. Subtle micro-delay for conversational rhythm
    await Future.delayed(const Duration(milliseconds: 350));

    // 3. Extract last 3 user turns for Context Stitching
    final userHistory = _messages
        .where((m) => m.sender == MessageSender.user && m.text != trimmed)
        .map((m) => m.text)
        .toList();
    final recentHistory = userHistory.length > 3
        ? userHistory.sublist(userHistory.length - 3)
        : userHistory;

    // 4. Process query through context-aware on-device engine
    final aiResponse = _engine.processQuery(
      userQuery: trimmed,
      context: _context,
      chatHistory: recentHistory,
    );

    _isTyping = false;
    _messages.add(aiResponse);
    notifyListeners();
  }

  void clearConversation() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }
}
