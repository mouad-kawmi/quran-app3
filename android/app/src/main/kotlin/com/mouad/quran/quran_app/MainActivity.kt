package com.mouad.quran.quran_app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeAdhanScheduler.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val id = call.argument<Int>("id")
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                        val prayerName = call.argument<String>("prayerName")
                        val rawResourceName = call.argument<String>("rawResourceName")
                        val filePath = call.argument<String>("filePath")

                        if (id == null ||
                            triggerAtMillis == null ||
                            (rawResourceName.isNullOrBlank() && filePath.isNullOrBlank())
                        ) {
                            result.error("bad_args", "Missing native adhan alarm arguments.", null)
                            return@setMethodCallHandler
                        }

                        NativeAdhanScheduler.schedule(
                            context = applicationContext,
                            id = id,
                            triggerAtMillis = triggerAtMillis,
                            prayerName = prayerName.orEmpty(),
                            rawResourceName = rawResourceName.orEmpty(),
                            filePath = filePath.orEmpty(),
                        )
                        result.success(true)
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

                    "pickAdhanAudio" -> pickAdhanAudio(result)

                    else -> result.notImplemented()
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
    }
}
