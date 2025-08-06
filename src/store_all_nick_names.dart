import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import 'bot.dart';
import 'db.dart';
import 'env.dart';

final storeAllNickNamesProvider = Provider<StoreAllNickNames>((ref) {
  return StoreAllNickNames(ref);
});

class StoreAllNickNames {
  final Ref ref;
  StoreAllNickNames(this.ref);

  Future<void> initialize() async {
    final bot = await ref.read(botProvider.future);
    final env = ref.read(envProvider);
    final db = ref.read(dbProvider);
    final guild = PartialGuild(
      id: Snowflake.parse(env.guildId),
      manager: bot.guilds,
    );
    final members = await guild.members.list(limit: 300);

    final nickNames = <String, String>{};
    for (final member in members) {
      print('StoreAllNickNames: member: ${member.user?.username}');
      print('StoreAllNickNames: member: ${member.id}');
      if (member.user != null && member.nick != null) {
        nickNames[member.user!.id.toString()] = member.nick!;
      }
    }
    print('StoreAllNickNames: nickNames: $nickNames');
    for (final MapEntry(:key, :value) in nickNames.entries) {
      final id = key;
      final nickName = value;
      db.updateDB((db) => db.setUserNickname(id, nickName));
    }
  }
}
