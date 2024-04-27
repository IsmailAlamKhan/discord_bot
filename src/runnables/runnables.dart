import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

export 'help_runnable.dart';
export 'mass_ping_runnable.dart';

abstract class Runnable {
  const Runnable();

  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required PartialMember member,
    required MessageCreateEvent messageCreateEvent,
  });
}
