import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod/riverpod.dart';

import 'env.dart';

// Provider for the Gemini service
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(ref);
});

/// Result type for Gemini API responses
class GeminiResult {
  final String? text;
  final String? error;
  final bool isSuccess;

  const GeminiResult._({
    this.text,
    this.error,
    required this.isSuccess,
  });

  factory GeminiResult.success(String text) => GeminiResult._(
        text: text,
        isSuccess: true,
      );

  factory GeminiResult.failure(String error) => GeminiResult._(
        error: error,
        isSuccess: false,
      );
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

/// Service class for interacting with Google Generative AI (Gemini)
class GeminiService {
  final Ref ref;
  GenerativeModel? _model;
  bool _isInitialized = false;

  GeminiService(this.ref);

  /// Initialize the Gemini model

  /// Generate text from a prompt using Gemini
  Future<GeminiResult> generateText(
    String prompt, {
    GeminiConfig geminiConfig = const GeminiConfig(),
  }) async {
    try {
      final env = ref.read(envProvider);

      final geminiContext = env.geminiContext ?? '';

      // Configure generation settings
      final generationConfig = GenerationConfig(
        temperature: geminiConfig.temperature,
        maxOutputTokens: geminiConfig.maxOutputTokens,
        topP: geminiConfig.topP,
        topK: geminiConfig.topK,
        stopSequences: geminiConfig.stopSequences,
      );

      // Create configured model with settings
      final configuredModel = GenerativeModel(
        model: 'gemini-2.5-pro',
        apiKey: env.geminiApiKey,
        requestOptions: RequestOptions(
          apiVersion: 'v1alpha',
        ),
        generationConfig: generationConfig,
        safetySettings: [
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        ],
        systemInstruction: Content.system(geminiContext),
      );
      print('GeminiService prompt: $prompt');
      // Generate content
      final response = await configuredModel.generateContent([
        Content.text(prompt),
      ]);
      print('GeminiService: response: $response');
      final text = response.text;
      if (text == null || text.isEmpty) {
        return GeminiResult.failure('No response generated from Gemini');
      }

      return GeminiResult.success(text);
    } catch (e) {
      print('GeminiService: error: $e');
      return GeminiResult.failure('Error generating text: ${e.toString()}');
    }
  }

  // /// Generate text with streaming response
  // Stream<Either<String, String>> generateTextStream(
  //   String prompt, {
  //   GeminiConfig config = const GeminiConfig(),
  // }) async* {
  //   try {
  //     // Ensure service is initialized
  //     final initResult = await initialize();
  //     if (initResult.isLeft()) {
  //       yield Left(initResult.fold((error) => error, (_) => ''));
  //       return;
  //     }

  //     if (_model == null) {
  //       yield const Left('Gemini model not initialized');
  //       return;
  //     }

  //     // Configure generation settings
  //     final generationConfig = GenerationConfig(
  //       temperature: config.temperature,
  //       maxOutputTokens: config.maxOutputTokens,
  //       topP: config.topP,
  //       topK: config.topK,
  //       stopSequences: config.stopSequences,
  //     );

  //     // Create configured model with settings
  //     final configuredModel = GenerativeModel(
  //       model: 'gemini-2.5-pro',
  //       apiKey: _env.geminiApiKey,
  //       generationConfig: generationConfig,
  //     );
  //     print('GeminiService: prompt: $prompt');
  //     // Generate streaming content
  //     final stream = configuredModel.generateContentStream([
  //       Content.text(prompt),
  //     ]);

  //     await for (final response in stream) {
  //       final text = response.text;
  //       if (text != null && text.isNotEmpty) {
  //         yield Right(text);
  //       }
  //     }
  //   } catch (e) {
  //     yield Left('Error generating text stream: ${e.toString()}');
  //   }
  // }

  // /// Check if the service is initialized and ready to use
  bool get isReady => _isInitialized && _model != null;

  /// Get the current model name
  String get modelName => 'gemini-1.5-flash';
}
