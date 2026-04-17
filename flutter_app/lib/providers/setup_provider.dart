import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/bootstrap_service.dart';

enum SetupStatus { idle, running, done, error }

class SetupProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final BootstrapService _bootstrap = BootstrapService();

  SetupStatus _status = SetupStatus.idle;
  int _currentStep   = 0;
  String _stepLog    = '';
  String _errorMsg   = '';
  bool _setupDone    = false;

  SetupProvider(this._prefs) {
    _setupDone = _prefs.getBool(AppConstants.prefSetupDone) ?? false;
  }

  SetupStatus get status      => _status;
  int         get currentStep => _currentStep;
  String      get stepLog     => _stepLog;
  String      get errorMsg    => _errorMsg;
  bool        get setupDone   => _setupDone;
  int         get totalSteps  => AppConstants.setupSteps.length;

  double get progress =>
      _status == SetupStatus.done ? 1.0 : _currentStep / totalSteps;

  Future<void> runSetup() async {
    _status      = SetupStatus.running;
    _currentStep = 0;
    _errorMsg    = '';
    notifyListeners();

    try {
      await _bootstrap.run(
        onStep: (step, log) {
          _currentStep = step;
          _stepLog     = log;
          notifyListeners();
        },
        onError: (e) {
          _errorMsg = e;
          _status   = SetupStatus.error;
          notifyListeners();
        },
      );

      if (_status != SetupStatus.error) {
        _status    = SetupStatus.done;
        _setupDone = true;
        await _prefs.setBool(AppConstants.prefSetupDone, true);
        notifyListeners();
      }
    } catch (e) {
      _errorMsg = e.toString();
      _status   = SetupStatus.error;
      notifyListeners();
    }
  }

  void resetSetup() {
    _status    = SetupStatus.idle;
    _setupDone = false;
    _prefs.remove(AppConstants.prefSetupDone);
    notifyListeners();
  }
}
