import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:riverpod/src/framework.dart';

import '../gemini_service.dart';
import '../msg_queue.dart';
import 'commands.dart';

class GeminiCommand extends SlashRunnable {
  final MsgQueue msgQueue;

  GeminiCommand() : msgQueue = MsgQueue();

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
          final member = context.member!.id.value;
          final shouldShow = msgQueue.addMessage(member);
          if (shouldShow) {
            await context.respond(
              MessageBuilder(
                content:
                    'You have requested too many times in the last 10 minutes. Please wait 10 minutes before using this command again.',
              ),
            );
            // return null;
          }
          print('GeminiCommand: context: $context');
          final geminiService = ref.read(geminiServiceProvider);

          if (prompt.isEmpty) {
            context.respond(MessageBuilder(content: 'Please provide a prompt to generate text.'));
            return null;
          }
          try {
            final result = await geminiService.generateText(prompt);
            print('GeminiCommand: result: $result');
            if (result.text != null && result.text!.isNotEmpty) {
              // return result;
              context.respond(MessageBuilder(content: result.text!));
            } else {
              context.respond(MessageBuilder(content: 'An error occurred while generating text.'));
            }
          } catch (e) {
            print('GeminiCommand: error: $e');
            // return null;
            context.respond(MessageBuilder(content: 'An error occurred while generating text.'));
          }
        },
      ),
    );
    return gemini;
  }
}
