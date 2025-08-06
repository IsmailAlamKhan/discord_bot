import 'package:nyxx/nyxx.dart';

enum EmdedColor {
  red(discordRedColor),
  green(discordGreenColor),
  orange(discordOrangeColor);

  final DiscordColor color;

  const EmdedColor(this.color);
}

const discordRedColor = DiscordColor(0xFF0000);
const discordGreenColor = DiscordColor(0x00FF00);
const discordOrangeColor = DiscordColor(0xFF6600);

EmbedBuilder createEmbed({
  required String title,
  String? description,
  required EmdedColor color,
  EmbedFooterBuilder? footer,
  List<EmbedFieldBuilder>? fields,
}) {
  return EmbedBuilder(
    title: title,
    description: description,
    color: color.color,
    timestamp: DateTime.now(),
    footer: footer,
    fields: fields,
  );
}

EmbedBuilder createEmbedForAI({
  required String title,
  String? description,
  required EmdedColor color,
  List<EmbedFieldBuilder>? fields,
}) {
  return createEmbed(
    title: title,
    description: description,
    color: color,
    footer: EmbedFooterBuilder(text: 'Red Door AI'),
    fields: fields,
  );
}

MessageBuilder createAlertMessage({
  required String content,
  String? description,
  required EmdedColor color,
  EmbedFooterBuilder? footer,
}) {
  return MessageBuilder(
    embeds: [
      EmbedBuilder(
        title: content,
        description: description,
        color: color.color,
        footer: footer,
      ),
    ],
  );
}

MessageBuilder createAlertMessageForAI({
  required String content,
  String? description,
  required EmdedColor color,
}) {
  return createAlertMessage(
    content: content,
    description: description,
    color: color,
    footer: EmbedFooterBuilder(text: 'Red Door AI'),
  );
}

bool isCancel(String content) {
  return content.toLowerCase() == 'cancel' || content.toLowerCase() == 'stop' || content.toLowerCase() == 'exit';
}

MessageBuilder createCancelMessage() {
  return createAlertMessage(content: 'Operation cancelled.', color: EmdedColor.red);
}
