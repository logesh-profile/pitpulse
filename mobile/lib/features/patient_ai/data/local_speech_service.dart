import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 100% Offline / Device Speech-To-Text Service
/// Captures speech from the mother via Android Native SpeechRecognizer (Whisper-style extraction).
class LocalSpeechService {
  static final LocalSpeechService _instance = LocalSpeechService._internal();
  factory LocalSpeechService() => _instance;

  LocalSpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  final ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> wordsSpokenNotifier = ValueNotifier<String>('');

  Future<bool> initialize() async {
    if (_isAvailable) return true;
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          _isListening = _speech.isListening;
          isListeningNotifier.value = _speech.isListening;
        },
        onError: (errorNotification) {
          debugPrint('[STT] Speech error: ${errorNotification.errorMsg}');
          _isListening = false;
          isListeningNotifier.value = false;
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('[STT] Speech init note: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String recognizedWords) onResult,
    String? localeId, // e.g. 'ta_IN' or 'en_IN'
  }) async {
    final available = await initialize();
    if (!available) {
      debugPrint('[STT] Speech not available on device.');
      return;
    }

    wordsSpokenNotifier.value = '';
    _isListening = true;
    isListeningNotifier.value = true;

    try {
      await _speech.listen(
        onResult: (result) {
          wordsSpokenNotifier.value = result.recognizedWords;
          onResult(result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('[STT] Listen error: $e');
      _isListening = false;
      isListeningNotifier.value = false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _isListening = false;
    isListeningNotifier.value = false;
  }
}
