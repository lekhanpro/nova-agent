import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/setup_provider.dart';
import 'dashboard_screen.dart';

class SetupWizardScreen extends StatelessWidget {
  const SetupWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SetupProvider>(
        builder: (context, setup, _) {
          if (setup.status == SetupStatus.idle) {
            return _WelcomePage(onStart: () => setup.runSetup());
          } else if (setup.status == SetupStatus.running) {
            return _ProgressPage(setup: setup);
          } else if (setup.status == SetupStatus.done) {
            return _DonePage(
              onContinue: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              ),
            );
          } else {
            return _ErrorPage(
              message: setup.errorMsg,
              onRetry: () => setup.runSetup(),
            );
          }
        },
      ),
    );
  }
}

// ── Welcome ──────────────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final VoidCallback onStart;
  const _WelcomePage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 44, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text('Welcome to\nNova Agent',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -1)),
            const SizedBox(height: 14),
            Text(
              'Run AutoGPT AI agent on your Android device.\n'
              'No root required — powered by proot-distro Ubuntu.',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            // Requirements
            ...['~2 GB storage', 'Stable internet (first setup)', 'Node.js via Termux']
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF7C3AED), size: 20),
                        const SizedBox(width: 10),
                        Text(r, style: const TextStyle(fontSize: 14)),
                      ]),
                    )),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                child: const Text('Begin Setup'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Estimated time: 5-15 minutes',
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress ──────────────────────────────────────────────────────────────────
class _ProgressPage extends StatelessWidget {
  final SetupProvider setup;
  const _ProgressPage({required this.setup});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Setting up...',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Step ${setup.currentStep} of ${setup.totalSteps}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14)),
            const SizedBox(height: 28),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: setup.progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF2D2D4E),
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
              ),
            ),
            const SizedBox(height: 28),
            // Step list
            Expanded(
              child: ListView.builder(
                itemCount: AppConstants.setupSteps.length,
                itemBuilder: (_, i) {
                  final done  = i + 1 < setup.currentStep;
                  final active = i + 1 == setup.currentStep;
                  final color = done
                      ? const Color(0xFF22C55E)
                      : active
                          ? const Color(0xFF7C3AED)
                          : Colors.white.withOpacity(0.2);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: done || active
                              ? color.withOpacity(0.15)
                              : Colors.transparent,
                          border: Border.all(color: color, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: done
                              ? Icon(Icons.check, color: color, size: 16)
                              : active
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: color))
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                          color: color, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          AppConstants.setupSteps[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: done || active
                                ? Colors.white
                                : Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
            // Live log
            if (setup.stepLog.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2D4E)),
                ),
                child: Text(
                  setup.stepLog,
                  style: const TextStyle(
                      fontFamily: 'JetBrainsMono', fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Done ──────────────────────────────────────────────────────────────────────
class _DonePage extends StatelessWidget {
  final VoidCallback onContinue;
  const _DonePage({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF22C55E), size: 56),
            ),
            const SizedBox(height: 28),
            const Text('Setup complete! 🎉',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'Nova Agent is ready. Add your API key and start the agent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: Colors.white.withOpacity(0.55)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                child: const Text('Go to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────────
class _ErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorPage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 64),
            const SizedBox(height: 20),
            const Text('Setup failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Text(message,
                  style: const TextStyle(
                      fontFamily: 'JetBrainsMono', fontSize: 12),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
