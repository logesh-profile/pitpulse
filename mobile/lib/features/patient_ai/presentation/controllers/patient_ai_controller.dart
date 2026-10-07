import 'package:flutter/foundation.dart';
import '../../data/gemini_ai_service.dart';
import '../../data/patient_ai_engine.dart';
import '../../domain/models/ai_source_reference.dart';
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
      prompts.add('How do I track my health in MAATRA?');
    }

    if (_context.hasVitals) {
      prompts.add('Explain my latest blood pressure and vitals');
    }

    if (_context.hasHomeVisits) {
      prompts.add('Summarize my recent ASHA home visits');
    }

    prompts.add('What foods are healthy during pregnancy?');
    prompts.add('Home remedies for stress and nausea');

    return prompts;
  }

  void updateContext(PatientAiContext newContext) {
    _context = newContext;
    notifyListeners();
  }

  void _initWelcomeMessage() {
    final patientName = _context.patientName;
    String greeting = 'Hello $patientName. I am **MAATRA AI**, powered by Google Gemini.';

    if (_context.hasActivePregnancy) {
      final preg = _context.activePregnancy!;
      greeting += '\n\nI see you are in **${preg.gestationalAgeDisplay}** (${preg.trimesterDisplay}). You can ask me anything about your symptoms, remedies, vitals, nutrition, or everyday conversations.';
    } else {
      greeting += '\n\nYou can ask me anything about wellness, remedies, medical guidance, your recorded vitals, or chat naturally in English or Tamil.';
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

    // 2. Extract last turns for conversation context
    final userHistory = _messages
        .where((m) => m.sender == MessageSender.user && m.text != trimmed)
        .map((m) => m.text)
        .toList();
    final recentHistory = userHistory.length > 3
        ? userHistory.sublist(userHistory.length - 3)
        : userHistory;

    PatientAiMessage? aiResponse;

    // 3. Live Google Gemini Free LLM Engine (Direct Over Internet)
    try {
      final historyPayload = _messages
          .take(6)
          .map((m) => <String, String>{
                'role': m.isUser ? 'user' : 'model',
                'content': m.text,
              })
          .toList();

      final geminiReply = await GeminiAiService.askGemini(
        userQuery: trimmed,
        context: _context,
        chatHistory: historyPayload,
      );

      if (geminiReply != null && geminiReply.isNotEmpty) {
        aiResponse = PatientAiMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: geminiReply,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          isOfflineGenerated: false,
          sources: const [
            AiSourceReference(
              type: AiSourceType.curatedKnowledgeBase,
              title: 'MAATRA Gemini Intelligence',
              detail: 'Google Gemini 100% Free Live Medical & Conversation Agent',
            ),
          ],
        );
      }
    } catch (_) {
      // Offline fallback
    }

    // 4. Natural Grounded Fallback if offline / airplane mode
    if (aiResponse == null) {
      await Future.delayed(const Duration(milliseconds: 250));
      aiResponse = _engine.processQuery(
        userQuery: trimmed,
        context: _context,
        chatHistory: recentHistory,
      );
    }

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
