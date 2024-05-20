import 'dart:async';

import 'package:dio/dio.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart' hide Options;
import 'package:riverpod/riverpod.dart';

import '../db.dart';
import '../dio.dart';
import '../generate_waifu.dart';
import '../user_waifu_preference.dart';
import '../waifu_celebrate.dart';
import 'commands.dart';

class MsgQueue {
  MsgQueue() {
    autoClearAfter10Minutes();
  }

  /// Map of user id to the number of requests they have made in the last 10 minutes
  final Map<int, int> messages = {};

  static const int maxMessages = 10;
  static const Duration maxAge = Duration(minutes: 10);

  /// Add a message to the queue
  /// and return true if one user has made 10 requests in the last 10 minutes
  bool addMessage(int userId) {
    int? count = messages[userId];

    if (count != null) {
      count += 1;
    } else {
      count = 1;
    }
    print('count: $count');
    messages[userId] = count;
    bool shouldShow = count > maxMessages;
    print('shouldShow: $shouldShow');
    return shouldShow;
  }

  /// Remove all messages from the queue
  void clear() {
    messages.clear();
  }

  void autoClearAfter10Minutes() {
    Timer.periodic(maxAge, (timer) => clear());
  }
}

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

  WaifuCommand() : msgQueue = MsgQueue();

  List<WaifuTag>? nsfwTags;
  List<WaifuTag>? sfwTags;

  Future<void> getTags(Ref ref) async {
    dbController = ref.read(dbControllerProvider);
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
        'waifu',
        'Get a random waifu image.',
        options: CommandOptions(
          type: CommandType.all,
        ),
        id(
          'waifu',
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

            await context.respond(MessageBuilder(content: 'Generating a waifu image'));
            final waifu = await generateWaifu(category: category, ref: ref);
            waifu.fold(
              (l) => context.respond(MessageBuilder(content: l)),
              (r) async {
                final (data, fileName) = r;
                await context.respond(MessageBuilder(
                  content: 'Here is your waifu image. ${isNSFW ? '**WARNING: NSFW**' : ''}<@$member>',
                  attachments: [AttachmentBuilder(data: data, fileName: fileName)],
                ));
              },
            );
          },
        ));

    return waifu;
  }
}
