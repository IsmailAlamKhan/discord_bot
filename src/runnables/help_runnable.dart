import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import '../commands.dart';
import '../config.dart';
import '../env.dart';
import 'runnables.dart';

class HelpRunnable extends Runnable {
  const HelpRunnable();
  @override
  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required PartialMember member,
    required MessageCreateEvent messageCreateEvent,
  }) {
    final (config, _) = ref.read(configProvider).getConfig;
    // final helpMessage = Command.values.map(
    //   (e) {
    //     String key;
    //     String value = e.description;
    //     if (e.alias != null) {
    //       key = '${e.command} (${e.alias})';
    //     } else {
    //       key = e.command;
    //     }
    //     return '**$key**: $value';
    //   },
    // ).join('\n\n');
    final env = ref.read(envProvider);
    return channel.sendMessage(
      MessageBuilder(
        embeds: [
          EmbedBuilder(
            color: DiscordColor(0xFA383B),
            // author: EmbedAuthorBuilder(name: 'Help'),
            title: 'Welcome to the help menu!!',
            description:
                "The bot is currently listening to ${config!.prefix} run ${Command.config.name} to change the prefix.",
            fields: [
              for (final command in Command.values)
                EmbedFieldBuilder(
                  name: command.command + (command.alias != null ? ' (${command.alias})' : ''),
                  value:
                      '${command.description}\n${command.arguments.isNotEmpty ? 'Arguments: ${command.arguments.join(', ')}' : ''}',
                  isInline: false,
                ),
            ],

            footer: EmbedFooterBuilder(text: env.footerText),
          ),
        ],
      ),
    );
  }
}
