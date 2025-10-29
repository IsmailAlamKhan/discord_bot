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
    required Member member,
    required MessageCreateEvent messageCreateEvent,
  });

  MessageBuilder messageBuilder(MessageCreateEvent messageCreateEvent) => MessageBuilder(
        referencedMessage: MessageReferenceBuilder.reply(messageId: messageCreateEvent.message.id),
      );
  MessageBuilder messageBuilderWithoutReply(MessageCreateEvent messageCreateEvent) => MessageBuilder();

  Future<void> sendMessage({
    required PartialTextChannel channel,
    required MessageBuilder message,
  }) =>
      channel.sendMessage(message);
}
