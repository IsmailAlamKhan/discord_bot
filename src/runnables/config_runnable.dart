import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:riverpod/src/framework.dart';

import '../bot.dart';
import '../config.dart';
import '../constants.dart';
import '../listen_to_message.dart';
import '../member_change.dart';
import 'runnables.dart';

Timer? _timerForEachInteraction;

class ConfigRunnable extends Runnable {
  const ConfigRunnable();

  @override
  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required PartialMember member,
    required MessageCreateEvent messageCreateEvent,
  }) async {
    bool timedOut = false;
    bool canceleld = false;

    void startTimer({
      Duration duration = const Duration(seconds: 60),
    }) {
      _timerForEachInteraction?.cancel();
      _timerForEachInteraction = Timer(duration, () {
        timedOut = true;
        sendMessage(
          channel: channel,
          message: createAlertMessage(
            color: EmdedColor.red,
            content: 'Timed out',
            description: 'You took too long to respond. Please try running the command again.',
          )..referencedMessage = MessageReferenceBuilder.reply(messageId: messageCreateEvent.message.id),
        );
        _timerForEachInteraction?.cancel();
      });
    }

    void cancelTimer() {
      _timerForEachInteraction?.cancel();
      _timerForEachInteraction = null;
    }

    final bot = await ref.read(botProvider.future);
    sendMessage(
      channel: channel,
      message: createAlertMessage(
        color: EmdedColor.green,
        content: 'Welcome to the config command. This command will help you set up the bot for the first time.',
      )..referencedMessage = MessageReferenceBuilder.reply(messageId: messageCreateEvent.message.id),
    );
    // await channel.sendMessage(MessageBuilder(content: 'Please provide a prefix for the bot.'));
    await channel.sendMessage(
      createAlertMessage(
        color: EmdedColor.green,
        content: 'Please provide a prefix for the bot.',
      )..referencedMessage = MessageReferenceBuilder.reply(messageId: messageCreateEvent.message.id),
    );
    startTimer();
    final prefixCompleter = Completer<String?>();

    late StreamSubscription<MessageCreateEvent> subscription;
    subscription = bot.onMessageCreate.listen((event) async {
      if (event.message.author.id != member.id) {
        return;
      }
      if (isCancel(event.message.content)) {
        await channel.sendMessage(createCancelMessage());
        prefixCompleter.complete(null);
        subscription.cancel();
        canceleld = true;

        return;
      }
      if (timedOut) {
        subscription.cancel();
        prefixCompleter.complete(null);
        return;
      }

      final message = event.message.content;
      final isSingleWord = message.split(' ').length == 1;
      if (!isSingleWord) {
        sendMessage(
          channel: channel,
          message: createAlertMessage(
            color: EmdedColor.red,
            content: 'Invalid prefix.',
            description: 'Prefix should be a single word.',
          )..referencedMessage = MessageReferenceBuilder.reply(messageId: event.message.id),
        );

        return;
      }
      prefixCompleter.complete(event.message.content.toLowerCase());
      subscription.cancel();
    });

    var prefix = await prefixCompleter.future;
    if (timedOut || canceleld) {
      return;
    } else {
      cancelTimer();
    }

    sendMessage(
      channel: channel,
      message: createAlertMessage(
        color: EmdedColor.green,
        content: 'Prefix set',
        description: 'Prefix has been set to: $prefix.',
      )..referencedMessage = MessageReferenceBuilder.reply(messageId: messageCreateEvent.message.id),
    );
    ref.read(configProvider).setConfig(Config(prefix: "!${prefix!}"));
    sendMessage(
      channel: channel,
      message: createAlertMessage(
        color: EmdedColor.green,
        content: 'Congrats!',
        description:
            'Config has been set you can now start using the bot using !$prefix. Type !$prefix help for more info',
      )..referencedMessage = MessageReferenceBuilder.reply(messageId: messageCreateEvent.message.id),
    );
    await ref.read(messageListenerProvider).restart();
    await ref.read(memberChangeProvider).restart();
  }
}
