# AT Support Chat notifications

Uses the app's existing Firebase and notification manager. No new Firebase
project or service-account file is required.

- FCM type `AT_SUPPORT_REPLY`, version `1`; only allowlisted event/chat/owner IDs.
- Taps from remote, local and cold-launch notifications wait for the authenticated
  home screen. The current customer's API checks the conversation before navigation.
- An open matching thread refreshes without an additional banner. A different
  thread shows a generic notification. No message text or attachment information
  appears on the lock screen.
- Sign-out clears pending support navigation and deletes the FCM token. The next
  login obtains/registers a fresh token through the existing device-token API.
- iOS foreground banners (including normal ride notifications) are rendered by
  the existing local manager instead of APNs automatic presentation. Physical
  iOS checks must verify ride banners/sounds and background/killed-app support alerts.

Server enablement is described in the Core repository's `SUPPORT_PUSH_SETUP.md`.
Source changes alone do not enable Core's CRM connection or publish an app update.

Pure-Dart check: `dart test/support_push_contract_check.dart`.
Complete Flutter SDK analysis and physical Android/iOS Firebase delivery must be
verified in the native build/release environment.
