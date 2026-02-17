import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cx_controller/models/telemetry.dart';
import 'package:cx_controller/services/telemetry_service.dart';

void main() {
  group('TelemetryService', () {
    late TelemetryService service;
    late StreamController<Map<String, dynamic>> controller;

    setUp(() {
      service = TelemetryService();
      controller = StreamController<Map<String, dynamic>>.broadcast();
      service.listenTo(controller.stream);
    });

    tearDown(() {
      service.dispose();
      controller.close();
    });

    test('initial state has no data', () {
      expect(service.latest, isNull);
      expect(service.history, isEmpty);
      expect(service.alerts, isEmpty);
    });

    test('processes telemetry messages', () {
      controller.add({
        'type': 'telemetry',
        'ts': 1000,
        'attitude': {'roll': 1.0, 'pitch': 2.0, 'yaw': 3.0},
        'altitude': 1.5,
        'battery': {'voltage': 11.0, 'percent': 75, 'current': 2.0},
        'position': {'x': 0.0, 'y': 0.0, 'z': 1.5},
        'armed': false,
        'mode': 'manual',
        'sensors': {'temp': 22.0, 'humidity': 50.0, 'dust_pm25': 10.0},
      });

      // Stream is async, need to wait
      expectLater(
        Stream.fromFuture(Future.delayed(Duration.zero, () => service.latest)),
        emits(isA<TelemetryData>()),
      );
    });

    test('processes alert messages', () async {
      controller.add({
        'type': 'alert',
        'level': 'warning',
        'message': 'Low battery',
        'ts': 2000,
      });

      await Future.delayed(Duration.zero);
      expect(service.alerts.length, 1);
      expect(service.alerts.first.message, 'Low battery');
      expect(service.alerts.first.isError, false);
    });

    test('clearAlerts removes all alerts', () async {
      controller.add({
        'type': 'alert',
        'level': 'error',
        'message': 'Connection lost',
        'ts': 3000,
      });

      await Future.delayed(Duration.zero);
      expect(service.alerts.length, 1);

      service.clearAlerts();
      expect(service.alerts, isEmpty);
    });

    test('ignores non-telemetry non-alert messages', () async {
      controller.add({
        'type': 'pong',
        'ts': 4000,
      });

      await Future.delayed(Duration.zero);
      expect(service.latest, isNull);
      expect(service.alerts, isEmpty);
    });

    test('history has max size', () async {
      for (int i = 0; i < 650; i++) {
        controller.add({
          'type': 'telemetry',
          'ts': i,
          'attitude': {'roll': 0.0, 'pitch': 0.0, 'yaw': 0.0},
          'altitude': 0.0,
          'battery': {'voltage': 11.0, 'percent': 80, 'current': 1.0},
          'position': {'x': 0.0, 'y': 0.0, 'z': 0.0},
          'armed': false,
          'mode': 'manual',
          'sensors': {'temp': 20.0, 'humidity': 40.0, 'dust_pm25': 5.0},
        });
      }

      await Future.delayed(Duration.zero);
      expect(service.history.length, lessThanOrEqualTo(600));
    });

    test('reset clears everything', () async {
      controller.add({
        'type': 'telemetry',
        'ts': 5000,
        'attitude': {'roll': 0.0, 'pitch': 0.0, 'yaw': 0.0},
        'altitude': 1.0,
        'battery': {'voltage': 11.0, 'percent': 80, 'current': 1.0},
        'position': {'x': 0.0, 'y': 0.0, 'z': 1.0},
        'armed': false,
        'mode': 'manual',
        'sensors': {'temp': 20.0, 'humidity': 40.0, 'dust_pm25': 5.0},
      });
      controller.add({
        'type': 'alert',
        'level': 'warning',
        'message': 'test',
        'ts': 5001,
      });

      await Future.delayed(Duration.zero);
      expect(service.latest, isNotNull);
      expect(service.alerts, isNotEmpty);

      service.reset();
      expect(service.latest, isNull);
      expect(service.history, isEmpty);
      expect(service.alerts, isEmpty);
    });
  });
}
