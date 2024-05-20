import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import '../commands.dart';
import '../commands/commands.dart';
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

    final env = ref.read(envProvider);
    final slashCommands = ref.read(slashCommandsProvider);
    return sendMessage(
      channel: channel,
      message: messageBuilder(messageCreateEvent)
        ..embeds = [
          EmbedBuilder(
            color: DiscordColor(0xFA383B),
            title: 'Welcome to the help menu!!',
            description:
                "The bot is currently listening to ${config!.prefix} run ${Command.config.name} to change the prefix.",
            footer: EmbedFooterBuilder(text: env.footerText),
          ),
          EmbedBuilder(
            color: DiscordColor(0xFA383B),
            description: 'Here are the inline commands which are triggered by the prefix',
            fields: [
              for (final command in Command.values)
                EmbedFieldBuilder(
                  name: command.command + (command.alias != null ? ' (${command.alias})' : ''),
                  value:
                      '${command.description}\n${command.arguments.isNotEmpty ? 'Arguments: ${command.arguments.join(', ')}' : ''}',
                  isInline: false,
                ),
            ],
          ),
          if (slashCommands.enabledCommands.isNotEmpty)
            EmbedBuilder(
              color: DiscordColor(0xFA383B),
              description: 'Here are the enabled commands which are triggered by slash or !<command name>',
              fields: [
                for (final command in slashCommands.enabledCommands)
                  EmbedFieldBuilder(
                    name: command.name,
                    value: command.description,
                    isInline: false,
                  ),
              ],
            ),
          if (slashCommands.disabledCommands.isNotEmpty)
            EmbedBuilder(
              color: DiscordColor(0xFA383B),
              description: 'Here are the disabled slash commands',
              fields: [
                for (final command in slashCommands.disabledCommands)
                  EmbedFieldBuilder(
                    name: command.name,
                    value: '${command.description}\nReason: ${command.runable.disabledReason}',
                    isInline: false,
                  ),
              ],
              footer: EmbedFooterBuilder(text: 'Please contact the bot owner for further information.'),
            ),
        ],
    );
  }
}
