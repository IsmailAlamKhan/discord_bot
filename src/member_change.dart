import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import 'bot.dart';
import 'db.dart';
import 'env.dart';

final memberChangeProvider = Provider<MemberChange>((ref) => MemberChange(ref));

class MemberChange {
  final Ref ref;
  MemberChange(this.ref);

  StreamSubscription? _streamSubscription;
  StreamSubscription? _streamSubscription2;

  Future<void>? stop() async {
    await _streamSubscription?.cancel();
    await _streamSubscription2?.cancel();
  }

  Future<void> restart() async {
    print('Restarting the member change listener');
    await stop();
    await start();
  }

  Future<void> start() async {
    final bot = await ref.read(botProvider.future);
    final env = ref.read(envProvider);
    _streamSubscription?.cancel();

    print('Starting the member change listener');
    _streamSubscription = bot.onGuildMemberUpdate.listen((event) {
      print('Member changed: ${event.member.user?.username}');
      print('Old nickname: ${event.oldMember?.nick}');
      print('New nickname: ${event.member.nick}');
      final db = ref.read(dbControllerProvider);
      if (event.member.nick != null && event.member.nick != event.oldMember?.nick) {
        print('Setting nickname for ${event.member.user?.id} to ${event.member.nick}');
        db.updateDB((db) {
          print('Setting nickname for ${event.member.user?.username} to ${event.member.nick}');
          return db.setUserNickname(event.member.user!.id.toString(), event.member.nick!);
        });
      }
    });
    _streamSubscription2 = bot.onGuildMemberAdd.listen((event) async {
      print('Member added: ${event.member.user?.username} Checking if they have a nickname');
      final db = ref.read(dbControllerProvider);
      final nickname = db.getFromDB((db) => db.getUserNickname(event.member.user!.id.toString()));
      if (nickname != null) {
        print('Setting nickname for ${event.member.user?.username} to $nickname');
        final guild = PartialGuild(
          id: Snowflake(int.parse(env.guildId)),
          manager: bot.guilds,
        );
        await guild.members.get(event.member.user!.id).then((member) async {
          print('Member: ${member.nick}');
          if (member.nick != nickname) {
            print('Setting nickname for ${event.member.user?.username} to $nickname');
            await member.update(MemberUpdateBuilder(nick: nickname));
            print('Nickname set for ${event.member.user?.username}, sending meme message to welcome channel');
            final id = "1153380246096183306";
            final channel = PartialTextChannel(id: Snowflake(int.parse(id)), manager: bot.channels);
            final memeGif = "https://tenor.com/view/deez-ha-got-heem-got-em-got-him-gif-4824899";
            await channel.sendMessage(MessageBuilder(
              content:
                  '<@${event.member.user?.id}> Hah got heem. You thought you could leave the server and your nickname would get reset? $memeGif',
            ));
          }
        });
      }
    });
  }
}
