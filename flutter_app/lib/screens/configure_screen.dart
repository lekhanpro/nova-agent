import 'package:flutter/material.dart';

/// Configure screen — shows novax configure command info and API key docs.
class ConfigureScreen extends StatelessWidget {
  const ConfigureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('API Keys',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Run the interactive wizard from Termux:',
            style: TextStyle(color: Colors.white.withOpacity(0.55)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D2D4E)),
            ),
            child: const Text(
              'novax configure',
              style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                  color: Color(0xFF7C3AED)),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Supported Providers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...[
            _Provider(
              name: 'OpenAI',
              models: 'gpt-4o, gpt-4o-mini',
              envKey: 'OPENAI_API_KEY',
              url: 'platform.openai.com',
              color: const Color(0xFF10A37F),
            ),
            _Provider(
              name: 'Anthropic',
              models: 'claude-3-5-sonnet, claude-3-haiku',
              envKey: 'ANTHROPIC_API_KEY',
              url: 'console.anthropic.com',
              color: const Color(0xFFD97706),
            ),
            _Provider(
              name: 'Google Gemini',
              models: 'gemini-1.5-flash, gemini-1.5-pro',
              envKey: 'GOOGLE_API_KEY',
              url: 'aistudio.google.com',
              color: const Color(0xFF4285F4),
            ),
          ],
        ],
      ),
    );
  }
}

class _Provider extends StatelessWidget {
  final String name, models, envKey, url;
  final Color color;

  const _Provider({
    required this.name,
    required this.models,
    required this.envKey,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            Text('Models: $models',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B6B8A))),
            Text('Env var: $envKey',
                style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: Color(0xFF7C3AED))),
            Text(url,
                style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
