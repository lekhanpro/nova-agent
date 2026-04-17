package com.novaagent.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Receives BOOT_COMPLETED and optionally restarts the foreground service
 * if the user had the agent running before shutdown.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val prefs = context.getSharedPreferences("NovaAgentPrefs", Context.MODE_PRIVATE)
            val wasRunning = prefs.getBoolean("was_running", false)
            if (wasRunning) {
                val svcIntent = Intent(context, NovaAgentForegroundService::class.java).apply {
                    putExtra("title", "Nova Agent")
                    putExtra("text", "AutoGPT agent restarted after reboot")
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(svcIntent)
                } else {
                    context.startService(svcIntent)
                }
            }
        }
    }
}
