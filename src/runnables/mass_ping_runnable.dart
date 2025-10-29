import 'dart:math';

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
    required Member member,
    required MessageCreateEvent messageCreateEvent,
  }) async {
    final bot = await ref.read(botProvider.future);
    final pingCrons = ref.read(pingCronsProvider);

    final userId = arguments[0];
    var senderUserId = member.user!.id.value.toString();
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
    if (userId == senderUserId) {
      await sendMessage(
        channel: channel,
        message: msgBuilder..content = 'You cannot mass ping yourself!',
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
        // Only the initiator and the admin can stop the ping
        final canStop = cron.initiator == senderUserId || senderUserId == adminUserId;
        final isAdminStopping = senderUserId == adminUserId;

        if (!canStop) {
          // Pick a random funny response to toy with them
          final teasingResponses = [
            (
              message: '🎵 Never gonna give you up, never gonna let this ping stop! 🎵',
              gif:
                  'https://tenor.com/view/rick-roll-rickroll-rick-rolled-rick-astley-never-gonna-give-you-up-gif-11884619245704429944'
            ),
            (
              message: 'Did you really think YOU could stop this? Only the sender has that power! 😂',
              gif: 'https://tenor.com/view/sarcastic-laugh-mocking-blah-blah-blah-ha-ha-ha-blah-gif-7015237656172556429'
            ),
            (
              message: 'Nice try, but you\'re not the boss of this ping train! 🚂',
              gif: 'https://tenor.com/view/laughing-mocking-funny-try-not-to-laugh-me-in-serious-situation-gif-16447979'
            ),
            (
              message: 'Oh, you want it to stop? That\'s hilarious. 💀',
              gif: 'https://tenor.com/view/ha-ha-laughing-mocking-laugh-mock-gif-19458243'
            ),
            (message: 'Skill issue detected 💀', gif: 'https://tenor.com/view/skill-issue-gif-19411985'),
            (
              message: 'L + ratio\'d by a Discord bot',
              gif: 'https://tenor.com/view/diagnosis-skill-issue-diagnosis-skill-issue-draker-discord-gif-22231351'
            ),
            (message: 'You lack the authority, peasant 👑', gif: 'https://tenor.com/search/you-have-no-power-gifs'),
            (message: 'Plot twist: pings are eternal now ✾️', gif: 'https://tenor.com/search/no-respect-gifs'),
            (
              message: 'Blame the sender, not me! I\'m just following orders 🤖',
              gif: 'https://tenor.com/view/good-job-laughing-mocking-gif-16105078462327936561'
            ),
            (
              message: 'I\'ll *maybe* consider stopping in 30 seconds... just kidding! ⏰',
              gif: 'https://tenor.com/view/mocking-laughing-mock-laugh-ephiria-gif-24650598'
            ),
            (
              message: 'Nice attempt at a rebellion! 🏴',
              gif: 'https://tenor.com/view/laughing-laugh-mocking-nwave-the-inseparables-gif-10995603239514618207'
            ),
            (
              message: '🚫 Unauthorized stop attempt detected 🚫',
              gif: 'https://tenor.com/view/denied-rejected-defied-refused-dejected-gif-1304492046723643140'
            ),
            (message: 'Your ping privileges have been REVOKED 😏', gif: 'https://tenor.com/search/denied-gifs'),
            (
              message: 'Did you think this was democratic? LOL',
              gif: 'https://tenor.com/view/no-denied-deny-reject-rejected-gif-9854322096812566874'
            ),
            (
              message: 'The pinging will continue until morale improves!',
              gif: 'https://tenor.com/search/respect-my-authority-gifs'
            ),
          ];

          final randomResponse = teasingResponses[Random().nextInt(teasingResponses.length)];
          await sendMessage(
              channel: channel, message: msgBuilder..content = '${randomResponse.message}\n${randomResponse.gif}');
          return;
        } else {
          // Determine the stop message based on who's stopping and who's being pinged
          final pingingUserId = cron.pinging.replaceAll(RegExp(r'[<@!>]'), '');
          final isAdminStoppingThemself = isAdminStopping && senderUserId == pingingUserId;
          final isAdminStoppingOther = isAdminStopping && senderUserId != pingingUserId;
          print("Is Admin Stopping other $isAdminStoppingOther");
          print("Is Admin Stopping themselves $isAdminStoppingThemself");
          print("USER $senderUserId $pingingUserId");
          late String stopMessage;
          if (isAdminStoppingThemself) {
            // Admin is stopping their own ping - savage responses to the initiator
            final adminCurseResponses = [
              (
                message: '😈 Hah, you thought I can\'t stop it? WATCH THIS <@${cron.initiator}>! 😈',
                gif:
                    'https://tenor.com/view/sarcastic-laugh-mocking-blah-blah-blah-ha-ha-ha-blah-gif-7015237656172556429'
              ),
              (
                message: '🔥 Oh look at that, turns out I CAN stop it whenever I want! <@${cron.initiator}> 🔥',
                gif:
                    'https://tenor.com/view/laughing-mocking-funny-try-not-to-laugh-me-in-serious-situation-gif-16447979'
              ),
              (
                message: '😡 IMAGINE THINKING YOU CAN TORTURE ME! <@${cron.initiator}> YOU\'RE DONE! 😡',
                gif: 'https://tenor.com/view/ha-ha-laughing-mocking-laugh-mock-gif-19458243'
              ),
              (
                message: '🤠 Yeah yeah, I\'m ending this. Nice try <@${cron.initiator}>, better luck next time! 🤠',
                gif: 'https://tenor.com/view/smug-satisfied-cocky-arrogant-confident-gif-13920833'
              ),
            ];

            final randomCurse = adminCurseResponses[Random().nextInt(adminCurseResponses.length)];
            stopMessage = '${randomCurse.message}\n${randomCurse.gif}';
          } else if (isAdminStoppingOther) {
            // Admin is stopping someone else's ping - pity message
            stopMessage = '😔 *The Admin felt a twinge of pity* 😔\n'
                'They have graciously ended your suffering. Perhaps they\'re not so cruel after all... '
                'or maybe they were just tired of hearing about it. Either way, you\'re welcome!';
          } else {
            // Regular sender stopping their own ping
            stopMessage = 'Stopping mass ping for user $userId...';
          }

          await sendMessage(
            channel: channel,
            message: msgBuilder..content = stopMessage,
          );
        }

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
    pingCrons.add(
      key: key,
      channel: massPingChannel,
      initiator: senderUserId,
      pinning: userId,
    );
    pingCrons.add(
      key: adminKey,
      channel: massPingChannel,
      initiator: senderUserId,
      pinning: userId,
    );
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
