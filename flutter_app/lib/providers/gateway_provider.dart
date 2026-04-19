import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/gateway_service.dart';

enum AgentStatus { stopped, starting, running, error }

class GatewayProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  AgentStatus _status       = AgentStatus.stopped;
  bool        _isInstalled  = false;
  String      _logs         = '';
  List<Map<String, dynamic>> _chatHistory = [];
  String      _errorMsg     = '';

  GatewayProvider(this._prefs);

  AgentStatus get status      => _status;
  bool        get isInstalled => _isInstalled;
  bool        get isRunning   => _status == AgentStatus.running;
  String      get logs        => _logs;
  List<Map<String, dynamic>> get chatHistory => List.unmodifiable(_chatHistory);
  String      get errorMsg    => _errorMsg;

  bool get autoStart => _prefs.getBool(AppConstants.prefAutoStart) ?? false;

  Future<void> setAutoStart(bool val) async {
    await _prefs.setBool(AppConstants.prefAutoStart, val);
    notifyListeners();
  }

  Future<void> checkStatus() async {
    try {
      _isInstalled = await GatewayService.isInstalled();
      final running = await GatewayService.isRunning();
      _status = running ? AgentStatus.running : AgentStatus.stopped;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> startAgent() async {
    _status   = AgentStatus.starting;
    _errorMsg = '';
    notifyListeners();
    try {
      await GatewayService.startAgent();
      _status = AgentStatus.running;
    } catch (e) {
      _errorMsg = e.toString();
      _status   = AgentStatus.error;
    }
    notifyListeners();
  }

  Future<void> stopAgent() async {
    try {
      await GatewayService.stopAgent();
    } catch (_) {}
    _status = AgentStatus.stopped;
    notifyListeners();
  }

  Future<String> ask(String query) async {
    return GatewayService.ask(query);
  }

  Future<void> refreshLogs() async {
    try {
      _logs = await GatewayService.getLogs();
      // Try to parse as JSON array
      try {
        final decoded = jsonDecode(_logs);
        if (decoded is List) {
          _chatHistory = decoded.cast<Map<String, dynamic>>();
        }
      } catch (_) {
        _chatHistory = [];
      }
      notifyListeners();
    } catch (_) {}
  }
}

