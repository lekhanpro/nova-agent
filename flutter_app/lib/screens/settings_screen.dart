import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../providers/setup_provider.dart';
import '../providers/gateway_provider.dart';
import '../services/native_bridge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, String> _sysInfo = {};
  bool _batteryOptimized = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await NativeBridge.getSystemInfo();
    final battOpt = await NativeBridge.isBatteryOptimized();
    if (mounted) {
      setState(() {
        _sysInfo = info;
        _batteryOptimized = battOpt;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gateway = context.watch<GatewayProvider>();
    final setup   = context.watch<SetupProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auto-start
          _SectionHeader('Behavior'),
          Card(
            child: SwitchListTile(
              title: const Text('Auto-start agent'),
              subtitle: const Text('Start agent when app opens'),
              value: gateway.autoStart,
              onChanged: (v) => gateway.setAutoStart(v),
              activeColor: const Color(0xFF7C3AED),
            ),
          ),

          const SizedBox(height: 16),

          // Battery
          _SectionHeader('Android'),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.battery_alert_rounded,
                color: _batteryOptimized
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
              ),
              title: const Text('Battery Optimization'),
              subtitle: Text(
                _batteryOptimized
                    ? 'Enabled — agent may be killed in background'
                    : 'Disabled — agent can run freely',
                style: TextStyle(
                  color: _batteryOptimized
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                  fontSize: 12,
                ),
              ),
              trailing: _batteryOptimized
                  ? TextButton(
                      onPressed: NativeBridge.openBatterySettings,
                      child: const Text('Fix',
                          style: TextStyle(color: Color(0xFF7C3AED))),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // System info
          _SectionHeader('System Info'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ..._sysInfo.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Text(e.key,
                            style: const TextStyle(
                                color: Color(0xFF6B6B8A), fontSize: 13)),
                        const Spacer(),
                        Text(e.value,
                            style: const TextStyle(
                                fontFamily: 'JetBrainsMono', fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reset
          _SectionHeader('Advanced'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.refresh_rounded, color: Color(0xFFF59E0B)),
              title: const Text('Re-run Setup'),
              subtitle: const Text('Reinstall Ubuntu + AutoGPT'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Re-run Setup?'),
                    content: const Text(
                        'This will re-run the full setup. Existing .env settings are preserved.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Re-run')),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  setup.resetSetup();
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // About
          _SectionHeader('About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _AboutRow('App', '${AppConstants.appName} v${AppConstants.version}'),
                _AboutRow('CLI', AppConstants.cliCommand),
                _AboutRow('Package', AppConstants.npmPackage),
                _AboutRow('GitHub', AppConstants.githubRepo),
              ]),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      );
}

class _AboutRow extends StatelessWidget {
  final String label, value;
  const _AboutRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF6B6B8A), fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}
