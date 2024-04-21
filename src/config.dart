import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'commands.dart';

class Config {
  final String prefix;
  final int massPingChannelID;

  const Config({
    required this.prefix,
    required this.massPingChannelID,
  });

  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'mass-ping-channel-id': massPingChannelID,
    };
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      prefix: json['prefix'] as String,
      massPingChannelID: json['mass-ping-channel-id'],
    );
  }
}

class ConfigController {
  Config? _config;

  void init() => getConfigFromFile();

  void setConfig(Config config) {
    final file = File('config.json');

    file.writeAsStringSync(jsonEncode(config.toJson()));

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
