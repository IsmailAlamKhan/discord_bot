import 'commands/waifu_command.dart';

class UserWaifuPreference {
  final int userId;
  final WaifuTag waifuTag;

  const UserWaifuPreference({
    required this.userId,
    required this.waifuTag,
  });

  factory UserWaifuPreference.fromJson(Map<String, dynamic> json) {
    return UserWaifuPreference(
      userId: json['userId'],
      waifuTag: WaifuTag.fromJson(json['waifuTag']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'waifuTag': waifuTag.toJson(),
    };
  }
}
