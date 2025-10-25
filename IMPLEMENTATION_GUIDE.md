# 🎵 Music Bot - Complete Implementation Guide

## 📦 What's Already Done

- ✅ `pubspec.yaml` - Added `web_socket_channel: ^3.0.1` dependency
- ✅ `Dockerfile` - Added Python3, pip, ffmpeg, and yt-dlp installation
- ✅ `docker-compose.yml` - Added Lavalink service with networking

---

## 🚀 STEP-BY-STEP IMPLEMENTATION

### ✅ USING HOSTED LAVALINK (Recommended)

You're using a **free hosted Lavalink server**, so you can skip deploying Lavalink yourself!

**No need for:**

- ❌ `lavalink/application.yml` (not needed)
- ❌ Separate Lavalink service
- ❌ `docker-compose.yml` (Render doesn't use it)

**Just configure the environment variables to point to the hosted server!**

---

### STEP 1: ~~Create Lavalink Configuration~~ ✅ SKIP THIS!

**You're using hosted Lavalink, so this step is not needed!**

The hosted server at `lavalink.darrennathanael.com` is already configured and running.

---

### STEP 2: Configure Environment Variables

### STEP 2: Configure Environment Variables

**Create or update your `.env` file with these values:**

```bash
# Discord Bot
BOT_TOKEN=your_discord_bot_token
PREFIX=!
FOOTER_TEXT=Red Door Bot
ADMIN_USER_ID=your_discord_user_id
GUILD_ID=your_guild_id

# Waifu API
WAIFU_API_URL=https://api.waifu.pics

# Google AI
AI_API_KEY=your_google_ai_api_key
RED_DOOR_AI_PERSONA=Your AI persona
AI_MODEL=gemini-1.5-flash

# 🎵 HOSTED LAVALINK (Free)
LAVALINK_HOST=lavalink.darrennathanael.com
LAVALINK_PORT=443
LAVALINK_PASSWORD=youshallnotpass

# Music Bot Settings
RICKROLL_URL=https://www.youtube.com/watch?v=4YweTt_Usjg
CONVERSATION_HISTORY_LIMIT=10
MUSIC_AI_PERSONA="You are a sassy DJ bot. Analyze music requests for: 1) Politeness 2) Music intent 3) Query extraction. Return JSON: {\"isPolite\": bool, \"shouldPlay\": bool, \"query\": string|null, \"replyMessage\": string}. If rude: insult them creatively with swear words. If polite: be friendly."
```

**For Render Deployment:** Add these same variables in **Render Dashboard → Your Service → Environment**

---

### STEP 3: Update src/env.dart

**Find the `envKeys` constant and ADD these entries:**

```dart
"lavalinkHost": {"required": true, "description": "Lavalink server host", "key": "LAVALINK_HOST"},
"lavalinkPort": {"required": true, "description": "Lavalink server port", "key": "LAVALINK_PORT"},
"lavalinkPassword": {"required": true, "description": "Lavalink password", "key": "LAVALINK_PASSWORD"},
"musicAiPersona": {"required": true, "description": "Music DJ AI persona", "key": "MUSIC_AI_PERSONA"},
"rickrollUrl": {"required": true, "description": "Rickroll video URL", "key": "RICKROLL_URL"},
"conversationHistoryLimit": {"required": true, "description": "Max conversation messages per user", "key": "CONVERSATION_HISTORY_LIMIT"},
```

**Find the `Env` abstract class and ADD these properties:**

```dart
late String lavalinkHost;
late String lavalinkPort;
late String lavalinkPassword;
late String musicAiPersona;
late String rickrollUrl;
late String conversationHistoryLimit;
```

**Find the `setEnv` method and ADD these assignments:**

```dart
lavalinkHost = env[envKeys['lavalinkHost']!['key']]!;
lavalinkPort = env[envKeys['lavalinkPort']!['key']]!;
lavalinkPassword = env[envKeys['lavalinkPassword']!['key']]!;
musicAiPersona = env[envKeys['musicAiPersona']!['key']]!;
rickrollUrl = env[envKeys['rickrollUrl']!['key']]!;
conversationHistoryLimit = env[envKeys['conversationHistoryLimit']!['key']]!;
```

---

### STEP 4: Create Directory Structure

Run:

```bash
mkdir -p src/services
mkdir -p src/models
```

---

### STEP 5: Create Data Models

#### File: `src/models/conversation_message.dart`

```dart
class ConversationMessage {
  final String userId;
  final String message;
  final DateTime timestamp;
  final String role;

  ConversationMessage({
    required this.userId,
    required this.message,
    required this.timestamp,
    required this.role,
  });
}
```

#### File: `src/models/music_request.dart`

```dart
class MusicRequest {
  final bool isPolite;
  final bool shouldPlay;
  final String? query;
  final String replyMessage;

  MusicRequest({
    required this.isPolite,
    required this.shouldPlay,
    this.query,
    required this.replyMessage,
  });

  factory MusicRequest.fromJson(Map<String, dynamic> json) => MusicRequest(
    isPolite: json['isPolite'] ?? false,
    shouldPlay: json['shouldPlay'] ?? false,
    query: json['query'],
    replyMessage: json['replyMessage'] ?? '',
  );
}
```

#### File: `src/models/track_info.dart`

```dart
class TrackInfo {
  final String identifier;
  final String author;
  final int length;
  final String title;
  final String? uri;

  TrackInfo({
    required this.identifier,
    required this.author,
    required this.length,
    required this.title,
    this.uri,
  });

  factory TrackInfo.fromLavalinkJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>;
    return TrackInfo(
      identifier: info['identifier'] ?? '',
      author: info['author'] ?? 'Unknown',
      length: info['length'] ?? 0,
      title: info['title'] ?? 'Unknown Track',
      uri: info['uri'],
    );
  }

  String get formattedDuration {
    final duration = Duration(milliseconds: length);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
```

---

### STEP 5: Create Directory Structure

Run:

```bash
mkdir -p src/services
mkdir -p src/models
```

---

### STEP 6: Create Data Models

---

### STEP 7: Create Services

#### File: `src/services/conversation_history_service.dart`

```dart
import 'package:riverpod/riverpod.dart';
import '../models/conversation_message.dart';
import '../env.dart';

final conversationHistoryServiceProvider = Provider<ConversationHistoryService>((ref) {
  return ConversationHistoryService(ref);
});

class ConversationHistoryService {
  final Ref ref;
  final Map<String, List<ConversationMessage>> _history = {};

  ConversationHistoryService(this.ref);

  void addMessage(String userId, String message, String role) {
    if (!_history.containsKey(userId)) {
      _history[userId] = [];
    }

    _history[userId]!.add(ConversationMessage(
      userId: userId,
      message: message,
      timestamp: DateTime.now(),
      role: role,
    ));

    final limit = int.parse(ref.read(envProvider).conversationHistoryLimit);
    if (_history[userId]!.length > limit) {
      _history[userId] = _history[userId]!.sublist(_history[userId]!.length - limit);
    }
  }

  List<ConversationMessage> getHistory(String userId, {int? limit}) {
    if (!_history.containsKey(userId)) return [];
    final messages = _history[userId]!;
    if (limit != null && messages.length > limit) {
      return messages.sublist(messages.length - limit);
    }
    return messages;
  }

  String formatHistoryForPrompt(String userId) {
    final messages = getHistory(userId);
    if (messages.isEmpty) return "No previous conversation.";
    return messages.map((msg) => "${msg.role}: ${msg.message}").join("\n");
  }
}
```

#### File: `src/services/music_ai_service.dart`

````dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../dio.dart';
import '../env.dart';
import '../models/music_request.dart';
import 'conversation_history_service.dart';

final musicAIServiceProvider = Provider<MusicAIService>((ref) {
  return MusicAIService(ref);
});

class MusicAIService {
  final Ref ref;

  MusicAIService(this.ref);

  Future<MusicRequest> analyzeMusicRequest(String userId, String userMessage) async {
    try {
      final env = ref.read(envProvider);
      final conversationService = ref.read(conversationHistoryServiceProvider);
      final history = conversationService.formatHistoryForPrompt(userId);
      final systemPrompt = env.musicAiPersona;

      final fullPrompt = '''$systemPrompt

Conversation History:
$history

Current User Request: $userMessage

Respond ONLY with valid JSON: {"isPolite": true/false, "shouldPlay": true/false, "query": "song or null", "replyMessage": "your response"}''';

      final requestBody = {
        "contents": [
          {
            "parts": [{"text": fullPrompt}]
          }
        ],
        "generationConfig": {
          "temperature": 0.8,
          "maxOutputTokens": 1024,
        },
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
        ]
      };

      final dio = ref.read(dioProvider);
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/${env.aiModel}:generateContent',
        data: requestBody,
        options: Options(headers: {'x-goog-api-key': env.aiApiKey}),
      );

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No AI response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      String aiText = parts?[0]['text'] as String? ?? '';

      aiText = aiText.trim().replaceAll(RegExp(r'^```json\s*'), '').replaceAll(RegExp(r'```\s*$'), '').trim();

      final jsonResponse = jsonDecode(aiText) as Map<String, dynamic>;
      final musicRequest = MusicRequest.fromJson(jsonResponse);

      conversationService.addMessage(userId, userMessage, 'user');
      conversationService.addMessage(userId, musicRequest.replyMessage, 'bot');

      return musicRequest;
    } catch (e) {
      print('MusicAIService Error: $e');
      return _fallbackAnalysis(userMessage);
    }
  }

  MusicRequest _fallbackAnalysis(String message) {
    final lower = message.toLowerCase();
    final rudeWords = ['dumb', 'stupid', 'idiot', 'fuck', 'shit'];
    final isRude = rudeWords.any((w) => lower.contains(w));
    final politeWords = ['please', 'thanks', 'could you'];
    final isPolite = politeWords.any((w) => lower.contains(w));

    if (isRude) {
      return MusicRequest(
        isPolite: false,
        shouldPlay: false,
        query: null,
        replyMessage: "Watch your language! I'm not playing anything for you.",
      );
    }

    final playIndex = lower.indexOf('play');
    String? query;
    if (playIndex != -1 && playIndex + 5 < message.length) {
      query = message.substring(playIndex + 5).trim();
    }

    return MusicRequest(
      isPolite: isPolite,
      shouldPlay: query != null,
      query: query,
      replyMessage: isPolite ? "Sure! Let me play that." : "Alright.",
    );
  }
}
````

