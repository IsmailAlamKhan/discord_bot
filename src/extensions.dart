import 'package:nyxx/nyxx.dart';

extension ExtendedMessageBuilder on MessageBuilder {
  MessageUpdateBuilder toMessageUpdateBuilder() {
    return MessageUpdateBuilder(
      content: content,
      embeds: embeds ?? [],
      attachments: attachments ?? [],
      allowedMentions: allowedMentions,
      components: components,
      poll: poll,
      suppressEmbeds: suppressEmbeds,
    );
  }
}
