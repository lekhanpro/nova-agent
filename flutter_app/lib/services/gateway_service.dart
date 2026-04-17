import 'native_bridge.dart';
import '../constants.dart';

/// Manages AutoGPT agent lifecycle via NativeBridge shell commands.
class GatewayService {
  static const String _agentProcess = 'autogpt';
  static const String _webProcess   = 'server.py';

  Future<void> start() async {
    // Start log web viewer in background
    await NativeBridge.runCommand(
      'proot-distro login ubuntu -- bash -c "'
      'pkill -f server.py 2>/dev/null || true; '
      'nohup python3 ${AppConstants.webServerPath} '
      '> /tmp/webserver.log 2>&1 &"',
    );

    await Future.delayed(const Duration(milliseconds: 800));

    // Start AutoGPT agent
    await NativeBridge.runCommand(
      r'proot-distro login ubuntu -- bash -c "'
      r'CLASSIC_DIR=/root/autogpt/classic/original_autogpt; '
      r'[ -d "$CLASSIC_DIR" ] || CLASSIC_DIR=/root/autogpt; '
      r'cd "$CLASSIC_DIR" && [ -f venv/bin/activate ] && source venv/bin/activate; '
      r'export PYTHONUNBUFFERED=1; '
      r'nohup python -m autogpt run --continuous --skip-reprompt '
      r'> ${AppConstants.logFile} 2>&1 &'
      r'echo $! > ${AppConstants.pidFile}"',
    );
  }

  Future<void> stop() async {
    await NativeBridge.runCommand(
      'proot-distro login ubuntu -- bash -c "'
      'pkill -f autogpt 2>/dev/null; '
      'pkill -f server.py 2>/dev/null; '
      'sleep 1; '
      'pkill -9 -f autogpt 2>/dev/null || true"',
    );
  }

  Future<bool> isRunning() async {
    return NativeBridge.isProcessRunning(_agentProcess);
  }

  Future<String> fetchLogs({int maxLines = 200}) async {
    return NativeBridge.readLog(AppConstants.logFile, maxLines: maxLines);
  }

  Future<bool> isWebViewerRunning() async {
    return NativeBridge.isProcessRunning(_webProcess);
  }
}