#### File: `src/services/lavalink_service.dart`

```dart
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../dio.dart';
import '../env.dart';
import '../models/track_info.dart';

final lavalinkServiceProvider = Provider<LavalinkService>((ref) {
  return LavalinkService(ref);
});

class LavalinkService {
  final Ref ref;

  LavalinkService(this.ref);

  String get _baseUrl {
    final env = ref.read(envProvider);
    return 'http://${env.lavalinkHost}:${env.lavalinkPort}';
  }

  Map<String, String> get _headers {
    final env = ref.read(envProvider);
    return {
      'Authorization': env.lavalinkPassword,
    };
  }

  Future<List<TrackInfo>> searchTracks(String query) async {
    try {
      final dio = ref.read(dioProvider);
      final identifier = query.startsWith('http') ? query : 'ytsearch:$query';

      print('LavalinkService: Searching: $identifier');

      final response = await dio.get(
        '$_baseUrl/loadtracks',
        queryParameters: {'identifier': identifier},
        options: Options(headers: _headers),
      );

      final loadType = response.data['loadType'] as String?;

      if (loadType == 'TRACK_LOADED') {
        return [TrackInfo.fromLavalinkJson(response.data['tracks'][0])];
      } else if (loadType == 'SEARCH_RESULT' || loadType == 'PLAYLIST_LOADED') {
        final tracks = response.data['tracks'] as List<dynamic>;
        return tracks.map((t) => TrackInfo.fromLavalinkJson(t)).toList();
      }
      return [];
    } catch (e) {
      print('LavalinkService Error: $e');
      return [];
    }
  }
}
```

