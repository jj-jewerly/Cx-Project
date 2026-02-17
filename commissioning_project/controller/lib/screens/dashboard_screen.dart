import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drone_command.dart';
import '../services/connection_service.dart';
import '../services/settings_service.dart';
import '../services/telemetry_service.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/sensor_panel.dart';
import '../widgets/telemetry_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ConnectionService, TelemetryService, SettingsService>(
      builder: (context, conn, telemetry, settings, _) {
        final data = telemetry.latest;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectionCard(context, conn, settings),
              const SizedBox(height: 16),
              if (data != null) ...[
                _buildStatusRow(context, data, conn),
                const SizedBox(height: 16),
                SensorPanel(sensors: data.sensors),
                const SizedBox(height: 16),
                _buildTelemetryGrid(context, data),
                const SizedBox(height: 16),
              ],
              _buildAlertsList(context, telemetry),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionCard(
      BuildContext context, ConnectionService conn, SettingsService settings) {

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drone Connection',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.connectionConfig.droneIp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                if (conn.isConnected ||
                    conn.state == DroneConnectionState.connecting) {
                  conn.disconnect();
                } else {
                  conn.connect(settings.connectionConfig);
                }
              },
              icon: Icon(conn.isConnected ? Icons.link_off : Icons.link),
              label: Text(conn.isConnected ? 'Disconnect' : 'Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      BuildContext context, dynamic data, ConnectionService conn) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            BatteryIndicator(battery: data.battery),
            const SizedBox(width: 24),
            _buildModeChip(context, data.mode),
            const SizedBox(width: 24),
            _buildArmChip(context, data.armed, conn),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(BuildContext context, String mode) {
    return Chip(
      avatar: const Icon(Icons.tune, size: 16),
      label: Text(mode.toUpperCase()),
    );
  }

  Widget _buildArmChip(
      BuildContext context, bool armed, ConnectionService conn) {
    return ActionChip(
      avatar: Icon(
        armed ? Icons.lock_open : Icons.lock,
        size: 16,
        color: armed ? Colors.red : Colors.green,
      ),
      label: Text(armed ? 'ARMED' : 'DISARMED'),
      backgroundColor: armed
          ? Colors.red.withAlpha(30)
          : Colors.green.withAlpha(30),
      onPressed: () {
        if (armed) {
          conn.sendCommand(
              DroneCommand.arm(false));
        } else {
          _showArmConfirmation(context, conn);
        }
      },
    );
  }

  void _showArmConfirmation(
      BuildContext context, ConnectionService conn) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arm Drone?'),
        content: const Text('Make sure the area is clear before arming.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () {
              conn.sendCommand(
                  DroneCommand.arm(true));
              Navigator.pop(ctx);
            },
            child: const Text('ARM'),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(BuildContext context, dynamic data) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 160,
          child: TelemetryTile(
            icon: Icons.height,
            label: 'Altitude',
            value: data.altitude.toStringAsFixed(2),
            unit: 'm',
          ),
        ),
        SizedBox(
          width: 160,
          child: TelemetryTile(
            icon: Icons.rotate_right,
            label: 'Roll',
            value: data.attitude.roll.toStringAsFixed(1),
            unit: 'deg',
          ),
        ),
        SizedBox(
          width: 160,
          child: TelemetryTile(
            icon: Icons.straight,
            label: 'Pitch',
            value: data.attitude.pitch.toStringAsFixed(1),
            unit: 'deg',
          ),
        ),
        SizedBox(
          width: 160,
          child: TelemetryTile(
            icon: Icons.navigation,
            label: 'Yaw',
            value: data.attitude.yaw.toStringAsFixed(1),
            unit: 'deg',
          ),
        ),
        SizedBox(
          width: 160,
          child: TelemetryTile(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: data.sensors.temperature.toStringAsFixed(1),
            unit: 'C',
          ),
        ),
        SizedBox(
          width: 160,
          child: TelemetryTile(
            icon: Icons.water_drop,
            label: 'Humidity',
            value: data.sensors.humidity.toStringAsFixed(1),
            unit: '%',
          ),
        ),
        SizedBox(
          width: 160,
          child: TelemetryTile(
            icon: Icons.air,
            label: 'PM2.5',
            value: data.sensors.dustPm25.toStringAsFixed(1),
            unit: 'ug/m3',
          ),
        ),
        SizedBox(
          width: 160,
          child: TelemetryTile(
            icon: Icons.bolt,
            label: 'Current',
            value: data.battery.current.toStringAsFixed(1),
            unit: 'A',
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsList(
      BuildContext context, TelemetryService telemetry) {
    if (telemetry.alerts.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Alerts',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                TextButton(
                  onPressed: telemetry.clearAlerts,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          ...telemetry.alerts.take(5).map((alert) => ListTile(
                dense: true,
                leading: Icon(
                  alert.isError ? Icons.error : Icons.warning,
                  color: alert.isError ? Colors.red : Colors.orange,
                  size: 20,
                ),
                title: Text(alert.message),
              )),
        ],
      ),
    );
  }
}
