import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:riverpod/riverpod.dart';

import '../constants.dart';
import '../google_ai_service.dart';
import '../msg_queue.dart';

/// Result of AI command validation
class AICommandValidationResult {
  final bool shouldContinue;
  final MessageBuilder? errorMessage;

  AICommandValidationResult({required this.shouldContinue, this.errorMessage});
}

/// Utility class for handling AI command responses and error handling
class AICommandUtils {
  /// Checks rate limiting for AI commands
  /// Returns true if the user is rate limited (should stop processing)
  /// Returns false if the user can proceed
  static bool checkAIRateLimit(ChatContext context, MsgQueue msgQueue) {
    final member = context.member!.id.value;
    final isRateLimited = msgQueue.addMessage(member);
    return isRateLimited;
  }

  /// Validates AI prompt input
  /// Returns null if input is valid
  /// Returns error message if input is invalid
  static String? validateAIPrompt(String input, {int maxLength = 4000}) {
    if (input.trim().isEmpty) {
      return '❌ **Invalid Input**: Please provide a prompt to generate text.';
    }

    if (input.length > maxLength) {
      return '❌ **Prompt Too Long**: Please provide a shorter prompt (max $maxLength characters).';
    }

    return null; // Input is valid
  }

  /// Builds an AI prompt validation error message (caller handles sending)
  static MessageBuilder buildAIInputErrorMessage(String errorMessage) {
    return createAlertMessageForAI(
      content: '❌ Input Error',
      description: errorMessage,
      color: EmdedColor.red,
    );
  }

  /// Creates a success embed with the AI response
  static EmbedBuilder createAISuccessEmbed(String prompt, String response) {
    // Create list of fields for the embed
    final fields = <EmbedFieldBuilder>[];

    // Add prompt as a field (up to 1024 chars)
    if (prompt.length <= 1024) {
      fields.add(EmbedFieldBuilder(name: '📝 Your Prompt', value: prompt, isInline: false));
    } else {
      // If prompt is too long, truncate it
      String truncatedPrompt = '${prompt.substring(0, 1020)}...';
      fields.add(EmbedFieldBuilder(name: '📝 Your Prompt', value: truncatedPrompt, isInline: false));
    }

    // If response is too long for description, add as field
    if (response.length > 4096) {
      String truncatedResponse = '${response.substring(0, 1020)}...\n\n*Response truncated due to length*';
      fields.add(EmbedFieldBuilder(name: '💬 Response', value: truncatedResponse, isInline: false));
    }

    // Create the embed using constants
    return createEmbedForAI(
      title: '🤖 AI Response',
      description: response.length <= 4096 ? response : null,
      color: EmdedColor.green,
      fields: fields,
    );
  }

  /// Creates an error embed for AI API failures
  static EmbedBuilder createAIErrorEmbed(String prompt, String errorMessage) {
    String title;
    String description;

    if (errorMessage.contains('quota') || errorMessage.contains('limit')) {
      title = '🚫 API Quota Exceeded';
      description = 'The AI service has reached its usage limit. Please try again later.';
    } else if (errorMessage.contains('key') || errorMessage.contains('auth')) {
      title = '🔑 Authentication Error';
      description = 'There\'s an issue with the AI service configuration. Please contact an administrator.';
    } else if (errorMessage.contains('blocked') || errorMessage.contains('safety')) {
      title = '🛡️ Content Blocked';
      description = 'Your prompt was blocked by safety filters. Please try a different request.';
    } else if (errorMessage.contains('network') || errorMessage.contains('timeout')) {
      title = '🌐 Network Error';
      description = 'Unable to reach the AI service. Please try again in a moment.';
    } else {
      title = '⚠️ AI Service Error';
      description = errorMessage;
    }

    // Create fields for the error embed
    final errorFields = <EmbedFieldBuilder>[];

    // Add prompt as a field
    if (prompt.length <= 1024) {
      errorFields.add(EmbedFieldBuilder(name: '📝 Your Prompt', value: prompt, isInline: false));
    } else {
      String truncatedPrompt = '${prompt.substring(0, 1020)}...';
      errorFields.add(EmbedFieldBuilder(name: '📝 Your Prompt', value: truncatedPrompt, isInline: false));
    }

    return createEmbedForAI(
      title: title,
      description: description,
      color: EmdedColor.red,
      fields: errorFields,
    );
  }

