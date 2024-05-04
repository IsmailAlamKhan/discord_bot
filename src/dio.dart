import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import 'env.dart';

final waifuDioProvider = Provider<Dio>((ref) {
  final env = ref.read(envProvider);
  return Dio(BaseOptions(baseUrl: env.waifuApiUrl));
});
final dioProvider = Provider<Dio>((ref) => Dio());
