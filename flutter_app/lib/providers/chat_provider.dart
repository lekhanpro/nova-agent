import 'package:flutter/material.dart';
import '../services/gateway_service.dart';

class ChatMessage {
  final String role; // 'user', 'assistant', 'tool'
  final String content;
  final List<String> toolCalls;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.toolCalls = const [],
    required this.timestamp,
  });
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool    _isLoading = false;
  String? _error;

  List<ChatMessage> get messages  => List.unmodifiable(_messages);
  bool              get isLoading => _isLoading;
  String?           get error     => _error;

  Future<void> sendMessage(String text) async {
    _messages.add(ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final rawResponse = await GatewayService.ask(text);
      // Parse tool calls from output (lines starting with ⚙ or containing "Calling")
      final toolCalls     = <String>[];
      final responseLines = <String>[];
      for (final line in rawResponse.split('\n')) {
        if (line.startsWith('⚙') || line.contains('Calling ')) {
          toolCalls.add(line.trim());
        } else if (line.trim().isNotEmpty &&
            !line.startsWith('Nova Agent') &&
            !line.startsWith('>')) {
          responseLines.add(line);
        }
      }
      final response = responseLines.join('\n').trim();
      _messages.add(ChatMessage(
        role: 'assistant',
        content: response.isNotEmpty ? response : rawResponse,
        toolCalls: toolCalls,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _error = e.toString();
      _messages.add(ChatMessage(
        role: 'assistant',
        content: 'Error: ${e.toString()}',
        timestamp: DateTime.now(),
      ));
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearHistory() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
