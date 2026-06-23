package com.mouad.quran.quran_app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object NativeAdhanScheduler {
    const val CHANNEL = "quran_app/native_adhan"
    const val ACTION_PLAY_ADHAN = "com.mouad.quran.quran_app.PLAY_ADHAN"
    const val ACTION_SHOW_NOTIFICATION = "com.mouad.quran.quran_app.SHOW_NOTIFICATION"
    const val ACTION_STOP_ADHAN = "com.mouad.quran.quran_app.STOP_ADHAN"
    const val EXTRA_ID = "extra_id"
    const val EXTRA_PRAYER_NAME = "extra_prayer_name"
    const val EXTRA_RAW_RESOURCE_NAME = "extra_raw_resource_name"
    const val EXTRA_FILE_PATH = "extra_file_path"
    const val EXTRA_TRIGGER_AT = "extra_trigger_at"
    const val EXTRA_VOLUME = "extra_volume"
    const val EXTRA_TITLE = "extra_title"
    const val EXTRA_BODY = "extra_body"
    const val EXTRA_TIMEOUT_AFTER = "extra_timeout_after"
    private const val PREFS_NAME = "native_adhan_alarms"
    private const val IDS_KEY = "alarm_ids"
    private const val NOTIFICATION_IDS_KEY = "notification_alarm_ids"
    private const val PRAYER_PREFIX = "prayer_"
    private const val RAW_PREFIX = "raw_"
    private const val FILE_PREFIX = "file_"
    private const val TRIGGER_PREFIX = "trigger_"
    private const val VOLUME_PREFIX = "volume_"
    private const val NOTIFICATION_TITLE_PREFIX = "notification_title_"
    private const val NOTIFICATION_BODY_PREFIX = "notification_body_"
    private const val NOTIFICATION_TRIGGER_PREFIX = "notification_trigger_"
    private const val NOTIFICATION_TIMEOUT_PREFIX = "notification_timeout_"
    private const val NOTIFICATION_CHANNEL_ID = "prayer_native_exact_alerts_v1"
    private const val NOTIFICATION_CHANNEL_NAME = "Prayer exact alerts"
    private const val DEFAULT_VOLUME = 0.85
    private const val DEFAULT_NOTIFICATION_TIMEOUT_MS = 5L * 60L * 1000L

    fun schedule(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        prayerName: String,
        rawResourceName: String,
        filePath: String,
        volume: Double,
    ): Boolean {
        if (triggerAtMillis <= System.currentTimeMillis()) return false
        val scheduled = scheduleAlarm(
            context,
            id,
            triggerAtMillis,
            prayerName,
            rawResourceName,
            filePath,
            volume,
        )
        if (!scheduled) return false
        saveAlarm(context, id, triggerAtMillis, prayerName, rawResourceName, filePath, volume)
        return true
    }

    fun scheduleNotification(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        title: String,
        body: String,
        timeoutAfterMillis: Long,
    ): Boolean {
        if (triggerAtMillis <= System.currentTimeMillis()) return false
        val scheduled = scheduleNotificationAlarm(
            context,
            id,
            triggerAtMillis,
            title,
            body,
            timeoutAfterMillis,
        )
        if (!scheduled) return false
        saveNotificationAlarm(
            context,
            id,
            triggerAtMillis,
            title,
            body,
            timeoutAfterMillis,
        )
        return true
    }

    fun cancel(context: Context, id: Int) {
        removeAlarm(context, id)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent(context, id))
    }

    fun cancelNotification(context: Context, id: Int) {
        removeNotificationAlarm(context, id)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(notificationPendingIntent(context, id))
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(id)
    }

    fun rescheduleStored(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(IDS_KEY, emptySet()).orEmpty().toList()
        val now = System.currentTimeMillis()

        for (idString in ids) {
            val id = idString.toIntOrNull() ?: continue
            val triggerAtMillis = prefs.getLong("$TRIGGER_PREFIX$id", 0L)
            val rawResourceName = prefs.getString("$RAW_PREFIX$id", null)
            val filePath = prefs.getString("$FILE_PREFIX$id", null)
            val prayerName = prefs.getString("$PRAYER_PREFIX$id", "").orEmpty()
            val volume = prefs.getFloat("$VOLUME_PREFIX$id", DEFAULT_VOLUME.toFloat()).toDouble()

            if (triggerAtMillis <= now ||
                (rawResourceName.isNullOrBlank() && filePath.isNullOrBlank())
            ) {
                removeAlarm(context, id)
                continue
            }

            val scheduled = scheduleAlarm(
                context,
                id,
                triggerAtMillis,
                prayerName,
                rawResourceName.orEmpty(),
                filePath.orEmpty(),
                volume,
            )
            if (!scheduled) {
                removeAlarm(context, id)
            }
        }

        val notificationIds = prefs.getStringSet(NOTIFICATION_IDS_KEY, emptySet()).orEmpty().toList()
        for (idString in notificationIds) {
            val id = idString.toIntOrNull() ?: continue
            val triggerAtMillis = prefs.getLong("$NOTIFICATION_TRIGGER_PREFIX$id", 0L)
            val title = prefs.getString("$NOTIFICATION_TITLE_PREFIX$id", "").orEmpty()
            val body = prefs.getString("$NOTIFICATION_BODY_PREFIX$id", "").orEmpty()
            val timeoutAfterMillis = prefs.getLong(
                "$NOTIFICATION_TIMEOUT_PREFIX$id",
                DEFAULT_NOTIFICATION_TIMEOUT_MS,
            )

            if (triggerAtMillis <= now || title.isBlank()) {
                removeNotificationAlarm(context, id)
                continue
            }

            val scheduled = scheduleNotificationAlarm(
                context,
                id,
                triggerAtMillis,
                title,
                body,
                timeoutAfterMillis,
            )
            if (!scheduled) {
                removeNotificationAlarm(context, id)
            }
        }
    }

    fun pendingScheduledCount(context: Context): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val adhanCount = prefs.getStringSet(IDS_KEY, emptySet())
            .orEmpty()
            .count { idString ->
                val id = idString.toIntOrNull() ?: return@count false
                prefs.getLong("$TRIGGER_PREFIX$id", 0L) > now
            }
        val notificationCount = prefs.getStringSet(NOTIFICATION_IDS_KEY, emptySet())
            .orEmpty()
            .count { idString ->
                val id = idString.toIntOrNull() ?: return@count false
                prefs.getLong("$NOTIFICATION_TRIGGER_PREFIX$id", 0L) > now
            }

        return adhanCount + notificationCount
    }

    fun showScheduledNotification(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, -1)
        if (id < 0) return

        val title = intent.getStringExtra(EXTRA_TITLE).orEmpty()
        if (title.isBlank()) return

        val body = intent.getStringExtra(EXTRA_BODY).orEmpty()
        val triggerAtMillis = intent.getLongExtra(EXTRA_TRIGGER_AT, System.currentTimeMillis())
        val timeoutAfterMillis = intent.getLongExtra(
            EXTRA_TIMEOUT_AFTER,
            DEFAULT_NOTIFICATION_TIMEOUT_MS,
        )

        showNotification(
            context,
            id,
            title,
            body,
            triggerAtMillis,
            timeoutAfterMillis,
        )
        removeNotificationAlarm(context, id)
    }

    private fun scheduleAlarm(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        prayerName: String,
        rawResourceName: String,
        filePath: String,
        volume: Double,
    ): Boolean {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(
            context = context,
            id = id,
            prayerName = prayerName,
            rawResourceName = rawResourceName,
            filePath = filePath,
            triggerAtMillis = triggerAtMillis,
            volume = volume,
        )

        return scheduleExactWakeup(alarmManager, triggerAtMillis, pendingIntent) ||
            scheduleAlarmClock(context, alarmManager, triggerAtMillis, id, pendingIntent)
    }

    private fun scheduleNotificationAlarm(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        title: String,
        body: String,
        timeoutAfterMillis: Long,
    ): Boolean {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = notificationPendingIntent(
            context = context,
            id = id,
            title = title,
            body = body,
            triggerAtMillis = triggerAtMillis,
            timeoutAfterMillis = timeoutAfterMillis,
        )

        return scheduleExactWakeup(alarmManager, triggerAtMillis, pendingIntent) ||
            scheduleAlarmClock(context, alarmManager, triggerAtMillis, id, pendingIntent)
    }

    private fun scheduleExactWakeup(
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        operation: PendingIntent,
    ): Boolean {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !alarmManager.canScheduleExactAlarms()
            ) {
                return false
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    operation,
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, operation)
            }
            return true
        } catch (_: SecurityException) {
            return false
        } catch (_: RuntimeException) {
            return false
        }
    }

    private fun scheduleAlarmClock(
        context: Context,
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        id: Int,
        operation: PendingIntent,
    ): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                val showIntent = appLaunchPendingIntent(context, id) ?: operation
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent),
                    operation,
                )
                return true
            } catch (_: RuntimeException) {
                return false
            }
        }

        return false
    }

    private fun saveAlarm(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        prayerName: String,
        rawResourceName: String,
        filePath: String,
        volume: Double,
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(IDS_KEY, emptySet()).orEmpty().toMutableSet()
        ids.add(id.toString())

        prefs.edit()
            .putStringSet(IDS_KEY, ids)
            .putString("$PRAYER_PREFIX$id", prayerName)
            .putString("$RAW_PREFIX$id", rawResourceName)
            .putString("$FILE_PREFIX$id", filePath)
            .putLong("$TRIGGER_PREFIX$id", triggerAtMillis)
            .putFloat("$VOLUME_PREFIX$id", volume.coerceIn(0.1, 1.0).toFloat())
            .apply()
    }

    private fun saveNotificationAlarm(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        title: String,
        body: String,
        timeoutAfterMillis: Long,
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(NOTIFICATION_IDS_KEY, emptySet()).orEmpty().toMutableSet()
        ids.add(id.toString())

        prefs.edit()
            .putStringSet(NOTIFICATION_IDS_KEY, ids)
            .putString("$NOTIFICATION_TITLE_PREFIX$id", title)
            .putString("$NOTIFICATION_BODY_PREFIX$id", body)
            .putLong("$NOTIFICATION_TRIGGER_PREFIX$id", triggerAtMillis)
            .putLong(
                "$NOTIFICATION_TIMEOUT_PREFIX$id",
                timeoutAfterMillis.coerceAtLeast(0L),
            )
            .apply()
    }

    private fun removeAlarm(context: Context, id: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(IDS_KEY, emptySet()).orEmpty().toMutableSet()
        ids.remove(id.toString())

        prefs.edit()
            .putStringSet(IDS_KEY, ids)
            .remove("$PRAYER_PREFIX$id")
            .remove("$RAW_PREFIX$id")
            .remove("$FILE_PREFIX$id")
            .remove("$TRIGGER_PREFIX$id")
            .remove("$VOLUME_PREFIX$id")
            .apply()
    }

    private fun removeNotificationAlarm(context: Context, id: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(NOTIFICATION_IDS_KEY, emptySet()).orEmpty().toMutableSet()
        ids.remove(id.toString())

        prefs.edit()
            .putStringSet(NOTIFICATION_IDS_KEY, ids)
            .remove("$NOTIFICATION_TITLE_PREFIX$id")
            .remove("$NOTIFICATION_BODY_PREFIX$id")
            .remove("$NOTIFICATION_TRIGGER_PREFIX$id")
            .remove("$NOTIFICATION_TIMEOUT_PREFIX$id")
            .apply()
    }

    private fun showNotification(
        context: Context,
        id: Int,
        title: String,
        body: String,
        triggerAtMillis: Long,
        timeoutAfterMillis: Long,
    ) {
        createNotificationChannel(context)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        builder
            .setSmallIcon(R.drawable.ic_notif_prayer)
            .setContentTitle(title)
            .setContentText(body)
            .setWhen(triggerAtMillis)
            .setShowWhen(true)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setPriority(Notification.PRIORITY_HIGH)

        appLaunchPendingIntent(context, id)?.let { builder.setContentIntent(it) }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && timeoutAfterMillis > 0L) {
            builder.setTimeoutAfter(timeoutAfterMillis)
        }

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try {
            notificationManager.notify(id, builder.build())
        } catch (_: SecurityException) {
            // Notification permission can be denied on Android 13+.
        }
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            NOTIFICATION_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Exact prayer reminders and prayer-time alerts."
        }

        val notificationManager = context.getSystemService(NotificationManager::class.java)
        notificationManager.createNotificationChannel(channel)
    }

    private fun pendingIntent(
        context: Context,
        id: Int,
        prayerName: String = "",
        rawResourceName: String = "",
        filePath: String = "",
        triggerAtMillis: Long = 0L,
        volume: Double = DEFAULT_VOLUME,
    ): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = ACTION_PLAY_ADHAN
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_PRAYER_NAME, prayerName)
            putExtra(EXTRA_RAW_RESOURCE_NAME, rawResourceName)
            putExtra(EXTRA_FILE_PATH, filePath)
            putExtra(EXTRA_TRIGGER_AT, triggerAtMillis)
            putExtra(EXTRA_VOLUME, volume.coerceIn(0.1, 1.0))
        }

        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun notificationPendingIntent(
        context: Context,
        id: Int,
        title: String = "",
        body: String = "",
        triggerAtMillis: Long = 0L,
        timeoutAfterMillis: Long = DEFAULT_NOTIFICATION_TIMEOUT_MS,
    ): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = ACTION_SHOW_NOTIFICATION
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_TRIGGER_AT, triggerAtMillis)
            putExtra(EXTRA_TIMEOUT_AFTER, timeoutAfterMillis)
        }

        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun appLaunchPendingIntent(context: Context, requestCode: Int): PendingIntent? {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return null
        launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        return PendingIntent.getActivity(
            context,
            requestCode,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
