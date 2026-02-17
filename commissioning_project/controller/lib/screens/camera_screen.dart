import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/camera_service.dart';
import '../services/connection_service.dart';
import '../services/settings_service.dart';
import '../widgets/mjpeg_viewer.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ConnectionService, CameraService, SettingsService>(
      builder: (context, conn, camera, settings, _) {
        final config = settings.connectionConfig;
        final isWide = MediaQuery.of(context).size.width >= 800;

        if (!conn.isConnected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect to drone to view camera feeds',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        if (isWide) {
          return _buildWideLayout(context, camera, config.rgbStreamUrl, config.thermalStreamUrl);
        } else {
          return _buildNarrowLayout(context, camera, config.rgbStreamUrl, config.thermalStreamUrl);
        }
      },
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    CameraService camera,
    String rgbUrl,
    String thermalUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _CameraFeedCard(
                    label: 'RGB Camera',
                    streamUrl: rgbUrl,
                    camera: 'rgb',
                    cameraService: camera,
                    isRecording: camera.rgbRecording,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CameraFeedCard(
                    label: 'Thermal Camera',
                    streamUrl: thermalUrl,
                    camera: 'thermal',
                    cameraService: camera,
                    isRecording: camera.thermalRecording,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SnapshotBar(camera: camera),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    CameraService camera,
    String rgbUrl,
    String thermalUrl,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: _CameraFeedCard(
              label: 'RGB Camera',
              streamUrl: rgbUrl,
              camera: 'rgb',
              cameraService: camera,
              isRecording: camera.rgbRecording,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: _CameraFeedCard(
              label: 'Thermal Camera',
              streamUrl: thermalUrl,
              camera: 'thermal',
              cameraService: camera,
              isRecording: camera.thermalRecording,
            ),
          ),
          const SizedBox(height: 12),
          _SnapshotBar(camera: camera),
        ],
      ),
    );
  }
}

class _CameraFeedCard extends StatelessWidget {
  final String label;
  final String streamUrl;
  final String camera;
  final CameraService cameraService;
  final bool isRecording;

  const _CameraFeedCard({
    required this.label,
    required this.streamUrl,
    required this.camera,
    required this.cameraService,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  camera == 'rgb' ? Icons.camera_alt : Icons.thermostat,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'REC',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          // Stream
          Expanded(
            child: MjpegViewer(
              streamUrl: streamUrl,
              fit: BoxFit.contain,
            ),
          ),
          // Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => cameraService.takeSnapshot(camera),
                  icon: const Icon(Icons.camera),
                  tooltip: 'Snapshot',
                  iconSize: 22,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => cameraService.toggleRecording(camera),
                  icon: Icon(
                    isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                    color: isRecording ? Colors.red : null,
                  ),
                  tooltip: isRecording ? 'Stop Recording' : 'Start Recording',
                  iconSize: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotBar extends StatelessWidget {
  final CameraService camera;

  const _SnapshotBar({required this.camera});

  @override
  Widget build(BuildContext context) {
    final snapshots = camera.snapshots;

    if (snapshots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No snapshots yet',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Snapshots (${snapshots.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton(
              onPressed: camera.clearSnapshots,
              child: const Text('Clear', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: snapshots.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final snap = snapshots[snapshots.length - 1 - index];
              final time =
                  '${snap.timestamp.hour.toString().padLeft(2, '0')}'
                  ':${snap.timestamp.minute.toString().padLeft(2, '0')}'
                  ':${snap.timestamp.second.toString().padLeft(2, '0')}';
              return Chip(
                avatar: Icon(
                  snap.camera == 'rgb' ? Icons.camera_alt : Icons.thermostat,
                  size: 16,
                ),
                label: Text(
                  '${snap.camera.toUpperCase()} $time',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
