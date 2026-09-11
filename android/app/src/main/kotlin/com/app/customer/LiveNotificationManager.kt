package com.app.customer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.io.File
import kotlin.math.roundToInt

object LiveNotificationManager {
    // A channel's importance can only be lowered by the user, never raised by
    // the app once created — the original channel shipped as IMPORTANCE_LOW, so
    // ranking it at the top requires a NEW channel id.
    private const val CHANNEL_ID = "live_booking_channel_v2"
    private const val LEGACY_CHANNEL_ID = "live_notification_channel_id"
    private val activeBookingIds = linkedSetOf<String>()

    // Last-seen rich (ride-static) fields per booking. A backend live push only
    // carries progress/status with blank driver/vehicle/address fields; without
    // this cache such a push would rebuild the notification and wipe the rich
    // card. We fall back to the cached value whenever an incoming field is blank.
    private data class RichData(
        val driverName: String,
        val rating: String,
        val vehicleName: String,
        val plateNo: String,
        val pickupAddress: String,
        val destinationAddress: String,
        val pickupTime: String,
        val destinationTime: String,
        val photoPath: String,
    )

    private val richCache = mutableMapOf<String, RichData>()

    private fun merge(new: String, old: String?): String =
        new.ifBlank { old ?: "" }

    /// On Android 8+ a notification posted to a channel that was never
    /// registered is silently dropped, so create the live channel before
    /// posting. HIGH importance keeps the ride pinned near the top of the
    /// shade; sound and vibration stay off so frequent status updates are
    /// still quiet (setOnlyAlertOnce also stops it re-alerting on updates).
    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as? NotificationManager ?: return
        // Drop the old low-importance channel so it doesn't linger in settings.
        manager.deleteNotificationChannel(LEGACY_CHANNEL_ID)
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Live booking status",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Ongoing updates for your active booking"
            setShowBadge(false)
            enableVibration(false)
            enableLights(false)
            setSound(null, null)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    fun showNotification(
        context: Context,
        bookingId: String,
        uniqueId: String,
        statusText: String,
        status: Int,
        progress: Int,
        destinationPoint: Int,
        driverName: String,
        rating: String,
        vehicleName: String,
        plateNo: String,
        pickupAddress: String,
        destinationAddress: String,
        pickupTime: String,
        destinationTime: String,
        photoPath: String,
    ) {
        ensureChannel(context)

        // Merge blank incoming fields with the last-seen values (see richCache).
        val prev = richCache[bookingId]
        val d = RichData(
            driverName = merge(driverName, prev?.driverName),
            rating = merge(rating, prev?.rating),
            vehicleName = merge(vehicleName, prev?.vehicleName),
            plateNo = merge(plateNo, prev?.plateNo),
            pickupAddress = merge(pickupAddress, prev?.pickupAddress),
            destinationAddress = merge(destinationAddress, prev?.destinationAddress),
            // Not merged, unlike the fields above: these two are live ETAs the
            // caller clears on purpose. Once the ride starts Dart sends an empty
            // pickupTime because that ETA is spent, and merging resurrected the
            // stale value from the cache for the rest of the trip.
            pickupTime = pickupTime,
            destinationTime = destinationTime,
            photoPath = merge(photoPath, prev?.photoPath),
        )
        richCache[bookingId] = d

        val notificationId = bookingId.hashCode()
        val remoteViews = RemoteViews(context.packageName, R.layout.layout_live_notification)
        // DecoratedCustomViewStyle decorates whatever custom view each state has;
        // without a collapsed view the shrunken notification renders empty.
        val collapsedViews =
            RemoteViews(context.packageName, R.layout.layout_live_notification_collapsed)

        val appName = context.applicationInfo.loadLabel(context.packageManager).toString()

        // Status badge (overlaid on the map) — short label for narrow space.
        remoteViews.setTextViewText(R.id.tv_live_status, shortStatus(status))
        remoteViews.setInt(R.id.tv_live_status, "setBackgroundResource", badgeRes(status))

        // Identity. Before a driver is engaged every one of these fields is
        // blank, and the row then rendered as a bare blue disc (createAvatarBitmap's
        // no-photo/no-initials fallback) above an empty line. Fall back to the
        // status line so the searching state reads as something.
        val hasDriver = d.driverName.isNotBlank() ||
            d.vehicleName.isNotBlank() ||
            d.plateNo.isNotBlank()

        if (hasDriver) {
            remoteViews.setViewVisibility(R.id.iv_live_avatar, View.VISIBLE)
            remoteViews.setImageViewBitmap(
                R.id.iv_live_avatar,
                createAvatarBitmap(context, d.photoPath, d.driverName, sizeDp = 36f),
            )
            setTextOrHide(remoteViews, R.id.tv_live_driver_name, d.driverName)
        } else {
            remoteViews.setViewVisibility(R.id.iv_live_avatar, View.GONE)
            setTextOrHide(remoteViews, R.id.tv_live_driver_name, statusText)
        }
        setTextOrHide(remoteViews, R.id.tv_live_vehicle, d.vehicleName)
        setTextOrHide(remoteViews, R.id.tv_live_plate, d.plateNo)

        // Trip rows
        toggleRow(
            remoteViews, R.id.row_live_pickup, R.id.tv_live_pickup, R.id.tv_live_pickup_time,
            d.pickupAddress, d.pickupTime,
        )
        toggleRow(
            remoteViews, R.id.row_live_drop, R.id.tv_live_drop, R.id.tv_live_drop_time,
            d.destinationAddress, d.destinationTime,
        )
        // The dotted connector only makes sense when both rows are visible.
        remoteViews.setViewVisibility(
            R.id.iv_live_connector,
            if (d.pickupAddress.isNotBlank() && d.destinationAddress.isNotBlank()) {
                View.VISIBLE
            } else {
                View.GONE
            },
        )
        // The divider separates identity from the trip rows — with no trip rows
        // it was left hanging under the identity as a stray line.
        remoteViews.setViewVisibility(
            R.id.divider_live,
            if (d.pickupAddress.isNotBlank() || d.destinationAddress.isNotBlank()) {
                View.VISIBLE
            } else {
                View.GONE
            },
        )

        // Map illustration (rounded, center-cropped to match the iOS widget).
        remoteViews.setImageViewBitmap(
            R.id.iv_live_map,
            roundedMapBitmap(context, widthDp = 92f, heightDp = 84f),
        )

        // Collapsed state — same identity, compact.
        if (hasDriver) {
            collapsedViews.setViewVisibility(R.id.iv_live_avatar_c, View.VISIBLE)
            collapsedViews.setImageViewBitmap(
                R.id.iv_live_avatar_c,
                createAvatarBitmap(context, d.photoPath, d.driverName, sizeDp = 32f),
            )
        } else {
            collapsedViews.setViewVisibility(R.id.iv_live_avatar_c, View.GONE)
        }
        setTextOrHide(collapsedViews, R.id.tv_live_driver_name_c, d.driverName.ifBlank { appName })
        setTextOrHide(collapsedViews, R.id.tv_live_vehicle_c, d.vehicleName.ifBlank { statusText })
        collapsedViews.setTextViewText(R.id.tv_live_status_c, shortStatus(status))
        collapsedViews.setInt(R.id.tv_live_status_c, "setBackgroundResource", badgeRes(status))

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_notification)
            .setContentTitle(if (d.driverName.isBlank()) appName else d.driverName)
            .setContentText("#$uniqueId: $statusText")
            .setTicker("#$uniqueId: $statusText")
            .setOngoing(true)
            // Alert once, then update quietly — without this a HIGH-importance
            // channel would heads-up on every status change.
            .setOnlyAlertOnce(true)
            // NOTE: no setSilent(true) — it files the notification under the
            // shade's "silent" group, which is what buried it at the bottom.
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(false)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(remoteViews)
            .setContentIntent(createContentIntent(context))

