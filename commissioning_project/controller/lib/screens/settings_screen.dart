import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connection_config.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Connection
            Text(
              'Connection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.wifi),
                    title: const Text('Network Mode'),
                    subtitle: Text(
                      settings.connectionConfig.mode == ConnectionMode.rpiAp
                          ? 'RPi Access Point'
                          : 'Site WiFi',
                    ),
                    trailing: Switch(
                      value: settings.connectionConfig.mode ==
                          ConnectionMode.siteWifi,
                      onChanged: (value) {
                        settings.updateConnectionConfig(
                          settings.connectionConfig.copyWith(
                            mode: value
                                ? ConnectionMode.siteWifi
                                : ConnectionMode.rpiAp,
                          ),
                        );
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lan),
                    title: const Text('Drone IP'),
                    subtitle: Text(settings.connectionConfig.droneIp),
                    onTap: () => _editIp(context, settings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_ethernet),
                    title: const Text('Ports'),
                    subtitle: Text(
                      'WS: ${settings.connectionConfig.wsPort}  '
                      'UDP: ${settings.connectionConfig.udpPort}  '
                      'RGB: ${settings.connectionConfig.rgbCameraPort}  '
                      'THM: ${settings.connectionConfig.thermalCameraPort}',
                    ),
                    onTap: () => _editPorts(context, settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Drone Parameters
            Text(
              'Drone Parameters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _buildSliderTile(
                    context,
                    icon: Icons.height,
                    title: 'Max Altitude',
                    value: settings.maxAltitude,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    unit: 'm',
                    onChanged: settings.updateMaxAltitude,
                  ),
                  const Divider(height: 1),
                  _buildSliderTile(
                    context,
                    icon: Icons.speed,
                    title: 'Max Speed',
                    value: settings.maxSpeed,
                    min: 0.1,
                    max: 3.0,
                    divisions: 29,
                    unit: 'm/s',
                    onChanged: settings.updateMaxSpeed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Joystick
            Text(
              'Joystick',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.gamepad),
                    title: const Text('Throttle on Left Stick'),
                    subtitle: Text(
                      settings.joystickLeftThrottle
                          ? 'Mode 2 (Standard)'
                          : 'Mode 1 (Throttle Right)',
                    ),
                    value: settings.joystickLeftThrottle,
                    onChanged: settings.updateJoystickLeftThrottle,
                  ),
                  const Divider(height: 1),
                  _buildSliderTile(
                    context,
                    icon: Icons.adjust,
                    title: 'Deadzone',
                    value: settings.joystickDeadzone,
                    min: 0.0,
                    max: 0.2,
                    divisions: 20,
                    unit: '',
                    format: (v) => '${(v * 100).toStringAsFixed(0)}%',
                    onChanged: settings.updateJoystickDeadzone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Cx Controller'),
                    subtitle: Text('v1.0.0'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.architecture),
                    title: Text('Architecture'),
                    subtitle: Text(
                      'Flutter -> WiFi -> RPi -> MSP -> Betaflight FC',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Reset All Settings'),
                    subtitle: const Text('Restore defaults'),
                    onTap: () => _confirmReset(context, settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
    String Function(double)? format,
  }) {
    final display = format != null
        ? format(value)
        : '${value.toStringAsFixed(1)} $unit';

    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            display,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: display,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _editIp(BuildContext context, SettingsService settings) {
    final controller =
        TextEditingController(text: settings.connectionConfig.droneIp);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Drone IP Address'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '192.168.4.1',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                settings.updateConnectionConfig(
                  settings.connectionConfig.copyWith(droneIp: ip),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPorts(BuildContext context, SettingsService settings) {
    final wsCtrl = TextEditingController(
        text: '${settings.connectionConfig.wsPort}');
    final udpCtrl = TextEditingController(
        text: '${settings.connectionConfig.udpPort}');
    final rgbCtrl = TextEditingController(
        text: '${settings.connectionConfig.rgbCameraPort}');
    final thermalCtrl = TextEditingController(
        text: '${settings.connectionConfig.thermalCameraPort}');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Port Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _portField(wsCtrl, 'WebSocket Port'),
              const SizedBox(height: 8),
              _portField(udpCtrl, 'UDP Joystick Port'),
              const SizedBox(height: 8),
              _portField(rgbCtrl, 'RGB Camera Port'),
              const SizedBox(height: 8),
              _portField(thermalCtrl, 'Thermal Camera Port'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              settings.updateConnectionConfig(
                settings.connectionConfig.copyWith(
                  wsPort: int.tryParse(wsCtrl.text) ?? 8765,
                  udpPort: int.tryParse(udpCtrl.text) ?? 8766,
                  rgbCameraPort: int.tryParse(rgbCtrl.text) ?? 8080,
                  thermalCameraPort:
                      int.tryParse(thermalCtrl.text) ?? 8081,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _portField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
    );
  }

  void _confirmReset(BuildContext context, SettingsService settings) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
          'All settings will be restored to defaults. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              settings.updateConnectionConfig(const ConnectionConfig());
              settings.updateMaxAltitude(3.0);
              settings.updateMaxSpeed(1.0);
              settings.updateJoystickDeadzone(0.05);
              settings.updateJoystickLeftThrottle(true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