---

### STEP 7: Create Play Command

#### File: `src/commands/play_command.dart`

```dart
import 'dart:async';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:riverpod/riverpod.dart';
import '../env.dart';
import '../services/music_ai_service.dart';
import '../services/lavalink_service.dart';
import 'commands.dart';

class PlayCommand extends SlashRunnable {
  @override
  final String name = 'play';

  @override
  final String description = 'Play music (be nice!)';

  @override
  FutureOr<ChatCommand?> initialize(Ref<Object?> ref) {
    enabled = true;

    return ChatCommand(
      name,
      description,
      options: CommandOptions(type: CommandType.all),
      id(
        name,
        (ChatContext context, @Description('What music?') String request) async {
          try {
            final userId = context.user.id.toString();

            await context.respond(MessageBuilder(content: '🤔 Analyzing...'));

            final musicAI = ref.read(musicAIServiceProvider);
            final analysis = await musicAI.analyzeMusicRequest(userId, request);

            if (!analysis.isPolite) {
              final env = ref.read(envProvider);
              final rickrollUrl = env.rickrollUrl;

              await context.respond(MessageBuilder(content: analysis.replyMessage));

              final lavalink = ref.read(lavalinkServiceProvider);
              final tracks = await lavalink.searchTracks(rickrollUrl);

              if (tracks.isNotEmpty) {
                await context.respond(MessageBuilder(
                  content: '🎵 Here\'s what you deserve! 🎵\n${tracks.first.title}',
                ));
              }
              return;
            }

            if (analysis.shouldPlay && analysis.query != null) {
              final lavalink = ref.read(lavalinkServiceProvider);
              final tracks = await lavalink.searchTracks(analysis.query!);

              if (tracks.isEmpty) {
                await context.respond(MessageBuilder(
                  content: '${analysis.replyMessage}\n\n❌ Couldn\'t find that track.',
                ));
                return;
              }

              final track = tracks.first;
              await context.respond(MessageBuilder(
                content: '${analysis.replyMessage}\n\n🎵 **${track.title}**\n👤 ${track.author}\n⏱️ ${track.formattedDuration}',
              ));
            } else {
              await context.respond(MessageBuilder(content: analysis.replyMessage));
            }
          } catch (e) {
            print('PlayCommand Error: $e');
            await context.respond(MessageBuilder(content: '❌ Something went wrong!'));
          }
        },
      ),
    );
  }
}
```

