import 'native_bridge.dart';
import '../constants.dart';

typedef StepCallback  = void Function(int step, String log);
typedef ErrorCallback = void Function(String error);

/// Orchestrates the 5-step nova-agent environment setup.
class BootstrapService {
  Future<void> run({
    required StepCallback onStep,
    required ErrorCallback onError,
  }) async {
    try {
      // Step 1: Update Termux
      onStep(1, 'Updating Termux packages...');
      await NativeBridge.runCommand('pkg update -y 2>&1 | tail -3 || true');

      // Step 2: Install Node.js & Python
      onStep(2, 'Installing Node.js & Python...');
      await NativeBridge.runCommand('pkg install -y nodejs python 2>&1 | tail -5');

      // Step 3: Install Termux:API bridge
      onStep(3, 'Installing Termux:API bridge...');
      await NativeBridge.runCommand('pkg install -y termux-api 2>&1 | tail -3 || true');

      // Step 4: Install Nova Agent globally
      onStep(4, 'Installing Nova Agent globally...');
      await NativeBridge.runCommand('npm install -g nova-agent 2>&1 | tail -5');

      // Step 5: Verify installation
      onStep(5, 'Verifying installation...');
      final version = await NativeBridge.runCommand('novax --version 2>&1');
      if (version.trim().isEmpty) {
        throw Exception('novax not found after installation');
      }

    } catch (e) {
      onError(e.toString());
      rethrow;
    }
  }
}

