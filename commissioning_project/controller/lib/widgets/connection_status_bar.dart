import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/connection_service.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, conn, _) {
        final (color, icon, label) = switch (conn.state) {
          DroneConnectionState.connected => (
              Colors.green,
              Icons.wifi,
              'Connected (${conn.latencyMs}ms)'
            ),
          DroneConnectionState.degraded => (
              Colors.orange,
              Icons.wifi_1_bar,
              'Degraded'
            ),
          DroneConnectionState.connecting => (
              Colors.blue,
              Icons.sync,
              'Connecting...'
            ),
          DroneConnectionState.lost => (
              Colors.red,
              Icons.wifi_off,
              'Connection Lost'
            ),
          DroneConnectionState.disconnected => (
              Colors.grey,
              Icons.wifi_off,
              'Disconnected'
            ),
        };

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: color.withAlpha(40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
