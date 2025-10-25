import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'commands/waifu_command.dart';
import 'conversation_history.dart';
import 'encode_json.dart';
import 'google_ai_service.dart';
import 'user_waifu_preference.dart';

class DB {
  final Map<int, int> waifuPoints;
  final List<UserWaifuPreference> userWaifuPreferences;
  final Map<String, String> userNicknames;
  final ConversationHistory conversationHistory;

  DB({
    required this.waifuPoints,
    required this.userWaifuPreferences,
    required this.userNicknames,
    required this.conversationHistory,
  });

  Map<String, dynamic> toMap() {
    return {
      'waifu-points': {for (final e in waifuPoints.entries) e.key.toString(): e.value},
      'user-waifu-preferences': userWaifuPreferences.map((e) => e.toJson()).toList(),
      'user-nicknames': {for (final e in userNicknames.entries) e.key.toString(): e.value},
      'conversation-history': conversationHistory.toJson(),
    };
  }

  factory DB.fromMap(Map<String, dynamic> map) {
    final conversation = map['conversation-history'];
    ConversationHistory conversationHistory;
    if (conversation != null) {
      conversationHistory = ConversationHistory.fromJson(conversation as List<Map<String, dynamic>>);
    } else {
      conversationHistory = ConversationHistory([]);
    }
    return DB(
      waifuPoints: (map['waifu-points'] as Map<dynamic, dynamic>?)
              ?.map<int, int>((key, value) => MapEntry(int.parse(key), value as int)) ??
          {},
      userWaifuPreferences:
          (map['user-waifu-preferences'] as List<dynamic>?)?.map((e) => UserWaifuPreference.fromJson(e)).toList() ??
              <UserWaifuPreference>[],
      userNicknames: (map['user-nicknames'] as Map<dynamic, dynamic>?)
              ?.map<String, String>((key, value) => MapEntry(key, value as String)) ??
          {},
      conversationHistory: conversationHistory,
    );
  }

  int getWaifuPoints(int userID) {
    return waifuPoints[userID] ?? 0;
  }

  DB addWaifuPoint(int userID) {
    int? point = waifuPoints[userID];
    point ??= 0;

    point++;
    waifuPoints[userID] = point;
    return this;
  }

  DB addUserWaifuPreference(UserWaifuPreference userWaifuPreference) {
    userWaifuPreferences.add(userWaifuPreference);
    return this;
  }

  UserWaifuPreference? getMostUsedWaifu(int userId) {
    final waifuTags = userWaifuPreferences.map((e) => e.waifuTag).toList();
    final mostUsed = waifuTags
        .fold<Map<WaifuTag, int>>({}, (acc, e) {
          acc[e] = (acc[e] ?? 0) + 1;
          return acc;
        })
        .entries
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (mostUsed.isNotEmpty) {
      return UserWaifuPreference(userId: userId, waifuTag: mostUsed.last.key);
    }
    return null;
  }

  String? getUserNickname(String userId) {
    return userNicknames[userId];
  }

  DB setUserNickname(String userId, String nickname) {
    userNicknames[userId] = nickname;
    return this;
  }

  DB setMultipleUserNicknames(Map<String, String> userNicknames) {
    this.userNicknames.addAll(userNicknames);
    return this;
  }

  DB addConversationHistory(ConversationHistoryItem conversationHistory) {
    this.conversationHistory.add(conversationHistory);
    return this;
  }

  DB setConversationHistory(List<ConversationHistoryItem> conversationHistory) {
    this.conversationHistory.clear();
    this.conversationHistory.addAll(conversationHistory);
    return this;
  }

  DB removeConversationHistory(ConversationHistoryItem conversationHistory) {
    this.conversationHistory.remove(conversationHistory);
    return this;
  }

  DB removeConversationHistoryByUserId(String userId) {
    conversationHistory.removeWhere((element) => element.userId == userId);
    return this;
  }

  ConversationHistory getConversationHistoryByUserId(String userId) {
    return ConversationHistory(conversationHistory.where((element) => element.userId == userId).toList());
  }

  ConversationHistory getConversationHistory() {
    return conversationHistory;
  }

  ConversationHistory getConversationHistoryByType(AIType type) {
    return ConversationHistory(conversationHistory.where((element) => element.type == type).toList());
  }
}

class DBController {
  DB? _db;
  // DB get db => _db!;

  void init() => getDBFromFile();

  void setDB(DB db) {
    final file = File('db.json');
    print(db.toMap());
    final json = encodeJson(db.toMap());
    print(json);

    file.writeAsStringSync(json);

    _db = db;
  }

  void getDBFromFile() {
    final file = File('db.json');

    if (!file.existsSync()) {
      file.createSync();
    }

    final jsonString = file.readAsStringSync();
    Map<String, dynamic> json = {};
    if (jsonString.isNotEmpty) {
      json = jsonDecode(jsonString);
    }

    _db = DB.fromMap(json);
    print('DB loaded: ${_db!.toMap()}');
  }

  void updateDB(DB Function(DB db) fn) {
    final db = fn(_db!);
    setDB(db);
  }

  T getFromDB<T>(T Function(DB db) fn) {
    return fn(_db!);
  }
}

final dbProvider = Provider((ref) => DBController()..init());
