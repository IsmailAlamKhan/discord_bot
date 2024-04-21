import 'package:collection/collection.dart';
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import '../src/commands/commands.dart';

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
    "mass-ping",
    "Mass ping a user. Usage: mass-ping <user-id> [stop](E.g. !mass-ping <@1231515227158347796> @user stop)",
    [CommandArgument('user-id', false), CommandArgument('stop', true)],
  ),
  help("help", "Get help for the bot commands.");

  final String command;
  final String description;
  final List<CommandArgument> arguments;
  const Command(
    this.command,
    this.description, [
    this.arguments = const [],
  ]);
}

final envProvider = Provider<DotEnv>((ref) {
  return DotEnv()..load();
});

final botProvider = FutureProvider<NyxxGateway>((ref) {
  final env = ref.read(envProvider);
  final token = env['BOT_TOKEN']!;
  return Nyxx.connectGateway(
    token,
    GatewayIntents.all,
    options: GatewayClientOptions(
      plugins: [
        Logging(),
        CliIntegration(),
        IgnoreExceptions(),
      ],
    ),
  );
});

Future<void> main() async {
  final ref = ProviderContainer();

  final env = ref.read(envProvider);

  final prefix = env['PREFIX']!;

  final bot = await ref.read(botProvider.future);

  bot.onMessageCreate.listen((event) async {
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
      await Commands.parseCommand(
        ref: ref,
        arguments: arguments,
        channel: msgChannel,
        command: command,
      );
    }

    // /// Getting the arguments.
    // String? userId;
    // if (commandList.length > 1) {
    //   final arguement = commandList[1];
    //   if (arguement.startsWith('<@') && arguement.endsWith('>')) {
    //     userId = commandList[1];
    //   } else if (arguement == 'stop') {
    //     msgChannel.sendMessage(MessageBuilder.content('Stopping mass ping...'));
    //     cron.close();
    //     return;
    //   }
    // }

    // print("Command: $command, $userId");
    // if (userId == null) {
    //   msgChannel.sendMessage(MessageBuilder.content('Invalid command Please provide a user to ping.'));
    //   return;
    // }
    // print("Command: $command, $userId");

    // // if (!regex.hasMatch(userId[0])) {
    // if (command == prefix.toLowerCase()) {
    //   Commands.sendMassPing(msgChannel, userId);
    // }
    // return;
    // // }
  });
}
