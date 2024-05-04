import 'package:cron/cron.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/framework.dart';

import '../bot.dart';
import '../cron.dart';
import '../env.dart';
import 'runnables.dart';

class MassPingRunnable extends Runnable {
  const MassPingRunnable();
  @override
  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required PartialMember member,
    required MessageCreateEvent messageCreateEvent,
  }) async {
    final bot = await ref.read(botProvider.future);
    final pingCrons = ref.read(pingCronsProvider);

    final userId = arguments[0];
    var senderUserId = member.id.value.toString();
    senderUserId = '<@$senderUserId>';
    final isStop = arguments.length > 1 && arguments[1] == 'stop';
    final env = ref.read(envProvider);
    final adminUserId = env.adminUserId;

    final key = PingCronKey(senderUserId: senderUserId, receiverUserId: userId);
    final adminKey = PingCronKey(senderUserId: adminUserId, receiverUserId: userId);

    if (arguments.isEmpty) {
      await channel.sendMessage(MessageBuilder(content: 'Invalid command. Please provide a user to ping.'));
      return;
    }
    if (!userId.contains('<@')) {
      await channel.sendMessage(
        MessageBuilder(content: 'Invalid command. Please provide a user to start massping or stop.'),
      );
      return;
    }
    var cron = pingCrons.get(key);
    cron ??= pingCrons.get(adminKey);

    PartialTextChannel? massPingChannel = cron?.channel;
    final guild = messageCreateEvent.guild!;
    if (massPingChannel == null) {
      try {
        final sender = await member.fetch();
        final receiver = await guild.members.get(Snowflake.parse(userId.replaceAll(RegExp(r'[<@!>]'), '')));
        final senderName = sender.user!.username;
        final receiverName = receiver.user!.username;
        final channel = await guild.createChannel(
          GuildChannelBuilder(
            name: 'mass-ping-$receiverName-$senderName',
            type: ChannelType.guildText,
          ),
          auditLogReason: 'Mass ping channel Created for user $receiverName requested by $senderName',
        );
        massPingChannel = PartialTextChannel(id: channel.id, manager: bot.channels);
        await massPingChannel.fetch();
      } on Exception catch (e) {
        if (e.toString().contains('Unknown Channel')) {
          print('Channel not found in the guild.');
        } else {
          print('Error creating channel: $e');
        }
        massPingChannel = null;
      }
    }

    if (massPingChannel == null) {
      print('Mass ping channel not found in the guild-=----.');
      await channel.sendMessage(MessageBuilder(content: 'Mass ping channel not found in the guild.'));
      return;
    }

    if (isStop) {
      if (cron == null) {
        await channel
            .sendMessage(MessageBuilder(content: 'Looks like you have not started mass ping for user $userId...'));
      } else {
        await channel.sendMessage(MessageBuilder(content: 'Stopping mass ping for user $userId...'));
        await massPingChannel.delete(auditLogReason: 'Mass ping channel deleted.');
        cron.close();
        pingCrons.remove(key);
        pingCrons.remove(adminKey);
      }
      return;
    }
    if (cron != null) {
      await channel.sendMessage(MessageBuilder(content: 'Mass ping already running for user $userId...'));
      return;
    }
    // cron = Cron();
    // pingCrons[
    pingCrons.add(key, massPingChannel);
    pingCrons.add(adminKey, massPingChannel);
    cron = pingCrons[key]!;

    await channel.sendMessage(MessageBuilder(content: 'Starting mass ping for user $userId...'));
    final msg = '$userId ANSWER ME!!!!!!!!!!';
    final memberDetails = await member.get();
    final messageBuilder = MessageBuilder(
      content: msg,
      embeds: [
        EmbedBuilder(
          author: EmbedAuthorBuilder(
            name: memberDetails.user!.username,
            iconUrl: memberDetails.user!.avatar.url,
          ),
          color: DiscordColor(0x00ff00),
          footer: EmbedFooterBuilder(text: 'Mass ping'),
        ),
      ],
    );

    massPingChannel.sendMessage(messageBuilder);
    cron.cron.schedule(Schedule.parse('*/2 * * * * *'), () => massPingChannel!.sendMessage(messageBuilder));
  }
}
