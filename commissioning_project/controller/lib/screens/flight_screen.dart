import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/drone_command.dart';
import '../models/joystick_input.dart';
import '../services/connection_service.dart';
import '../services/telemetry_service.dart';
import '../widgets/attitude_indicator.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/flight_mode_selector.dart';
import '../widgets/virtual_joystick.dart';

class FlightScreen extends StatefulWidget {
  const FlightScreen({super.key});

  @override
  State<FlightScreen> createState() => _FlightScreenState();
}

class _FlightScreenState extends State<FlightScreen> {
  FlightMode _flightMode = FlightMode.manual;
  Timer? _joystickTimer;

  // Joystick values
  double _throttle = 0;
  double _yaw = 0;
  double _pitch = 0;
  double _roll = 0;

  // Keyboard state
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startJoystickLoop();
  }

  @override
  void dispose() {
    _joystickTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startJoystickLoop() {
    _joystickTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      _applyKeyboardInput();

      final conn = context.read<ConnectionService>();
      if (conn.isConnected && _flightMode == FlightMode.manual) {
        conn.sendJoystick(JoystickInput(
          roll: _roll,
          pitch: _pitch,
          throttle: _throttle,
          yaw: _yaw,
        ));
      }
    });
  }

  void _applyKeyboardInput() {
    const step = 0.05;
    const decay = 0.9;

    if (_pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      _throttle = (_throttle + step).clamp(0.0, 1.0);
    } else if (_pressedKeys.contains(LogicalKeyboardKey.keyS)) {
      _throttle = (_throttle - step).clamp(0.0, 1.0);
    }

    if (_pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      _yaw = (_yaw - step).clamp(-1.0, 1.0);
    } else if (_pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      _yaw = (_yaw + step).clamp(-1.0, 1.0);
    } else {
      _yaw *= decay;
    }

    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      _pitch = (_pitch + step).clamp(-1.0, 1.0);
    } else if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      _pitch = (_pitch - step).clamp(-1.0, 1.0);
    } else {
      _pitch *= decay;
    }

    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      _roll = (_roll + step).clamp(-1.0, 1.0);
    } else if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      _roll = (_roll - step).clamp(-1.0, 1.0);
    } else {
      _roll *= decay;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Consumer2<ConnectionService, TelemetryService>(
        builder: (context, conn, telemetry, _) {
          final data = telemetry.latest;
          final isWide = MediaQuery.of(context).size.width >= 800;

          if (isWide) {
            return _buildWideLayout(conn, data);
          } else {
            return _buildNarrowLayout(conn, data);
          }
        },
      ),
    );
  }

  Widget _buildWideLayout(ConnectionService conn, dynamic data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Left: Throttle/Yaw joystick
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VirtualJoystick(
                  size: 200,
                  label: 'Throttle / Yaw',
                  returnToCenter: false,
                  onChanged: (offset) {
                    _yaw = offset.dx;
                    _throttle = (offset.dy + 1) / 2;
                  },
                ),
                const SizedBox(height: 12),
                _buildJoystickValues(),
              ],
            ),
          ),
          // Center: Instruments
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeAndArm(conn, data),
                const SizedBox(height: 16),
                AttitudeIndicator(
                  roll: data?.attitude.roll ?? 0,
                  pitch: data?.attitude.pitch ?? 0,
                  size: 220,
                ),
                const SizedBox(height: 16),
                _buildTelemetryRow(data),
                const SizedBox(height: 8),
                _buildKeyboardHint(),
              ],
            ),
          ),
          // Right: Pitch/Roll joystick
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VirtualJoystick(
                  size: 200,
                  label: 'Pitch / Roll',
                  onChanged: (offset) {
                    _roll = offset.dx;
                    _pitch = offset.dy;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(ConnectionService conn, dynamic data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModeAndArm(conn, data),
          const SizedBox(height: 16),
          AttitudeIndicator(
            roll: data?.attitude.roll ?? 0,
            pitch: data?.attitude.pitch ?? 0,
            size: 160,
          ),
          const SizedBox(height: 12),
          _buildTelemetryRow(data),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              VirtualJoystick(
                size: 150,
                label: 'Throttle / Yaw',
                returnToCenter: false,
                onChanged: (offset) {
                  _yaw = offset.dx;
                  _throttle = (offset.dy + 1) / 2;
                },
              ),
              VirtualJoystick(
                size: 150,
                label: 'Pitch / Roll',
                onChanged: (offset) {
                  _roll = offset.dx;
                  _pitch = offset.dy;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeAndArm(ConnectionService conn, dynamic data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlightModeSelector(
          selected: _flightMode,
          onChanged: (mode) {
            setState(() => _flightMode = mode);
            conn.sendCommand(DroneCommand.mode(mode.name));
          },
        ),
        const SizedBox(width: 16),
        if (data != null)
          FilledButton.tonalIcon(
            onPressed: () {
              conn.sendCommand(DroneCommand.arm(!data.armed));
            },
            icon: Icon(
              data.armed ? Icons.lock_open : Icons.lock,
              color: data.armed ? Colors.red : Colors.green,
            ),
            label: Text(data.armed ? 'DISARM' : 'ARM'),
          ),
      ],
    );
  }

  Widget _buildTelemetryRow(dynamic data) {
    if (data == null) {
      return Text(
        'No telemetry data',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BatteryIndicator(battery: data.battery),
        const SizedBox(width: 24),
        _buildQuickStat(Icons.height, '${data.altitude.toStringAsFixed(2)}m'),
        const SizedBox(width: 16),
        _buildQuickStat(Icons.navigation, '${data.attitude.yaw.toStringAsFixed(0)}'),
        const SizedBox(width: 16),
        _buildQuickStat(Icons.speed, data.mode.toUpperCase()),
      ],
    );
  }

  Widget _buildQuickStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildJoystickValues() {
    return Text(
      'T:${_throttle.toStringAsFixed(2)} Y:${_yaw.toStringAsFixed(2)} '
      'P:${_pitch.toStringAsFixed(2)} R:${_roll.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 11,
        fontFamily: 'monospace',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildKeyboardHint() {
    return Text(
      'Keyboard: W/S = Throttle, A/D = Yaw, Arrows = Pitch/Roll',
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(120),
      ),
    );
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }
}
