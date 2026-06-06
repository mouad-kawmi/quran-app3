package com.mouad.quran.quran_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import java.io.File
import kotlin.math.roundToInt

class AdhanPlaybackService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var previousAlarmVolume: Int? = null
    private var keepElapsedNotification = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == NativeAdhanScheduler.ACTION_STOP_ADHAN) {
            keepElapsedNotification = false
            cancelPlaybackNotification()
            stopSelf(startId)
            return START_NOT_STICKY
        }

        val prayerName = intent?.getStringExtra(NativeAdhanScheduler.EXTRA_PRAYER_NAME).orEmpty()
        val rawResourceName = intent?.getStringExtra(NativeAdhanScheduler.EXTRA_RAW_RESOURCE_NAME)
        val filePath = intent?.getStringExtra(NativeAdhanScheduler.EXTRA_FILE_PATH)
        val volume = intent?.getDoubleExtra(
            NativeAdhanScheduler.EXTRA_VOLUME,
            DEFAULT_ADHAN_VOLUME,
        ) ?: DEFAULT_ADHAN_VOLUME
        if (rawResourceName.isNullOrBlank() && filePath.isNullOrBlank()) {
            stopSelf(startId)
            return START_NOT_STICKY
        }

        val triggerAtMillis = intent?.getLongExtra(
            NativeAdhanScheduler.EXTRA_TRIGGER_AT,
            System.currentTimeMillis(),
        ) ?: System.currentTimeMillis()

        startForegroundCompat(buildNotification(prayerName, triggerAtMillis))
        keepElapsedNotification = false
        playAdhan(rawResourceName.orEmpty(), filePath.orEmpty(), startId, volume)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releasePlayer()
        abandonAudioFocus()
        restoreAlarmVolume()
        stopForegroundCompat(removeNotification = !keepElapsedNotification)
        super.onDestroy()
    }

    private fun playAdhan(
        rawResourceName: String,
        filePath: String,
        startId: Int,
        volume: Double,
    ) {
        releasePlayer()
        requestAudioFocus()
        applyAlarmVolume(volume)

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                if (filePath.isNotBlank()) {
                    val file = File(filePath)
                    if (!file.exists()) {
                        stopSelf(startId)
                        return
                    }
                    setDataSource(file.absolutePath)
                } else {
                    val resourceId = resources.getIdentifier(rawResourceName, "raw", packageName)
                    if (resourceId == 0) {
                        stopSelf(startId)
                        return
                    }
                    resources.openRawResourceFd(resourceId).use { descriptor ->
                        setDataSource(
                            descriptor.fileDescriptor,
                            descriptor.startOffset,
                            descriptor.length,
                        )
                    }
                }
                setOnCompletionListener { finishPlayback(startId) }
                setOnErrorListener { _, _, _ ->
                    stopSelf(startId)
                    true
                }
                prepare()
                start()
            }
        } catch (_: Exception) {
            releasePlayer()
            stopSelf(startId)
        }
    }

    private fun requestAudioFocus() {
        val manager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager = manager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                .setOnAudioFocusChangeListener { }
                .build()
            focusRequest = request
            manager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            manager.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
    }

    private fun abandonAudioFocus() {
        val manager = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { manager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            manager.abandonAudioFocus(null)
        }
        focusRequest = null
    }

    private fun applyAlarmVolume(volume: Double) {
        val manager = audioManager ?: return
        val currentVolume = manager.getStreamVolume(AudioManager.STREAM_ALARM)
        val maxVolume = manager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        if (maxVolume <= 0) return

        val targetVolume = (maxVolume * volume.coerceIn(0.1, 1.0))
            .roundToInt()
            .coerceIn(1, maxVolume)
        if (currentVolume == targetVolume) return

        previousAlarmVolume = previousAlarmVolume ?: currentVolume
        manager.setStreamVolume(
            AudioManager.STREAM_ALARM,
            targetVolume,
            0,
        )
    }

    private fun restoreAlarmVolume() {
        val previousVolume = previousAlarmVolume ?: return
        val manager = audioManager ?: return
        manager.setStreamVolume(AudioManager.STREAM_ALARM, previousVolume, 0)
        previousAlarmVolume = null
    }

    private fun releasePlayer() {
        mediaPlayer?.run {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
    }

    private fun finishPlayback(startId: Int) {
        releasePlayer()
        abandonAudioFocus()
        restoreAlarmVolume()
        keepElapsedNotification = true
        stopSelf(startId)
    }

    private fun buildNotification(prayerName: String, triggerAtMillis: Long): Notification {
        createPlaybackChannel()
        val legacyText = if (prayerName.isBlank()) {
            "حان وقت الصلاة"
        } else {
            "حان وقت صلاة $prayerName"
        }

        val text = if (prayerName.isBlank()) {
            "حان وقت الصلاة"
        } else {
            "حان وقت صلاة $prayerName"
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, PLAYBACK_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(R.drawable.ic_notification_icon)
            .setContentTitle("الأذان")
            .setContentText(text)
            .setWhen(triggerAtMillis)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setPriority(Notification.PRIORITY_MAX)
            .addAction(
                android.R.drawable.ic_media_pause,
                "إيقاف",
                stopPendingIntent(),
            )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setTimeoutAfter(ADHAN_NOTIFICATION_VISIBILITY_MS)
        }

        return builder.build()
    }

    private fun stopPendingIntent(): PendingIntent {
        val intent = Intent(this, AdhanPlaybackService::class.java).apply {
            action = NativeAdhanScheduler.ACTION_STOP_ADHAN
        }
        return PendingIntent.getService(
            this,
            STOP_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun createPlaybackChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            PLAYBACK_CHANNEL_ID,
            "Adhan playback",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Foreground service used to play adhan audio."
            setSound(null, null)
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                PLAYBACK_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(PLAYBACK_NOTIFICATION_ID, notification)
        }
    }

    private fun stopForegroundCompat(removeNotification: Boolean = true) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(
                if (removeNotification) {
                    STOP_FOREGROUND_REMOVE
                } else {
                    STOP_FOREGROUND_DETACH
                },
            )
        } else {
            @Suppress("DEPRECATION")
            stopForeground(removeNotification)
        }
    }

    private fun cancelPlaybackNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(PLAYBACK_NOTIFICATION_ID)
    }

    companion object {
        private const val PLAYBACK_CHANNEL_ID = "adhan_native_playback"
        private const val PLAYBACK_NOTIFICATION_ID = 990011
        private const val STOP_REQUEST_CODE = 990012
        private const val ADHAN_NOTIFICATION_VISIBILITY_MS = 30L * 60L * 1000L
        private const val DEFAULT_ADHAN_VOLUME = 0.85
    }
}
