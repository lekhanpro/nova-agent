import 'dart:convert';
import 'package:flutter/services.dart';

/// Calls into the native Kotlin NativeBridgePlugin via platform channel.
class NativeBridge {
  static const MethodChannel _channel =
      MethodChannel('com.novaagent.app/native');

  NativeBridge._();

  // ── Shell execution ────────────────────────────────────────────────────────

  /// Runs a proot-distro command inside Ubuntu and returns stdout.
  static Future<String> runCommand(String cmd) async {
    final result = await _channel.invokeMethod<String>(
      'runCommand',
      {'cmd': cmd},
    );
    return result ?? '';
  }

  /// Runs a shell command and streams output line by line.
  /// Use [NativeBridgeEventStream] for streaming.
  static Future<String> runCommandSync(String cmd) async {
    final result =
        await _channel.invokeMethod<String>('runCommandSync', {'cmd': cmd});
    return result ?? '';
  }

  // ── Process management ─────────────────────────────────────────────────────

  static Future<bool> isProcessRunning(String processName) async {
    final result = await _channel.invokeMethod<bool>(
      'isProcessRunning',
      {'processName': processName},
    );
    return result ?? false;
  }

  static Future<void> killProcess(String processName) async {
    await _channel.invokeMethod('killProcess', {'processName': processName});
  }

  // ── Log file ───────────────────────────────────────────────────────────────

  static Future<String> readLog(String path, {int maxLines = 200}) async {
    final result = await _channel.invokeMethod<String>(
      'readLog',
      {'path': path, 'maxLines': maxLines},
    );
    return result ?? '';
  }

  // ── Battery optimization ───────────────────────────────────────────────────

  static Future<bool> isBatteryOptimized() async {
    final result =
        await _channel.invokeMethod<bool>('isBatteryOptimized');
    return result ?? false;
  }

  static Future<void> openBatterySettings() async {
    await _channel.invokeMethod('openBatterySettings');
  }

  // ── System info ────────────────────────────────────────────────────────────

  static Future<Map<String, String>> getSystemInfo() async {
    final result = await _channel.invokeMethod<Map>('getSystemInfo');
    return result?.cast<String, String>() ?? {};
  }

  // ── Foreground service ─────────────────────────────────────────────────────

  static Future<void> startForegroundService(String title, String text) async {
    await _channel
        .invokeMethod('startForegroundService', {'title': title, 'text': text});
  }

  static Future<void> stopForegroundService() async {
    await _channel.invokeMethod('stopForegroundService');
  }
}

/// EventChannel stream for live terminal output.
class NativeBridgeEventStream {
  static const EventChannel _eventChannel =
      EventChannel('com.novaagent.app/terminal_output');

  static Stream<String> get stream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString());
  }
}