  /// Creates an unexpected error embed for AI commands
  static EmbedBuilder createAICrashEmbed(String prompt, String errorDetails) {
    // Create fields for the crash embed
    final crashFields = <EmbedFieldBuilder>[];

    // Add prompt as a field
    if (prompt.length <= 1024) {
      crashFields.add(EmbedFieldBuilder(name: '📝 Your Prompt', value: prompt, isInline: false));
    } else {
      String truncatedPrompt = '${prompt.substring(0, 1020)}...';
      crashFields.add(EmbedFieldBuilder(name: '📝 Your Prompt', value: truncatedPrompt, isInline: false));
    }

    // Add error details as a field (truncated if too long)
    String truncatedErrorDetails = errorDetails;
    if (errorDetails.length > 1024) {
      truncatedErrorDetails = '${errorDetails.substring(0, 1020)}...';
    }
    crashFields.add(EmbedFieldBuilder(name: '🔍 Error Details', value: truncatedErrorDetails, isInline: false));

    return createEmbedForAI(
      title: '💥 Unexpected Error',
      description: 'Something went wrong while processing your request. Please try again.',
      color: EmdedColor.orange,
      fields: crashFields,
    );
  }

  /// Complete AI command handler that combines validation and rate limiting
  /// Returns a result object indicating whether to continue and any error message to send
  static AICommandValidationResult validateAICommand({
    required ChatContext context,
    required MsgQueue msgQueue,
    required String prompt,
    int maxPromptLength = 4000,
  }) {
    // Check rate limiting first
    if (checkAIRateLimit(context, msgQueue)) {
      final message = createAlertMessageForAI(
        content: '⏳ Rate Limited',
        description:
            'You have requested too many times in the last 10 minutes. Please wait before using this command again.',
        color: EmdedColor.orange,
      );
      return AICommandValidationResult(shouldContinue: false, errorMessage: message);
    }

    // Validate input
    final inputError = validateAIPrompt(prompt, maxLength: maxPromptLength);
    if (inputError != null) {
      final message = buildAIInputErrorMessage(inputError);
      return AICommandValidationResult(shouldContinue: false, errorMessage: message);
    }

    return AICommandValidationResult(shouldContinue: true);
  }

  /// Makes AI service call and returns the result
  /// This function only handles the AI service interaction, not Discord responses
  /// Returns a GeminiResult that the calling function can use to send appropriate Discord responses
  static Future<GeminiResult> callAIService({
    Ref? ref,
    ProviderContainer? container,
    required String prompt,
  }) async {
    if (ref == null && container == null) {
      return GeminiResult.failure('No ref or container provided');
    }

    try {
      // final geminiService = ref?.read(googleAIServiceProvider);
      GoogleAIService geminiService;
      if (ref != null) {
        geminiService = ref.read(googleAIServiceProvider);
      } else {
        geminiService = container!.read(googleAIServiceProvider);
      }
      final result = await geminiService.generateText(prompt);
      return result;
    } catch (e) {
      // Return a failed result with the error details
      return GeminiResult.failure('Unexpected error: ${e.toString()}');
    }
  }

  /// Build an AI success response message (caller handles sending)
  static MessageBuilder buildAISuccessMessage(String prompt, String response) {
    final embed = createAISuccessEmbed(prompt, response);
    return MessageBuilder(embeds: [embed]);
  }

  /// Build an AI error response message (caller handles sending)
  static MessageBuilder buildAIErrorMessage(String prompt, String errorMessage) {
    final embed = createAIErrorEmbed(prompt, errorMessage);
    return MessageBuilder(embeds: [embed]);
  }

  /// Build an AI unexpected error response message (caller handles sending)
  static MessageBuilder buildAICrashMessage(String prompt, String errorDetails) {
    final embed = createAICrashEmbed(prompt, errorDetails);
    return MessageBuilder(embeds: [embed]);
  }
}
