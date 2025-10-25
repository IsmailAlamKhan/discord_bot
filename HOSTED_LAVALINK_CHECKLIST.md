# ✅ Hosted Lavalink Implementation Checklist

## 🎯 You're using FREE hosted Lavalink - No self-hosting needed!

---

## 📋 Step-by-Step Checklist

### 1. Environment Configuration ⬜

- [ ] Copy `.env.render.example` to `.env`
- [ ] Fill in your Discord bot token
- [ ] Fill in your Google AI API key
- [ ] Verify Lavalink settings:
  ```bash
  LAVALINK_HOST=lavalink.darrennathanael.com
  LAVALINK_PORT=443
  LAVALINK_PASSWORD=youshallnotpass
  ```

### 2. Create Directory Structure ⬜

```bash
mkdir -p src/services
mkdir -p src/models
```

### 3. Create Model Files ⬜

Follow `IMPLEMENTATION_GUIDE.md` STEP 6:

- [ ] `src/models/conversation_message.dart` (copy from guide)
- [ ] `src/models/music_request.dart` (copy from guide)
- [ ] `src/models/track_info.dart` (copy from guide)

### 4. Update env.dart ⬜

Follow `IMPLEMENTATION_GUIDE.md` STEP 3:

- [ ] Add 6 new entries to `envKeys` constant
- [ ] Add 6 new properties to `Env` abstract class
- [ ] Add 6 new assignments to `setEnv` method

### 5. Create Service Files ⬜

Follow `IMPLEMENTATION_GUIDE.md` STEP 4 & 7:

- [ ] `src/services/lavalink_service.dart` (with HTTPS support - STEP 4)
- [ ] `src/services/conversation_history_service.dart` (STEP 7)
- [ ] `src/services/music_ai_service.dart` (STEP 7)

### 6. Create Play Command ⬜

Follow `IMPLEMENTATION_GUIDE.md` STEP 8:

- [ ] `src/commands/play_command.dart` (copy from guide)

### 7. Register Play Command ⬜

Follow `IMPLEMENTATION_GUIDE.md` STEP 9:

- [ ] Add `import 'play_command.dart';` to `src/commands/commands.dart`
- [ ] Add `PlayCommand().command,` to the slashCommands list

### 8. Test Locally (Optional) ⬜

- [ ] Run `dart pub get`
- [ ] Run `dart run bin/main.dart`
- [ ] Check if bot connects to Discord
- [ ] Test `/play please play lofi hip hop`

### 9. Deploy to Render ⬜

Follow `IMPLEMENTATION_GUIDE.md` STEP 10:

- [ ] Push code to GitHub
- [ ] Create Render Background Worker
- [ ] Select Docker runtime
- [ ] Add ALL environment variables from `.env`
- [ ] Click "Create Background Worker"

### 10. Verify Deployment ⬜

Follow `IMPLEMENTATION_GUIDE.md` STEP 11:

- [ ] Check Render logs for "Environment variables loaded successfully"
- [ ] Check logs for "Bot connected to Discord"
- [ ] Test polite command: `/play please play never gonna give you up`
- [ ] Test rude command: `/play play music you stupid bot`
- [ ] Verify rickroll response for rude requests

---

## 🎉 Success Criteria

✅ Bot shows online in Discord
✅ `/play` command appears in Discord
✅ Polite requests show friendly response + track info
✅ Rude requests show insult + rickroll track
✅ AI remembers conversation context

---

## 🐛 Troubleshooting

### Bot won't start on Render

- Check all environment variables are set
- Check Render logs for specific error
- Verify `BOT_TOKEN` is correct

### "Can't connect to Lavalink"

- Verify `LAVALINK_HOST=lavalink.darrennathanael.com`
- Verify `LAVALINK_PORT=443`
- Check if hosted Lavalink is up: https://lavalink.darrennathanael.com/

### "No tracks found"

- Check Render logs for Lavalink response
- Try different search query
- Verify Lavalink service is responding (check logs)

### AI not detecting rudeness

- Check `MUSIC_AI_PERSONA` is set
- Check `AI_API_KEY` is valid
- Look for AI service errors in logs
- Fallback keyword detection should still work

---

## 🗑️ After Completion

Delete these documentation files:

- [ ] HOSTED_LAVALINK_CHECKLIST.md (this file)
- [ ] IMPLEMENTATION_GUIDE.md
- [ ] RENDER_DEPLOYMENT_GUIDE.md
- [ ] MUSIC_BOT_IMPLEMENTATION_PLAN.md
- [ ] QUICK_START.md
