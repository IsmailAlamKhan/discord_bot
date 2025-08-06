import 'dart:async';

import 'package:dio/dio.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart' hide Options;
import 'package:riverpod/riverpod.dart';

import '../db.dart';
import '../dio.dart';
import '../extensions.dart';
import '../generate_waifu.dart';
import '../msg_queue.dart';
import '../user_waifu_preference.dart';
import '../waifu_celebrate.dart';
import 'commands.dart';

class WaifuTag {
  final int id;
  final String name;
  final String description;
  final bool nsfw;

  WaifuTag({required this.id, required this.name, required this.description, required this.nsfw});

  factory WaifuTag.fromJson(Map<String, dynamic> json) {
    return WaifuTag(
      id: json['tag_id'],
      name: json['name'],
      description: json['description'],
      nsfw: json['is_nsfw'],
    );
  }

  @override
  String toString() {
    return '$name - $description';
  }

  Map<String, dynamic> toJson() {
    return {
      'tag_id': id,
      'name': name,
      'description': description,
      'is_nsfw': nsfw,
    };
  }
}

class WaifuCommand extends SlashRunnable {
  final MsgQueue msgQueue;
  late DBController dbController;

  @override
  final String name = 'waifu';

  @override
  final String description = 'Get a random waifu image.';

  WaifuCommand() : msgQueue = MsgQueue();

  List<WaifuTag>? nsfwTags;
  List<WaifuTag>? sfwTags;

  Future<void> getTags(Ref ref) async {
    dbController = ref.read(dbProvider);
    final waifuDio = ref.read(waifuDioProvider);
    try {
      final res = await waifuDio.get('tags?full=true');

      sfwTags = (res.data['versatile'] as List).map((e) => WaifuTag.fromJson(e)).toList();
      nsfwTags = (res.data['nsfw'] as List).map((e) => WaifuTag.fromJson(e)).toList();
      if (nsfwTags!.isEmpty || sfwTags!.isEmpty) {
        enabled = false;
        disabledReason = 'No tags found.';
        return;
      }

      enabled = true;
    } on DioException catch (e) {
      print(e);
      enabled = false;
      disabledReason = 'An error occurred while fetching the tags.';
    }
  }

  @override
  Future<ChatCommand?> initialize(Ref ref) async {
    await getTags(ref);
    if (!enabled) {
      return Future.value(null);
    }
    final waifu = ChatCommand(
        name,
        description,
        options: CommandOptions(
          type: CommandType.all,
        ),
        id(
          name,
          (ChatContext context) async {
            final member = context.member!.id.value;

            dbController.updateDB((db) => db.addWaifuPoint(member));
            final point = dbController.getFromDB((db) => db.getWaifuPoints(member));
            final waifuCelebrate = ref.read(waifuCelebrateProvider);
            waifuCelebrate.celebrate(member, point);

            final shouldShow = msgQueue.addMessage(member);

            if (shouldShow) {
              await context.respond(
                MessageBuilder(
                  content:
                      '**Aaara aaraaaa** Yamete kudasai!!!! You have requested too many waifu images in the last 10 minutes.',
                ),
              );
            }

            final type = await context.getSelection(
              ['sfw', 'nsfw'],
              MessageBuilder(content: 'Select the type of waifu image you want to get. SFW or NSFW?'),
              authorOnly: true,
              timeout: const Duration(minutes: 1),
            );

            final isNSFW = type == 'nsfw';
            print('SFW: $sfwTags');

            final category = await context.getSelection<WaifuTag>(
              !isNSFW ? sfwTags! : nsfwTags!,
              MessageBuilder(content: 'Select the category of waifu image you want to get.'),
              authorOnly: true,
              toSelectMenuOption: (tag) {
                String description = tag.description;
                if (description.length >= 90) {
                  description = '${description.substring(0, 90)}...';
                }
                return SelectMenuOptionBuilder(label: tag.name, value: tag.name, description: description);
              },
              timeout: const Duration(minutes: 1),
            );
            dbController
                .updateDB((db) => db.addUserWaifuPreference(UserWaifuPreference(userId: member, waifuTag: category)));
            final channel = context.channel;
            final message = await context.respond(MessageBuilder(content: 'Generating a waifu image'));

            await channel.manager.triggerTyping(channel.id);
            final waifu = await generateWaifu(category: category, ref: ref);
            waifu.fold(
              (l) => message.edit(MessageBuilder(content: l).toMessageUpdateBuilder()),
              (r) async {
                final (data, fileName) = r;
                message.edit(
                  MessageBuilder(
                    content: 'Here is your waifu image. ${isNSFW ? '**WARNING: NSFW**' : ''}<@$member>',
                    attachments: [AttachmentBuilder(data: data, fileName: fileName)],
                  ).toMessageUpdateBuilder(),
                );
              },
            );
          },
        ));

    return waifu;
  }
}
