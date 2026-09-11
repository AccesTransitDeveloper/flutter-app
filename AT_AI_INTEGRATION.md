# AT AI Flutter integration

The customer app contains a native AT AI assistant with text chat, microphone
recording, transcription, text-to-speech playback, and animated listening,
thinking, and speaking states.

## Configure the backend

The mobile app does not contain OpenAI, ElevenLabs, or AT API keys. It connects
to the AT AI backend through a compile-time URL:

```bash
flutter pub get
flutter run \
  --dart-define=AT_AI_API_BASE_URL=https://your-published-at-ai-api-domain
```

Use the published HTTPS domain of the AT AI API server. Do not use a localhost
address in a device build and do not place server API keys in `--dart-define`.

The client initializes an HttpOnly-compatible server session through
`POST /api/session/init` and sends the returned session cookie to:

- `POST /api/chat/message`
- `POST /api/chat/transcribe`
- `POST /api/chat/tts`

## User flow

1. Open **Plan your ride**.
2. Tap the **AT AI** chip.
3. Type a request or tap the microphone.
4. AT AI transcribes the recording, replies, and speaks the reply.
5. When a trip suggestion appears, tap **Continue booking in app** to return to
   the existing native booking screen.

AT AI does not create a separate booking. The existing Flutter booking flow
remains the source of truth.

## Platform permissions

- Android: `RECORD_AUDIO`
- iOS: `NSMicrophoneUsageDescription`

## Verification

Run these checks in a Flutter environment before release:

```bash
dart format lib
flutter analyze
flutter test
flutter build apk \
  --dart-define=AT_AI_API_BASE_URL=https://your-published-at-ai-api-domain
```