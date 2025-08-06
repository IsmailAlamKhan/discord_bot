import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:riverpod/riverpod.dart';

import 'commands/commands.dart';
import 'env.dart';

final botProvider = FutureProvider<NyxxGateway>((ref) async {
  final env = ref.read(envProvider);
  final token = env.botToken;
  final commandsPlugin = CommandsPlugin(prefix: mentionOr((_) => '!'));
  final slashCommands = ref.read(slashCommandsProvider);
  await slashCommands.initialize();
  final commands = slashCommands.enabledCommands;
  for (final command in commands) {
    final chatCommand = await command.runable.initialize(ref);
    if (chatCommand == null) {
      continue;
    }
    commandsPlugin.addCommand(chatCommand);
  }
  commandsPlugin.onCommandError.listen((error) async {
    if (error is ConverterFailedException) {
      // ConverterFailedException can be thrown during autocompletion, in which case we can't
      // respond with an error. This check makes sure we can respond.
      if (error.context case InteractiveContext context) {
        await context.respond(MessageBuilder(
          content: 'Invalid input: `${error.input.remaining}`',
        ));
      } else {
        print('Uncaught error: $error');
      }
    } else {
      print('Uncaught error: $error');
    }
  });

  return Nyxx.connectGateway(
    token,
    GatewayIntents.allUnprivileged | GatewayIntents.messageContent | GatewayIntents.guildMembers,
    options: GatewayClientOptions(
      plugins: [
        Logging(),
        CliIntegration(),
        IgnoreExceptions(),
        commandsPlugin,
      ],
    ),
  );
});
