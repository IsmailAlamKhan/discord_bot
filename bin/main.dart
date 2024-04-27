import 'package:riverpod/riverpod.dart';

import '../src/config.dart';
import '../src/env.dart';
import '../src/listen_to_message.dart';

Future<void> main() async {
  final ref = ProviderContainer();

  final env = ref.read(envProvider);
  final config = ref.read(configProvider);

  await env.init();
  config.init();

  final messagListener = ref.read(messageListenerProvider);
  await messagListener.start();
}
