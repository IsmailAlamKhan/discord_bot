import 'dart:async';

import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import 'commands.dart';
import 'config.dart';
import 'providers.dart';

final messageListenerProvider = Provider<MessageListener>((ref) => MessageListener(ref));

class MessageListener {
  final Ref ref;
  MessageListener(this.ref);

  StreamSubscription? _streamSubscription;

  Future<void>? stop() => _streamSubscription?.cancel();

  Future<void> restart() async {
    print('Restarting the message listener');
    await stop();
    await start();
  }

  Future<void> start() async {
    final (currentConfig, _) = ref.read(configProvider).getConfig;

    final bot = await ref.read(botProvider.future);
    _streamSubscription?.cancel();

    final prefix = currentConfig?.prefix;
    if (prefix != null) {
      print('Starting to listen to messages with prefix: $prefix');
    } else {
      print('Prefix is not set. Please run the config command.');
    }
    _streamSubscription = bot.onMessageCreate.listen((event) async {
      final isBotMentioned = event.message.mentions.contains(bot.user);
      final msgContent = event.message.content;

      final msgChannel = event.message.channel;

      final member = event.member!;

      if (isBotMentioned) {
        if (currentConfig == null) {
          event
              .message //
              .channel
              .sendMessage(MessageBuilder(content: 'Bot is not configured. Running the config command.'));
          await Command.config.runnable.run(
            ref: ref.container,
            arguments: [],
            channel: event.message.channel,
            member: event.member!,
            messageCreateEvent: event,
          );
          _streamSubscription?.cancel();

          return start();
        } else {
          final haveTextWithMention = msgContent.replaceFirst('<@${bot.user.id.value}>', '').trim().isNotEmpty;
          if (!haveTextWithMention) {
            await Command.help.runnable.run(
              ref: ref.container,
              arguments: [],
              channel: msgChannel,
              member: member,
              messageCreateEvent: event,
            );
          }
        }
      }

      if (prefix == null) {
        print('Prefix is not set. Please run the config command.');
        return;
      }
      if (!event.message.content.startsWith(prefix)) {
        print('Message does not start with prefix: $prefix: ${event.message.content}');
        return;
      } else {
        print('Event received: ${event.message.content}');
      }

      final commandList = msgContent.split(' ');

      final command = Command.values.firstWhereOrNull(
        (element) {
          return element.command == commandList[1] || element.alias == commandList[1];
        },
      );
      List<String> arguments = [];
      if (commandList.length > 2) {
        arguments = commandList.sublist(2);
      }

      if (command == null) {
        final buffer = StringBuffer();
        buffer.writeln('Invalid command. Showing the help menu.');

        await msgChannel.sendMessage(MessageBuilder(content: buffer.toString()));
        await Command.help.runnable.run(
          ref: ref.container,
          arguments: [],
          channel: msgChannel,
          member: member,
          messageCreateEvent: event,
        );
      } else {
        await command.runnable.run(
          ref: ref.container,
          arguments: arguments,
          channel: msgChannel,
          member: member,
          messageCreateEvent: event,
        );
      }
    });
  }
}
