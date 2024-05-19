import 'dart:convert';

/// input must be json encodable
String encodeJson<T>(T json) {
  final encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(json);
}
