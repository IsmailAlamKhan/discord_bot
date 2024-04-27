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
  final PartialTextChannel channel;

  PingCronValue({required this.cron, required this.channel});

  @override
  List<Object?> get props => [cron, channel];

  Future<void> close() => cron.close();
}

class PingCrons {
  final Map<PingCronKey, PingCronValue> pingCrons = {};

  void add(PingCronKey key, PartialTextChannel channel) {
    pingCrons[key] = PingCronValue(cron: Cron(), channel: channel);
  }

  PingCronValue? get(PingCronKey key) => pingCrons[key];

  void remove(PingCronKey key) => pingCrons.remove(key);

  PingCronValue? operator [](PingCronKey key) => pingCrons[key];
  // void operator []=(PingCronKey key, Cron cron) => pingCrons[key] = cron;
}

final pingCronsProvider = Provider<PingCrons>((ref) => PingCrons());
