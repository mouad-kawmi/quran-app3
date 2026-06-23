package com.mouad.quran.quran_app

import android.app.Application
import dev.fluttercommunity.workmanager.WorkmanagerPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class MyApplication : Application(), PluginRegistry.PluginRegistrantCallback {

    override fun onCreate() {
        super.onCreate()
        WorkmanagerPlugin.setPluginRegistrantCallback(this)
    }

    override fun registerWith(registry: PluginRegistry) {
        val registrar = registry.registrarFor("com.mouad.quran.quran_app.BackgroundAdhanMethodHandler")
        val channel = MethodChannel(registrar.messenger(), NativeAdhanScheduler.CHANNEL)
        channel.setMethodCallHandler(BackgroundAdhanMethodHandler(this))
    }
}