        NotificationManagerCompat.from(context).notify(notificationId, builder.build())
        activeBookingIds += bookingId
    }

    private fun setTextOrHide(remoteViews: RemoteViews, viewId: Int, value: String) {
        if (value.isBlank()) {
            remoteViews.setViewVisibility(viewId, View.GONE)
        } else {
            remoteViews.setViewVisibility(viewId, View.VISIBLE)
            remoteViews.setTextViewText(viewId, value)
        }
    }

    private fun toggleRow(
        remoteViews: RemoteViews,
        rowId: Int,
        textId: Int,
        timeId: Int,
        text: String,
        time: String,
    ) {
        if (text.isBlank()) {
            remoteViews.setViewVisibility(rowId, View.GONE)
            return
        }
        remoteViews.setViewVisibility(rowId, View.VISIBLE)
        remoteViews.setTextViewText(textId, text)
        if (time.isBlank()) {
            remoteViews.setViewVisibility(timeId, View.GONE)
        } else {
            remoteViews.setViewVisibility(timeId, View.VISIBLE)
            remoteViews.setTextViewText(timeId, time)
        }
    }

    /// Short status label for the narrow map badge (mirrors the iOS widget).
    private fun shortStatus(status: Int): String = when (status) {
        1, 10, 16 -> "Finding"
        14, 141 -> "Preparing"
        20, 21, 24, 142 -> "Accepted"
        30 -> "En route"
        40 -> "At pickup"
        41 -> "Picked up"
        50 -> "On trip"
        65 -> "Arriving"
        70 -> "Arrived"
        80 -> "Done"
        90 -> "Cancelled"
        else -> "Ongoing"
    }

    private fun badgeRes(status: Int): Int = when (status) {
        90 -> R.drawable.bg_badge_red
        70, 80 -> R.drawable.bg_badge_green
        14, 141, 24, 142 -> R.drawable.bg_badge_orange
        else -> R.drawable.bg_badge_blue
    }

    fun dismissNotification(context: Context, bookingId: String) {
        NotificationManagerCompat.from(context).cancel(bookingId.hashCode())
        activeBookingIds -= bookingId
        richCache -= bookingId
    }

    fun dismissAllNotifications(context: Context) {
        val notificationManager = NotificationManagerCompat.from(context)
        activeBookingIds.forEach { bookingId ->
            notificationManager.cancel(bookingId.hashCode())
        }
        activeBookingIds.clear()
        richCache.clear()
    }

    private fun createContentIntent(context: Context): PendingIntent? {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            ?: return null

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        return PendingIntent.getActivity(context, 0, launchIntent, flags)
    }

    /// Circular driver avatar. Uses the downloaded photo file when readable,
    /// otherwise a coloured circle with the driver's initials (or a neutral
    /// disc when the name is unknown).
    private fun createAvatarBitmap(
        context: Context,
        photoPath: String,
        name: String,
        sizeDp: Float,
    ): Bitmap {
        val size = context.dp(sizeDp)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val radius = size / 2f

        val source = if (photoPath.isNotBlank() && File(photoPath).exists()) {
            try {
                BitmapFactory.decodeFile(photoPath)
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }

        if (source != null) {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            canvas.drawCircle(radius, radius, radius, paint)
            paint.xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.SRC_IN)
            // Center-crop the source into a square.
            val dim = minOf(source.width, source.height)
            val srcRect = Rect(
                (source.width - dim) / 2,
                (source.height - dim) / 2,
                (source.width - dim) / 2 + dim,
                (source.height - dim) / 2 + dim,
            )
            canvas.drawBitmap(source, srcRect, RectF(0f, 0f, size.toFloat(), size.toFloat()), paint)
        } else {
            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFF4C72C9.toInt()
                style = Paint.Style.FILL
            }
            canvas.drawCircle(radius, radius, radius, bgPaint)

            val initials = name.trim().split(" ")
                .filter { it.isNotBlank() }
                .take(2)
                .mapNotNull { it.firstOrNull()?.uppercaseChar() }
                .joinToString("")
            if (initials.isNotEmpty()) {
                val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    textSize = size * 0.4f
                    textAlign = Paint.Align.CENTER
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                }
                val yOffset = (textPaint.descent() + textPaint.ascent()) / 2f
                canvas.drawText(initials, radius, radius - yOffset, textPaint)
            }
        }
        return output
    }

    private var cachedMap: Bitmap? = null

    /// The map illustration, center-cropped into the panel and rounded to match
    /// the iOS widget. Cached — the image is static so it's drawn only once.
    private fun roundedMapBitmap(context: Context, widthDp: Float, heightDp: Float): Bitmap {
        cachedMap?.let { return it }

        val w = context.dp(widthDp)
        val h = context.dp(heightDp)
        val output = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val radius = context.dp(10f).toFloat()

        // Rounded mask, then draw the source through it (SRC_IN).
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), radius, radius, paint)
        paint.xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.SRC_IN)

        val source = decodeSampled(context, R.drawable.live_map, w, h)
        // Center-crop the source to fill w x h.
        val scale = maxOf(w.toFloat() / source.width, h.toFloat() / source.height)
        val sw = source.width * scale
        val sh = source.height * scale
        val left = (w - sw) / 2f
        val top = (h - sh) / 2f
        canvas.drawBitmap(source, null, RectF(left, top, left + sw, top + sh), paint)

        cachedMap = output
        return output
    }

    private fun decodeSampled(context: Context, resId: Int, reqW: Int, reqH: Int): Bitmap {
        val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeResource(context.resources, resId, opts)
        var sample = 1
        while (opts.outWidth / (sample * 2) >= reqW && opts.outHeight / (sample * 2) >= reqH) {
            sample *= 2
        }
        val decodeOpts = BitmapFactory.Options().apply { inSampleSize = sample }
        return BitmapFactory.decodeResource(context.resources, resId, decodeOpts)
    }

    private fun Context.dp(value: Float): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        value,
        resources.displayMetrics,
    ).roundToInt()
}
