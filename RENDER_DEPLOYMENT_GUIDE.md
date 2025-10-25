# 🚀 Render Deployment Guide for Music Bot

## 🔍 Key Difference: Render vs Docker Compose

**Problem:** Render doesn't support `docker-compose.yml` with multiple services in one repo.

**Solution:** Deploy Lavalink and Bot as **separate Render services** that communicate via private networking.

---

## 📦 Deployment Architecture on Render

```
┌─────────────────────────────────────────────────┐
│                  Render Account                  │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────────┐    ┌──────────────────┐  │
│  │   Service 1:     │    │   Service 2:     │  │
│  │   Discord Bot    │◄──►│   Lavalink       │  │
│  │  (Background     │    │  (Private        │  │
│  │   Worker)        │    │   Service)       │  │
│  └──────────────────┘    └──────────────────┘  │
│         ▲                                        │
│         │ Discord Gateway                        │
│         │                                        │
└─────────┼────────────────────────────────────────┘
          │
     ┌────▼─────┐
     │ Discord  │
     │  Servers │
     └──────────┘
```

---

## 🎯 Step-by-Step Render Deployment

### OPTION 1: Using Hosted Lavalink (RECOMMENDED - EASIEST)

Instead of hosting Lavalink yourself, use a free hosted Lavalink server:

**Free Lavalink Providers:**

- https://lavalink.darrennathanael.com/
- https://lavalink-replit.darrennathanael.repl.co/

**Pros:**

- No need to deploy Lavalink separately
- Free and maintained
- Just use their URL and password

**Cons:**

- Depends on third-party uptime
- Shared resources

#### Implementation for Hosted Lavalink:

1. **Remove Lavalink-specific files:**

   - Delete `docker-compose.yml` (not used on Render)
   - Delete `lavalink/` directory (not needed)

2. **Update `.env` with hosted Lavalink:**

   ```bash
   LAVALINK_HOST=lavalink.darrennathanael.com
   LAVALINK_PORT=443
   LAVALINK_PASSWORD=youshallnotpass
   # ... rest of your env variables
   ```

3. **Update `Dockerfile`** (remove Lavalink dependencies):

   ```dockerfile
   FROM dart:stable AS build
   WORKDIR /app

   # Install yt-dlp for fallback (optional)
   RUN apt-get update && apt-get install -y \
       python3 \
       python3-pip \
       && pip3 install --break-system-packages yt-dlp \
       && apt-get clean \
       && rm -rf /var/lib/apt/lists/*

   COPY pubspec.* ./
   RUN dart pub get

   COPY . .
   RUN dart pub get --offline

   CMD ["dart", "run", "bin/main.dart"]
   ```

4. **Deploy on Render:**
   - Service Type: **Background Worker**
   - Build Command: (leave empty, uses Dockerfile)
   - Runtime: Docker
   - Add environment variables from `.env`

---

### OPTION 2: Self-Hosted Lavalink on Render (ADVANCED)

Deploy both services separately on Render and connect them.

#### Step 1: Deploy Lavalink Service

1. **Create Lavalink configuration repo** (separate from your bot):

   Create a new GitHub repo with just these files:

   **`Dockerfile`:**

   ```dockerfile
   FROM openjdk:17-slim

   WORKDIR /opt/Lavalink

   # Download Lavalink jar
   ADD https://github.com/lavalink-devs/Lavalink/releases/download/4.0.4/Lavalink.jar Lavalink.jar

   # Copy config
   COPY application.yml application.yml

   # Expose port
   EXPOSE 2333

   # Run Lavalink
   CMD ["java", "-jar", "Lavalink.jar"]
   ```

   **`application.yml`:**

   ```yaml
   server:
     port: 2333
     address: 0.0.0.0

   lavalink:
     server:
       password: "youshallnotpass"
       sources:
         youtube: true
         bandcamp: true
         soundcloud: true
         http: true
       bufferDurationMs: 400
       frameBufferDurationMs: 5000
       youtubePlaylistLoadLimit: 6
       playerUpdateInterval: 5
       youtubeSearchEnabled: true
       soundcloudSearchEnabled: true

   logging:
     level:
       root: INFO
       lavalink: INFO
   ```

2. **Deploy on Render:**
   - Service Type: **Private Service** (not publicly accessible)
   - Name: `lavalink-server`
   - Runtime: Docker
   - Port: 2333
   - Health Check Path: `/version`
   - Note the **Internal URL** (e.g., `lavalink-server:2333`)

#### Step 2: Deploy Discord Bot

1. **Update Bot's environment variables:**

   ```bash
   # Use Lavalink's internal Render URL
   LAVALINK_HOST=lavalink-server  # Internal hostname from Render
   LAVALINK_PORT=2333
   LAVALINK_PASSWORD=youshallnotpass
   ```

2. **Deploy Bot on Render:**
   - Service Type: **Background Worker**
   - Runtime: Docker
   - Add all environment variables
   - **Important:** Deploy in **same region** as Lavalink for private networking

---

## 📝 Updated Files for Render

