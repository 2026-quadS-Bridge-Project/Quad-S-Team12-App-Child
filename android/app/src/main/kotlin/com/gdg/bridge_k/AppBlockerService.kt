package com.gdg.bridge_k

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Telephony
import android.telecom.TelecomManager
import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import kotlin.math.max
import kotlin.math.min

/**
 * Restricts the device to essential apps while blocking is active.
 *
 * On every window change we read the foreground package; if blocking is on and
 * the package is not allowlisted (this app, the default dialer, the default SMS
 * app, the home launcher, system UI / settings), we send the user back to the
 * home screen — so non-essential apps cannot stay in the foreground until the
 * child's screen time is restored.
 *
 * The user must enable this service once under Settings ▸ Accessibility; the
 * Flutter side opens that screen via `requestPermission`. The blocking flag is
 * flipped from [MainActivity] through [setBlocking] and read here.
 */
class AppBlockerService : AccessibilityService() {

    companion object {
        private const val PREFS = "bridge_k_device_block"
        private const val KEY_BLOCKING = "blocking_active"
        private const val KEY_TRACKER_ID = "screen_time_tracker_id"
        private const val KEY_ALLOCATED_SECONDS = "screen_time_allocated_seconds"
        private const val KEY_USED_SECONDS = "screen_time_used_seconds"
        private const val KEY_LAST_SCREEN_ON_ELAPSED = "screen_time_last_screen_on_elapsed"
        private const val ACTION_TRACKER_CONFIGURED = "com.gdg.bridge_k.SCREEN_TIME_TRACKER_CONFIGURED"

        /** Flip the device-wide blocking flag the service reads. */
        fun setBlocking(context: Context, active: Boolean) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_BLOCKING, active)
                .apply()
        }

        private fun isBlocking(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_BLOCKING, false)

        fun configureScreenTime(context: Context, trackerId: String, allocatedSeconds: Int): Boolean {
            if (trackerId.isBlank() || allocatedSeconds < 0) return false

            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val previousTrackerId = prefs.getString(KEY_TRACKER_ID, null)
            val nextUsedSeconds = if (previousTrackerId == trackerId) {
                min(prefs.getLong(KEY_USED_SECONDS, 0L), allocatedSeconds.toLong())
            } else {
                0L
            }

            val editor = prefs.edit()
                .putString(KEY_TRACKER_ID, trackerId)
                .putInt(KEY_ALLOCATED_SECONDS, allocatedSeconds)
                .putLong(KEY_USED_SECONDS, nextUsedSeconds)

            if (isScreenInteractive(context) && allocatedSeconds > nextUsedSeconds) {
                editor.putLong(KEY_LAST_SCREEN_ON_ELAPSED, SystemClock.elapsedRealtime())
            } else {
                editor.remove(KEY_LAST_SCREEN_ON_ELAPSED)
            }
            editor.apply()
            maybeActivateBlockingIfExpired(context)
            context.sendBroadcast(Intent(ACTION_TRACKER_CONFIGURED).setPackage(context.packageName))
            return true
        }

        fun clearScreenTime(context: Context): Boolean {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .remove(KEY_TRACKER_ID)
                .remove(KEY_ALLOCATED_SECONDS)
                .remove(KEY_USED_SECONDS)
                .remove(KEY_LAST_SCREEN_ON_ELAPSED)
                .apply()
            setBlocking(context, false)
            context.sendBroadcast(Intent(ACTION_TRACKER_CONFIGURED).setPackage(context.packageName))
            return true
        }

        fun remainingScreenTimeSeconds(context: Context): Int {
            refreshScreenTime(context)
            return remainingSeconds(context)
        }

        private fun hasActiveTracker(context: Context): Boolean {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val trackerId = prefs.getString(KEY_TRACKER_ID, null)
            val allocatedSeconds = prefs.getInt(KEY_ALLOCATED_SECONDS, 0)
            return !trackerId.isNullOrBlank() && allocatedSeconds >= 0
        }

        private fun remainingSeconds(context: Context): Int {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val allocatedSeconds = prefs.getInt(KEY_ALLOCATED_SECONDS, 0)
            val usedSeconds = prefs.getLong(KEY_USED_SECONDS, 0L)
            return max(0, allocatedSeconds - usedSeconds.toInt())
        }

        private fun recordScreenOn(context: Context) {
            if (!hasActiveTracker(context)) return
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (prefs.getLong(KEY_LAST_SCREEN_ON_ELAPSED, -1L) > 0L) return
            prefs.edit()
                .putLong(KEY_LAST_SCREEN_ON_ELAPSED, SystemClock.elapsedRealtime())
                .apply()
        }

        private fun recordScreenOff(context: Context) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val lastScreenOn = prefs.getLong(KEY_LAST_SCREEN_ON_ELAPSED, -1L)
            val editor = prefs.edit()
            if (lastScreenOn > 0L) {
                val elapsedSeconds = ((SystemClock.elapsedRealtime() - lastScreenOn) / 1000L).coerceAtLeast(0L)
                val usedSeconds = prefs.getLong(KEY_USED_SECONDS, 0L) + elapsedSeconds
                editor.putLong(KEY_USED_SECONDS, usedSeconds)
            }
            editor.remove(KEY_LAST_SCREEN_ON_ELAPSED).apply()
            maybeActivateBlockingIfExpired(context)
        }

        private fun refreshScreenTime(context: Context) {
            if (!hasActiveTracker(context)) return
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val lastScreenOn = prefs.getLong(KEY_LAST_SCREEN_ON_ELAPSED, -1L)

            if (!isScreenInteractive(context)) {
                if (lastScreenOn > 0L) recordScreenOff(context)
                return
            }

            if (lastScreenOn <= 0L) {
                recordScreenOn(context)
                return
            }

            val now = SystemClock.elapsedRealtime()
            val elapsedSeconds = ((now - lastScreenOn) / 1000L).coerceAtLeast(0L)
            if (elapsedSeconds <= 0L) return

            prefs.edit()
                .putLong(KEY_USED_SECONDS, prefs.getLong(KEY_USED_SECONDS, 0L) + elapsedSeconds)
                .putLong(KEY_LAST_SCREEN_ON_ELAPSED, now)
                .apply()
            maybeActivateBlockingIfExpired(context)
        }

        private fun maybeActivateBlockingIfExpired(context: Context) {
            if (hasActiveTracker(context) && remainingSeconds(context) <= 0) {
                setBlocking(context, true)
            }
        }

        private fun isScreenInteractive(context: Context): Boolean {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            return powerManager?.isInteractive ?: true
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var screenReceiverRegistered = false

    private val screenTick = object : Runnable {
        override fun run() {
            refreshScreenTime(this@AppBlockerService)
            if (hasActiveTracker(this@AppBlockerService) && !isBlocking(this@AppBlockerService)) {
                maybeActivateBlockingIfExpired(this@AppBlockerService)
            }
            if (hasActiveTracker(this@AppBlockerService)) {
                handler.postDelayed(this, 5_000L)
            }
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_ON -> {
                    recordScreenOn(context)
                    startScreenTicker()
                }
                Intent.ACTION_SCREEN_OFF -> {
                    recordScreenOff(context)
                    stopScreenTicker()
                }
                ACTION_TRACKER_CONFIGURED -> {
                    refreshScreenTime(context)
                    if (isScreenInteractive(context) && hasActiveTracker(context)) {
                        recordScreenOn(context)
                        startScreenTicker()
                    } else {
                        stopScreenTicker()
                    }
                }
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        registerScreenReceiver()
        if (isScreenInteractive(this)) {
            recordScreenOn(this)
            startScreenTicker()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }
        refreshScreenTime(this)
        if (isScreenInteractive(this) && hasActiveTracker(this)) {
            startScreenTicker()
        }
        if (!isBlocking(this)) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg in allowlist()) return

        // A non-essential app surfaced while blocked → bounce back to home.
        performGlobalAction(GLOBAL_ACTION_HOME)
    }

    override fun onInterrupt() {
        // No-op: nothing to clean up when the system interrupts feedback.
    }

    override fun onDestroy() {
        stopScreenTicker()
        unregisterScreenReceiver()
        super.onDestroy()
    }

    private fun registerScreenReceiver() {
        if (screenReceiverRegistered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(ACTION_TRACKER_CONFIGURED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenReceiver, filter)
        }
        screenReceiverRegistered = true
    }

    private fun unregisterScreenReceiver() {
        if (!screenReceiverRegistered) return
        runCatching { unregisterReceiver(screenReceiver) }
        screenReceiverRegistered = false
    }

    private fun startScreenTicker() {
        handler.removeCallbacks(screenTick)
        if (hasActiveTracker(this)) {
            handler.postDelayed(screenTick, 5_000L)
        }
    }

    private fun stopScreenTicker() {
        handler.removeCallbacks(screenTick)
    }

    /** Packages that remain usable while blocking is active. */
    private fun allowlist(): Set<String> {
        val allowed = mutableSetOf(
            packageName,            // this app
            "com.android.systemui", // status bar / system dialogs
            "com.android.settings", // so the user can re-disable blocking
            "android",
        )

        // Default phone (dialer) — TelecomManager.defaultDialerPackage is API 23+.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            runCatching {
                (getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)
                    ?.defaultDialerPackage
            }.getOrNull()?.let { allowed.add(it) }
        }

        // Default SMS app.
        runCatching { Telephony.Sms.getDefaultSmsPackage(this) }
            .getOrNull()?.let { allowed.add(it) }

        // Active home launcher, so the HOME action lands somewhere usable.
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        runCatching {
            packageManager.resolveActivity(home, 0)?.activityInfo?.packageName
        }.getOrNull()?.let { allowed.add(it) }

        return allowed
    }
}
