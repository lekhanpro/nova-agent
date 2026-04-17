import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/gateway_provider.dart';
import '../providers/setup_provider.dart';
import 'terminal_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';
import 'configure_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  static const _tabs = ['Dashboard', 'Terminal', 'Logs', 'Settings'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.terminal_rounded,
    Icons.subject_rounded,
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
      _HomeTab(onSwitchTab: (i) => setState(() => _tab = i)),
      const TerminalScreen(),
      const LogsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: const Color(0xFF0F0F1A),
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF7C3AED).withOpacity(0.2),
        destinations: List.generate(
          _tabs.length,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            label: _tabs[i],
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final void Function(int) onSwitchTab;
  const _HomeTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nova Agent',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('AutoGPT on Android',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF6B6B8A))),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => onSwitchTab(3),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ),

          // Status card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer<GatewayProvider>(
                builder: (_, gateway, __) => _StatusCard(gateway: gateway),
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.terminal_rounded,
                          label: 'Terminal',
                          color: const Color(0xFF059669),
                          onTap: () => onSwitchTab(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.subject_rounded,
                          label: 'Live Logs',
                          color: const Color(0xFF2563EB),
                          onTap: () => onSwitchTab(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.tune_rounded,
                          label: 'Configure',
                          color: const Color(0xFFD97706),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ConfigureScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Web dashboard card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    const Icon(Icons.web_rounded, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Web Dashboard',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(AppConstants.webDashboard,
                              style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 13,
                                  fontFamily: 'JetBrainsMono')),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ]),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ── Status Card ───────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final GatewayProvider gateway;
  const _StatusCard({required this.gateway});

  @override
  Widget build(BuildContext context) {
    final running = gateway.isRunning;
    final color   = running ? const Color(0xFF22C55E) : const Color(0xFF6B6B8A);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: running
              ? [const Color(0xFF0D2D1A), const Color(0xFF0F1F2E)]
              : [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: running
                    ? [BoxShadow(color: color, blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(running ? 'Agent Running' : 'Agent Stopped',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: gateway.status == AgentStatus.starting
                    ? null
                    : running
                        ? () => context.read<GatewayProvider>().stopAgent()
                        : () => context.read<GatewayProvider>().startAgent(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: running
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF7C3AED),
                ),
                icon: gateway.status == AgentStatus.starting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(running
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded),
                label: Text(
                  gateway.status == AgentStatus.starting
                      ? 'Starting...'
                      : running
                          ? 'Stop Agent'
                          : 'Start Agent',
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }
}
