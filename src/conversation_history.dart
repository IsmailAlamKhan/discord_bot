import 'dart:collection';

import 'package:collection/collection.dart';

import 'google_ai_service.dart';

class ConversationHistoryItem {
  final String id;
  final String userId;
  final String query;
  final String aiResponse;
  final AIType type;
  final DateTime createdAt;

  ConversationHistoryItem({
    required this.id,
    required this.userId,
    required this.query,
    required this.aiResponse,
    required this.type,
    required this.createdAt,
  });

  factory ConversationHistoryItem.fromJson(Map<String, dynamic> json) {
    return ConversationHistoryItem(
      id: json['id'],
      userId: json['userId'],
      query: json['query'],
      aiResponse: json['aiResponse'],
      createdAt: DateTime.parse(json['createdAt']),
      type: AIType.values.firstWhereOrNull((element) => element.name == json['type']) ?? AIType.chat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'query': query,
      'aiResponse': aiResponse,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
    };
  }
}

class ConversationHistory with ListMixin<ConversationHistoryItem> {
  final List<ConversationHistoryItem> _items;

  ConversationHistory([
    List<ConversationHistoryItem> items = const <ConversationHistoryItem>[],
  ]) : _items = items.toList();
  @override
  int get length => _items.length;

  @override
  set length(int newLength) {
    _items.length = newLength;
  }

  @override
  void add(ConversationHistoryItem element) {
    if (_items.length > 10) {
      _items.removeAt(0);
    }
    _items.add(element);
  }

  @override
  ConversationHistoryItem operator [](int index) {
    return _items[index];
  }

  @override
  void operator []=(int index, ConversationHistoryItem value) {
    _items[index] = value;
  }

  String getContextForAI() {
    return _items.map((e) => "[${e.userId}]: query: ${e.query}\nai-answer: ${e.aiResponse}").join("\n");
  }

  // toJson()
  List<Map<String, dynamic>> toJson() {
    return _items.map((e) => e.toJson()).toList();
  }

  factory ConversationHistory.fromJson(List<Map<String, dynamic>> json) {
    return ConversationHistory(json.map((e) => ConversationHistoryItem.fromJson(e)).toList());
  }
}
