import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../services/gateway_service.dart';

const _kAmber   = Color(0xFFC8946A);
const _kBorder  = Color(0xFF2A2218);
const _kSurface = Color(0xFF141210);
const _kBg      = Color(0xFF0B0907);
const _kMuted   = Color(0xFF6E6458);
const _kPrimary = Color(0xFFEDE8E2);

/// Configure Nova Agent — provider, model, and API key form.
class ConfigureScreen extends StatefulWidget {
  const ConfigureScreen({super.key});

  @override
  State<ConfigureScreen> createState() => _ConfigureScreenState();
}

class _ConfigureScreenState extends State<ConfigureScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _apiKeyCtrl = TextEditingController();

  String _provider    = 'gemini';
  String _model       = 'gemini-2.0-flash';
  bool   _obscureKey  = true;
  bool   _isSaving    = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProvider = prefs.getString(AppConstants.prefProvider) ?? 'gemini';
    final providerData = AppConstants.providers.firstWhere(
      (p) => p['id'] == savedProvider,
      orElse: () => AppConstants.providers.first,
    );
    setState(() {
      _provider = savedProvider;
      _model    = prefs.getString(AppConstants.prefModel) ??
          (providerData['default'] as String);
    });
  }

  void _onProviderChange(String? value) {
    if (value == null) return;
    final providerData = AppConstants.providers.firstWhere(
      (p) => p['id'] == value,
      orElse: () => AppConstants.providers.first,
    );
    setState(() {
      _provider = value;
      _model    = providerData['default'] as String;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await GatewayService.writeConfig(
        provider: _provider,
        model:    _model,
        apiKey:   _apiKeyCtrl.text.trim(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefProvider, _provider);
      await prefs.setString(AppConstants.prefModel, _model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Configuration saved'),
            backgroundColor: Color(0xFF72AE8A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProvider = AppConstants.providers.firstWhere(
      (p) => p['id'] == _provider,
      orElse: () => AppConstants.providers.first,
    );
    final models = (currentProvider['models'] as List).cast<String>();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: const Text('Configure Nova Agent',
            style: TextStyle(color: _kPrimary)),
        iconTheme: const IconThemeData(color: _kPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Provider selector
            _Label('AI Provider'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _provider,
              decoration: _inputDecor('Select provider'),
              dropdownColor: _kSurface,
              style: const TextStyle(color: _kPrimary, fontSize: 14),
              items: AppConstants.providers.map((p) {
                final isFree = p['free'] as bool;
                return DropdownMenuItem<String>(
                  value: p['id'] as String,
                  child: Row(children: [
                    Text(p['name'] as String),
                    if (isFree) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF72AE8A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFF72AE8A).withOpacity(0.5)),
                        ),
                        child: const Text('FREE',
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF72AE8A),
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                );
              }).toList(),
              onChanged: _onProviderChange,
            ),

            const SizedBox(height: 20),

            // Model selector
            _Label('Model'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: models.contains(_model) ? _model : models.first,
              decoration: _inputDecor('Select model'),
              dropdownColor: _kSurface,
              style: const TextStyle(color: _kPrimary, fontSize: 14),
              items: models
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _model = v ?? _model),
            ),

            const SizedBox(height: 20),

            // API key field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Label('API Key'),
                TextButton.icon(
                  onPressed: () =>
                      _openUrl(currentProvider['url'] as String),
                  icon: const Icon(Icons.open_in_new_rounded,
                      size: 14, color: _kAmber),
                  label: const Text('Get API Key',
                      style: TextStyle(fontSize: 12, color: _kAmber)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _apiKeyCtrl,
              obscureText: _obscureKey,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  color: _kPrimary,
                  fontSize: 13),
              decoration: _inputDecor(
                'Enter ${currentProvider['envKey']}',
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: _kMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'API key is required' : null,
            ),

            const SizedBox(height: 12),

            // Hint text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kAmber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kAmber.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: _kAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Config is saved to ~/.nova_agent/config on your device.',
                      style: TextStyle(
                          fontSize: 12,
                          color: _kPrimary.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAmber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Save Configuration',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
        filled: true,
        fillColor: _kSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kAmber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPrimary),
      );
}

