import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class Env {
  abstract final String botToken;
  abstract final String footerText;
  abstract final String prefix;

  FutureOr<void> init();
}

class DartDefineEnv implements Env {
  @override
  final String botToken = const String.fromEnvironment('BOT_TOKEN');

  @override
  final String footerText = const String.fromEnvironment('FOOTER_TEXT');

  @override
  final String prefix = const String.fromEnvironment('PREFIX');

  @override
  FutureOr<void> init() {}
}

class FileBasedEnv extends Env {
  late Map<String, String> _env;
  @override
  String get botToken => _env['BOT_TOKEN']!;

  @override
  String get footerText => _env['FOOTER_TEXT']!;
  @override
  String get prefix => _env['PREFIX']!;

  @override
  FutureOr<void> init() {
    final file = File('env.json');
    final content = file.readAsStringSync();
    _env = jsonDecode(content);
    print('Env loaded: $_env');
  }
}

class PlatformEnv extends Env {
  @override
  final String botToken = Platform.environment['BOT_TOKEN']!;
  @override
  final String footerText = Platform.environment['FOOTER_TEXT']!;
  @override
  final String prefix = Platform.environment['PREFIX']!;
  @override
  FutureOr<void> init() {}
}
