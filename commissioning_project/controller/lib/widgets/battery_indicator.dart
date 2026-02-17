import 'package:flutter/material.dart';

import '../models/telemetry.dart';

class BatteryIndicator extends StatelessWidget {
  final BatteryState battery;

  const BatteryIndicator({super.key, required this.battery});

  @override
  Widget build(BuildContext context) {
    final color = battery.isCritical
        ? Colors.red
        : battery.isLow
            ? Colors.orange
            : Colors.green;

    final icon = battery.isCritical
        ? Icons.battery_alert
        : battery.isLow
            ? Icons.battery_2_bar
            : battery.percent > 80
                ? Icons.battery_full
                : Icons.battery_5_bar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${battery.percent}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '${battery.voltage.toStringAsFixed(1)}V',
              style: TextStyle(
                color: color.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
