import 'package:flutter_test/flutter_test.dart';

import 'package:cx_controller/models/telemetry.dart';
import 'package:cx_controller/models/connection_config.dart';
import 'package:cx_controller/models/drone_command.dart';
import 'package:cx_controller/models/joystick_input.dart';
import 'package:cx_controller/models/mission.dart';

void main() {
  group('Telemetry models', () {
    test('Attitude fromJson', () {
      final json = {'roll': 1.5, 'pitch': -2.3, 'yaw': 180.0};
      final a = Attitude.fromJson(json);
      expect(a.roll, 1.5);
      expect(a.pitch, -2.3);
      expect(a.yaw, 180.0);
    });

    test('BatteryState fromJson and status flags', () {
      final json = {'voltage': 11.2, 'percent': 15, 'current': 3.5};
      final b = BatteryState.fromJson(json);
      expect(b.voltage, 11.2);
      expect(b.percent, 15);
      expect(b.current, 3.5);
      expect(b.isLow, true);
      expect(b.isCritical, false);
    });

    test('BatteryState critical', () {
      final json = {'voltage': 9.8, 'percent': 5, 'current': 0.5};
      final b = BatteryState.fromJson(json);
      expect(b.isCritical, true);
      expect(b.isLow, true);
    });

    test('Position fromJson', () {
      final json = {'x': 1.23, 'y': -0.45, 'z': 2.0};
      final p = Position.fromJson(json);
      expect(p.x, 1.23);
      expect(p.y, -0.45);
      expect(p.z, 2.0);
    });

    test('EnvironmentSensors fromJson', () {
      final json = {'temp': 22.5, 'humidity': 45.0, 'dust_pm25': 12.3};
      final s = EnvironmentSensors.fromJson(json);
      expect(s.temperature, 22.5);
      expect(s.humidity, 45.0);
      expect(s.dustPm25, 12.3);
    });

    test('TelemetryData full round trip', () {
      final json = {
        'ts': 1700000000000,
        'attitude': {'roll': 1.0, 'pitch': -1.0, 'yaw': 90.0},
        'altitude': 2.5,
        'battery': {'voltage': 11.5, 'percent': 80, 'current': 4.0},
        'position': {'x': 0.5, 'y': -0.3, 'z': 2.5},
        'armed': true,
        'mode': 'manual',
        'sensors': {'temp': 23.0, 'humidity': 50.0, 'dust_pm25': 10.0},
      };
      final data = TelemetryData.fromJson(json);
      expect(data.timestamp, 1700000000000);
      expect(data.altitude, 2.5);
      expect(data.armed, true);
      expect(data.mode, 'manual');
      expect(data.attitude.roll, 1.0);
      expect(data.battery.percent, 80);
      expect(data.position.x, 0.5);
      expect(data.sensors.temperature, 23.0);
    });
  });

  group('ConnectionConfig', () {
    test('default values', () {
      const config = ConnectionConfig();
      expect(config.droneIp, '192.168.4.1');
      expect(config.wsPort, 8765);
      expect(config.udpPort, 8766);
      expect(config.rgbCameraPort, 8080);
      expect(config.thermalCameraPort, 8081);
      expect(config.mode, ConnectionMode.rpiAp);
    });

    test('URL builders', () {
      const config = ConnectionConfig(droneIp: '10.0.0.1');
      expect(config.wsUrl, 'ws://10.0.0.1:8765');
      expect(config.rgbStreamUrl, 'http://10.0.0.1:8080/stream');
      expect(config.thermalStreamUrl, 'http://10.0.0.1:8081/stream');
    });

    test('JSON round trip', () {
      const config = ConnectionConfig(
        mode: ConnectionMode.siteWifi,
        droneIp: '172.16.0.5',
        wsPort: 9000,
        udpPort: 9001,
        rgbCameraPort: 9080,
        thermalCameraPort: 9081,
      );
      final json = config.toJson();
      final restored = ConnectionConfig.fromJson(json);
      expect(restored.mode, ConnectionMode.siteWifi);
      expect(restored.droneIp, '172.16.0.5');
      expect(restored.wsPort, 9000);
      expect(restored.udpPort, 9001);
      expect(restored.rgbCameraPort, 9080);
      expect(restored.thermalCameraPort, 9081);
    });

    test('copyWith', () {
      const config = ConnectionConfig();
      final updated = config.copyWith(droneIp: '1.2.3.4');
      expect(updated.droneIp, '1.2.3.4');
      expect(updated.wsPort, 8765); // unchanged
    });
  });

  group('DroneCommand', () {
    test('arm command', () {
      final cmd = DroneCommand.arm(true);
      final json = cmd.toJson();
      expect(json['type'], 'arm');
      expect(json['armed'], true);
      expect(json['ts'], isA<int>());
    });

    test('estop command', () {
      final json = DroneCommand.estop().toJson();
      expect(json['type'], 'estop');
    });

    test('mode command', () {
      final json = DroneCommand.mode('waypoint').toJson();
      expect(json['type'], 'mode');
      expect(json['mode'], 'waypoint');
    });

    test('camera command', () {
      final json = DroneCommand.camera('rgb', 'snapshot').toJson();
      expect(json['type'], 'camera');
      expect(json['camera'], 'rgb');
      expect(json['action'], 'snapshot');
    });

    test('ping command', () {
      final json = DroneCommand.ping().toJson();
      expect(json['type'], 'ping');
    });

    test('mission upload command', () {
      final waypoints = [
        {'id': 1, 'x': 0.0, 'y': 0.0, 'z': 1.5},
      ];
      final json = DroneCommand.missionUpload(waypoints).toJson();
      expect(json['type'], 'mission_upload');
      expect(json['waypoints'], hasLength(1));
    });

    test('mission control command', () {
      final json = DroneCommand.missionCtrl('pause').toJson();
      expect(json['type'], 'mission_ctrl');
      expect(json['action'], 'pause');
    });
  });

  group('JoystickInput', () {
    test('toJson compact format', () {
      const input = JoystickInput(
        roll: 0.5,
        pitch: -0.3,
        throttle: 0.8,
        yaw: 0.1,
      );
      final json = input.toJson();
      expect(json['r'], 0.5);
      expect(json['p'], -0.3);
      expect(json['t'], 0.8);
      expect(json['y'], 0.1);
      expect(json.length, 4);
    });
  });

  group('Mission', () {
    test('Waypoint JSON round trip', () {
      const wp = Waypoint(
        id: 1,
        x: 2.5,
        y: -1.0,
        z: 1.5,
        heading: 90,
        action: WaypointAction.photo,
        holdSeconds: 5,
      );
      final json = wp.toJson();
      final restored = Waypoint.fromJson(json);
      expect(restored.id, 1);
      expect(restored.x, 2.5);
      expect(restored.y, -1.0);
      expect(restored.z, 1.5);
      expect(restored.heading, 90);
      expect(restored.action, WaypointAction.photo);
      expect(restored.holdSeconds, 5);
    });

    test('Waypoint copyWith', () {
      const wp = Waypoint(id: 1, x: 0, y: 0, z: 1.5);
      final moved = wp.copyWith(x: 3.0, y: 2.0);
      expect(moved.x, 3.0);
      expect(moved.y, 2.0);
      expect(moved.z, 1.5); // unchanged
      expect(moved.id, 1);
    });

    test('Waypoint default action is none', () {
      final json = {'id': 1, 'x': 0.0, 'y': 0.0, 'z': 1.0};
      final wp = Waypoint.fromJson(json);
      expect(wp.action, WaypointAction.none);
      expect(wp.holdSeconds, 0);
    });

    test('Mission JSON round trip', () {
      final mission = Mission(
        name: 'Test Flight',
        waypoints: [
          const Waypoint(id: 1, x: 0, y: 0, z: 1.5),
          const Waypoint(
            id: 2,
            x: 3,
            y: 2,
            z: 2.0,
            action: WaypointAction.photoAll,
            holdSeconds: 3,
          ),
        ],
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );
      final json = mission.toJson();
      final restored = Mission.fromJson(json);
      expect(restored.name, 'Test Flight');
      expect(restored.waypoints.length, 2);
      expect(restored.waypoints[1].action, WaypointAction.photoAll);
      expect(restored.waypoints[1].holdSeconds, 3);
      expect(restored.createdAt.year, 2024);
    });

    test('MissionStatus enum values', () {
      expect(MissionStatus.values.length, 7);
      expect(MissionStatus.idle.name, 'idle');
      expect(MissionStatus.running.name, 'running');
    });

    test('WaypointAction enum values', () {
      expect(WaypointAction.values.length, 5);
      expect(WaypointAction.photoAll.name, 'photoAll');
    });
  });
}
