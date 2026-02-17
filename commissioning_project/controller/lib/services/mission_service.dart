import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/drone_command.dart';
import '../models/mission.dart';
import 'connection_service.dart';

class MissionService extends ChangeNotifier {
  final ConnectionService _connection;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  static const String _storageKey = 'saved_missions';

  List<Mission> _savedMissions = [];
  Mission? _activeMission;
  MissionStatus _status = MissionStatus.idle;
  int _currentWaypointIndex = -1;
  int _totalWaypoints = 0;

  List<Mission> get savedMissions => List.unmodifiable(_savedMissions);
  Mission? get activeMission => _activeMission;
  MissionStatus get status => _status;
  int get currentWaypointIndex => _currentWaypointIndex;
  int get totalWaypoints => _totalWaypoints;

  MissionService(this._connection) {
    _subscription = _connection.messageStream.listen(_onMessage);
    _loadMissions();
  }

  void _onMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;

    if (type == 'mission_progress') {
      _currentWaypointIndex = (msg['current_wp'] as num?)?.toInt() ?? 0;
      _totalWaypoints = (msg['total_wp'] as num?)?.toInt() ?? 0;
      final statusStr = msg['status'] as String? ?? 'running';
      switch (statusStr) {
        case 'running':
          _status = MissionStatus.running;
        case 'paused':
          _status = MissionStatus.paused;
        case 'completed':
          _status = MissionStatus.completed;
        case 'error':
          _status = MissionStatus.error;
      }
      notifyListeners();
    }
  }

  // CRUD operations

  void createMission(String name, List<Waypoint> waypoints) {
    final mission = Mission(
      name: name,
      waypoints: waypoints,
      createdAt: DateTime.now(),
    );
    _savedMissions.add(mission);
    _saveMissions();
    notifyListeners();
  }

  void updateMission(int index, Mission mission) {
    if (index >= 0 && index < _savedMissions.length) {
      _savedMissions[index] = mission;
      _saveMissions();
      notifyListeners();
    }
  }

  void deleteMission(int index) {
    if (index >= 0 && index < _savedMissions.length) {
      _savedMissions.removeAt(index);
      _saveMissions();
      notifyListeners();
    }
  }

  // Mission execution

  void setActiveMission(Mission? mission) {
    _activeMission = mission;
    _status = MissionStatus.idle;
    _currentWaypointIndex = -1;
    notifyListeners();
  }

  void uploadMission() {
    if (_activeMission == null) return;
    _status = MissionStatus.uploading;
    notifyListeners();

    _connection.sendCommand(DroneCommand.missionUpload(
      _activeMission!.waypoints.map((w) => w.toJson()).toList(),
    ));

    // Assume upload succeeds after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_status == MissionStatus.uploading) {
        _status = MissionStatus.ready;
        notifyListeners();
      }
    });
  }

  void startMission() {
    _connection.sendCommand(DroneCommand.missionCtrl('start'));
    _status = MissionStatus.running;
    _currentWaypointIndex = 0;
    notifyListeners();
  }

  void pauseMission() {
    _connection.sendCommand(DroneCommand.missionCtrl('pause'));
    _status = MissionStatus.paused;
    notifyListeners();
  }

  void cancelMission() {
    _connection.sendCommand(DroneCommand.missionCtrl('cancel'));
    _status = MissionStatus.idle;
    _currentWaypointIndex = -1;
    notifyListeners();
  }

  // Persistence

  Future<void> _loadMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _savedMissions = list
            .map((m) => Mission.fromJson(m as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Corrupted data, start fresh
    }
  }

  Future<void> _saveMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_savedMissions.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKey, json);
    } catch (_) {
      // Save failed
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
