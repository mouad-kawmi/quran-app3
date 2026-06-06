package com.mouad.quran.quran_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import kotlin.math.abs
import kotlin.math.roundToInt

class PrayerTimesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH_WIDGET) {
            updateAllWidgets(context)
        }
    }

    override fun onDisabled(context: Context) {
        cancelScheduledRefresh(context)
        super.onDisabled(context)
    }

    companion object {
        const val CHANNEL = "quran_app/prayer_widget"

        private const val PREFS_NAME = "prayer_times_widget"
        private const val KEY_CITY_NAME = "city_name"
        private const val KEY_HIJRI_DATE = "hijri_date"
        private const val KEY_NEXT_PRAYER_NAME = "next_prayer_name"
        private const val KEY_NEXT_PRAYER_MILLIS = "next_prayer_millis"
        private const val KEY_PREVIOUS_PRAYER_NAME = "previous_prayer_name"
        private const val KEY_PREVIOUS_PRAYER_MILLIS = "previous_prayer_millis"
        private const val KEY_PRAYER_COUNT = "prayer_count"
        private const val KEY_TIMELINE_PRAYER_COUNT = "timeline_prayer_count"
        private const val ADHAN_ELAPSED_WINDOW_MILLIS = 30L * 60L * 1000L
        private const val REFRESH_DELAY_BUFFER_MILLIS = 1000L
        private const val REFRESH_REQUEST_CODE = 5173
        private const val MAX_WIDGET_PRAYERS = 5
        private const val MAX_TIMELINE_PRAYERS = 10
        private const val ACTION_REFRESH_WIDGET =
            "com.mouad.quran.quran_app.REFRESH_PRAYER_WIDGET"
        private val primaryColor    = Color.rgb(0, 107, 85)       // #006B55 emerald
        private val goldColor       = Color.rgb(194, 162, 74)     // #C2A24A gold
        private val primaryTextColor= Color.rgb(27, 28, 32)       // #1B1C20 dark text
        private val mutedTextColor  = Color.rgb(111, 118, 114)    // #6F7672 gray
        private val activeChipTextColor = Color.WHITE             // white

        private data class PrayerEntry(val name: String, val millis: Long)

        private data class WidgetSchedule(
            val nextName: String,
            val nextMillis: Long,
            val previousName: String,
            val previousMillis: Long,
        )

        fun saveDataAndUpdate(context: Context, data: Map<*, *>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val prayers = data["prayers"] as? List<*> ?: emptyList<Any>()
            val timelinePrayers = data["timelinePrayers"] as? List<*> ?: prayers

            prefs.edit().apply {
                putString(KEY_CITY_NAME, data["cityName"] as? String)
                putString(KEY_HIJRI_DATE, data["hijriDate"] as? String)
                putString(KEY_NEXT_PRAYER_NAME, data["nextPrayerName"] as? String)
                putLong(KEY_NEXT_PRAYER_MILLIS, (data["nextPrayerMillis"] as? Number)?.toLong() ?: 0L)
                putString(KEY_PREVIOUS_PRAYER_NAME, data["previousPrayerName"] as? String)
                putLong(
                    KEY_PREVIOUS_PRAYER_MILLIS,
                    (data["previousPrayerMillis"] as? Number)?.toLong() ?: 0L,
                )
                putInt(KEY_PRAYER_COUNT, prayers.size.coerceAtMost(MAX_WIDGET_PRAYERS))
                putInt(
                    KEY_TIMELINE_PRAYER_COUNT,
                    timelinePrayers.size.coerceAtMost(MAX_TIMELINE_PRAYERS),
                )

                prayers.take(MAX_WIDGET_PRAYERS).forEachIndexed { index, item ->
                    val prayer = item as? Map<*, *> ?: return@forEachIndexed
                    putString(prayerNameKey(index), prayer["name"] as? String)
                    putString(prayerTimeKey(index), prayer["time"] as? String)
                    putLong(prayerMillisKey(index), (prayer["millis"] as? Number)?.toLong() ?: 0L)
                }

                timelinePrayers.take(MAX_TIMELINE_PRAYERS).forEachIndexed { index, item ->
                    val prayer = item as? Map<*, *> ?: return@forEachIndexed
                    putString(timelinePrayerNameKey(index), prayer["name"] as? String)
                    putLong(
                        timelinePrayerMillisKey(index),
                        (prayer["millis"] as? Number)?.toLong() ?: 0L,
                    )
                }
            }.apply()

            updateAllWidgets(context)
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)
            val now = System.currentTimeMillis()
            val nextMillis = prefs.getLong(KEY_NEXT_PRAYER_MILLIS, 0L)
            val previousMillis = prefs.getLong(KEY_PREVIOUS_PRAYER_MILLIS, 0L)
            val nextName = prefs.getString(KEY_NEXT_PRAYER_NAME, null) ?: "مواقيت الصلاة"
            val previousName = prefs.getString(KEY_PREVIOUS_PRAYER_NAME, null) ?: nextName
            val schedule = resolveSchedule(
                prefs = prefs,
                now = now,
                fallbackNextName = nextName,
                fallbackNextMillis = nextMillis,
                fallbackPreviousName = previousName,
                fallbackPreviousMillis = previousMillis,
            )

            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
            views.setTextViewText(
                R.id.widget_city,
                prefs.getString(KEY_CITY_NAME, null) ?: "نور القرآن",
            )
            views.setTextViewText(
                R.id.widget_hijri,
                prefs.getString(KEY_HIJRI_DATE, null) ?: "افتح التطبيق لتحديث المواقيت",
            )

            configureCountdown(
                views,
                now,
                schedule.nextMillis,
                schedule.previousMillis,
                schedule.nextName,
                schedule.previousName,
            )
            configurePrayerStrip(views, prefs, now, schedule.nextMillis, schedule.previousMillis)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            scheduleNextRefresh(context, now, schedule)
        }

        private fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PrayerTimesWidgetProvider::class.java),
            )
            if (ids.isEmpty()) {
                cancelScheduledRefresh(context)
                return
            }
            ids.forEach { updateWidget(context, manager, it) }
        }

        private fun resolveSchedule(
            prefs: SharedPreferences,
            now: Long,
            fallbackNextName: String,
            fallbackNextMillis: Long,
            fallbackPreviousName: String,
            fallbackPreviousMillis: Long,
        ): WidgetSchedule {
            val entries = prayerTimelineEntries(prefs).ifEmpty {
                displayPrayerEntries(prefs)
            }.toMutableList()

            if (fallbackPreviousMillis > 0L) {
                entries.add(PrayerEntry(fallbackPreviousName, fallbackPreviousMillis))
            }
            if (fallbackNextMillis > 0L) {
                entries.add(PrayerEntry(fallbackNextName, fallbackNextMillis))
            }

            val sortedEntries = entries
                .filter { it.millis > 0L }
                .distinctBy { it.millis }
                .sortedBy { it.millis }
            val previous = sortedEntries.lastOrNull { it.millis <= now }
            val next = sortedEntries.firstOrNull { it.millis > now }

            return WidgetSchedule(
                nextName = next?.name ?: fallbackNextName,
                nextMillis = next?.millis ?: fallbackNextMillis,
                previousName = previous?.name ?: fallbackPreviousName,
                previousMillis = previous?.millis ?: fallbackPreviousMillis,
            )
        }

        private fun prayerTimelineEntries(prefs: SharedPreferences): List<PrayerEntry> {
            val count = prefs.getInt(KEY_TIMELINE_PRAYER_COUNT, 0)
                .coerceIn(0, MAX_TIMELINE_PRAYERS)
            return (0 until count).mapNotNull { index ->
                val millis = prefs.getLong(timelinePrayerMillisKey(index), 0L)
                if (millis <= 0L) {
                    null
                } else {
                    PrayerEntry(
                        prefs.getString(
                            timelinePrayerNameKey(index),
                            defaultPrayerName(index % MAX_WIDGET_PRAYERS),
                        ) ?: defaultPrayerName(index % MAX_WIDGET_PRAYERS),
                        millis,
                    )
                }
            }
        }

        private fun displayPrayerEntries(prefs: SharedPreferences): List<PrayerEntry> {
            val count = prefs.getInt(KEY_PRAYER_COUNT, MAX_WIDGET_PRAYERS)
                .coerceIn(0, MAX_WIDGET_PRAYERS)
            return (0 until count).mapNotNull { index ->
                val millis = prefs.getLong(prayerMillisKey(index), 0L)
                if (millis <= 0L) {
                    null
                } else {
                    PrayerEntry(
                        prefs.getString(prayerNameKey(index), defaultPrayerName(index))
                            ?: defaultPrayerName(index),
                        millis,
                    )
                }
            }
        }

        private fun openAppIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                }
            return PendingIntent.getActivity(context, 0, intent, flags)
        }

        private fun configureCountdown(
            views: RemoteViews,
            now: Long,
            nextMillis: Long,
            previousMillis: Long,
            nextName: String,
            previousName: String,
        ) {
            val elapsedSincePrevious = now - previousMillis
            val isAfterRecentAdhan = previousMillis > 0L &&
                elapsedSincePrevious in 0L..ADHAN_ELAPSED_WINDOW_MILLIS

            when {
                isAfterRecentAdhan -> {
                    views.setTextViewText(R.id.widget_next_name, previousName)
                    views.setTextViewText(R.id.widget_countdown_prefix, "مضى")
                    views.setTextColor(R.id.widget_next_name, primaryColor)
                    views.setTextColor(R.id.widget_countdown_prefix, goldColor)
                    views.setTextColor(R.id.widget_countdown, goldColor)
                    startChronometer(
                        views = views,
                        base = SystemClock.elapsedRealtime() - elapsedSincePrevious,
                        countsDown = false,
                    )
                    views.setProgressBar(
                        R.id.widget_progress,
                        1000,
                        ((elapsedSincePrevious.toDouble() / ADHAN_ELAPSED_WINDOW_MILLIS) * 1000)
                            .roundToInt()
                            .coerceIn(0, 1000),
                        false,
                    )
                }

                nextMillis > now -> {
                    views.setTextViewText(R.id.widget_next_name, nextName)
                    views.setTextViewText(R.id.widget_countdown_prefix, "متبقي")
                    views.setTextColor(R.id.widget_next_name, primaryColor)
                    views.setTextColor(R.id.widget_countdown_prefix, goldColor)
                    views.setTextColor(R.id.widget_countdown, goldColor)
                    startChronometer(
                        views = views,
                        base = SystemClock.elapsedRealtime() + (nextMillis - now),
                        countsDown = true,
                    )
                    val total = nextMillis - previousMillis
                    val progress = if (total > 0L) {
                        (((now - previousMillis).toDouble() / total) * 1000)
                            .roundToInt()
                            .coerceIn(0, 1000)
                    } else {
                        0
                    }
                    views.setProgressBar(R.id.widget_progress, 1000, progress, false)
                }

                else -> {
                    views.setTextViewText(R.id.widget_next_name, "مواقيت الصلاة")
                    views.setTextViewText(R.id.widget_countdown_prefix, "")
                    views.setTextViewText(R.id.widget_countdown, "--:--")
                    views.setTextColor(R.id.widget_next_name, primaryColor)
                    views.setTextColor(R.id.widget_countdown, mutedTextColor)
                    views.setProgressBar(R.id.widget_progress, 1000, 0, false)
                }
            }
        }

        private fun startChronometer(
            views: RemoteViews,
            base: Long,
            countsDown: Boolean,
        ) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                views.setChronometerCountDown(R.id.widget_countdown, countsDown)
            }
            views.setChronometer(R.id.widget_countdown, base, "%s", true)
        }

        private fun configurePrayerStrip(
            views: RemoteViews,
            prefs: SharedPreferences,
            now: Long,
            nextMillis: Long,
            previousMillis: Long,
        ) {
            val elapsedSincePrevious = now - previousMillis
            val highlightedMillis = if (
                previousMillis > 0L &&
                elapsedSincePrevious in 0L..ADHAN_ELAPSED_WINDOW_MILLIS
            ) {
                previousMillis
            } else {
                nextMillis
            }

            val containerIds = intArrayOf(
                R.id.widget_prayer_0_container,
                R.id.widget_prayer_1_container,
                R.id.widget_prayer_2_container,
                R.id.widget_prayer_3_container,
                R.id.widget_prayer_4_container,
            )
            val nameIds = intArrayOf(
                R.id.widget_prayer_0_name,
                R.id.widget_prayer_1_name,
                R.id.widget_prayer_2_name,
                R.id.widget_prayer_3_name,
                R.id.widget_prayer_4_name,
            )
            val timeIds = intArrayOf(
                R.id.widget_prayer_0_time,
                R.id.widget_prayer_1_time,
                R.id.widget_prayer_2_time,
                R.id.widget_prayer_3_time,
                R.id.widget_prayer_4_time,
            )

            for (index in 0 until 5) {
                val name = prefs.getString(prayerNameKey(index), defaultPrayerName(index))
                val time = prefs.getString(prayerTimeKey(index), "--:--")
                val millis = prefs.getLong(prayerMillisKey(index), 0L)
                val isHighlighted = millis > 0L && abs(millis - highlightedMillis) < 60_000L

                views.setTextViewText(nameIds[index], name)
                views.setTextViewText(timeIds[index], time)
                views.setInt(
                    containerIds[index],
                    "setBackgroundResource",
                    if (isHighlighted) {
                        R.drawable.widget_prayer_chip_active
                    } else {
                        R.drawable.widget_prayer_chip_empty
                    },
                )
                views.setTextColor(
                    nameIds[index],
                    if (isHighlighted) activeChipTextColor else mutedTextColor,
                )
                views.setTextColor(
                    timeIds[index],
                    if (isHighlighted) activeChipTextColor else primaryTextColor,
                )
            }
        }

        private fun scheduleNextRefresh(
            context: Context,
            now: Long,
            schedule: WidgetSchedule,
        ) {
            val refreshAt = nextRefreshMillis(now, schedule)
            if (refreshAt == null) {
                cancelScheduledRefresh(context)
                return
            }

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = widgetRefreshPendingIntent(context)
            alarmManager.cancel(pendingIntent)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC, refreshAt, pendingIntent)
            } else {
                alarmManager.set(AlarmManager.RTC, refreshAt, pendingIntent)
            }
        }

        private fun nextRefreshMillis(now: Long, schedule: WidgetSchedule): Long? {
            val candidates = mutableListOf<Long>()
            if (schedule.previousMillis > 0L) {
                val elapsedWindowEnd = schedule.previousMillis +
                    ADHAN_ELAPSED_WINDOW_MILLIS +
                    REFRESH_DELAY_BUFFER_MILLIS
                if (elapsedWindowEnd > now) {
                    candidates.add(elapsedWindowEnd)
                }
            }
            if (schedule.nextMillis > now) {
                candidates.add(schedule.nextMillis + REFRESH_DELAY_BUFFER_MILLIS)
            }
            return candidates.minOrNull()
        }

        private fun cancelScheduledRefresh(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(widgetRefreshPendingIntent(context))
        }

        private fun widgetRefreshPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, PrayerTimesWidgetProvider::class.java).apply {
                action = ACTION_REFRESH_WIDGET
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                }
            return PendingIntent.getBroadcast(context, REFRESH_REQUEST_CODE, intent, flags)
        }

        private fun defaultPrayerName(index: Int): String {
            return when (index) {
                0 -> "الفجر"
                1 -> "الظهر"
                2 -> "العصر"
                3 -> "المغرب"
                4 -> "العشاء"
                else -> "الصلاة"
            }
        }

        private fun prayerNameKey(index: Int) = "prayer_${index}_name"
        private fun prayerTimeKey(index: Int) = "prayer_${index}_time"
        private fun prayerMillisKey(index: Int) = "prayer_${index}_millis"
        private fun timelinePrayerNameKey(index: Int) = "timeline_prayer_${index}_name"
        private fun timelinePrayerMillisKey(index: Int) = "timeline_prayer_${index}_millis"
    }
}
