import 'package:riverpod/riverpod.dart';

import '../src/bot.dart';
import '../src/config.dart';
import '../src/env.dart';
import '../src/listen_to_message.dart';
import '../src/member_change.dart';
import '../src/waifu_celebrate.dart';

Future<void> main() async {
  final ref = ProviderContainer();

  final env = ref.read(envProvider);
  final config = ref.read(configProvider);

  await env.init();
  config.init();

  await ref.read(botProvider.future);
  final messagListener = ref.read(messageListenerProvider);
  await messagListener.start();
  final memberChange = ref.read(memberChangeProvider);
  await memberChange.start();
  await ref.read(waifuCelebrateProvider).setup();
}
