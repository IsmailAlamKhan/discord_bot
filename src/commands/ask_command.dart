import 'dart:async';

import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:riverpod/src/framework.dart';

import '../msg_queue.dart';
import '../utils/discord_response_utils.dart';
import 'commands.dart';

class AskCommand extends SlashRunnable {
  final MsgQueue msgQueue;

  AskCommand() : msgQueue = MsgQueue();

  @override
  final String name = 'ask';

  @override
  final String description = 'Generate text using Red Door AI';

  @override
  FutureOr<ChatCommand?> initialize(Ref<Object?> ref) {
    enabled = true;
    final gemini = ChatCommand(
      name,
      description,
      options: CommandOptions(type: CommandType.all),
      id(
        name,
        (ChatContext context, @Description('Your prompt for AI generation') String prompt) async {
          // Validate command (rate limiting and input validation)
          final validation = AICommandUtils.validateAICommand(
            context: context,
            msgQueue: msgQueue,
            prompt: prompt,
          );

          if (!validation.shouldContinue) {
            if (validation.errorMessage != null) {
              await context.respond(validation.errorMessage!);
            }
            return; // Stop processing - rate limited or invalid input
          }

          print('AskCommand: Processing request for user: ${context.member!.id.value}');
          print('AskCommand: Prompt length: ${prompt.length} characters');

          // Call AI service and get result
          final result = await AICommandUtils.callAIService(
            ref: ref,
            prompt: prompt,
            userid: context.member!.user!.id.toString(),
          );

          // Build and send the response based on the result
          if (result.isSuccess && result.text != null && result.text!.trim().isNotEmpty) {
            final message = AICommandUtils.buildAISuccessMessage(prompt, result.text!);
            await context.respond(message);
            print('AskCommand: Successfully generated response');
          } else {
            final errorMessage = result.error ?? 'No response generated';
            print('AskCommand: API failure - $errorMessage');
            final message = AICommandUtils.buildAIErrorMessage(prompt, errorMessage);
            await context.respond(message);
          }
        },
      ),
    );
    return gemini;
  }
}
