# 🤖 Red Door Discord Bot

A feature-rich Discord bot built with **Dart** using the [nyxx](https://pub.dev/packages/nyxx) library. It supports prefix-based inline commands as well as slash commands, and comes fully containerized with Docker for easy deployment.

---

## ✨ Features

- **Mass Ping** — Relentlessly ping a user in a private channel until they respond (or mercy is granted). Only the initiator or an admin can stop it.
- **Waifu Command** — Fetch random anime waifu images (SFW & NSFW) via the Waifu API, with per-user category preferences and a points system.
- **AI Chat (`/ask`)** — Ask the bot anything and receive AI-generated responses powered by a configurable AI model.
- **Waifu Points** — Track how many waifu images each user has requested.
- **Help Menu** — Embedded help message listing all available commands and their usage.
- **Config** — Change the bot prefix and other settings at runtime.
- **Member Join/Leave Events** — Automated messages when members join or leave the server.
- **Cron Jobs** — Scheduled background tasks for recurring bot behaviors.

---

## 🛠 Tech Stack

| Technology | Purpose |
|---|---|
| [Dart](https://dart.dev) (SDK ^3.3.2) | Primary language |
| [nyxx](https://pub.dev/packages/nyxx) ^6.2.1 | Discord API client |
| [nyxx_commands](https://pub.dev/packages/nyxx_commands) ^6.0.2 | Slash & prefix command framework |
| [Riverpod](https://pub.dev/packages/riverpod) ^2.5.1 | Dependency injection & state management |
| [Dio](https://pub.dev/packages/dio) ^5.4.3 | HTTP client (Waifu API, AI API) |
| [cron](https://pub.dev/packages/cron) ^0.6.0 | Scheduled tasks |
| [fpdart](https://pub.dev/packages/fpdart) ^1.1.0 | Functional programming utilities |
| Docker & Docker Compose | Containerized deployment |

---

## 📋 Prerequisites

- [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/) installed on your machine.

---

## 🚀 Installation & Setup

### 1. Clone the repository

```bash
git clone https://github.com/IsmailAlamKhan/discord_bot.git
cd discord_bot
```

### 2. Configure environment variables

Create a `.env` file in the root directory with the following variables:

```env
BOT_TOKEN=<your_discord_bot_token>
FOOTER_TEXT=<your_footer_text>
ADMIN_USER_ID=<discord_user_id_of_the_admin>
WAIFU_API_URL=<waifu_api_base_url>
GUILD_ID=<your_discord_guild_id>
AI_API_KEY=<your_ai_api_key>
RED_DOOR_AI_PERSONA=<ai_persona_prompt>
AI_MODEL=<ai_model_name>
```

| Variable | Required | Description |
|---|---|---|
| `BOT_TOKEN` | ✅ | Your Discord bot token |
| `FOOTER_TEXT` | ✅ | Text shown in embed footers |
| `ADMIN_USER_ID` | ✅ | Discord ID of the bot admin |
| `WAIFU_API_URL` | ✅ | Base URL for the Waifu image API |
| `GUILD_ID` | ✅ | Your Discord server (guild) ID |
| `AI_API_KEY` | ✅ | API key for the AI service |
| `RED_DOOR_AI_PERSONA` | ✅ | System persona/prompt for the AI |
| `AI_MODEL` | ✅ | The AI model to use (e.g. `gemini-pro`) |

### 3. Run the bot

```bash
# If you encounter a permission error, run with sudo
docker-compose up --build -d
```

### 4. Initial setup

Once the bot is online, ping the bot in your server to trigger the initial setup process.

---

## 💬 Commands

### Prefix Commands

These commands are triggered using the configured bot prefix (default setup on first ping).

| Command | Alias | Description |
|---|---|---|
| `mass-ping <@user> [stop]` | `mp` | Start or stop mass pinging a user in a private channel |
| `config` | `conf` | View or update the bot configuration |
| `help` | `h` | Display all available commands |
| `waifu-points` | `wp` | Check a user's waifu points |
| `ai <question>` | `ai` | Ask the AI a question |

### Slash Commands

| Command | Description |
|---|---|
| `/waifu` | Get a random waifu image — choose SFW or NSFW, then select a category |
| `/ask` | Ask the AI a question |

---

## 🏗 Project Structure

```
discord_bot/
├── bin/                    # Entry point
├── src/
│   ├── commands/           # Slash command definitions
│   │   ├── waifu_command.dart
│   │   └── ask_command.dart
│   ├── runnables/          # Prefix command handlers
│   │   ├── mass_ping_runnable.dart
│   │   ├── waifu_points.dart
│   │   ├── help_runnable.dart
│   │   ├── config_runnable.dart
│   │   └── ask.dart
│   ├── utils/              # Shared utilities
│   ├── bot.dart            # Bot initialization
│   ├── commands.dart       # Command registry
│   ├── env.dart            # Environment variable handling
│   ├── db.dart             # Local database controller
│   ├── cron.dart           # Cron job management
│   └── generate_waifu.dart # Waifu image generation logic
├── tags.json               # Waifu API tag definitions
├── docker-compose.yml
├── Dockerfile
└── pubspec.yaml
```

---

## 🔧 Adding Custom Commands

The bot is designed to be easily extensible:

1. **Prefix command** — Create a new class extending `Runnable` in `src/runnables/`, implement the `run` method, then register it in `src/commands.dart` under the `Command` enum.
2. **Slash command** — Create a new class extending `SlashRunnable` in `src/commands/`, implement the `initialize` method, then register it in the slash commands provider.

---

## 🤝 Contributors

Special thanks to:

- **Tomic Riedel** — [@tomic-riedel](https://github.com/tomic-riedel/)

---

## 📄 License

This project does not currently include a license file. Please contact the repository owner for usage permissions.

---

<div align="center">
  <sub>Built with ❤️ using Dart & nyxx</sub>
</div>
