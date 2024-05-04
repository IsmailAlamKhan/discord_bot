import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:riverpod/riverpod.dart';

import 'bot_commands.dart';
import 'env.dart';

final botProvider = FutureProvider<NyxxGateway>((ref) {
  final env = ref.read(envProvider);
  final token = env.botToken;
  final commands = CommandsPlugin(prefix: mentionOr((_) => '!'));
  final botCommands = BotCommands(ref).initialize();
  for (final command in botCommands) {
    commands.addCommand(command);
  }
  commands.onCommandError.listen((error) async {
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
    GatewayIntents.allUnprivileged | GatewayIntents.messageContent,
    options: GatewayClientOptions(
      plugins: [
        Logging(),
        CliIntegration(),
        IgnoreExceptions(),
        commands,
      ],
    ),
  );
});
