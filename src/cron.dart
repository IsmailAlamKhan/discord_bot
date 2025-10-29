import 'package:cron/cron.dart';
import 'package:equatable/equatable.dart';
import 'package:nyxx/nyxx.dart';
import 'package:riverpod/riverpod.dart';

class PingCronKey extends Equatable {
  final String senderUserId;
  final String receiverUserId;

  PingCronKey({required this.senderUserId, required this.receiverUserId});

  @override
  List<Object?> get props => [senderUserId, receiverUserId];
}

class PingCronValue extends Equatable {
  final Cron cron;
  final String initiator;
  final String pinging;
  final PartialTextChannel channel;

  PingCronValue({required this.cron, required this.channel, required this.initiator, required this.pinging});

  @override
  List<Object?> get props => [cron, channel, initiator, pinging];

  Future<void> close() => cron.close();
}

class PingCrons {
  final Map<PingCronKey, PingCronValue> pingCrons = {};

  void add({
    required PingCronKey key,
    required PartialTextChannel channel,
    required String initiator,
    required String pinning,
  }) {
    pingCrons[key] = PingCronValue(cron: Cron(), channel: channel, initiator: initiator, pinging: pinning);
  }

  PingCronValue? get(PingCronKey key) => pingCrons[key];

  void remove(PingCronKey key) => pingCrons.remove(key);

  PingCronValue? operator [](PingCronKey key) => pingCrons[key];
  // void operator []=(PingCronKey key, Cron cron) => pingCrons[key] = cron;
}

final pingCronsProvider = Provider<PingCrons>((ref) => PingCrons());
