package com.mouad.quran.quran_app

import android.app.Application
import com.mouad.quran.native_adhan_bridge.AdhanBridge

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Register the background method handler onto the local bridge.
        // This makes sure both MainActivity's engine and Workmanager's 
        // headless engine will properly find and execute the Kotlin methods.
        AdhanBridge.handler = BackgroundAdhanMethodHandler(this)
    }
}
