import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import 'dio.dart';
import 'env.dart';

// Provider for the Gemini service
final googleAIServiceProvider = Provider<GoogleAIService>((ref) {
  return GoogleAIService(ref);
});

class GoogleAIResponse {
  final List<Candidate> candidates;
  final int promptTokenCount;
  final int candidatesTokenCount;
  final int totalTokenCount;
  final List<Map<String, dynamic>> promptTokensDetails;
  final String modelVersion;
  final String responseId;

  GoogleAIResponse({
    required this.candidates,
    required this.promptTokenCount,
    required this.candidatesTokenCount,
    required this.totalTokenCount,
    required this.promptTokensDetails,
    required this.modelVersion,
    required this.responseId,
  });

  factory GoogleAIResponse.fromJson(Map<String, dynamic> json) {
    return GoogleAIResponse(
      candidates:
          (json['candidates'] as List<dynamic>?)?.map((e) => Candidate.fromJson(e as Map<String, dynamic>)).toList() ??
              [],
      promptTokenCount: json['usageMetadata']?['promptTokenCount'] ?? 0,
      candidatesTokenCount: json['usageMetadata']?['candidatesTokenCount'] ?? 0,
      totalTokenCount: json['usageMetadata']?['totalTokenCount'] ?? 0,
      promptTokensDetails: (json['usageMetadata']?['promptTokensDetails'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      modelVersion: json['modelVersion'] ?? '',
      responseId: json['responseId'] ?? '',
    );
  }
}

class Candidate {
  final String text;
  final String role;
  final String finishReason;
  final int index;

  Candidate({required this.text, required this.role, required this.finishReason, required this.index});

  factory Candidate.fromJson(Map<String, dynamic> json) {
    // Extract text from the content parts array
    String text = '';
    try {
      final content = json['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        text = parts[0]['text'] as String? ?? '';
      }
    } catch (e) {
      print('Warning: Failed to parse candidate text: $e');
    }

    return Candidate(
      text: text,
      role: json['content']?['role'] as String? ?? 'model',
      finishReason: json['finishReason'] as String? ?? 'STOP',
      index: json['index'] as int? ?? 0,
    );
  }
}

/// Result type for Gemini API responses
class GeminiResult {
  final String? text;
  final String? error;
  final bool isSuccess;

  const GeminiResult._({this.text, this.error, required this.isSuccess});

  factory GeminiResult.success(String text) => GeminiResult._(text: text, isSuccess: true);

  factory GeminiResult.failure(String error) => GeminiResult._(error: error, isSuccess: false);
}

/// Configuration for Gemini text generation
class GeminiConfig {
  final double temperature;
  final int maxOutputTokens;
  final double topP;
  final int topK;
  final List<String> stopSequences;

  const GeminiConfig({
    this.temperature = 0.7,
    this.maxOutputTokens = 1000,
    this.topP = 0.8,
    this.topK = 40,
    this.stopSequences = const [],
  });
}

class GoogleAIService {
  final Ref ref;

  GoogleAIService(this.ref);

  Future<GeminiResult> generateText(String prompt,
      {GeminiConfig geminiConfig = const GeminiConfig(), required String userid}) async {
    try {
      final env = ref.read(envProvider);

      final geminiContext = env.aiPersona;

      print('GoogleAIService prompt: $prompt');
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": "$geminiContext\n\nYou are talking to $userid\n\nUser Prompt: $prompt"},
            ]
          }
        ],
        "safetySettings": [
          {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
          {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"}
        ]
      };
      final encoder = JsonEncoder.withIndent('  ');
      print('GoogleAIService requestBody: ${encoder.convert(requestBody)}');

      final dio = ref.read(dioProvider);
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/${env.aiModel}:generateContent',
        data: requestBody,
        options: Options(
          headers: {
            'x-goog-api-key': env.aiApiKey,
          },
        ),
      );
      print('GeminiService: response: ${response.data}');
      final data = GoogleAIResponse.fromJson(response.data);

      return GeminiResult.success(data.candidates[0].text);
    } catch (e, stackTrace) {
      if (e is DioException) {
        print('GeminiService: error: ${e.response?.data}');
      } else {
        print('GeminiService: error: $e, stackTrace: $stackTrace');
      }
      return GeminiResult.failure('Error generating text: ${e.toString()}');
    }
  }
}
