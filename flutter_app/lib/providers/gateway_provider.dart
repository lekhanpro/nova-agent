import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/gateway_service.dart';

enum AgentStatus { stopped, starting, running, error }

class GatewayProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final GatewayService _gateway = GatewayService();

  AgentStatus _status   = AgentStatus.stopped;
  String      _logs     = '';
  bool        _webUp    = false;
  String      _errorMsg = '';

  GatewayProvider(this._prefs);

  AgentStatus get status   => _status;
  String      get logs     => _logs;
  bool        get webUp    => _webUp;
  String      get errorMsg => _errorMsg;
  bool        get isRunning => _status == AgentStatus.running;

  bool get autoStart => _prefs.getBool(AppConstants.prefAutoStart) ?? false;

  Future<void> setAutoStart(bool val) async {
    await _prefs.setBool(AppConstants.prefAutoStart, val);
    notifyListeners();
  }

  Future<void> startAgent() async {
    _status   = AgentStatus.starting;
    _errorMsg = '';
    notifyListeners();
    try {
      await _gateway.start();
      _status = AgentStatus.running;
      _webUp  = true;
    } catch (e) {
      _errorMsg = e.toString();
      _status   = AgentStatus.error;
    }
    notifyListeners();
  }

  Future<void> stopAgent() async {
    try {
      await _gateway.stop();
    } catch (_) {}
    _status = AgentStatus.stopped;
    _webUp  = false;
    notifyListeners();
  }

  Future<void> restartAgent() async {
    await stopAgent();
    await Future.delayed(const Duration(seconds: 1));
    await startAgent();
  }

  Future<void> refreshLogs() async {
    try {
      _logs = await _gateway.fetchLogs();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> checkStatus() async {
    try {
      final running = await _gateway.isRunning();
      _status = running ? AgentStatus.running : AgentStatus.stopped;
      _webUp  = running;
      notifyListeners();
    } catch (_) {}
  }
}
