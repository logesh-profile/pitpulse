import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/patient_ai_context.dart';

/// Direct Google Gemini AI Service for MAATRA Mobile Client.
/// Connects directly to Google Gemini 100% Free Tier API.
/// Provides live conversational intelligence across general medicine, remedies,
/// and authenticated patient profile data with zero hardcoded fake data.
class GeminiAiService {
  static String get _geminiApiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      return utf8.decode(
        base64.decode('QVEuQWI4Uk42TERScFFHQVdLd0dOSVc2dWh0dGNYODBLVUFQQ3gxX0Q4dnVJQVFrSnE3bEE='),
      );
    } catch (_) {
      return '';
    }
  }

  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-flash-lite-latest',
    'gemini-3.8-flash',
    'gemini-flash-latest',
  ];

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Sends query directly to Google Gemini API
  static Future<String?> askGemini({
    required String userQuery,
    required PatientAiContext context,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    // 1. Build System Instruction with Authentic Patient Records Only
    final buffer = StringBuffer();
    buffer.writeln('You are Anu, "ur ai at ur place" — an intelligent, empathetic medical and health assistant.');
    buffer.writeln('You converse naturally in English, Tamil, and Tanglish with a warm, caring tone (like ChatGPT/Claude).');
    buffer.writeln('GUIDELINES:');
    buffer.writeln('1. Natural Human Conversations: Greet warmly, engage in friendly small talk, and listen attentively.');
    buffer.writeln('2. Comprehensive Health & Home Remedies: Explain practical home remedies, fever, headache, cough, digestion, elderly and maternal wellness, nutrition, and blood pressure. For acute red flags (severe bleeding, chest pain), instruct to call 108 immediately.');
    buffer.writeln('3. ZERO HARDCODED / FAKE DATA: Never invent fake clinic names, fake worker names, or imaginary numbers. If personal medical data is needed, rely strictly on the authenticated patient records provided below. If the patient has no records recorded yet, state that gently.');
    buffer.writeln('4. Authenticated Patient Clinical Profile:');
    buffer.writeln('   - Patient Name: ${context.patientName}');

    if (context.hasVitals) {
      final v = context.latestVitals!;
      buffer.writeln('   - Latest Blood Pressure: ${v.systolicBp}/${v.diastolicBp} mmHg');
      if (v.weightKg != null) buffer.writeln('   - Weight: ${v.weightKg} kg');
      if (v.temperatureC != null) buffer.writeln('   - Temperature: ${v.temperatureC}°C');
      buffer.writeln('   - Recorded On: ${v.recordedAt.toIso8601String()}');
    } else {
      buffer.writeln('   - Vitals: No vitals recorded yet.');
    }

    if (context.hasActivePregnancy) {
      final p = context.activePregnancy!;
      buffer.writeln('   - Active Pregnancy: ${p.gestationalAgeDisplay} (${p.trimesterDisplay}), EDD: ${p.edd.toIso8601String()}');
    } else {
      buffer.writeln('   - Pregnancy: No active pregnancy recorded.');
    }

    if (context.assignedAshaName != null && context.assignedAshaName!.isNotEmpty) {
      buffer.writeln('   - Assigned Healthcare Worker: ${context.assignedAshaName}');
    } else {
      buffer.writeln('   - Assigned Healthcare Worker: None assigned yet.');
    }

    final systemInstruction = buffer.toString();

    // 2. Build multi-turn contents ensuring strictly alternating user/model roles
    final contents = <Map<String, dynamic>>[];
    String? lastRole;

    for (final turn in chatHistory.take(6)) {
      final role = (turn['role'] == 'user') ? 'user' : 'model';
      final text = turn['content'] ?? '';
      if (text.isNotEmpty && role != lastRole) {
        contents.add({
          'role': role,
          'parts': [{'text': text}],
        });
        lastRole = role;
      }
    }

    // Ensure the current user query is added as a user turn
    if (lastRole == 'user' && contents.isNotEmpty) {
      // Append user text to the last user message
      final parts = contents.last['parts'] as List;
      parts.add({'text': userQuery});
    } else {
      contents.add({
        'role': 'user',
        'parts': [{'text': userQuery}],
      });
    }

    final payload = {
      'system_instruction': {
        'parts': [{'text': systemInstruction}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.6,
        'maxOutputTokens': 800,
      },
    };

    // Try candidate models
    for (final model in _models) {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey';
      try {
        final response = await _dio.post(url, data: payload);
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }
        }
      } on DioException catch (e) {
        debugPrint('[GeminiAiService] Model $model error: ${e.response?.data ?? e}');
        continue;
      } catch (e) {
        debugPrint('[GeminiAiService] Model $model error: $e');
        continue;
      }
    }

    return null;
  }
}
