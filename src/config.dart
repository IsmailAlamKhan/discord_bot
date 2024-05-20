import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'commands.dart';
import 'encode_json.dart';

class Config {
  final String prefix;
  final int? waifuCelebrateChannel;

  const Config({required this.prefix, this.waifuCelebrateChannel});

  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      if (waifuCelebrateChannel != null) 'waifu-celebrate-channel': waifuCelebrateChannel,
    };
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      prefix: json['prefix'] as String,
      waifuCelebrateChannel: json['waifu-celebrate-channel'] as int?,
    );
  }
  Config copyWith({String? prefix, int? waifuCelebrateChannel}) {
    return Config(
      prefix: prefix ?? this.prefix,
      waifuCelebrateChannel: waifuCelebrateChannel ?? this.waifuCelebrateChannel,
    );
  }
}

class ConfigController {
  Config? _config;

  void init() => getConfigFromFile();

  void setConfig(Config config) {
    final file = File('config.json');
    file.writeAsStringSync(encodeJson(config.toJson()));

    _config = config;
  }

  (Config?, String?) getConfigFromFile() {
    if (_config != null) {
      return (_config, null);
    }
    final file = File('config.json');

    if (!file.existsSync()) {
      print('Config not found');
      return (
        null,
        'Config not found please sure you ran ${Command.config.name} once with the respected arguments. Use ${Command.help.name} for more info'
      );
    }

    final json = jsonDecode(file.readAsStringSync());

    _config = Config.fromJson(json);
    print('Config loaded: ${_config!.toJson()}');
    return (_config, null);
  }

  (Config?, String?) get getConfig {
    final (config, error) = getConfigFromFile();
    if (error != null) {
      return (null, error);
    } else {
      return (config, null);
    }
  }
}

final configProvider = Provider((ref) => ConfigController());
