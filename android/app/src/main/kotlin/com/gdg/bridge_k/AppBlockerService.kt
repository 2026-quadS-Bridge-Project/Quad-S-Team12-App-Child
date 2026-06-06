package com.gdg.bridge_k

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telecom.TelecomManager
import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

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
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
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
