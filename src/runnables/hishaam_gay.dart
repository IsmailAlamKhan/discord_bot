import 'package:nyxx/nyxx.dart';
import 'package:riverpod/src/framework.dart';

import 'runnables.dart';

class HishaamGayRunnable extends Runnable {
  static const hishaamUserId = 804023105080655892;
  @override
  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required PartialMember member,
    required MessageCreateEvent messageCreateEvent,
  }) {
    return channel.sendMessage(
      MessageBuilder(
        replyId: messageCreateEvent.message.id,
        content: 'We just wanna say that <@$hishaamUserId> is gay.',
      ),
    );
  }
}
