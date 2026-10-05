import 'ai_screening_warning.dart';
import 'ai_source_reference.dart';

enum MessageSender {
  user,
  ai,
  system,
}

class PatientAiMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final List<AiSourceReference> sources;
  final AiScreeningWarning? warning;
  final List<String> suggestedQuestions;
  final bool isOfflineGenerated;
  final bool isTamil;

  const PatientAiMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.sources = const [],
    this.warning,
    this.suggestedQuestions = const [],
    this.isOfflineGenerated = true,
    this.isTamil = false,
  });

  bool get isUser => sender == MessageSender.user;
  bool get isAi => sender == MessageSender.ai;
  bool get isSystem => sender == MessageSender.system;
}
