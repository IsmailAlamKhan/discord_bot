import 'dart:async';

import 'package:cron/cron.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import '../../bin/discord_spam_bot.dart';

// final cron = Cron();
final pingCrons = <String, Cron>{};

class Commands {
  static Future<void> parseCommand({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required Command command,
  }) async {
    final commands = Commands();
    switch (command) {
      case Command.massPing:
        await commands._sendMassPing(ref: ref, msgChannel: channel, arguments: arguments);
        break;
      case Command.help:
        await commands._sendHelp(ref: ref, msgChannel: channel);
        break;
    }
  }

  Future<void> _sendHelp({
    required ProviderContainer ref,
    required PartialTextChannel msgChannel,
  }) {
    final helpMessage = Command.values.map((e) => '${e.command}: ${e.description}').join('\n');
    return msgChannel.sendMessage(
      MessageBuilder(
        embeds: [
          EmbedBuilder(
            color: DiscordColor(0xFA383B),
            author: EmbedAuthorBuilder(name: 'Help'),
            description: "Welcome to the help menu. Here are the available commands: \n$helpMessage.",
            footer: EmbedFooterBuilder(
              text:
                  "The bot was built by Md Ismail Alam Khan with a bit of help from Tomic Riedel. The code for the bot can be found at: ",
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMassPing({
    required ProviderContainer ref,
    required PartialTextChannel msgChannel,
    required List<String> arguments,
  }) async {
    final bot = await ref.read(botProvider.future);

    PartialTextChannel? massPingChannel;
    try {
      massPingChannel = PartialTextChannel(id: Snowflake(1231544520693252188), manager: bot.channels);
      await massPingChannel.fetch();
    } on Exception catch (e) {
      if (e.toString().contains('Unknown Channel')) {
        print('Channel not found in the guild.');
      }
      massPingChannel = null;
    }

    if (massPingChannel == null) {
      print('Mass ping channel not found in the guild-=----.');
      await msgChannel.sendMessage(MessageBuilder(content: 'Mass ping channel not found in the guild.'));
      return;
    }

    if (arguments.isEmpty) {
      await msgChannel.sendMessage(MessageBuilder(content: 'Invalid command. Please provide a user to ping.'));
      return;
    }
    final userId = arguments[0];
    if (!userId.contains('<@')) {
      await msgChannel.sendMessage(
        MessageBuilder(content: 'Invalid command. Please provide a user to start massping or stop.'),
      );
      return;
    }
    final isStop = arguments.length > 1 && arguments[1] == 'stop';
    var cron = pingCrons[userId];
    if (isStop) {
      await msgChannel.sendMessage(MessageBuilder(content: 'Stopping mass ping for user $userId...'));
      cron?.close();
      pingCrons.remove(userId);
      return;
    }
    if (cron != null) {
      await msgChannel.sendMessage(MessageBuilder(content: 'Mass ping already running for user $userId...'));
      return;
    }
    cron = Cron();
    pingCrons[userId] = cron;

    await msgChannel.sendMessage(MessageBuilder(content: 'Starting mass ping for user $userId...'));
    massPingChannel.sendMessage(MessageBuilder(content: '$userId ANSWER!!!!!'));
    cron.schedule(Schedule.parse('*/2 * * * * *'), () async {
      massPingChannel!.sendMessage(MessageBuilder(content: '$userId ANSWER!!!!!'));
    });
  }
}
