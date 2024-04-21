import 'package:cron/cron.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/framework.dart';

import '../providers.dart';
import 'runnables.dart';

class MassPingRunnable extends Runnable {
  const MassPingRunnable();
  @override
  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
  }) async {
    final bot = await ref.read(botProvider.future);
    final pingCrons = ref.read(pingCronsProvider);
    final env = ref.read(envProvider);

    PartialTextChannel? massPingChannel;
    try {
      massPingChannel = PartialTextChannel(id: Snowflake(env.massPingChannelId), manager: bot.channels);
      await massPingChannel.fetch();
    } on Exception catch (e) {
      if (e.toString().contains('Unknown Channel')) {
        print('Channel not found in the guild.');
      }
      massPingChannel = null;
    }

    if (massPingChannel == null) {
      print('Mass ping channel not found in the guild-=----.');
      await channel.sendMessage(MessageBuilder(content: 'Mass ping channel not found in the guild.'));
      return;
    }

    if (arguments.isEmpty) {
      await channel.sendMessage(MessageBuilder(content: 'Invalid command. Please provide a user to ping.'));
      return;
    }
    final userId = arguments[0];
    if (!userId.contains('<@')) {
      await channel.sendMessage(
        MessageBuilder(content: 'Invalid command. Please provide a user to start massping or stop.'),
      );
      return;
    }
    final isStop = arguments.length > 1 && arguments[1] == 'stop';
    var cron = pingCrons[userId];
    if (isStop) {
      await channel.sendMessage(MessageBuilder(content: 'Stopping mass ping for user $userId...'));
      cron?.close();
      pingCrons.remove(userId);
      return;
    }
    if (cron != null) {
      await channel.sendMessage(MessageBuilder(content: 'Mass ping already running for user $userId...'));
      return;
    }
    cron = Cron();
    pingCrons[userId] = cron;

    await channel.sendMessage(MessageBuilder(content: 'Starting mass ping for user $userId...'));
    massPingChannel.sendMessage(MessageBuilder(content: '$userId ANSWER!!!!!'));
    cron.schedule(Schedule.parse('*/2 * * * * *'), () async {
      massPingChannel!.sendMessage(MessageBuilder(content: '$userId ANSWER!!!!!'));
    });
  }
}
