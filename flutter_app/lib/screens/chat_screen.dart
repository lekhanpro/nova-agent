import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/chat_provider.dart';
import '../providers/gateway_provider.dart';
import 'configure_screen.dart';

const _kAmber     = Color(0xFFC8946A);
const _kGreen     = Color(0xFF72AE8A);
const _kRed       = Color(0xFFEF4444);
const _kSurface   = Color(0xFF141210);
const _kBorder    = Color(0xFF2A2218);
const _kMuted     = Color(0xFF6E6458);
const _kSecondary = Color(0xFFB8B0A6);
const _kPrimary   = Color(0xFFEDE8E2);
const _kBg        = Color(0xFF0B0907);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    context.read<ChatProvider>().sendMessage(text).then((_) => _scrollToBottom());
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        title: Row(
          children: [
            const Text(
              'Nova Agent',
              style: TextStyle(
                color: _kPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Consumer<GatewayProvider>(
              builder: (_, gw, __) {
                final running = gw.isRunning;
                return Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: running ? _kGreen : _kMuted,
                      boxShadow: running
                          ? [BoxShadow(color: _kGreen.withOpacity(0.5), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    running ? 'online' : 'offline',
                    style: TextStyle(
                      fontSize: 11,
                      color: running ? _kGreen : _kMuted,
                    ),
                  ),
                ]);
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: _kSecondary),
            tooltip: 'Configure',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConfigureScreen()),
            ),
          ),
          Consumer<ChatProvider>(
            builder: (_, chat, __) => IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: _kSecondary),
              tooltip: 'Clear chat',
              onPressed: chat.messages.isEmpty ? null : () => chat.clearHistory(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message list
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (_, chat, __) {
                  if (chat.messages.isEmpty) {
                    return _EmptyState(onSuggestion: (s) {
                      _inputCtrl.text = s;
                      _send();
                    });
                  }
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount:
                        chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == chat.messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(msg: chat.messages[i]);
                    },
                  );
                },
              ),
            ),
            // Input area
            _InputBar(
              controller: _inputCtrl,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state with suggestions ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _EmptyState({required this.onSuggestion});

  static const _suggestions = [
    "What's the weather?",
    'Take a photo',
    'My battery level',
    'List my files',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kSurface,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 40, color: _kAmber),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ask Nova Agent anything',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Access 27 Android sensors with AI',
              style: TextStyle(
                  fontSize: 13, color: _kSecondary.withOpacity(0.7)),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => ActionChip(
                        label: Text(s,
                            style: const TextStyle(
                                fontSize: 12, color: _kAmber)),
                        backgroundColor: _kAmber.withOpacity(0.08),
                        side: const BorderSide(
                            color: _kAmber, width: 0.5),
                        onPressed: () => onSuggestion(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final time = '${msg.timestamp.hour.toString().padLeft(2, '0')}:'
        '${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _kAmber.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      size: 14, color: _kAmber),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? _kAmber.withOpacity(0.15)
                        : _kSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? _kAmber.withOpacity(0.3)
                          : _kBorder,
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _kPrimary),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          // Tool call chips
          if (msg.toolCalls.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(left: isUser ? 0 : 36),
              child: Wrap(
                spacing: 6,
                children: msg.toolCalls.map((t) => Chip(
                  label: Text(t,
                      style: const TextStyle(
                          fontSize: 10, color: _kSecondary)),
                  backgroundColor: _kSurface,
                  side: const BorderSide(color: _kBorder),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ),
          ],
          // Timestamp
          Padding(
            padding: EdgeInsets.only(
                top: 4,
                left: isUser ? 0 : 36,
                right: isUser ? 8 : 0),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: _kMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _kAmber.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                size: 14, color: _kAmber),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _kBorder),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final t = (_ctrl.value - delay).clamp(0.0, 1.0);
                    final opacity = (1.0 - (t - 0.5).abs() * 2).clamp(0.2, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _kAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Consumer<ChatProvider>(
        builder: (_, chat, __) => Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !chat.isLoading,
                style: const TextStyle(color: _kPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: chat.isLoading
                      ? 'Nova is thinking...'
                      : 'Ask Nova anything...',
                  hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
                  filled: true,
                  fillColor: _kBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: _kAmber, width: 1.5),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: chat.isLoading
                    ? _kMuted
                    : _kAmber,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: chat.isLoading ? null : onSend,
                icon: chat.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white),
                iconSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
