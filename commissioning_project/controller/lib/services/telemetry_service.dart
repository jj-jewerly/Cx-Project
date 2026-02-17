import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/telemetry.dart';

class AlertMessage {
  final String level;
  final String message;
  final int timestamp;

  const AlertMessage({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  factory AlertMessage.fromJson(Map<String, dynamic> json) => AlertMessage(
        level: json['level'] as String,
        message: json['message'] as String,
        timestamp: json['ts'] as int,
      );

  bool get isError => level == 'error';
}

class TelemetryService extends ChangeNotifier {
  TelemetryData? _latest;
  final Queue<TelemetryData> _history = Queue<TelemetryData>();
  final List<AlertMessage> _alerts = [];
  StreamSubscription<Map<String, dynamic>>? _subscription;

  static const int maxHistorySize = 600;

  TelemetryData? get latest => _latest;
  List<TelemetryData> get history => _history.toList();
  List<AlertMessage> get alerts => List.unmodifiable(_alerts);

  void listenTo(Stream<Map<String, dynamic>> messageStream) {
    _subscription?.cancel();
    _subscription = messageStream.listen(_onMessage);
  }

  void _onMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;

    if (type == 'telemetry') {
      _latest = TelemetryData.fromJson(msg);
      _history.addLast(_latest!);
      while (_history.length > maxHistorySize) {
        _history.removeFirst();
      }
      notifyListeners();
    } else if (type == 'alert') {
      _alerts.insert(0, AlertMessage.fromJson(msg));
      if (_alerts.length > 50) {
        _alerts.removeLast();
      }
      notifyListeners();
    }
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  void reset() {
    _latest = null;
    _history.clear();
    _alerts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
