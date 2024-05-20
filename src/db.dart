import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'commands/waifu_command.dart';
import 'encode_json.dart';
import 'user_waifu_preference.dart';

class DB {
  final Map<int, int> waifuPoints;
  final List<UserWaifuPreference> userWaifuPreferences;

  DB({required this.waifuPoints, required this.userWaifuPreferences});

  Map<String, dynamic> toMap() {
    return {
      'waifu-points': {for (final e in waifuPoints.entries) e.key.toString(): e.value},
      'user-waifu-preferences': userWaifuPreferences.map((e) => e.toJson()).toList(),
    };
  }

  factory DB.fromMap(Map<String, dynamic> map) {
    return DB(
      waifuPoints: (map['waifu-points'] as Map<dynamic, dynamic>?)
              ?.map<int, int>((key, value) => MapEntry(int.parse(key), value as int)) ??
          {},
      userWaifuPreferences:
          (map['user-waifu-preferences'] as List<dynamic>?)?.map((e) => UserWaifuPreference.fromJson(e)).toList() ??
              <UserWaifuPreference>[],
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

final dbControllerProvider = Provider((ref) => DBController()..init());
