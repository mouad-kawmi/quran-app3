package com.mouad.quran.quran_app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private var pendingAdhanAudioResult: MethodChannel.Result? = null
    private var nativeAdhanChannel: MethodChannel? = null
    private var previewAdhanPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        nativeAdhanChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NativeAdhanScheduler.CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val id = call.argument<Int>("id")
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                        val prayerName = call.argument<String>("prayerName")
                        val rawResourceName = call.argument<String>("rawResourceName")
                        val filePath = call.argument<String>("filePath")
                        val volume = adhanVolume(call.argument<Double>("volume"))

                        if (id == null ||
                            triggerAtMillis == null ||
                            (rawResourceName.isNullOrBlank() && filePath.isNullOrBlank())
                        ) {
                            result.error("bad_args", "Missing native adhan alarm arguments.", null)
                            return@setMethodCallHandler
                        }

                        val scheduled = NativeAdhanScheduler.schedule(
                            context = applicationContext,
                            id = id,
                            triggerAtMillis = triggerAtMillis,
                            prayerName = prayerName.orEmpty(),
                            rawResourceName = rawResourceName.orEmpty(),
                            filePath = filePath.orEmpty(),
                            volume = volume,
                        )
                        result.success(scheduled)
                    }

                    "scheduleNotification" -> {
                        val id = call.argument<Int>("id")
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                        val title = call.argument<String>("title")
                        val body = call.argument<String>("body")
                        val timeoutAfterMillis = call.argument<Long>("timeoutAfterMillis")

                        if (id == null ||
                            triggerAtMillis == null ||
                            title.isNullOrBlank()
                        ) {
                            result.error("bad_args", "Missing native notification alarm arguments.", null)
                            return@setMethodCallHandler
                        }

                        val scheduled = NativeAdhanScheduler.scheduleNotification(
                            context = applicationContext,
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
                            return@setMethodCallHandler
                        }

                        NativeAdhanScheduler.cancel(applicationContext, id)
                        result.success(true)
                    }

                    "cancelNotification" -> {
                        val id = call.argument<Int>("id")
                        if (id == null) {
                            result.error("bad_args", "Missing native notification alarm id.", null)
                            return@setMethodCallHandler
                        }

                        NativeAdhanScheduler.cancelNotification(applicationContext, id)
                        result.success(true)
                    }

                    "pendingScheduledCount" -> {
                        result.success(NativeAdhanScheduler.pendingScheduledCount(applicationContext))
                    }

                    "pickAdhanAudio" -> pickAdhanAudio(result)

                    "preview" -> {
                        val rawResourceName = call.argument<String>("rawResourceName")
                        val filePath = call.argument<String>("filePath")
                        if (rawResourceName.isNullOrBlank() && filePath.isNullOrBlank()) {
                            result.error("bad_args", "Missing adhan preview sound.", null)
                            return@setMethodCallHandler
                        }

                        try {
                            previewAdhanAudio(
                                rawResourceName = rawResourceName.orEmpty(),
                                filePath = filePath.orEmpty(),
                                volume = adhanVolume(call.argument<Double>("volume")),
                            )
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("preview_failed", "Could not play adhan preview.", error.message)
                        }
                    }

                    "stopPreview" -> {
                        stopAdhanPreview(notifyCompletion = false)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PrayerTimesWidgetProvider.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("bad_args", "Missing prayer widget data.", null)
                            return@setMethodCallHandler
                        }

                        PrayerTimesWidgetProvider.saveDataAndUpdate(applicationContext, args)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PICK_ADHAN_AUDIO) return

        val result = pendingAdhanAudioResult ?: return
        pendingAdhanAudioResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }

        try {
            result.success(copyAdhanAudio(uri))
        } catch (error: Exception) {
            result.error("copy_failed", "Could not copy selected adhan audio.", error.message)
        }
    }

    override fun onDestroy() {
        stopAdhanPreview(notifyCompletion = false)
        nativeAdhanChannel = null
        super.onDestroy()
    }

    private fun pickAdhanAudio(result: MethodChannel.Result) {
        if (pendingAdhanAudioResult != null) {
            result.error("pick_in_progress", "Another audio picker is already open.", null)
            return
        }

        pendingAdhanAudioResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            startActivityForResult(intent, REQUEST_PICK_ADHAN_AUDIO)
        } catch (_: ActivityNotFoundException) {
            pendingAdhanAudioResult = null
            result.error("picker_unavailable", "No audio picker is available on this device.", null)
        }
    }

    private fun copyAdhanAudio(uri: Uri): Map<String, String> {
        val displayName = audioDisplayName(uri)
        val extension = audioExtension(uri, displayName)
        val directory = File(filesDir, "adhan").apply {
            if (!exists()) mkdirs()
        }

        directory.listFiles()
            ?.filter { it.name.startsWith("custom_adhan_") }
            ?.forEach { it.delete() }

        val target = File(directory, "custom_adhan_${System.currentTimeMillis()}$extension")
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(target).use { output ->
                input.copyTo(output)
            }
        } ?: error("Could not open selected audio.")

        return mapOf(
            "path" to target.absolutePath,
            "name" to displayName,
        )
    }

    private fun previewAdhanAudio(rawResourceName: String, filePath: String, volume: Double) {
        stopAdhanPreview(notifyCompletion = false)

        previewAdhanPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
            )
            if (filePath.isNotBlank()) {
                val file = File(filePath)
                if (!file.exists()) error("Adhan preview file does not exist.")
                setDataSource(file.absolutePath)
            } else {
                val resourceId = resources.getIdentifier(rawResourceName, "raw", packageName)
                if (resourceId == 0) error("Adhan preview resource does not exist.")
                resources.openRawResourceFd(resourceId).use { descriptor ->
                    setDataSource(
                        descriptor.fileDescriptor,
                        descriptor.startOffset,
                        descriptor.length,
                    )
                }
            }
            setVolume(volume.toFloat(), volume.toFloat())
            setOnCompletionListener { stopAdhanPreview(notifyCompletion = true) }
            setOnErrorListener { _, _, _ ->
                stopAdhanPreview(notifyCompletion = true)
                true
            }
            prepare()
            start()
        }
    }

    private fun stopAdhanPreview(notifyCompletion: Boolean) {
        previewAdhanPlayer?.run {
            if (isPlaying) stop()
            release()
        }
        previewAdhanPlayer = null
        if (notifyCompletion) {
            nativeAdhanChannel?.invokeMethod("adhanPreviewCompleted", null)
        }
    }

    private fun adhanVolume(volume: Double?): Double {
        return (volume ?: DEFAULT_ADHAN_VOLUME).coerceIn(0.1, 1.0)
    }

    private fun audioDisplayName(uri: Uri): String {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) {
                        val name = cursor.getString(index)
                        if (!name.isNullOrBlank()) return name
                    }
                }
            }

        return "أذان من الهاتف"
    }

    private fun audioExtension(uri: Uri, displayName: String): String {
        val nameExtension = displayName.substringAfterLast('.', missingDelimiterValue = "")
        if (nameExtension.length in 1..5) {
            return ".$nameExtension"
        }

        val mimeExtension = MimeTypeMap.getSingleton()
            .getExtensionFromMimeType(contentResolver.getType(uri))
        return if (mimeExtension.isNullOrBlank()) ".mp3" else ".$mimeExtension"
    }

    private companion object {
        const val REQUEST_PICK_ADHAN_AUDIO = 7001
        const val DEFAULT_ADHAN_VOLUME = 0.85
    }
}
