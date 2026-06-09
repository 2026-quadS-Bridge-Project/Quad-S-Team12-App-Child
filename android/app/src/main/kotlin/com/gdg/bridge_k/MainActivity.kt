package com.gdg.bridge_k

import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the `com.gdg.bridge_k/device_block` MethodChannel that the Flutter
 * [DeviceBlockController] drives. The actual foreground-app enforcement lives
 * in [AppBlockerService]; here we only expose permission checks and flip the
 * shared blocking flag the service reads.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "com.gdg.bridge_k/device_block"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(isAccessibilityServiceEnabled())
                    "requestPermission" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    "setBlocked" -> {
                        val blocked = call.argument<Boolean>("blocked") ?: false
                        AppBlockerService.setBlocking(this, blocked)
                        result.success(true)
                    }
                    "configureScreenTime" -> {
                        val key = call.argument<String>("key") ?: ""
                        val allocatedSeconds = call.argument<Int>("allocatedSeconds") ?: 0
                        result.success(
                            AppBlockerService.configureScreenTime(
                                this,
                                key,
                                allocatedSeconds,
                            )
                        )
                    }
                    "remainingScreenTimeSeconds" -> {
                        result.success(AppBlockerService.remainingScreenTimeSeconds(this))
                    }
                    "clearScreenTime" -> {
                        result.success(AppBlockerService.clearScreenTime(this))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** True when the user has enabled our [AppBlockerService] in Settings. */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = "$packageName/${AppBlockerService::class.java.name}"
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabled)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expected, ignoreCase = true)) return true
        }
        return false
    }
}
