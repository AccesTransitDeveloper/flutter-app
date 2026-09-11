package com.app.customer

import android.content.Intent
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

/**
 * Live-activity pushes carry a `progress` data field plus an empty
 * `notification` block. When the app is backgrounded the FCM SDK auto-posts
 * that empty block to the system tray, which shows up as a blank card next to
 * the custom live-booking notification built by [LiveNotificationManager].
 *
 * Stripping the `gcm.notification.*` extras makes the SDK treat those pushes as
 * data-only, so nothing is auto-displayed. This mirrors the native app, whose
 * `FirebaseCloudMessagingService` overrides `handleIntent` and never calls
 * `super` for message intents.
 *
 * Delivery to Dart is unaffected: the plugin routes messages through
 * `FlutterFirebaseMessagingReceiver`, a separate broadcast receiver.
 */
class AppFirebaseMessagingService : FlutterFirebaseMessagingService() {

    override fun handleIntent(intent: Intent) {
        if (intent.extras?.getString("progress") != null) {
            intent.extras
                ?.keySet()
                ?.filter { it.startsWith(NOTIFICATION_EXTRA_PREFIX) }
                ?.forEach { intent.removeExtra(it) }
        }
        dismissEndedLiveNotification(intent)
        super.handleIntent(intent)
    }

    /**
     * Tear the live notification down from the push itself, the way native's
     * `FirebaseCloudMessagingService` does via `LiveNotificationType.END`.
     *
     * The Dart side only stops the surface from `CurrentRideViewModel`, which is
     * an autoDispose family provider — it exists solely while the running-ride
     * screen is on top. Cancel the ride from anywhere else, or have the driver
     * cancel while the app is backgrounded or killed, and nothing ever cancelled
     * the notification, so dead bookings piled up in the tray.
     *
     * The push is authoritative here and arrives in every app state, so both
     * sides of a cancellation — customer's or driver's — land the same way.
     */
    private fun dismissEndedLiveNotification(intent: Intent) {
        val extras = intent.extras ?: return
        val bookingId = extras.getString("bookingId")?.takeIf { it.isNotBlank() } ?: return

        val isEndEvent = extras.getString("event").equals(EVENT_END, ignoreCase = true)
        // Servers that don't send an explicit `end` still report the status, and
        // everything at or past "arrived" (70) — completed and cancelled (90)
        // included — is terminal for the live surface.
        val status = extras.getString("status")?.toIntOrNull() ?: -1
        val isTerminalStatus = status >= TERMINAL_STATUS

        if (isEndEvent || isTerminalStatus) {
            LiveNotificationManager.dismissNotification(this, bookingId)
        }
    }

    private companion object {
        const val NOTIFICATION_EXTRA_PREFIX = "gcm.notification."
        const val EVENT_END = "end"
        const val TERMINAL_STATUS = 70
    }
}
