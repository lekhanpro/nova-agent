import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/native_bridge.dart';

const _kGreen  = Color(0xFF72AE8A);
const _kAmber  = Color(0xFFC8946A);
const _kMuted  = Color(0xFF6E6458);
const _kBg     = Color(0xFF060810);
const _kSurface = Color(0xFF0D0F18);

/// Interactive terminal for running novax commands.
class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final List<String> _lines    = [];
  final _inputCtrl             = TextEditingController();
  final _scrollCtrl            = ScrollController();
  bool _isRunning              = false;

  static const _quickCommands = [
    'novax --version',
    'novax tools',
    'novax ask "hello"',
  ];

  Future<void> _runCmd(String cmd) async {
    if (cmd.trim().isEmpty) return;
    _inputCtrl.clear();
    setState(() {
      _lines.add('\$ $cmd');
      _isRunning = true;
    });
    _scrollToBottom();
    try {
      final output = await NativeBridge.runCommand(cmd);
      setState(() {
        _lines.addAll(output.isEmpty ? ['(no output)'] : output.split('\n'));
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _lines.add('Error: $e');
        _isRunning = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: _lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Row(children: [
          const Icon(Icons.terminal_rounded, size: 18, color: _kGreen),
          const SizedBox(width: 8),
          const Text('Terminal',
              style: TextStyle(
                  fontFamily: 'monospace', fontSize: 16, color: _kGreen)),
        ]),
        actions: [
          if (_lines.isNotEmpty)
            IconButton(
              onPressed: _copyAll,
              icon: const Icon(Icons.copy_rounded, color: _kMuted),
              tooltip: 'Copy all',
            ),
          IconButton(
            onPressed: () => setState(() => _lines.clear()),
            icon: const Icon(Icons.delete_sweep_rounded, color: _kMuted),
            tooltip: 'Clear',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1A1D2E)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Output area
            Expanded(
              child: _lines.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: _lines.length,
                      itemBuilder: (_, i) => _TermLine(_lines[i]),
                    ),
            ),
            // Quick command chips
            Container(
              color: _kSurface,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: _quickCommands
                    .map((cmd) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _QuickChip(
                            label: cmd,
                            onTap: () => _runCmd(cmd),
                          ),
                        ))
                    .toList(),
              ),
            ),
            // Input row
            Container(
              color: _kSurface,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                const Text('\$',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        color: _kGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    enabled: !_isRunning,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: _kMuted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _runCmd,
                  ),
                ),
                if (_isRunning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kGreen),
                  )
                else
                  IconButton(
                    onPressed: () => _runCmd(_inputCtrl.text),
                    icon: const Icon(Icons.send_rounded,
                        color: _kAmber, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TermLine('Nova Agent Terminal', color: _kAmber, bold: true),
          _TermLine('─────────────────────────────', color: Color(0xFF2A2218)),
          _TermLine(''),
          _TermLine('Quick commands:', color: _kGreen),
          _TermLine('  novax --version   — check version'),
          _TermLine('  novax tools       — list 27 tools'),
          _TermLine('  novax ask "..."   — one-shot query'),
          _TermLine(''),
          _TermLine('Type any shell command below.'),
        ],
      ),
    );
  }
}

class _TermLine extends StatelessWidget {
  final String text;
  final Color  color;
  final bool   bold;

  const _TermLine(this.text, {
    this.color = const Color(0xFFCCCCDD),
    this.bold  = false,
  });

  @override
  Widget build(BuildContext context) {
    Color c = color;
    if (text.startsWith('\$')) {
      c = const Color(0xFF72AE8A);
    } else if (text.contains('Error') || text.contains('ERROR')) {
      c = const Color(0xFFEF4444);
    } else if (text.contains('WARN')) {
      c = const Color(0xFFEBBA60);
    }
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.6,
        color: c,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kAmber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kAmber.withOpacity(0.25)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: _kAmber)),
        ),
      );
}

