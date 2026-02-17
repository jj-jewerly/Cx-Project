class Attitude {
  final double roll;
  final double pitch;
  final double yaw;

  const Attitude({required this.roll, required this.pitch, required this.yaw});

  factory Attitude.fromJson(Map<String, dynamic> json) => Attitude(
        roll: (json['roll'] as num).toDouble(),
        pitch: (json['pitch'] as num).toDouble(),
        yaw: (json['yaw'] as num).toDouble(),
      );

  static const zero = Attitude(roll: 0, pitch: 0, yaw: 0);
}

class BatteryState {
  final double voltage;
  final int percent;
  final double current;

  const BatteryState({
    required this.voltage,
    required this.percent,
    required this.current,
  });

  factory BatteryState.fromJson(Map<String, dynamic> json) => BatteryState(
        voltage: (json['voltage'] as num).toDouble(),
        percent: (json['percent'] as num).toInt(),
        current: (json['current'] as num).toDouble(),
      );

  bool get isLow => percent < 20;
  bool get isCritical => percent < 10;

  static const unknown =
      BatteryState(voltage: 0, percent: 0, current: 0);
}

class Position {
  final double x;
  final double y;
  final double z;

  const Position({required this.x, required this.y, required this.z});

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        z: (json['z'] as num).toDouble(),
      );

  static const zero = Position(x: 0, y: 0, z: 0);
}

class EnvironmentSensors {
  final double temperature;
  final double humidity;
  final double dustPm25;

  const EnvironmentSensors({
    required this.temperature,
    required this.humidity,
    required this.dustPm25,
  });

  factory EnvironmentSensors.fromJson(Map<String, dynamic> json) =>
      EnvironmentSensors(
        temperature: (json['temp'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        dustPm25: (json['dust_pm25'] as num).toDouble(),
      );

  static const zero =
      EnvironmentSensors(temperature: 0, humidity: 0, dustPm25: 0);
}

class TelemetryData {
  final int timestamp;
  final Attitude attitude;
  final double altitude;
  final BatteryState battery;
  final Position position;
  final bool armed;
  final String mode;
  final EnvironmentSensors sensors;

  const TelemetryData({
    required this.timestamp,
    required this.attitude,
    required this.altitude,
    required this.battery,
    required this.position,
    required this.armed,
    required this.mode,
    required this.sensors,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) => TelemetryData(
        timestamp: json['ts'] as int,
        attitude: Attitude.fromJson(json['attitude'] as Map<String, dynamic>),
        altitude: (json['altitude'] as num).toDouble(),
        battery:
            BatteryState.fromJson(json['battery'] as Map<String, dynamic>),
        position:
            Position.fromJson(json['position'] as Map<String, dynamic>),
        armed: json['armed'] as bool,
        mode: json['mode'] as String,
        sensors: EnvironmentSensors.fromJson(
            json['sensors'] as Map<String, dynamic>),
      );
}
