import 'package:nyxx/nyxx.dart';
import 'package:riverpod/src/framework.dart';

import '../db.dart';
import '../waifu_celebrate.dart';
import 'runnables.dart';

class WaifuPointsRunnable extends Runnable {
  const WaifuPointsRunnable();
  @override
  Future<void> run({
    required ProviderContainer ref,
    required List<String> arguments,
    required PartialTextChannel channel,
    required PartialMember member,
    required MessageCreateEvent messageCreateEvent,
  }) async {
    // final message = messageCreateEvent.message.content;
    final db = ref.read(dbProvider);
    final mentions = messageCreateEvent.message.mentions;
    int userID;
    bool isCurrentUser;
    print(mentions);
    if (mentions.isEmpty) {
      userID = member.id.value;
      isCurrentUser = true;
    } else {
      userID = mentions.first.id.value;
      isCurrentUser = member.id == mentions.first.id;
    }

    final points = db.getFromDB((db) => db.getWaifuPoints(userID));
    final celebrateMod = WaifuCelebrate.celebratePointsMod;
    final remaining = points % celebrateMod;
    final next = celebrateMod - remaining;
    final message = isCurrentUser
        ? 'You have $points waifu points. You need $next more points to get a reward.'
        : '<@${member.id.value}> has $points waifu points. They need $next more points to get a reward.';
    await channel.sendMessage(MessageBuilder(content: message, replyId: messageCreateEvent.message.id));
  }
}
