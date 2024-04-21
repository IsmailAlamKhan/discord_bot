import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

final envProvider = Provider<Env>((ref) {
  return PlatformEnv();
  // return FileBasedEnv();
});

abstract class Env {
  abstract final String botToken;
  abstract final String footerText;
  // abstract final String prefix;
  // abstract final int massPingChannelId;

  FutureOr<void> init();
}

class DartDefineEnv implements Env {
  @override
  final String botToken = const String.fromEnvironment('BOT_TOKEN');

  @override
  final String footerText = const String.fromEnvironment('FOOTER_TEXT');

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
  FutureOr<void> init() {
    final file = File('.env');
    final content = file.readAsStringSync();
    final lines = LineSplitter.split(content);
    _env = lines.fold<Map<String, String>>({}, (acc, line) {
      final parts = line.split('=');
      acc[parts[0]] = parts[1];
      return acc;
    });
    print("Env loaded: $_env");
  }
}

class PlatformEnv extends Env {
  @override
  final String botToken = Platform.environment['BOT_TOKEN']!;
  @override
  final String footerText = Platform.environment['FOOTER_TEXT']!;

  @override
  FutureOr<void> init() {}
}
