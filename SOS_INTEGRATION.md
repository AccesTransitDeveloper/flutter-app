# Passenger SOS — Profile / Help

In `AccesTransitDeveloper/flutter-app`, Profile → Help → **SOS — Emergency help**
opens the passenger safety screen. Existing Help tickets, contact buttons,
AT Support Chat, Firebase notifications and Mapbox rendering remain unchanged.
SOS alerts AT dispatch; it does not automatically call emergency services.
The emergency dialer button explicitly says **911 (US)**.

## Trusted server boundary

The existing Replit onboarding/support gateway exposes these passenger routes:

- POST `/at-driver-web/onboarding/api/passenger-sos/alerts`
  `{requestId: UUIDv4, tripId: Core booking ID, reason?: string}`
- GET `/at-driver-web/onboarding/api/passenger-sos/alerts/:id`
- POST `/at-driver-web/onboarding/api/passenger-sos/alerts/:id/location`
  `{sampleId: UUIDv4, location: {latitude, longitude, accuracyMeters?, capturedAt}}`

The Flutter app sends its existing account authorization, never a CRM secret.
The gateway verifies a Core customer (type 2), loads the real Core booking and
checks `customerDetail.id` against the authenticated account. Contacts, driver,
vehicle and route come only from that verified booking. Foreign trips, closed
trips and incomplete participant contacts fail explicitly.
CRM receives `/api/external/sos/passenger/<verified-account-id>/...`
with the gateway's existing server-only `DRIVER_APPLICATION_API_KEY`.
Passenger and driver ownership remain separate, even if their account IDs match.
The native response contains only confirmation/status; dispatcher notes and the
other participant's GPS are never returned.

## Delivery and location

The original UUID, trip ID and reason are saved before network I/O, per customer
account. Timeout retries and reopening reuse that request; the server also keeps
the original verified trip snapshot. Confirmation means CRM saved the event,
not that dispatch accepted it or help arrived. Status is polled while open.
Retriable connection errors use bounded backoff; permanent errors need action.

SOS never waits for GPS. Only after confirmation can the customer consent to
sharing their own foreground position. Saved GPS samples retain the same UUID
and real capture timestamp when retried. GPS stops on resolution, sign-out,
permission/session loss, leaving the screen or backgrounding. Reopening requires
fresh consent. No background/killed-app tracking is promised.
No active Core trip: show honest unavailability and retain phone fallbacks.
Pre-SOS trip tracking and assignment-time CRM synchronization are not added.

## Release and verification

Gateway source is maintained separately in Replit, not this Flutter repository.
Publish its passenger SOS changes and build/release this native client together.
The existing PostgreSQL gateway store is required, including permission to create
its SOS request table. Do not confuse a GitHub source update with either release.

Existing native dependencies and lockfiles are preserved.
Pure Dart contract checks can be run with `dart test/sos_contract_check.dart`.
Full Flutter analyze/build requires the project's Flutter SDK. Before release,
test Android/iOS Profile → Help navigation, a real assigned trip, CRM acceptance
and resolution, poor network/reopening without duplicate alerts, GPS denial,
withdrawal, backgrounding/logout, and both native dialer buttons.
Automated verification must not send production emergency alerts.