---

### STEP 9: Register Play Command

**File:** `src/commands/commands.dart`

**Add import:**

```dart
import 'play_command.dart';
```

**Find the `initialize()` method and add PlayCommand:**

```dart
final slashCommands = [
  WaifuCommand().command,
  AskCommand().command,
  PlayCommand().command,  // ADD THIS LINE
];
```

---

### STEP 10: Deploy to Render!

1. **Push code to GitHub**

2. **Create Render Background Worker:**

   - Go to Render Dashboard
   - Click "New +" → "Background Worker"
   - Connect your GitHub repo
   - Name: `discord-music-bot`
   - Runtime: **Docker**
   - Region: Choose closest to you

3. **Add Environment Variables in Render:**

   - Go to "Environment" tab
   - Add ALL variables from your `.env` file
   - Make sure `LAVALINK_HOST=lavalink.darrennathanael.com`
   - Make sure `LAVALINK_PORT=443`
   - Make sure `LAVALINK_PASSWORD=youshallnotpass`

4. **Deploy!**
   - Click "Create Background Worker"
   - Wait for build and deployment
   - Check logs for: `Environment variables loaded successfully`

---

### STEP 11: Test It!

1. **Start services:**

```bash
docker-compose up --build
```

2. **Test commands in Discord:**

- Polite: `/play please play lofi hip hop`
- Rude: `/play play music you stupid bot`

---

## ⚠️ IMPORTANT NOTES

1. **Using Hosted Lavalink** - Free and maintained by third party
2. **Voice connection NOT fully implemented** - Shows search results but doesn't play in VC yet (Nyxx v6 voice API needs research)
3. **Conversation history is in-memory** - Lost on restart
4. **No queue system** - Single track search only
5. **Hosted Lavalink limitations** - Shared resources, depends on uptime

### If Hosted Lavalink is Down:

Try alternative hosted servers:

- `https://lavalink-replit.darrennathanael.repl.co/`
- Check [lavalink.darrennathanael.com](https://lavalink.darrennathanael.com/) for status

Or deploy your own (see RENDER_DEPLOYMENT_GUIDE.md Option 2)

---

## 🚧 TODO (Advanced)

- Implement actual voice channel connection
- Add queue management
- Add skip/stop/nowplaying commands
- Persist conversation history to database

---

## 🗑️ DELETE BOTH FILES AFTER COMPLETION

- IMPLEMENTATION_GUIDE.md
- MUSIC_BOT_IMPLEMENTATION_PLAN.md
