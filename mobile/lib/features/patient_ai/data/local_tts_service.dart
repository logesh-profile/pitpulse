import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 100% Offline Local Text-to-Speech (TTS) Service
/// Leverages native on-device Android TTS engine with zero cloud dependency.
class LocalTtsService {
  static final LocalTtsService _instance = LocalTtsService._internal();
  factory LocalTtsService() => _instance;

  LocalTtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentlySpeakingId;

  bool get isPlaying => _isPlaying;
  String? get currentlySpeakingId => _currentlySpeakingId;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.48); // Natural, clear pace for maternal guidance
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        isPlayingNotifier.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _currentlySpeakingId = null;
        isPlayingNotifier.value = false;
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        _isPlaying = false;
        _currentlySpeakingId = null;
        isPlayingNotifier.value = false;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[TTS] Init note: $e');
    }
  }

  /// Speaks text aloud using local Android TTS engine in Tamil or English
  Future<void> speak({
    required String text,
    required String messageId,
    bool isTamil = false,
  }) async {
    await initialize();

    if (_isPlaying && _currentlySpeakingId == messageId) {
      await stop();
      return;
    }

    await stop();

    // Clean markdown symbols for natural speech reading
    final cleanText = _sanitizeForSpeech(text);

    try {
      if (isTamil) {
        await _flutterTts.setLanguage('ta-IN');
      } else {
        await _flutterTts.setLanguage('en-IN');
      }

      _currentlySpeakingId = messageId;
      _isPlaying = true;
      isPlayingNotifier.value = true;
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('[TTS] Speak error: $e');
      _isPlaying = false;
      _currentlySpeakingId = null;
      isPlayingNotifier.value = false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isPlaying = false;
    _currentlySpeakingId = null;
    isPlayingNotifier.value = false;
  }

  /// Strips markdown characters and headers so speech sounds human and medical
  String _sanitizeForSpeech(String input) {
    var s = input;
    s = s.replaceAll(RegExp(r'\*\*'), '');
    s = s.replaceAll(RegExp(r'#{1,6}\s'), '');
    s = s.replaceAll(RegExp(r'__'), '');
    s = s.replaceAll(RegExp(r'>\s'), '');
    s = s.replaceAll(RegExp(r'•\s'), '');
    s = s.replaceAll(RegExp(r'-\s'), '');
    s = s.replaceAll(RegExp(r'[\r\n]+'), '. ');
    s = s.replaceAll(RegExp(r'[🚨🩺🥗👶🌸🏡📋💡⚠️🚫]'), '');
    return s.trim();
  }
}
