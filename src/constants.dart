import 'package:nyxx/nyxx.dart';

enum EmdedColor {
  red(discordRedColor),
  green(discordGreenColor);

  final DiscordColor color;

  const EmdedColor(this.color);
}

const discordRedColor = DiscordColor(0xFF0000);
const discordGreenColor = DiscordColor(0x00FF00);

EmbedBuilder createEmbed({
  required String title,
  required String description,
  required EmdedColor color,
}) {
  return EmbedBuilder(title: title, description: description, color: color.color);
}

MessageBuilder createAlertMessage({
  required String content,
  String? description,
  required EmdedColor color,
}) {
  return MessageBuilder(
    embeds: [EmbedBuilder(title: content, description: description, color: color.color)],
  );
}

bool isCancel(String content) {
  return content.toLowerCase() == 'cancel' || content.toLowerCase() == 'stop' || content.toLowerCase() == 'exit';
}

MessageBuilder createCancelMessage() {
  return createAlertMessage(content: 'Operation cancelled.', color: EmdedColor.red);
}
