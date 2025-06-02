package com.example.ip_messanger

import androidx.multidex.MultiDexApplication
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.security.ProviderInstaller
import com.google.android.gms.security.ProviderInstaller.ProviderInstallListener

class MainApplication : MultiDexApplication(), ProviderInstallListener {
    override fun onCreate() {
        super.onCreate()
        ProviderInstaller.installIfNeededAsync(this, this)
    }

    override fun onProviderInstallFailed(errorCode: Int, intent: android.content.Intent?) {
        GoogleApiAvailability.getInstance().showErrorNotification(this, errorCode)
    }

    override fun onProviderInstalled() {
        // Security provider is up-to-date
    }
}