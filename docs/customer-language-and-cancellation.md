# Customer chat, route pins and cancellation rollout

## Customer changes

- The AT AI quick-question grid and Suggestions toggle are removed.
- The message composer is raised by 27 logical pixels, in addition to existing safe-area/keyboard spacing.
- EN, RU, ES, AR, ZH, HI, TR and JA selections are passed to chat, transcription and speech. Changing language stops old speech/recording and rejects stale responses.
- Speech uses the actual voice configured on the corresponding ElevenLabs customer agent. It does not use a shared default English voice for every language.
- Text and structured address suggestions still use the AT AI server. Native booking remains authoritative. This is not a migration to native live ElevenLabs conversation sessions.
- Cancellation offers five localized quick reasons and optional free text. Selecting or writing a reason is not required. Empty reason is serialized explicitly as `cancellationReason: ""`.
- The cancellation sheet stays open while the request runs. Failed requests remain retryable; duplicate submission is disabled.
- Debug ribbons are disabled on all MaterialApp branches.
- Pickup and final destination use a shared black ring-and-stem glyph, with a transparent background and hole. Mapbox, the blue route, driver vehicle images and numbered intermediate stops are preserved.

## Required server releases

1. Release the AT AI backend and its updated OpenAPI contract together with this client. `/chat/message`, `/chat/transcribe` and `/chat/tts` accept the selected `language`. Chat and speech responses echo the language; speech also returns the selected `agentId`. Old servers that ignore the selection produce an explicit configuration error rather than a wrong-language reply.
2. Customer agents are resolved by the existing `AT ai — EN` / `AT ai — RU` etc. names. Optional server-only `ELEVENLABS_CUSTOMER_AGENT_<CODE>` configuration can reference differently named existing agents. The backend validates the agent's language and uses its actual configured voice. Secrets must stay server-side.
3. In the separate Accessible Transit Core backend, the shared cancellation validator must allow an explicitly blank reason:

   `cancellationReason`: string, required property, `isAllowBlank: true`.

   Do not replace a missing user reason with fabricated text or whitespace. Do not change cancellation eligibility, ownership checks or cancellation fees. Deploy the Core change before relying on reason-free cancellation.

## Verification

The workspace has Dart but no Flutter SDK. Syntax/source checks and the pure-Dart cancellation-reason checks ran here; Flutter widget tests and Android/iOS builds still require the project's supported Flutter SDK.

Run `dart test/customer_changes_check.dart` for source-contract checks and `flutter test test/route_point_glyph_test.dart` with Flutter for actual glyph geometry/widget checks. Then verify chat language switching, microphone/audio cleanup, the cancellation success/failure paths, keyboard spacing and marker rendering on Android and iOS. Do not cancel a real passenger booking as a test.
