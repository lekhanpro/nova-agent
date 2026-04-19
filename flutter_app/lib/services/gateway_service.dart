import 'native_bridge.dart';
import '../constants.dart';

/// Manages nova-agent lifecycle via NativeBridge shell commands.
class GatewayService {
  /// Check if novax is installed.
  static Future<bool> isInstalled() async {
    final result = await NativeBridge.runCommand('which novax 2>/dev/null');
    return result.trim().isNotEmpty;
  }

  /// Check if novax process is currently running.
  static Future<bool> isRunning() async {
    final result = await NativeBridge.runCommand('pgrep -f novax || echo ""');
    return result.trim().isNotEmpty;
  }

  /// Send a one-shot query to nova agent.
  static Future<String> ask(String query) async {
    final escaped = query.replaceAll('"', '\\"');
    return NativeBridge.runCommand('novax ask "$escaped" 2>&1');
  }

  /// Read conversation history.
  static Future<String> getHistory() async {
    return NativeBridge.runCommand(
        'cat ~/.nova_agent/history.json 2>/dev/null || echo "[]"');
  }

  /// Read recent logs / history tail.
  static Future<String> getLogs() async {
    return NativeBridge.runCommand(
        'tail -n 100 ~/.nova_agent/history.json 2>/dev/null || echo ""');
  }

  /// Write provider config to ~/.nova_agent/config.
  static Future<void> writeConfig({
    required String provider,
    required String model,
    required String apiKey,
  }) async {
    final providerData = AppConstants.providers.firstWhere(
      (p) => p['id'] == provider,
      orElse: () => AppConstants.providers.first,
    );
    final envKey = providerData['envKey'] as String;
    final content = [
      'PROVIDER=$provider',
      'MODEL=$model',
      '$envKey=$apiKey',
    ].join('\n');
    await NativeBridge.writeConfig({'content': content});
  }

  /// Start agent foreground service.
  static Future<void> startAgent() async {
    await NativeBridge.startForegroundService(
      title: 'Nova Agent',
      text: 'AI agent is running',
    );
  }

  /// Stop agent process and foreground service.
  static Future<void> stopAgent() async {
    await NativeBridge.runCommand('pkill -f novax 2>/dev/null || true');
    await NativeBridge.stopForegroundService();
  }
}

