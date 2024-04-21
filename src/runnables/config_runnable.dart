import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:riverpod/src/framework.dart';

import '../config.dart';
import '../constants.dart';
import '../providers.dart';
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
  }) async {
    bool timedOut = false;
    bool canceleld = false;

    void startTimer({
      Duration duration = const Duration(seconds: 60),
    }) {
      _timerForEachInteraction?.cancel();
      _timerForEachInteraction = Timer(duration, () {
        timedOut = true;
        channel.sendMessage(
          createAlertMessage(
            color: EmdedColor.red,
            content: 'Timed out',
            description: 'You took too long to respond. Please try running the command again.',
          ),
        );
        _timerForEachInteraction?.cancel();
      });
    }

    void cancelTimer() {
      _timerForEachInteraction?.cancel();
      _timerForEachInteraction = null;
    }

    final bot = await ref.read(botProvider.future);
    await channel.sendMessage(
      createAlertMessage(
        color: EmdedColor.green,
        content: 'Welcome to the config command. This command will help you set up the bot for the first time.',
      ),
    );
    await channel.sendMessage(MessageBuilder(content: 'Please provide a prefix for the bot.'));
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
        await channel.sendMessage(
          createAlertMessage(
            color: EmdedColor.red,
            content: 'Invalid prefix.',
            description: 'Prefix should be a single word.',
          ),
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

    await channel.sendMessage(
      createAlertMessage(
        color: EmdedColor.green,
        content: 'Prefix set',
        description: 'Prefix has been set to: $prefix.',
      ),
    );

    await channel.sendMessage(
      createAlertMessage(
        color: EmdedColor.green,
        content: 'Please provide a channel id where you want to send mass pings.',
      ),
    );

    final massPingChannelIdCompleter = Completer<int?>();
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
        massPingChannelIdCompleter.complete(null);
        return;
      }
      final channelMentions = event.message.content.split(' ').where((element) => element.startsWith('<#')).toList();
      print('Message ${event.message.content}');
      print(channelMentions);
      if (channelMentions.isEmpty) {
        await channel.sendMessage(createAlertMessage(
          color: EmdedColor.red,
          content: 'Invalid channel id.',
          description: 'Please provide a valid channel id.',
        ));
        return;
      }
      if (channelMentions.length > 1) {
        await channel.sendMessage(
          createAlertMessage(
            color: EmdedColor.red,
            content: 'Invalid channel id.',
            description: 'Please provide only one channel id.',
          ),
        );
        return;
      }
      final firstChannelID = channelMentions.first.replaceAll('<#', '').replaceAll('>', '');
      final channelId = int.parse(firstChannelID);

      massPingChannelIdCompleter.complete(channelId);
      subscription.cancel();
    });

    final massPingChannelId = await massPingChannelIdCompleter.future;
    if (timedOut || canceleld) {
      return;
    } else {
      cancelTimer();
    }

    await channel.sendMessage(
      createAlertMessage(
        color: EmdedColor.green,
        content: 'Mass ping channel set',
        description: 'Mass ping channel has been set to: <#$massPingChannelId>.',
      ),
    );
    ref.read(configProvider).setConfig(Config(prefix: "!${prefix!}", massPingChannelID: massPingChannelId!));
    await channel.sendMessage(
      createAlertMessage(
        color: EmdedColor.green,
        content: 'Congrats!',
        description:
            'Config has been set you can now start using the bot using !$prefix. Type !$prefix help for more info',
      ),
    );
  }
}
