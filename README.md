## Discord Bot

This is a discord bot which does only thing mass ping someone 🤣. You can add your own commands if you like.

## Prerequisites
1. Docker

## Installation
1. Clone the repository
2. Create a `.env` file in the root directory and add the following
```env
BOT_TOKEN=<YOUR_BOT_TOKEN>
PREFIX=<YOUR_BOT_PREFIX>
FOOTER_TEXT=<YOUR_FOOTER_TEXT>

```

3. Run the bot(if you get a permission error, run the command with `sudo`)
```bash
docker-compose up --build -d
```
4. Once the bot is online just ping the bot and the initial setup will start


## Contributers
Special thanks goes 
1. Tomic Riedel: [@tomic-riedel](https://github.com/tomic-riedel/)