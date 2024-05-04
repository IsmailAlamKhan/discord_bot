import 'package:dio/dio.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart' hide Options;
import 'package:riverpod/riverpod.dart';

import '../dio.dart';
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
}

class WaifuCommand extends SlashRunnable {
  WaifuCommand();
  List<WaifuTag>? nsfwTags;
  List<WaifuTag>? sfwTags;

  Future<void> getTags(Ref ref) async {
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
            final type = await context.getSelection(
              ['sfw', 'nsfw'],
              MessageBuilder(content: 'Select the type of waifu image you want to get. SFW or NSFW?'),
              authorOnly: true,
              timeout: const Duration(minutes: 1),
            );
            // final forceGif = await context.getSelection(
            //   ['yes', 'no'],
            //   MessageBuilder(content: 'Do you want to force a gif image?'),
            //   authorOnly: true,
            //   timeout: const Duration(minutes: 1),
            // );
            // print(forceGif);

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

            await context.respond(MessageBuilder(content: 'Generating a waifu image'));

            final waifuDio = ref.read(waifuDioProvider);
            final dio = ref.read(dioProvider);
            try {
              final uri = Uri(
                queryParameters: {
                  'included_tags': category.name,
                  'height': '>1000',
                  'is_nsfw': isNSFW.toString(),
                },
                path: 'search',
              );
              print(uri);
              final res = await waifuDio.getUri(uri);
              final url = res.data['images'].first['url'];

              final download = await dio.get(url, options: Options(responseType: ResponseType.bytes));
              var fileName = url.split('/').last;
              if (type == 'nsfw') {
                fileName = 'SPOILER_$fileName';
              }
              await context.respond(MessageBuilder(
                content: 'Here is your waifu image. ${isNSFW ? '**WARNING: NSFW**' : ''}',
                attachments: [AttachmentBuilder(data: download.data, fileName: fileName)],
              ));
            } on DioException catch (e) {
              print("DIO $e");
              if (e.response?.data != null) {
                await context.respond(MessageBuilder(content: e.response!.data['message']));
              } else {
                await context.respond(MessageBuilder(content: 'An error occurred while fetching the image.'));
              }
            } on Exception catch (e) {
              print(e);
              await context.respond(MessageBuilder(content: 'An error occurred while fetching the image.'));
            }
          },
        ));

    return waifu;
  }
}
