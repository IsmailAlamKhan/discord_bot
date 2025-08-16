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
    final msgBuilder = this.messageBuilder(messageCreateEvent);

    if (arguments.isEmpty || !userId.contains('<@')) {
      sendMessage(
        channel: channel,
        message: msgBuilder..content = 'Invalid command. Please provide a user to start massping or stop.',
      );
      return;
    }
    var cron = pingCrons.get(key);
    cron ??= pingCrons.get(adminKey);

    PartialTextChannel? massPingChannel = cron?.channel;
    final guild = messageCreateEvent.guild!;

    // Create a private channel for mass pinging
    if (massPingChannel == null) {
      try {
        final sender = await member.fetch();
        final targetUserId = Snowflake.parse(userId.replaceAll(RegExp(r'[<@!>]'), ''));
        final receiver = await guild.members.get(targetUserId);
        final senderName = sender.user!.username;
        final receiverName = receiver.user!.username;

        // Create a private text channel with restricted permissions
        final createdChannel = await guild.createChannel(
          GuildChannelBuilder(
            name: 'mass-ping-$receiverName-$senderName',
            type: ChannelType.guildText,
            // Set up permission overwrites to make it private
            permissionOverwrites: [
              // Deny @everyone from seeing the channel
              PermissionOverwriteBuilder(
                id: guild.id, // @everyone role has the same ID as the guild
                type: PermissionOverwriteType.role,
                deny: Permissions.viewChannel,
              ),
              // Allow the target user to see and use the channel
              PermissionOverwriteBuilder(
                id: targetUserId,
                type: PermissionOverwriteType.member,
                allow: Permissions.viewChannel | Permissions.sendMessages | Permissions.readMessageHistory,
              ),
              // Allow the sender to see the channel
              PermissionOverwriteBuilder(
                id: member.id,
                type: PermissionOverwriteType.member,
                allow: Permissions.viewChannel | Permissions.sendMessages | Permissions.readMessageHistory,
              ),
              // Allow the bot to see and manage the channel
              PermissionOverwriteBuilder(
                id: bot.user.id,
                type: PermissionOverwriteType.member,
                allow: Permissions.viewChannel |
                    Permissions.sendMessages |
                    Permissions.readMessageHistory |
                    Permissions.manageChannels,
              ),
            ],
          ),
          auditLogReason: 'Private mass ping channel created for user $receiverName requested by $senderName',
        );
        massPingChannel = PartialTextChannel(id: createdChannel.id, manager: bot.channels);
        await massPingChannel.fetch();
        print('Created private mass ping channel for: $receiverName requested by $senderName');
      } on Exception catch (e) {
        print('Error creating private channel: $e');
        await sendMessage(
          channel: channel,
          message: msgBuilder..content = 'Could not create private mass ping channel: $e',
        );
        return;
      }
    }

    // massPingChannel should always be non-null at this point due to the logic above
    print('Private mass ping channel id: ${massPingChannel.id.value}');

    if (isStop) {
      if (cron == null) {
        await sendMessage(
          channel: channel,
          message: msgBuilder..content = 'Looks like you have not started mass ping for user $userId...',
        );
      } else {
        await sendMessage(
          channel: channel,
          message: msgBuilder..content = 'Stopping mass ping for user $userId...',
        );
        // Delete the private channel when stopping
        try {
          await massPingChannel.delete(auditLogReason: 'Mass ping stopped - removing private channel');
          print('Deleted private mass ping channel for user $userId');
        } catch (e) {
          print('Could not delete private mass ping channel: $e');
        }
        cron.close();
        pingCrons.remove(key);
        pingCrons.remove(adminKey);
      }
      return;
    }
    if (cron != null) {
      await sendMessage(
        channel: channel,
        message: msgBuilder..content = 'Mass ping already running for user $userId...',
      );
      return;
    }
    pingCrons.add(key, massPingChannel);
    pingCrons.add(adminKey, massPingChannel);
    cron = pingCrons[key]!;

    await sendMessage(
      channel: channel,
      message: msgBuilder..content = 'Starting mass ping for user $userId in a private channel...',
    );

    final msg = '$userId ANSWER ME!!!!!!!!!!';
    final memberDetails = await member.get();

    final messageBuilder = messageBuilderWithoutReply(messageCreateEvent)
      ..content = msg
      ..embeds = [
        EmbedBuilder(
          author: EmbedAuthorBuilder(
            name: memberDetails.user!.username,
            iconUrl: memberDetails.user!.avatar.url,
          ),
          color: DiscordColor(0x00ff00),
          footer: EmbedFooterBuilder(text: 'Mass ping'),
        ),
      ];

    // Send the first message immediately to the private channel
    await sendMessage(
      channel: massPingChannel,
      message: messageBuilder,
    );

    // Schedule recurring messages every 2 seconds
    cron.cron.schedule(Schedule.parse('*/2 * * * * *'), () => massPingChannel!.sendMessage(messageBuilder));
  }
}
