package com.novaagent.app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

/**
 * NativeBridgePlugin
 * Exposes shell execution, process management, log reading,
 * battery optimization controls, and system info to Flutter/Dart.
 *
 * MethodChannel : com.novaagent.app/native
 * EventChannel  : com.novaagent.app/terminal_output
 */
class NativeBridgePlugin(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val METHOD_CHANNEL = "com.novaagent.app/native"
        private const val EVENT_CHANNEL  = "com.novaagent.app/terminal_output"

        fun register(messenger: BinaryMessenger, context: Context) {
            val plugin = NativeBridgePlugin(context)
            MethodChannel(messenger, METHOD_CHANNEL)
                .setMethodCallHandler(plugin)
            EventChannel(messenger, EVENT_CHANNEL)
                .setStreamHandler(TerminalStreamHandler())
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // ── Shell ─────────────────────────────────────────────────────────
            "runCommand" -> {
                val cmd = call.argument<String>("cmd") ?: return result.error("NO_CMD", "cmd is null", null)
                Thread {
                    try {
                        val output = execShell(cmd)
                        result.success(output)
                    } catch (e: Exception) {
                        result.error("EXEC_FAILED", e.message, null)
                    }
                }.start()
            }

            "runCommandSync" -> {
                val cmd = call.argument<String>("cmd") ?: return result.error("NO_CMD", "cmd is null", null)
                try {
                    result.success(execShell(cmd))
                } catch (e: Exception) {
                    result.error("EXEC_FAILED", e.message, null)
                }
            }

            // ── Process management ────────────────────────────────────────────
            "isProcessRunning" -> {
                val name = call.argument<String>("processName") ?: ""
                val running = execShell("pgrep -f $name").trim().isNotEmpty()
                result.success(running)
            }

            "killProcess" -> {
                val name = call.argument<String>("processName") ?: ""
                execShell("pkill -f $name 2>/dev/null || true")
                result.success(null)
            }

            // ── Logs ──────────────────────────────────────────────────────────
            "readLog" -> {
                val path     = call.argument<String>("path") ?: "/tmp/autogpt.log"
                val maxLines = call.argument<Int>("maxLines") ?: 200
                Thread {
                    try {
                        val cmd = "proot-distro login ubuntu -- tail -n $maxLines $path 2>/dev/null || echo ''"
                        result.success(execShell(cmd))
                    } catch (e: Exception) {
                        result.error("LOG_READ_FAILED", e.message, null)
                    }
                }.start()
            }

            // ── Battery ───────────────────────────────────────────────────────
            "isBatteryOptimized" -> {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val optimized = !pm.isIgnoringBatteryOptimizations(context.packageName)
                result.success(optimized)
            }

            "openBatterySettings" -> {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
                result.success(null)
            }

            // ── System info ───────────────────────────────────────────────────
            "getSystemInfo" -> {
                val info = mapOf(
                    "Android"      to Build.VERSION.RELEASE,
                    "Device"       to "${Build.MANUFACTURER} ${Build.MODEL}",
                    "Architecture" to Build.SUPPORTED_ABIS[0],
                    "API Level"    to Build.VERSION.SDK_INT.toString(),
                    "Package"      to context.packageName,
                )
                result.success(info)
            }

            // ── Foreground Service ────────────────────────────────────────────
            "startForegroundService" -> {
                val title = call.argument<String>("title") ?: "Nova Agent"
                val text  = call.argument<String>("text")  ?: "Agent is running"
                val intent = Intent(context, NovaAgentForegroundService::class.java).apply {
                    putExtra("title", title)
                    putExtra("text", text)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                result.success(null)
            }

            "stopForegroundService" -> {
                context.stopService(
                    Intent(context, NovaAgentForegroundService::class.java)
                )
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ── Shell helper ──────────────────────────────────────────────────────────
    private fun execShell(cmd: String): String {
        val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", cmd))
        val stdout  = BufferedReader(InputStreamReader(process.inputStream))
        val stderr  = BufferedReader(InputStreamReader(process.errorStream))
        val sb      = StringBuilder()
        stdout.forEachLine { sb.appendLine(it) }
        stderr.forEachLine { /* discard stderr */ }
        process.waitFor()
        return sb.toString().trimEnd()
    }
}

// ── Terminal event stream ─────────────────────────────────────────────────────
class TerminalStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun emit(line: String) {
        eventSink?.success(line)
    }
}
