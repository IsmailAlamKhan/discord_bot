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

// enum Command {
//   massPing(
//     command: "mass-ping",
//     description:
//         "Mass ping a user. Usage: mass-ping <user-id> [stop](E.g. !mass-ping <@1231515227158347796> @user stop)",
//     arguments: [CommandArgument('user-id', false), CommandArgument('stop', true)],
//     runnable: MassPingRunnable(),
//     alias: 'mp',
//   ),
//   config(
//     command: "config",
//     description: "Get or set the bot configuration.",
//     arguments: [CommandArgument('prefix', true), CommandArgument('mass-ping-channel-id', true)],
//     runnable: ConfigRunnable(),
//   ),
//   help(
//     // "help",
//     // "Get help for the bot commands.",
//     command: "help",
//     description: "Get help for the bot commands.",
//     runnable: HelpRunnable(),
//   );

//   final String command;
//   final String description;
//   final List<CommandArgument> arguments;
//   final Runnable runnable;
//   final String? alias;
//   const Command({
//     required this.command,
//     required this.description,
//     required this.runnable,
//     this.arguments = const [],
//     this.alias,
//   });
// }

class Command {
  final String command;
  final String description;
  final List<CommandArgument> arguments;
  final Runnable runnable;
  final String? alias;
  final String name;
  const Command({
    required this.command,
    required this.description,
    required this.runnable,
    this.arguments = const [],
    this.alias,
  }) : name = command;

  static const massPing = Command(
    command: "mass-ping",
    description:
        "Mass ping a user. Usage: mass-ping <user-id> [stop](E.g. !mass-ping <@1231515227158347796> @user stop)",
    arguments: [CommandArgument('user-id', false), CommandArgument('stop', true)],
    runnable: MassPingRunnable(),
    alias: 'mp',
  );

  static const config = Command(
    command: "config",
    alias: 'conf',
    description: "Get or set the bot configuration",
    runnable: ConfigRunnable(),
  );

  static const help = Command(
    command: "help",
    alias: 'h',
    description: "Get help for the bot commands",
    runnable: HelpRunnable(),
  );

  static const values = [massPing, config, help];
}
