import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/telemetry.dart';
import '../services/camera_service.dart';
import '../services/telemetry_service.dart';
import '../widgets/sensor_panel.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart, size: 18), text: 'Flight Log'),
            Tab(icon: Icon(Icons.sensors, size: 18), text: 'Sensors'),
            Tab(icon: Icon(Icons.photo_library, size: 18), text: 'Snapshots'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FlightLogTab(),
              _SensorsTab(),
              _SnapshotsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlightLogTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryService>(
      builder: (context, telemetry, _) {
        final history = telemetry.history;

        if (history.isEmpty) {
          return _buildEmptyState(context, 'No flight data yet',
              'Connect to drone to start recording');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChartCard(
                context,
                'Altitude',
                history,
                (d) => d.altitude,
                'm',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildChartCard(
                context,
                'Roll / Pitch',
                history,
                null,
                'deg',
                Colors.orange,
                secondaryExtractor: (d) => d.attitude.pitch,
                primaryExtractor: (d) => d.attitude.roll,
                secondaryColor: Colors.green,
                primaryLabel: 'Roll',
                secondaryLabel: 'Pitch',
              ),
              const SizedBox(height: 12),
              _buildChartCard(
                context,
                'Battery',
                history,
                (d) => d.battery.percent.toDouble(),
                '%',
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(context, history),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    String title,
    List<TelemetryData> history,
    double Function(TelemetryData)? extractor,
    String unit,
    Color color, {
    double Function(TelemetryData)? primaryExtractor,
    double Function(TelemetryData)? secondaryExtractor,
    Color? secondaryColor,
    String? primaryLabel,
    String? secondaryLabel,
  }) {
    final effectivePrimary = primaryExtractor ?? extractor!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (primaryLabel != null) ...[
                  _legendDot(color),
                  const SizedBox(width: 4),
                  Text(primaryLabel,
                      style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 8),
                ],
                if (secondaryLabel != null) ...[
                  _legendDot(secondaryColor!),
                  const SizedBox(width: 4),
                  Text(secondaryLabel,
                      style: const TextStyle(fontSize: 10)),
                ],
                if (primaryLabel == null)
                  Text(
                    '${effectivePrimary(history.last).toStringAsFixed(1)} $unit',
                    style: TextStyle(fontSize: 12, color: color),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _LineChartPainter(
                  data: history.map(effectivePrimary).toList(),
                  color: color,
                  secondaryData: secondaryExtractor != null
                      ? history.map(secondaryExtractor).toList()
                      : null,
                  secondaryColor: secondaryColor,
                  gridColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withAlpha(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, List<TelemetryData> history) {
    final latest = history.last;
    final duration = history.length > 1
        ? Duration(
            milliseconds: history.last.timestamp - history.first.timestamp)
        : Duration.zero;
    final maxAlt = history.map((d) => d.altitude).reduce(max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Summary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _summaryItem('Duration', _formatDuration(duration)),
                _summaryItem('Samples', '${history.length}'),
                _summaryItem('Max Alt', '${maxAlt.toStringAsFixed(2)}m'),
                _summaryItem('Battery', '${latest.battery.percent}%'),
                _summaryItem('Mode', latest.mode.toUpperCase()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  Widget _buildEmptyState(
      BuildContext context, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48,
              color: Theme.of(context).colorScheme.primary.withAlpha(80)),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SensorsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryService>(
      builder: (context, telemetry, _) {
        final data = telemetry.latest;

        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sensors, size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(80)),
                const SizedBox(height: 12),
                Text('No sensor data',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SensorPanel(sensors: data.sensors),
              const SizedBox(height: 12),
              _buildSensorHistory(context, telemetry),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorHistory(
      BuildContext context, TelemetryService telemetry) {
    final history = telemetry.history;
    if (history.length < 2) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Sensor History',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                _legendItem(Colors.red, 'Temp'),
                const SizedBox(width: 8),
                _legendItem(Colors.blue, 'Hum'),
                const SizedBox(width: 8),
                _legendItem(Colors.orange, 'PM2.5'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _LineChartPainter(
                  data: history
                      .map((d) => d.sensors.temperature)
                      .toList(),
                  color: Colors.red,
                  secondaryData: history
                      .map((d) => d.sensors.humidity)
                      .toList(),
                  secondaryColor: Colors.blue,
                  gridColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withAlpha(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _SnapshotsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CameraService>(
      builder: (context, camera, _) {
        final snapshots = camera.snapshots;

        if (snapshots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(80)),
                const SizedBox(height: 12),
                Text('No snapshots yet',
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text('Take snapshots from the Camera tab',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Text('${snapshots.length} snapshots',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: camera.clearSnapshots,
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Clear All',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: snapshots.length,
                itemBuilder: (context, index) {
                  final snap =
                      snapshots[snapshots.length - 1 - index];
                  final time =
                      '${snap.timestamp.hour.toString().padLeft(2, '0')}'
                      ':${snap.timestamp.minute.toString().padLeft(2, '0')}'
                      ':${snap.timestamp.second.toString().padLeft(2, '0')}';

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        snap.camera == 'rgb'
                            ? Icons.camera_alt
                            : Icons.thermostat,
                        color: snap.camera == 'rgb'
                            ? Colors.blue
                            : Colors.orange,
                      ),
                      title: Text(snap.filename,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${snap.camera.toUpperCase()} - $time',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final List<double>? secondaryData;
  final Color? secondaryColor;
  final Color gridColor;

  _LineChartPainter({
    required this.data,
    required this.color,
    this.secondaryData,
    this.secondaryColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw grid
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw primary line
    _drawLine(canvas, size, data, color);

    // Draw secondary line
    if (secondaryData != null && secondaryColor != null) {
      _drawLine(canvas, size, secondaryData!, secondaryColor!);
    }
  }

  void _drawLine(
      Canvas canvas, Size size, List<double> values, Color lineColor) {
    if (values.length < 2) return;

    final minVal = values.reduce(min) - 1;
    final maxVal = values.reduce(max) + 1;
    final range = maxVal - minVal;
    if (range == 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return data.length != oldDelegate.data.length ||
        (data.isNotEmpty &&
            oldDelegate.data.isNotEmpty &&
            data.last != oldDelegate.data.last);
  }
}
