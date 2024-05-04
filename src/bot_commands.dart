import 'package:dio/dio.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart' hide Options;
import 'package:riverpod/riverpod.dart';

import 'dio.dart';

class BotCommands {
  final Ref ref;

  BotCommands(this.ref);

  List<ChatCommand> initialize() {
    final wifu = ChatCommand(
        'waifu',
        'Get a random wifu image.',
        options: CommandOptions(
          type: CommandType.all,
        ),
        id(
          'waifu',
          (ChatContext context) async {
            final type = await context.getSelection(
              ['sfw', 'nsfw'],
              MessageBuilder(content: 'Select the type of wifu image you want to get. SFW or NSFW?'),
              authorOnly: true,
            );
            const sfwCategories = [
              "waifu",
              "neko",
              "shinobu",
              "bully",
              "cry",
              "hug",
              "kiss",
              "lick",
              "pat",
              "smug",
              "highfive",
              "nom",
              "bite",
              "slap",
              "wink",
              "poke",
              "dance",
              "cringe",
              "blush",
            ];
            const nsfwCategories = ["waifu", "neko", "trap", "blowjob"];
            final category = await context.getSelection(
              type == 'sfw' ? sfwCategories : nsfwCategories,
              MessageBuilder(content: 'Select the category of wifu image you want to get.'),
              authorOnly: true,
            );
            await context.respond(MessageBuilder(content: 'Generating a waifu image'));

            final waifuDio = ref.read(waifuDioProvider);
            final dio = ref.read(dioProvider);
            try {
              final res = await waifuDio.get('$type/$category');
              final url = res.data['url'];

              final download = await dio.get(url, options: Options(responseType: ResponseType.bytes));
              var fileName = url.split('/').last;
              if (type == 'nsfw') {
                fileName = 'SPOILER_$fileName';
              }
              await context.respond(MessageBuilder(
                content: 'Here is your wifu image.',
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

    return [wifu];
  }
}
