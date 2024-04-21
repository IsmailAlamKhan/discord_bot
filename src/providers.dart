import 'package:cron/cron.dart';
import 'package:equatable/equatable.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import 'env.dart';

final envProvider = Provider<Env>((ref) {
  // return PlatformEnv();
  return FileBasedEnv();
});

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

class PingCronKey extends Equatable {
  final String senderUserId;
  final String receiverUserId;

  PingCronKey({required this.senderUserId, required this.receiverUserId});

  @override
  List<Object?> get props => [senderUserId, receiverUserId];
}

class PingCrons {
  final Map<PingCronKey, Cron> pingCrons = {};

  void add(PingCronKey key) {
    pingCrons[key] = Cron();
  }

  Cron? get(PingCronKey key) => pingCrons[key];

  void remove(PingCronKey key) => pingCrons.remove(key);

  Cron? operator [](PingCronKey key) => pingCrons[key];
  // void operator []=(PingCronKey key, Cron cron) => pingCrons[key] = cron;
}

final pingCronsProvider = Provider<PingCrons>((ref) => PingCrons());
