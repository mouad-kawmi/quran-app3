package com.mouad.quran.quran_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            NativeAdhanScheduler.ACTION_PLAY_ADHAN -> {
                val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
                    putExtras(intent)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }

            NativeAdhanScheduler.ACTION_SHOW_NOTIFICATION -> {
                NativeAdhanScheduler.showScheduledNotification(context, intent)
            }
        }
    }
}
