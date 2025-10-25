import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

final envProvider = Provider<Env>((ref) {
  return PlatformEnv();
  // return FileBasedEnv();
});

const envKeys = {
  "botToken": {"required": true, "description": "The token for the bot", "key": "BOT_TOKEN"},
  "footerText": {"required": true, "description": "The footer text for the bot", "key": "FOOTER_TEXT"},
  "adminUserId": {"required": true, "description": "The ID of the admin user", "key": "ADMIN_USER_ID"},
  "waifuApiUrl": {"required": true, "description": "The URL of the waifu API", "key": "WAIFU_API_URL"},
  "guildId": {"required": true, "description": "The ID of the guild", "key": "GUILD_ID"},
  "aiApiKey": {"required": true, "description": "The API key for the AI", "key": "AI_API_KEY"},
  "aiPersona": {"required": true, "description": "The persona for the AI", "key": "RED_DOOR_AI_PERSONA"},
  "aiModel": {"required": true, "description": "The model for the AI", "key": "AI_MODEL"},
  "rickrollUrl": {"required": true, "description": "The URL of the rickroll", "key": "RICKROLL_URL"},
  "conversationHistoryLimit": {
    "required": true,
    "description": "The number of messages to keep in the conversation history",
    "key": "CONVERSATION_HISTORY_LIMIT"
  },
  "jockyPrefix": {"required": true, "description": "The prefix for the jocky bot", "key": "JOCKY_PREFIX"},
  "musicAiPersona": {"required": true, "description": "The persona for the music AI", "key": "MUSIC_AI_PERSONA"},
};

abstract class Env {
  late String botToken;
  late String footerText;
  late String adminUserId;
  late String waifuApiUrl;
  late String guildId;
  late String aiApiKey;
  late String aiPersona;
  late String aiModel;
  late String rickrollUrl;
  late int conversationHistoryLimit;
  late String jockyPrefix;
  late String musicAiPersona;

  void setEnv(Map<String, String> env) {
    botToken = env[envKeys['botToken']!['key']]!;
    footerText = env[envKeys['footerText']!['key']]!;
    adminUserId = env[envKeys['adminUserId']!['key']]!;
    waifuApiUrl = env[envKeys['waifuApiUrl']!['key']]!;
    guildId = env[envKeys['guildId']!['key']]!;
    aiApiKey = env[envKeys['aiApiKey']!['key']]!;
    aiPersona = env[envKeys['aiPersona']!['key']]!;
    aiModel = env[envKeys['aiModel']!['key']]!;
    rickrollUrl = env[envKeys['rickrollUrl']!['key']]!;
    conversationHistoryLimit = int.parse(env[envKeys['conversationHistoryLimit']!['key']]!);
    jockyPrefix = env[envKeys['jockyPrefix']!['key']]!;
    musicAiPersona = env[envKeys['musicAiPersona']!['key']]!;
  }

  FutureOr<void> init();

  (bool, List<String>) validate(Map<String, String> env) {
    bool isValid = true;
    List<String> errors = [];
    print(env);
    for (final key in envKeys.keys) {
      final envKey = envKeys[key]!;
      if (env[envKey['key']] == null) {
        errors.add('${envKey['key']} is not set in the environment variables.');
      }
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
      setEnv(env);
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
      setEnv(env);
      print('Environment variables loaded successfully.');
    }
  }
}
