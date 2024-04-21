import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import '../../bin/main.dart';
import 'runnables.dart';

class HelpRunnable extends Runnable {
  const HelpRunnable();
  @override
  Future<void> run(
      {required ProviderContainer ref, required List<String> arguments, required PartialTextChannel channel}) {
    final helpMessage = Command.values.map((e) => '${e.command}: ${e.description}').join('\n');
    return channel.sendMessage(
      MessageBuilder(
        embeds: [
          EmbedBuilder(
            color: DiscordColor(0xFA383B),
            author: EmbedAuthorBuilder(name: 'Help'),
            description: "Welcome to the help menu. Here are the available commands: \n$helpMessage.",
            footer: EmbedFooterBuilder(
              text:
                  "The bot was built by Md Ismail Alam Khan with a bit of help from Tomic Riedel. The code for the bot can be found at: http://github.com/ismailalamkhan/discord_bot",
            ),
          ),
        ],
      ),
    );
  }
}
