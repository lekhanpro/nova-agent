import 'package:flutter/material.dart';

/// Minimal terminal-like output display for running novax commands.
class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy output',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF060610),
        width: double.infinity,
        child: Column(
          children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF12121F),
              child: Row(
                children: [
                  const Icon(Icons.terminal_rounded,
                      size: 16, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  const Text('proot-distro ubuntu',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: Color(0xFF6B6B8A))),
                  const Spacer(),
                  _ChipButton(label: 'novax status'),
                  const SizedBox(width: 6),
                  _ChipButton(label: 'novax logs'),
                ],
              ),
            ),
            // Output
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: _TerminalOutput(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalOutput extends StatelessWidget {
  const _TerminalOutput();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line('Nova Agent Terminal', color: Color(0xFF7C3AED), bold: true),
          _Line('─────────────────────────────────', color: Color(0xFF2D2D4E)),
          _Line('Type commands in the Termux app, or use quick actions above.'),
          _Line(''),
          _Line('Quick commands:', color: Color(0xFF7C3AED)),
          _Line('  novax start     — launch AutoGPT agent'),
          _Line('  novax stop      — stop the agent'),
          _Line('  novax logs      — tail live logs'),
          _Line('  novax status    — check running status'),
          _Line('  novax configure — set API keys'),
          _Line('  novax shell     — open Ubuntu shell'),
          _Line(''),
          _Line('Web dashboard: http://localhost:8000',
              color: Color(0xFF2563EB)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String text;
  final Color color;
  final bool bold;

  const _Line(this.text,
      {this.color = const Color(0xFFCCCCDD), this.bold = false});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          height: 1.7,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      );
}

class _ChipButton extends StatelessWidget {
  final String label;
  const _ChipButton({required this.label});

  @override
  Widget build(BuildContext context) => GestureDetector(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: Color(0xFF7C3AED))),
        ),
      );
}
