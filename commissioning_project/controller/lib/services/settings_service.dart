import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/connection_config.dart';

class SettingsService extends ChangeNotifier {
  ConnectionConfig _connectionConfig = const ConnectionConfig();
  double _maxAltitude = 3.0;
  double _maxSpeed = 1.0;
  double _joystickDeadzone = 0.05;
  bool _joystickLeftThrottle = true;

  static const String _keyConnection = 'connection_config';
  static const String _keyMaxAltitude = 'max_altitude';
  static const String _keyMaxSpeed = 'max_speed';
  static const String _keyDeadzone = 'joystick_deadzone';
  static const String _keyLeftThrottle = 'joystick_left_throttle';

  ConnectionConfig get connectionConfig => _connectionConfig;
  double get maxAltitude => _maxAltitude;
  double get maxSpeed => _maxSpeed;
  double get joystickDeadzone => _joystickDeadzone;
  bool get joystickLeftThrottle => _joystickLeftThrottle;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final connJson = prefs.getString(_keyConnection);
    if (connJson != null) {
      try {
        _connectionConfig = ConnectionConfig.fromJson(
            jsonDecode(connJson) as Map<String, dynamic>);
      } catch (_) {
        // Corrupted settings, use defaults
      }
    }

    _maxAltitude = prefs.getDouble(_keyMaxAltitude) ?? 3.0;
    _maxSpeed = prefs.getDouble(_keyMaxSpeed) ?? 1.0;
    _joystickDeadzone = prefs.getDouble(_keyDeadzone) ?? 0.05;
    _joystickLeftThrottle = prefs.getBool(_keyLeftThrottle) ?? true;

    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyConnection, jsonEncode(_connectionConfig.toJson()));
    await prefs.setDouble(_keyMaxAltitude, _maxAltitude);
    await prefs.setDouble(_keyMaxSpeed, _maxSpeed);
    await prefs.setDouble(_keyDeadzone, _joystickDeadzone);
    await prefs.setBool(_keyLeftThrottle, _joystickLeftThrottle);
  }

  void updateConnectionConfig(ConnectionConfig config) {
    _connectionConfig = config;
    notifyListeners();
    save();
  }

  void updateMaxAltitude(double value) {
    _maxAltitude = value;
    notifyListeners();
    save();
  }

  void updateMaxSpeed(double value) {
    _maxSpeed = value;
    notifyListeners();
    save();
  }

  void updateJoystickDeadzone(double value) {
    _joystickDeadzone = value;
    notifyListeners();
    save();
  }

  void updateJoystickLeftThrottle(bool value) {
    _joystickLeftThrottle = value;
    notifyListeners();
    save();
  }
}
