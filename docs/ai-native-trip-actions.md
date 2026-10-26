# AT AI native pickup and cancellation review

## Booking

The customer approved using device location as the default pickup and then
opening the existing native ride confirmation, not autonomous AI ordering.
The app uses a fresh GPS fix (up to 60 seconds old), reverse-geocodes it, and
sends only the address in `currentPickup` to `/api/chat/message`.
The native coordinates remain on-device and are retained for route confirmation.
An explicitly supplied pickup overrides this default.

If location permission has not been granted, the app asks the OS only after AI
requests a pickup. Denied permission, disabled location or a failed GPS fix
leave manual address entry available. No old saved location is substituted.

## Cancellation

The server's `nativeAction: CANCEL_TRIP` only opens a review card in chat.
It does not execute a cancellation. The native Core repository:

- reloads the current account and its active booking IDs;
- lets the customer choose if more than one trip is active;
- loads the real trip, driver acceptance, cancellation eligibility and fee;
- offers the five product-approved reasons, Other and optional written text;
- requires the customer to press Confirm cancellation;
- reloads ownership, trip stage, driver and fee before mutation;
- requires a new confirmation if those details have changed;
- submits through the existing authenticated Core cancellation API;
- reports success only after Core confirms it.

No account token, booking ID, payment data or cancellation authority is sent to
the AI server. Reasons remain optional. Core must accept a blank reason for
reason-free cancellation. The AI and native releases must ship together.

## Verification boundary

Pure-Dart policy/source checks and backend TypeScript checks are available here.
Flutter compilation and real-device location, permission and active-trip tests
require the project's supported Flutter SDK/native release environment.
Do not cancel real passenger bookings as a test.
