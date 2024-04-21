import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import '../commands.dart';
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
  }) {
    final helpMessage = Command.values.map((e) => '${e.command}: ${e.description}').join('\n');
    final env = ref.read(envProvider);
    return channel.sendMessage(
      MessageBuilder(
        embeds: [
          EmbedBuilder(
            color: DiscordColor(0xFA383B),
            author: EmbedAuthorBuilder(name: 'Help'),
            description: "Welcome to the help menu. Here are the available commands: \n$helpMessage.",
            footer: EmbedFooterBuilder(text: env.footerText),
          ),
        ],
      ),
    );
  }
}
