import 'dart:math';

import 'package:flutter/material.dart';

import '../models/telemetry.dart';

/// Displays environment sensor data with visual gauges.
class SensorPanel extends StatelessWidget {
  final EnvironmentSensors sensors;

  const SensorPanel({super.key, required this.sensors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SensorGauge(
            icon: Icons.thermostat,
            label: 'Temp',
            value: sensors.temperature,
            unit: 'C',
            min: 0,
            max: 50,
            warningThreshold: 35,
            dangerThreshold: 45,
            color: _tempColor(sensors.temperature),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SensorGauge(
            icon: Icons.water_drop,
            label: 'Humidity',
            value: sensors.humidity,
            unit: '%',
            min: 0,
            max: 100,
            warningThreshold: 70,
            dangerThreshold: 85,
            color: _humidityColor(sensors.humidity),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SensorGauge(
            icon: Icons.air,
            label: 'PM2.5',
            value: sensors.dustPm25,
            unit: 'ug/m3',
            min: 0,
            max: 150,
            warningThreshold: 35,
            dangerThreshold: 75,
            color: _dustColor(sensors.dustPm25),
          ),
        ),
      ],
    );
  }

  Color _tempColor(double temp) {
    if (temp > 45) return Colors.red;
    if (temp > 35) return Colors.orange;
    if (temp < 5) return Colors.blue;
    return Colors.green;
  }

  Color _humidityColor(double humidity) {
    if (humidity > 85) return Colors.red;
    if (humidity > 70) return Colors.orange;
    return Colors.blue.shade300;
  }

  Color _dustColor(double pm25) {
    if (pm25 > 75) return Colors.red;
    if (pm25 > 35) return Colors.orange;
    return Colors.green;
  }
}

class _SensorGauge extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final double warningThreshold;
  final double dangerThreshold;
  final Color color;

  const _SensorGauge({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.warningThreshold,
    required this.dangerThreshold,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 60,
              height: 60,
              child: CustomPaint(
                painter: _ArcGaugePainter(
                  fraction: fraction,
                  color: color,
                  trackColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;

  _ArcGaugePainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    const startAngle = 0.75 * pi;
    const sweepAngle = 1.5 * pi;
    const strokeWidth = 6.0;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fraction,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return fraction != oldDelegate.fraction || color != oldDelegate.color;
  }
}
