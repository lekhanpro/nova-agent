import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gateway_provider.dart';
import 'chat_screen.dart';
import 'terminal_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

const _kAmber   = Color(0xFFC8946A);
const _kBg      = Color(0xFF0B0907);
const _kBorder  = Color(0xFF2A2218);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  static const _tabs  = ['Chat', 'Terminal', 'History', 'Settings'];
  static const _icons = [
    Icons.chat_bubble_outline_rounded,
    Icons.terminal_rounded,
    Icons.history_rounded,
    Icons.settings_rounded,
  ];
  static const _activeIcons = [
    Icons.chat_bubble_rounded,
    Icons.terminal_rounded,
    Icons.history_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GatewayProvider>().checkStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ChatScreen(),
      const TerminalScreen(),
      const LogsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _kAmber.withOpacity(0.15),
        destinations: List.generate(
          _tabs.length,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_activeIcons[i], color: _kAmber),
            label: _tabs[i],
          ),
        ),
      ),
    );
  }
}

