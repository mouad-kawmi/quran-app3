package com.mouad.quran.native_adhan_bridge

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object AdhanBridge {
    var handler: MethodChannel.MethodCallHandler? = null
}

class NativeAdhanBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "quran_app/native_adhan")
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val currentHandler = AdhanBridge.handler
        if (currentHandler != null) {
            currentHandler.onMethodCall(call, result)
        } else {
            result.notImplemented()
        }
    }
}
