import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gateway_provider.dart';

const _kAmber = Color(0xFFC8946A);

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
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
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
      return const Color(0xFFEBBA60);
    }
    if (line.contains('INFO') || line.contains('✓')) {
      return const Color(0xFF72AE8A);
    }
    return const Color(0xFFCCCCDD);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom_rounded
                  : Icons.pause_rounded,
              color: _autoScroll ? _kAmber : Colors.white54,
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
                  Icon(Icons.history_rounded,
                      size: 48, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 14),
                  Text('No history yet',
                      style: TextStyle(color: Colors.white.withOpacity(0.4))),
                  const SizedBox(height: 8),
                  Text('Chat with Nova Agent to see history here',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.25))),
                ],
              ),
            );
          }

          // Try to parse as JSON conversation history
          try {
            final decoded = jsonDecode(logs);
            if (decoded is List && decoded.isNotEmpty) {
              return _buildConversationView(decoded.cast<Map<String, dynamic>>());
            }
          } catch (_) {}

          // Fallback: raw line-by-line display
          final lines = logs.split('\n');
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: lines.length,
            itemBuilder: (_, i) => Text(
              lines[i],
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.6,
                color: _lineColor(lines[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationView(List<Map<String, dynamic>> entries) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry   = entries[i];
        final role    = (entry['role'] as String? ?? 'unknown').toUpperCase();
        final content = entry['content'] as String? ?? '';
        final isUser  = role == 'USER';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: Text(
                  isUser ? 'YOU' : 'NOVA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isUser ? _kAmber : const Color(0xFF72AE8A),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFFEDE8E2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

