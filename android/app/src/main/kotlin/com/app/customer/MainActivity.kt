package com.app.customer

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val LIVE_ACTIVITY_CHANNEL = "com.accessible.customer/live_activity"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LIVE_ACTIVITY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startActivity" -> {
                    val bookingId = call.argument<String>("bookingId")
                    val uniqueId = call.argument<String>("uniqueId")
                    val statusText = call.argument<String>("statusText")
                    val progress = call.argument<Int>("progress")
                    val destinationPoint = call.argument<Int>("destinationPoint")

                    if (bookingId == null ||
                        uniqueId == null ||
                        statusText == null ||
                        progress == null ||
                        destinationPoint == null
                    ) {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }

                    LiveNotificationManager.showNotification(
                        context = this,
                        bookingId = bookingId,
                        uniqueId = uniqueId,
                        statusText = statusText,
                        status = call.argument<Int>("status") ?: 0,
                        progress = progress,
                        destinationPoint = destinationPoint,
                        driverName = call.argument<String>("driverName") ?: "",
                        rating = call.argument<String>("rating") ?: "",
                        vehicleName = call.argument<String>("vehicleName") ?: "",
                        plateNo = call.argument<String>("plateNo") ?: "",
                        pickupAddress = call.argument<String>("pickupAddress") ?: "",
                        destinationAddress = call.argument<String>("destinationAddress") ?: "",
                        pickupTime = call.argument<String>("pickupTime") ?: "",
                        destinationTime = call.argument<String>("destinationTime") ?: "",
                        photoPath = call.argument<String>("photoPath") ?: "",
                    )
                    result.success(true)
                }

                "stopActivity" -> {
                    val bookingId = call.argument<String>("bookingId")
                    if (bookingId == null) {
                        result.error("INVALID_ARGS", "Missing bookingId", null)
                        return@setMethodCallHandler
                    }

                    LiveNotificationManager.dismissNotification(this, bookingId)
                    result.success(true)
                }

                "stopAllActivities" -> {
                    LiveNotificationManager.dismissAllNotifications(this)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
