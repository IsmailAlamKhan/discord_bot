import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import 'bot.dart';
import 'config.dart';
import 'db.dart';
import 'env.dart';
import 'generate_waifu.dart';

class WaifuCelebrate {
  final Ref ref;
  WaifuCelebrate(this.ref);
  static const int celebratePointsMod = 10;

  Future<int> setup() async {
    final bot = await ref.read(botProvider.future);
    final (config, _) = ref.read(configProvider).getConfig;
    int? waifuCelebrateChannel;
    final env = ref.read(envProvider);

    if (config != null) {
      waifuCelebrateChannel = config.waifuCelebrateChannel;
      final guild = PartialGuild(
        id: Snowflake(int.parse(env.guildId)),
        manager: bot.guilds,
      );
      waifuCelebrateChannel ??= await guild
          .createChannel<GuildChannel>(
            GuildChannelBuilder(
              name: 'waifu-celebrate',
              type: ChannelType.guildText,
              position: 10,
            ),
            auditLogReason: 'Waifu celebrate channel',
          )
          .then((value) => value.id.value);
      ref.read(configProvider).setConfig(config.copyWith(waifuCelebrateChannel: waifuCelebrateChannel));
    }
    return waifuCelebrateChannel!;
  }

  Future<void> celebrate(int userId, int point) async {
    if (point % celebratePointsMod != 0) return;
    final dbController = ref.read(dbProvider);
    final bot = await ref.read(botProvider.future);
    final mostUsed = dbController.getFromDB((db) => db.getMostUsedWaifu(userId));
    final (config, _) = ref.read(configProvider).getConfig;
    int? waifuCelebrateChannel = config?.waifuCelebrateChannel;
    waifuCelebrateChannel ??= await setup();

    if (mostUsed != null) {
      final channel = PartialTextChannel(id: Snowflake(waifuCelebrateChannel), manager: bot.channels);
      final value = await generateWaifu(category: mostUsed.waifuTag, ref: ref);
      value.fold(
        (l) => print(l),
        (r) async {
          final (data, fileName) = r;

          await channel.sendMessage(MessageBuilder(
            // content: 'Here is your celebration waifu image.<@$userId>',
            content:
                '<@$userId>**Congratulations**! on reaching $point points. Here is your reward waifu image from the most used category ${mostUsed.waifuTag.name}.',
            attachments: [AttachmentBuilder(data: data, fileName: fileName)],
          ));
        },
      );
    }
  }
}

final waifuCelebrateProvider = Provider<WaifuCelebrate>((ref) => WaifuCelebrate(ref));
