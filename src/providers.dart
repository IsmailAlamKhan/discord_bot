import 'package:cron/cron.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import 'env.dart';

final envProvider = Provider<Env>((ref) => PlatformEnv());

final botProvider = FutureProvider<NyxxGateway>((ref) {
  final env = ref.read(envProvider);
  final token = env.botToken;
  return Nyxx.connectGateway(
    token,
    GatewayIntents.all,
    options: GatewayClientOptions(
      plugins: [
        Logging(),
        CliIntegration(),
        IgnoreExceptions(),
      ],
    ),
  );
});

class PingCrons {
  final Map<String, Cron> pingCrons = {};

  void add(String userId, Cron cron) {
    pingCrons[userId] = cron;
  }

  Cron? get(String userId) {
    return pingCrons[userId];
  }

  void remove(String userId) {
    pingCrons.remove(userId);
  }

  Cron? operator [](String userId) => pingCrons[userId];
  void operator []=(String userId, Cron cron) {
    pingCrons[userId] = cron;
  }
}

final pingCronsProvider = Provider<PingCrons>((ref) => PingCrons());
