import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/drone_command.dart';
import 'connection_service.dart';

class CameraService extends ChangeNotifier {
  final ConnectionService _connection;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  bool _rgbRecording = false;
  bool _thermalRecording = false;
  final List<SnapshotEvent> _snapshots = [];

  bool get rgbRecording => _rgbRecording;
  bool get thermalRecording => _thermalRecording;
  List<SnapshotEvent> get snapshots => List.unmodifiable(_snapshots);

  CameraService(this._connection) {
    _subscription = _connection.messageStream.listen(_onMessage);
  }

  void _onMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;

    if (type == 'snapshot_ready') {
      _snapshots.add(SnapshotEvent(
        camera: msg['camera'] as String? ?? 'rgb',
        filename: msg['filename'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          msg['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
      ));
      notifyListeners();
    }
  }

  void takeSnapshot(String camera) {
    _connection.sendCommand(DroneCommand.camera(camera, 'snapshot'));
  }

  void toggleRecording(String camera) {
    if (camera == 'rgb') {
      _rgbRecording = !_rgbRecording;
      _connection.sendCommand(
        DroneCommand.camera(camera, _rgbRecording ? 'record_start' : 'record_stop'),
      );
    } else {
      _thermalRecording = !_thermalRecording;
      _connection.sendCommand(
        DroneCommand.camera(camera, _thermalRecording ? 'record_start' : 'record_stop'),
      );
    }
    notifyListeners();
  }

  void clearSnapshots() {
    _snapshots.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class SnapshotEvent {
  final String camera;
  final String filename;
  final DateTime timestamp;

  const SnapshotEvent({
    required this.camera,
    required this.filename,
    required this.timestamp,
  });
}
