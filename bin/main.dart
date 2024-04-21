import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import '../src/config.dart';
import '../src/providers.dart';
import '../src/runnables/config_runnable.dart';
import '../src/runnables/runnables.dart';

class CommandArgument {
  final String argument;
  final bool isOptional;
  const CommandArgument(this.argument, this.isOptional);

  @override
  String toString() {
    return argument;
  }
}

enum Command {
  massPing(
    command: "mass-ping",
    description:
        "Mass ping a user. Usage: mass-ping <user-id> [stop](E.g. !mass-ping <@1231515227158347796> @user stop)",
    arguments: [CommandArgument('user-id', false), CommandArgument('stop', true)],
    runnable: MassPingRunnable(),
  ),
  config(
    command: "config",
    description: "Get or set the bot configuration.",
    arguments: [CommandArgument('prefix', true), CommandArgument('mass-ping-channel-id', true)],
    runnable: ConfigRunnable(),
  ),
  help(
    // "help",
    // "Get help for the bot commands.",
    command: "help",
    description: "Get help for the bot commands.",
    runnable: HelpRunnable(),
  );

  final String command;
  final String description;
  final List<CommandArgument> arguments;
  final Runnable runnable;
  const Command({
    required this.command,
    required this.description,
    required this.runnable,
    this.arguments = const [],
  });
}

Future<void> main() async {
  final ref = ProviderContainer();

  final env = ref.read(envProvider);
  final config = ref.read(configProvider);

  await env.init();
  config.init();

  var (currentConfig, _) = config.getConfig;

  final bot = await ref.read(botProvider.future);

  bot.onMessageCreate.listen((event) async {
    var prefix = currentConfig?.prefix;
    final isBotMentioned = event.message.mentions.contains(bot.user);
    if (isBotMentioned && currentConfig == null) {
      event.message.channel.sendMessage(
        MessageBuilder(
          content: 'Bot is not configured. Running the config command.',
        ),
      );
      await Command.config.runnable.run(
        ref: ref,
        arguments: [],
        channel: event.message.channel,
        member: event.member!,
      );
      final (newConfig, _) = ref.read(configProvider).getConfig;
      currentConfig = newConfig;
      prefix = newConfig?.prefix;
      print('New prefix: $prefix');
      return;
    }
    print('Prefix: $prefix');
    if (prefix == null) {
      return;
    }
    if (!event.message.content.startsWith(prefix)) {
      print('Message does not start with prefix: $prefix: ${event.message.content}');
      return;
    } else {
      print('Event received: ${event.message.content}');
    }

    /// Get Message Content
    final msgContent = event.message.content;

    final msgChannel = event.message.channel;

    /// Splitting the command to get the command name and the arguments.
    final commandList = msgContent.split(' ');

    /// Getting the command name.
    final command = Command.values.firstWhereOrNull((element) => element.command == commandList[1]);
    List<String> arguments = [];
    if (commandList.length > 2) {
      arguments = commandList.sublist(2);
    }
    final member = event.member;

    if (command == null) {
      final buffer = StringBuffer();
      buffer.write('Invalid command. Available commands are: ');
      for (var element in Command.values) {
        buffer.write('${element.command}, ');
        if (element.arguments.isNotEmpty) {
          buffer.write('Arguments: ${element.arguments.join(', ')}');
        }
      }
      msgChannel.sendMessage(MessageBuilder(content: buffer.toString()));
    } else {
      await command.runnable.run(
        ref: ref,
        arguments: arguments,
        channel: msgChannel,
        member: member!,
      );
    }
  });
}
