import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import '../bot.dart';
import '../config.dart';
import '../constants.dart';
import '../extensions.dart';
import '../runnables/runnables.dart';
import '../utils/discord_response_utils.dart';

class AIRunnable extends Runnable {
  const AIRunnable();

  @override
  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required PartialMember member,
    required MessageCreateEvent messageCreateEvent,
  }) async {
    final bot = await ref.read(botProvider.future);
    final (config, _) = ref.read(configProvider).getConfig;
    if (config == null) {
      await channel.sendMessage(createAlertMessageForAI(content: 'Config not found.', color: EmdedColor.red));
      return;
    }

    // remove "!{config.prefix}" and "ai" from the prompt
    var prompt = messageCreateEvent.message.content;
    prompt = prompt.replaceFirst(config.prefix, '').replaceFirst('ai', '').trim();

    print("Prompt: $prompt");

    if (prompt.isEmpty) {
      await channel.sendMessage(createAlertMessageForAI(content: 'Please provide a prompt.', color: EmdedColor.red));
      return;
    }

    final message = await channel.sendMessage(
      MessageBuilder(content: 'Generating a response...')
        ..referencedMessage = MessageReferenceBuilder.reply(messageId: messageCreateEvent.message.id),
    );

    await channel.manager.triggerTyping(channel.id);
    final result = await AICommandUtils.callAIService(
      container: ref,
      prompt: prompt,
    );

    // Build and send the response based on the result
    if (result.isSuccess && result.text != null && result.text!.trim().isNotEmpty) {
      final updatedMessage = AICommandUtils.buildAISuccessMessage(prompt, result.text!);
      message.edit(updatedMessage.toMessageUpdateBuilder());
    } else {
      final errorMessage = result.error ?? 'No response generated';
      final updatedMessage = AICommandUtils.buildAIErrorMessage(prompt, errorMessage);
      message.edit(updatedMessage.toMessageUpdateBuilder());
    }
  }
}
