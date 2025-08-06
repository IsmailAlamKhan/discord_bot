import 'dart:async';

import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:riverpod/riverpod.dart';

import 'gemini_command.dart';
import 'waifu_command.dart';

final slashCommandsProvider = Provider<SlashCommands>(SlashCommands.new);

class SlashCommands {
  final Ref ref;

  SlashCommands(this.ref);

  List<SlashCommand> enabledCommands = [];
  List<SlashCommand> disabledCommands = [];

  Future<void> initialize() async {
    final slashCommands = [
      WaifuCommand().command,
      GeminiCommand().command,
    ];
    for (final command in slashCommands) {
      final runable = command.runable;
      final chatCommand = await runable.initialize(ref);
      print('chatCommand: $chatCommand');
      if (chatCommand == null || !runable.enabled) {
        disabledCommands.add(command);
        continue;
      }
      enabledCommands.add(command);
    }
  }
}

class SlashCommand {
  final SlashRunnable runable;
  final String name;
  final String description;

  SlashCommand({required this.runable, required this.name, required this.description});
}

abstract class SlashRunnable {
  SlashRunnable();
  bool enabled = false;
  String? disabledReason;

  abstract final String name;
  abstract final String description;
  SlashCommand get command => SlashCommand(runable: this, name: name, description: description);

  FutureOr<ChatCommand?> initialize(Ref ref);
}
