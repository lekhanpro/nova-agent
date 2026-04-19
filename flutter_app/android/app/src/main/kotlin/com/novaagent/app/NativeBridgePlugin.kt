package com.novaagent.app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileWriter
import java.io.InputStreamReader

/**
 * NativeBridgePlugin
 * Exposes Termux shell execution, process management, log reading,
 * config writing, battery optimization controls, and system info to Flutter/Dart.
 *
 * MethodChannel : com.novaagent.app/native
 * EventChannel  : com.novaagent.app/terminal_output
 */
class NativeBridgePlugin(
    private val context: Context,
    private val terminalStream: TerminalStreamHandler,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val METHOD_CHANNEL = "com.novaagent.app/native"
        private const val EVENT_CHANNEL  = "com.novaagent.app/terminal_output"

        private const val TERMUX_HOME   = "/data/data/com.termux/files/home"
        private const val TERMUX_PREFIX = "/data/data/com.termux/files/usr"

        fun register(messenger: BinaryMessenger, context: Context) {
            val streamHandler = TerminalStreamHandler()
            val plugin = NativeBridgePlugin(context, streamHandler)
            MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler(plugin)
            EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(streamHandler)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // ── Shell ─────────────────────────────────────────────────────────
            "runCommand" -> {
                val cmd = call.argument<String>("cmd") ?: return result.error("NO_CMD", "cmd is null", null)
                Thread {
                    try {
                        result.success(execShell(cmd))
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

            "runCommandStreaming" -> {
                val cmd = call.argument<String>("cmd") ?: return result.error("NO_CMD", "cmd is null", null)
                Thread {
                    try {
                        val pb = ProcessBuilder("${TERMUX_PREFIX}/bin/bash", "-c", cmd).apply {
                            environment().apply {
                                put("HOME", TERMUX_HOME)
                                put("PREFIX", TERMUX_PREFIX)
                                put("PATH", "${TERMUX_PREFIX}/bin")
                                put("LD_LIBRARY_PATH", "${TERMUX_PREFIX}/lib")
                                put("TERM", "xterm-256color")
                                put("LANG", "en_US.UTF-8")
                            }
                            redirectErrorStream(true)
                        }
                        val process = pb.start()
                        val reader = BufferedReader(InputStreamReader(process.inputStream))
                        var line: String?
                        while (reader.readLine().also { line = it } != null) {
                            terminalStream.emit(line!!)
                        }
                        process.waitFor()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("EXEC_FAILED", e.message, null)
                    }
                }.start()
            }

            // ── Process management ────────────────────────────────────────────
            "isProcessRunning" -> {
                val name = call.argument<String>("processName") ?: ""
                Thread {
                    val running = execShell("pgrep -f $name 2>/dev/null").trim().isNotEmpty()
                    result.success(running)
                }.start()
            }

            "killProcess" -> {
                val name = call.argument<String>("processName") ?: ""
                Thread {
                    execShell("pkill -f $name 2>/dev/null || true")
                    result.success(null)
                }.start()
            }

            // ── Logs ──────────────────────────────────────────────────────────
            "readLog" -> {
                val maxLines = call.argument<Int>("maxLines") ?: 200
                Thread {
                    try {
                        val cmd = "tail -n $maxLines ${TERMUX_HOME}/.nova_agent/history.json 2>/dev/null"
                        result.success(execShell(cmd))
                    } catch (e: Exception) {
                        result.error("LOG_READ_FAILED", e.message, null)
                    }
                }.start()
            }

            // ── Config write ──────────────────────────────────────────────────
            "writeConfig" -> {
                val content = call.argument<String>("content") ?: ""
                Thread {
                    try {
                        val dir = File("${TERMUX_HOME}/.nova_agent")
                        if (!dir.exists()) dir.mkdirs()
                        FileWriter(File("${TERMUX_HOME}/.nova_agent/config")).use { it.write(content) }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("WRITE_FAILED", e.message, null)
                    }
                }.start()
            }

            // ── File read ─────────────────────────────────────────────────────
            "readFile" -> {
                val path = call.argument<String>("path") ?: ""
                Thread {
                    try {
                        val file = File(path)
                        result.success(if (file.exists()) file.readText() else "")
                    } catch (e: Exception) {
                        result.error("READ_FAILED", e.message, null)
                    }
                }.start()
            }

            // ── Battery ───────────────────────────────────────────────────────
            "isBatteryOptimized" -> {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                result.success(!pm.isIgnoringBatteryOptimizations(context.packageName))
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
                context.stopService(Intent(context, NovaAgentForegroundService::class.java))
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun execShell(cmd: String): String {
        val pb = ProcessBuilder("${TERMUX_PREFIX}/bin/bash", "-c", cmd).apply {
            environment().apply {
                put("HOME", TERMUX_HOME)
                put("PREFIX", TERMUX_PREFIX)
                put("PATH", "${TERMUX_PREFIX}/bin")
                put("LD_LIBRARY_PATH", "${TERMUX_PREFIX}/lib")
                put("TERM", "xterm-256color")
                put("LANG", "en_US.UTF-8")
            }
        }
        val process = pb.start()
        val stdout  = BufferedReader(InputStreamReader(process.inputStream))
        val stderr  = BufferedReader(InputStreamReader(process.errorStream))
        val sb      = StringBuilder()
        stdout.forEachLine { sb.appendLine(it) }
        stderr.forEachLine { /* discard */ }
        process.waitFor()
        return sb.toString().trimEnd()
    }
}

// ── Terminal event stream ─────────────────────────────────────────────────────
class TerminalStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun emit(line: String) {
        val sink = eventSink ?: return
        mainHandler.post { sink.success(line) }
    }
}

