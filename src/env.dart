import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

final envProvider = Provider<Env>((ref) {
  return PlatformEnv();
  // return FileBasedEnv();
});

abstract class Env {
  late Map<String, String> _env;
  String get botToken => _env['BOT_TOKEN']!;
  String get footerText => _env['FOOTER_TEXT']!;
  String get adminUserId => _env['ADMIN_USER_ID']!;
  String get waifuApiUrl => _env['WAIFU_API_URL']!;
  String get guildId => _env['GUILD_ID']!;

  FutureOr<void> init();

  (bool, List<String>) validate(Map<String, String> env) {
    bool isValid = true;
    List<String> errors = [];
    print(env);
    if (env['BOT_TOKEN'] == null) {
      errors.add('BOT_TOKEN is not set in the environment variables.');
    }
    if (env['FOOTER_TEXT'] == null) {
      errors.add('FOOTER_TEXT is not set in the environment variables.');
    }
    if (env['ADMIN_USER_ID'] == null) {
      errors.add('ADMIN_USER_ID is not set in the environment variables.');
    }
    if (errors.isNotEmpty) {
      isValid = false;
    }
    return (isValid, errors);
  }
}

class FileBasedEnv extends Env {
  @override
  FutureOr<void> init() {
    final file = File('.env');
    final content = file.readAsStringSync();
    var lines = LineSplitter.split(content);
    lines = lines.where((element) => element.isNotEmpty).toList();

    final env = lines.fold<Map<String, String>>({}, (acc, line) {
      final parts = line.split('=');
      acc[parts[0]] = parts[1];
      return acc;
    });

    final (isValid, errors) = validate(env);
    if (!isValid) {
      throw Exception('Environment variables are not set properly: ${errors.join(', ')}');
    } else {
      _env = env;
      print('Environment variables loaded successfully.');
    }
  }
}

class PlatformEnv extends Env {
  @override
  FutureOr<void> init() {
    final env = Platform.environment;
    final (isValid, errors) = validate(env);
    if (!isValid) {
      throw Exception('Environment variables are not set properly: ${errors.join(', ')}');
    } else {
      _env = env;
      print('Environment variables loaded successfully.');
    }
  }
}
