package com.mouad.quran.quran_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
        private const val ADHAN_ELAPSED_WINDOW_MILLIS = 30L * 60L * 1000L
        private val primaryColor = Color.rgb(0, 107, 85)
        private val primaryTextColor = Color.rgb(27, 28, 32)
        private val mutedTextColor = Color.rgb(111, 118, 114)
        private val surfaceTextColor = Color.WHITE

        fun saveDataAndUpdate(context: Context, data: Map<*, *>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val prayers = data["prayers"] as? List<*> ?: emptyList<Any>()

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
                putInt(KEY_PRAYER_COUNT, prayers.size.coerceAtMost(5))

                prayers.take(5).forEachIndexed { index, item ->
                    val prayer = item as? Map<*, *> ?: return@forEachIndexed
                    putString(prayerNameKey(index), prayer["name"] as? String)
                    putString(prayerTimeKey(index), prayer["time"] as? String)
                    putLong(prayerMillisKey(index), (prayer["millis"] as? Number)?.toLong() ?: 0L)
                }
            }.apply()

            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PrayerTimesWidgetProvider::class.java),
            )
            ids.forEach { updateWidget(context, manager, it) }
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

            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
            views.setTextViewText(
                R.id.widget_city,
                prefs.getString(KEY_CITY_NAME, null) ?: "نور القرآن",
            )
            views.setTextViewText(
                R.id.widget_hijri,
                prefs.getString(KEY_HIJRI_DATE, null) ?: "افتح التطبيق لتحديث المواقيت",
            )

            configureCountdown(views, now, nextMillis, previousMillis, nextName, previousName)
            configurePrayerStrip(views, prefs, now, nextMillis, previousMillis)

            appWidgetManager.updateAppWidget(appWidgetId, views)
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
                    views.setTextColor(R.id.widget_countdown_prefix, mutedTextColor)
                    views.setTextColor(R.id.widget_countdown, primaryTextColor)
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
                    views.setTextViewText(R.id.widget_countdown_prefix, "بعد")
                    views.setTextColor(R.id.widget_next_name, primaryColor)
                    views.setTextColor(R.id.widget_countdown_prefix, mutedTextColor)
                    views.setTextColor(R.id.widget_countdown, primaryTextColor)
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
                    views.setTextViewText(R.id.widget_countdown, "--:--:--")
                    views.setTextColor(R.id.widget_next_name, primaryColor)
                    views.setTextColor(R.id.widget_countdown, primaryTextColor)
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
            prefs: android.content.SharedPreferences,
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
                    if (isHighlighted) surfaceTextColor else mutedTextColor,
                )
                views.setTextColor(
                    timeIds[index],
                    if (isHighlighted) surfaceTextColor else primaryTextColor,
                )
            }
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
    }
}