### Remove These Files:

- ❌ `docker-compose.yml` (not used on Render)

### Keep/Modify These Files:

#### `Dockerfile` (Simplified for Render):

```dockerfile
FROM dart:stable AS build
WORKDIR /app

# Optional: Install yt-dlp for backup audio extraction
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && pip3 install --break-system-packages yt-dlp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline

# Health check for Render
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD dart --version || exit 1

CMD ["dart", "run", "bin/main.dart"]
```

---

## 🔐 Render Environment Variables

Add these in Render Dashboard → Environment:

```bash
# Discord
BOT_TOKEN=your_discord_token
PREFIX=!
FOOTER_TEXT=Red Door Bot
ADMIN_USER_ID=your_discord_user_id
GUILD_ID=your_guild_id

# Waifu API
WAIFU_API_URL=your_waifu_api

# Google AI
AI_API_KEY=your_google_ai_key
RED_DOOR_AI_PERSONA=your_ai_persona
AI_MODEL=gemini-1.5-flash

# Music Bot - Option 1: Hosted Lavalink
LAVALINK_HOST=lavalink.darrennathanael.com
LAVALINK_PORT=443
LAVALINK_PASSWORD=youshallnotpass

# Music Bot - Option 2: Self-hosted (use internal URL)
# LAVALINK_HOST=lavalink-server
# LAVALINK_PORT=2333
# LAVALINK_PASSWORD=youshallnotpass

# Music Settings
RICKROLL_URL=https://www.youtube.com/watch?v=4YweTt_Usjg
CONVERSATION_HISTORY_LIMIT=10
MUSIC_AI_PERSONA="You are a sassy DJ bot. Analyze music requests for: 1) Politeness 2) Music intent 3) Query extraction. Return JSON: {\"isPolite\": bool, \"shouldPlay\": bool, \"query\": string|null, \"replyMessage\": string}. If rude: insult them. If polite: be friendly."
```

---

## 🔧 Service Configuration in `src/services/lavalink_service.dart`

**Update for HTTPS support (if using hosted Lavalink):**

```dart
String get _baseUrl {
  final env = ref.read(envProvider);
  final port = env.lavalinkPort;
  final protocol = port == '443' ? 'https' : 'http';
  return '$protocol://${env.lavalinkHost}${port == '443' || port == '80' ? '' : ':$port'}';
}
```

---

## ✅ Deployment Checklist

### For Hosted Lavalink (Recommended):

- [ ] Update `.env` with hosted Lavalink URL
- [ ] Remove `docker-compose.yml`
- [ ] Update `Dockerfile` (remove Lavalink deps)
- [ ] Push to GitHub
- [ ] Create Render Background Worker
- [ ] Add environment variables in Render
- [ ] Deploy and test

### For Self-Hosted Lavalink:

- [ ] Create separate Lavalink repo
- [ ] Deploy Lavalink as Private Service
- [ ] Note Lavalink's internal URL
- [ ] Update bot's `LAVALINK_HOST` to internal URL
- [ ] Deploy bot as Background Worker
- [ ] Test connectivity

---

## 🧪 Testing on Render

1. **Check Logs:**

   ```
   Render Dashboard → Your Service → Logs
   ```

2. **Look for:**

   ```
   ✓ Environment variables loaded successfully
   ✓ LavalinkService: Connected to Lavalink
   ✓ Bot connected to Discord
   ```

3. **Test Commands:**
   - `/play please play lofi hip hop` → Should search and show results
   - `/play play music stupid bot` → Should insult and rickroll

---

## 🚨 Common Render Issues

### Issue 1: "Background worker keeps restarting"

**Cause:** Bot exits immediately
**Fix:** Make sure bot keeps running (event loop active)

### Issue 2: "Can't connect to Lavalink"

**Cause:** Wrong host/port or Lavalink not running
**Fix:**

- Check `LAVALINK_HOST` uses internal URL (no http://)
- Verify Lavalink service is deployed and healthy
- Use hosted Lavalink as backup

### Issue 3: "Environment variables not found"

**Cause:** Not set in Render dashboard
**Fix:** Add all variables in Render → Environment tab

---

## 💰 Render Pricing Notes

- **Background Worker:** Free tier available (750 hrs/month)
- **Private Service (Lavalink):** Paid only ($7/month minimum)
- **Recommendation:** Use **hosted Lavalink** to stay on free tier

---

## 📚 Additional Resources

- [Render Background Workers](https://render.com/docs/background-workers)
- [Render Private Services](https://render.com/docs/private-services)
- [Render Docker Guide](https://render.com/docs/docker)
- [Free Lavalink Servers List](https://lavalink.darrennathanael.com/)

---

## 🗑️ Cleanup After Implementation

Delete these files:

- `RENDER_DEPLOYMENT_GUIDE.md`
- `IMPLEMENTATION_GUIDE.md`
- `MUSIC_BOT_IMPLEMENTATION_PLAN.md`
- `QUICK_START.md`
- `docker-compose.yml` (not used on Render)
