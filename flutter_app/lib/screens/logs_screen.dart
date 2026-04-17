import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gateway_provider.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  Timer? _timer;
  final ScrollController _scroll = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  void _refresh() {
    context.read<GatewayProvider>().refreshLogs().then((_) {
      if (_autoScroll && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Color _lineColor(String line) {
    if (line.contains('ERROR') || line.contains('Error')) {
      return const Color(0xFFEF4444);
    }
    if (line.contains('WARNING') || line.contains('WARN')) {
      return const Color(0xFFF59E0B);
    }
    if (line.contains('INFO') || line.contains('✓')) {
      return const Color(0xFF22C55E);
    }
    return const Color(0xFFCCCCDD);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Logs'),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom_rounded
                  : Icons.pause_rounded,
              color: _autoScroll
                  ? const Color(0xFF7C3AED)
                  : Colors.white54,
            ),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Consumer<GatewayProvider>(
        builder: (_, gateway, __) {
          final logs = gateway.logs;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.subject_rounded,
                      size: 48, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 14),
                  Text('No logs yet',
                      style: TextStyle(color: Colors.white.withOpacity(0.4))),
                  const SizedBox(height: 8),
                  Text('Start the agent to see output here',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.25))),
                ],
              ),
            );
          }

          final lines = logs.split('\n');
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: lines.length,
            itemBuilder: (_, i) {
              final line = lines[i];
              return Text(
                line,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  height: 1.6,
                  color: _lineColor(line),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
