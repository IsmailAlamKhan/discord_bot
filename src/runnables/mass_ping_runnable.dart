import 'package:cron/cron.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/framework.dart';

import '../config.dart';
import '../cron.dart';
import '../providers.dart';
import 'runnables.dart';

class MassPingRunnable extends Runnable {
  const MassPingRunnable();
  @override
  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required PartialMember member,
  }) async {
    final bot = await ref.read(botProvider.future);
    final pingCrons = ref.read(pingCronsProvider);
    final (config, configError) = ref.read(configProvider).getConfig;
    if (configError != null) {
      await channel.sendMessage(MessageBuilder(content: configError));
      return;
    }

    PartialTextChannel? massPingChannel;
    try {
      massPingChannel = PartialTextChannel(id: Snowflake(config!.massPingChannelID), manager: bot.channels);
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
    var senderUserId = member.id.value.toString();
    senderUserId = '<@$senderUserId>';

    final key = PingCronKey(senderUserId: senderUserId, receiverUserId: userId);

    var cron = pingCrons[key];
    if (isStop) {
      if (cron == null) {
        await channel
            .sendMessage(MessageBuilder(content: 'Looks like you have not started mass ping for user $userId...'));
      } else {
        await channel.sendMessage(MessageBuilder(content: 'Stopping mass ping for user $userId...'));
        cron.close();
        pingCrons.remove(key);
      }
      return;
    }
    if (cron != null) {
      await channel.sendMessage(MessageBuilder(content: 'Mass ping already running for user $userId...'));
      return;
    }
    // cron = Cron();
    // pingCrons[
    pingCrons.add(key);
    cron = pingCrons[key]!;

    await channel.sendMessage(MessageBuilder(content: 'Starting mass ping for user $userId...'));
    final msg = '$userId ANSWER ME!!!!!!!!!!';
    final memberDetails = await member.get();
    final messageBuilder = MessageBuilder(embeds: [
      EmbedBuilder(
        author: EmbedAuthorBuilder(
          name: memberDetails.user!.username,
          iconUrl: memberDetails.user!.avatar.url,
        ),
        color: DiscordColor(0x00ff00),
        description: msg,
        footer: EmbedFooterBuilder(text: 'Mass ping'),
      ),
    ]);
    massPingChannel.sendMessage(messageBuilder);
    cron.schedule(Schedule.parse('*/2 * * * * *'), () => massPingChannel!.sendMessage(messageBuilder));
  }
}
