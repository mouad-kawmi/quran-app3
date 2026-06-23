package com.mouad.quran.quran_app

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BackgroundAdhanMethodHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "schedule" -> {
                val id = call.argument<Int>("id")
                val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                val prayerName = call.argument<String>("prayerName")
                val rawResourceName = call.argument<String>("rawResourceName")
                val filePath = call.argument<String>("filePath")
                val volume = call.argument<Double>("volume")

                if (id == null || triggerAtMillis == null ||
                    (rawResourceName.isNullOrBlank() && filePath.isNullOrBlank())
                ) {
                    result.error("bad_args", "Missing native adhan alarm arguments.", null)
                    return
                }

                val scheduled = NativeAdhanScheduler.schedule(
                    context = context,
                    id = id,
                    triggerAtMillis = triggerAtMillis,
                    prayerName = prayerName.orEmpty(),
                    rawResourceName = rawResourceName.orEmpty(),
                    filePath = filePath.orEmpty(),
                    volume = (volume ?: 0.85).coerceIn(0.1, 1.0),
                )
                result.success(scheduled)
            }
            "scheduleNotification" -> {
                val id = call.argument<Int>("id")
                val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                val title = call.argument<String>("title")
                val body = call.argument<String>("body")
                val timeoutAfterMillis = call.argument<Long>("timeoutAfterMillis")

                if (id == null || triggerAtMillis == null || title.isNullOrBlank()) {
                    result.error("bad_args", "Missing native notification alarm arguments.", null)
                    return
                }

                val scheduled = NativeAdhanScheduler.scheduleNotification(
                    context = context,
                    id = id,
                    triggerAtMillis = triggerAtMillis,
                    title = title,
                    body = body.orEmpty(),
                    timeoutAfterMillis = timeoutAfterMillis ?: 0L,
                )
                result.success(scheduled)
            }
            "cancel" -> {
                val id = call.argument<Int>("id")
                if (id == null) {
                    result.error("bad_args", "Missing native adhan alarm id.", null)
                    return
                }

                NativeAdhanScheduler.cancel(context, id)
                result.success(true)
            }
            "cancelNotification" -> {
                val id = call.argument<Int>("id")
                if (id == null) {
                    result.error("bad_args", "Missing native notification alarm id.", null)
                    return
                }

                NativeAdhanScheduler.cancelNotification(context, id)
                result.success(true)
            }
            "pendingScheduledCount" -> {
                result.success(NativeAdhanScheduler.pendingScheduledCount(context))
            }
            else -> result.notImplemented()
        }
    }
}
