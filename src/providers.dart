import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

import 'env.dart';

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
