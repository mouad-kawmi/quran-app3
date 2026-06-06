package com.mouad.quran.quran_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object NativeAdhanScheduler {
    const val CHANNEL = "quran_app/native_adhan"
    const val ACTION_PLAY_ADHAN = "com.mouad.quran.quran_app.PLAY_ADHAN"
    const val ACTION_STOP_ADHAN = "com.mouad.quran.quran_app.STOP_ADHAN"
    const val EXTRA_ID = "extra_id"
    const val EXTRA_PRAYER_NAME = "extra_prayer_name"
    const val EXTRA_RAW_RESOURCE_NAME = "extra_raw_resource_name"
    const val EXTRA_FILE_PATH = "extra_file_path"
    const val EXTRA_TRIGGER_AT = "extra_trigger_at"
    const val EXTRA_VOLUME = "extra_volume"
    private const val PREFS_NAME = "native_adhan_alarms"
    private const val IDS_KEY = "alarm_ids"
    private const val PRAYER_PREFIX = "prayer_"
    private const val RAW_PREFIX = "raw_"
    private const val FILE_PREFIX = "file_"
    private const val TRIGGER_PREFIX = "trigger_"
    private const val VOLUME_PREFIX = "volume_"
    private const val DEFAULT_VOLUME = 0.85

    fun schedule(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        prayerName: String,
        rawResourceName: String,
        filePath: String,
        volume: Double,
    ) {
        if (triggerAtMillis <= System.currentTimeMillis()) return
        saveAlarm(context, id, triggerAtMillis, prayerName, rawResourceName, filePath, volume)
        scheduleAlarm(context, id, triggerAtMillis, prayerName, rawResourceName, filePath, volume)
    }

    fun cancel(context: Context, id: Int) {
        removeAlarm(context, id)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent(context, id))
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

            scheduleAlarm(
                context,
                id,
                triggerAtMillis,
                prayerName,
                rawResourceName.orEmpty(),
                filePath.orEmpty(),
                volume,
            )
        }
    }

    private fun scheduleAlarm(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        prayerName: String,
        rawResourceName: String,
        filePath: String,
        volume: Double,
    ) {
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

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        }
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
}
