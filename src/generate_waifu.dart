import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';

import 'commands/waifu_command.dart';
import 'dio.dart';

Future<Either<String, (List<int>, String)>> generateWaifu({
  required WaifuTag category,
  required Ref ref,
}) async {
  final isNSFW = category.nsfw;
  final waifuDio = ref.read(waifuDioProvider);
  final dio = ref.read(dioProvider);
  final file = File('waifu.jpg');
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
    file.createSync();
    await dio.download(url, file.path);
    print('Downloaded image from $url');
    var fileName = url.split('/').last;
    if (isNSFW) {
      fileName = 'SPOILER_$fileName';
    }
    final bytes = file.readAsBytesSync();
    file.deleteSync();
    return right((bytes, fileName));
  } on DioException catch (e) {
    print("DIO $e");
    if (e.response?.data != null) {
      return left(e.response!.data['message']);
    } else {
      return left('An error occurred while fetching the image.');
    }
  } on Exception catch (e) {
    print(e);
    return left('An error occurred while fetching the image.');
  } finally {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
