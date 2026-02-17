import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mission.dart';
import '../services/connection_service.dart';
import '../services/mission_service.dart';
import '../widgets/waypoint_editor.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  List<Waypoint> _editorWaypoints = [];
  int? _selectedWaypointIndex;
  bool _editingExisting = false;
  int _editingMissionIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Consumer2<MissionService, ConnectionService>(
      builder: (context, mission, conn, _) {
        if (isWide) {
          return _buildWideLayout(context, mission, conn);
        }
        return _buildNarrowLayout(context, mission, conn);
      },
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    MissionService mission,
    ConnectionService conn,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left: Waypoint editor
          Expanded(
            flex: 3,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildEditorToolbar(context, mission),
                  Expanded(
                    child: WaypointEditor(
                      waypoints: _editorWaypoints,
                      activeWaypointIndex: _selectedWaypointIndex,
                      onChanged: (waypoints) {
                        setState(() => _editorWaypoints = waypoints);
                      },
                      onWaypointTap: (index) {
                        setState(() => _selectedWaypointIndex = index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right: Panel
          SizedBox(
            width: 280,
            child: Column(
              children: [
                if (_selectedWaypointIndex != null &&
                    _selectedWaypointIndex! < _editorWaypoints.length)
                  _buildWaypointProperties(context),
                if (_selectedWaypointIndex != null)
                  const SizedBox(height: 12),
                _buildMissionControls(context, mission, conn),
                const SizedBox(height: 12),
                Expanded(child: _buildSavedMissions(context, mission)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    MissionService mission,
    ConnectionService conn,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildEditorToolbar(context, mission),
                SizedBox(
                  height: 300,
                  child: WaypointEditor(
                    waypoints: _editorWaypoints,
                    activeWaypointIndex: _selectedWaypointIndex,
                    onChanged: (waypoints) {
                      setState(() => _editorWaypoints = waypoints);
                    },
                    onWaypointTap: (index) {
                      setState(() => _selectedWaypointIndex = index);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedWaypointIndex != null &&
              _selectedWaypointIndex! < _editorWaypoints.length)
            _buildWaypointProperties(context),
          if (_selectedWaypointIndex != null) const SizedBox(height: 12),
          _buildMissionControls(context, mission, conn),
          const SizedBox(height: 12),
          _buildSavedMissions(context, mission),
        ],
      ),
    );
  }

  Widget _buildEditorToolbar(BuildContext context, MissionService mission) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.map,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Waypoint Editor (${_editorWaypoints.length} pts)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (_selectedWaypointIndex != null)
            IconButton(
              onPressed: _deleteSelectedWaypoint,
              icon: const Icon(Icons.delete, size: 18),
              tooltip: 'Delete waypoint',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            onPressed: _editorWaypoints.isEmpty
                ? null
                : () => setState(() {
                      _editorWaypoints = [];
                      _selectedWaypointIndex = null;
                      _editingExisting = false;
                    }),
            icon: const Icon(Icons.clear_all, size: 18),
            tooltip: 'Clear all',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildWaypointProperties(BuildContext context) {
    final wp = _editorWaypoints[_selectedWaypointIndex!];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Waypoint ${_selectedWaypointIndex! + 1}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      setState(() => _selectedWaypointIndex = null),
                  icon: const Icon(Icons.close, size: 16),
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'X: ${wp.x.toStringAsFixed(2)}m  Y: ${wp.y.toStringAsFixed(2)}m',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // Altitude slider
            Row(
              children: [
                const Text('Alt:', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: wp.z,
                    min: 0.5,
                    max: 5.0,
                    divisions: 18,
                    label: '${wp.z.toStringAsFixed(1)}m',
                    onChanged: (v) => _updateWaypoint(wp.copyWith(z: v)),
                  ),
                ),
                Text('${wp.z.toStringAsFixed(1)}m',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
            // Action dropdown
            Row(
              children: [
                const Text('Action:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<WaypointAction>(
                    value: wp.action,
                    isExpanded: true,
                    isDense: true,
                    style: const TextStyle(fontSize: 12),
                    items: WaypointAction.values.map((action) {
                      return DropdownMenuItem(
                        value: action,
                        child: Text(_actionLabel(action)),
                      );
                    }).toList(),
                    onChanged: (action) {
                      if (action != null) {
                        _updateWaypoint(wp.copyWith(action: action));
                      }
                    },
                  ),
                ),
              ],
            ),
            // Hold time
            if (wp.action != WaypointAction.none)
              Row(
                children: [
                  const Text('Hold:', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: wp.holdSeconds.toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: '${wp.holdSeconds}s',
                      onChanged: (v) =>
                          _updateWaypoint(wp.copyWith(holdSeconds: v.toInt())),
                    ),
                  ),
                  Text('${wp.holdSeconds}s',
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionControls(
    BuildContext context,
    MissionService mission,
    ConnectionService conn,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mission Control',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Status
            if (mission.status != MissionStatus.idle)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _statusIcon(mission.status),
                      size: 16,
                      color: _statusColor(mission.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusLabel(mission.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _statusColor(mission.status),
                      ),
                    ),
                    if (mission.status == MissionStatus.running)
                      Text(
                        '  WP ${mission.currentWaypointIndex + 1}/${mission.totalWaypoints}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            // Progress bar
            if (mission.status == MissionStatus.running &&
                mission.totalWaypoints > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(
                  value: (mission.currentWaypointIndex + 1) /
                      mission.totalWaypoints,
                ),
              ),
            // Save button
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _editorWaypoints.isEmpty
                        ? null
                        : () => _saveMission(context, mission),
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(
                        _editingExisting ? 'Update Mission' : 'Save Mission'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Upload + Execute
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (!conn.isConnected ||
                            _editorWaypoints.isEmpty)
                        ? null
                        : () {
                            mission.setActiveMission(Mission(
                              name: 'Current',
                              waypoints: _editorWaypoints,
                              createdAt: DateTime.now(),
                            ));
                            mission.uploadMission();
                          },
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Upload'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildExecutionButton(mission, conn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionButton(
      MissionService mission, ConnectionService conn) {
    switch (mission.status) {
      case MissionStatus.ready:
        return FilledButton.icon(
          onPressed: conn.isConnected ? mission.startMission : null,
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text('Start'),
        );
      case MissionStatus.running:
        return FilledButton.icon(
          onPressed: mission.pauseMission,
          icon: const Icon(Icons.pause, size: 16),
          label: const Text('Pause'),
        );
      case MissionStatus.paused:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: mission.startMission,
                icon: const Icon(Icons.play_arrow, size: 14),
                label: const Text('Go', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: mission.cancelMission,
              icon: const Icon(Icons.stop, size: 16, color: Colors.red),
              tooltip: 'Cancel',
              visualDensity: VisualDensity.compact,
            ),
          ],
        );
      default:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text('Start'),
        );
    }
  }

  Widget _buildSavedMissions(BuildContext context, MissionService mission) {
    final missions = mission.savedMissions;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              'Saved Missions (${missions.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (missions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No saved missions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: missions.length,
                itemBuilder: (context, index) {
                  final m = missions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.route, size: 18),
                    title: Text(m.name, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${m.waypoints.length} waypoints',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _loadMission(m, index),
                          icon: const Icon(Icons.edit, size: 16),
                          tooltip: 'Edit',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: () =>
                              _confirmDelete(context, mission, index),
                          icon:
                              const Icon(Icons.delete, size: 16, color: Colors.red),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Helpers

  void _updateWaypoint(Waypoint updated) {
    final list = List<Waypoint>.from(_editorWaypoints);
    list[_selectedWaypointIndex!] = updated;
    setState(() => _editorWaypoints = list);
  }

  void _deleteSelectedWaypoint() {
    if (_selectedWaypointIndex == null) return;
    setState(() {
      _editorWaypoints = List<Waypoint>.from(_editorWaypoints)
        ..removeAt(_selectedWaypointIndex!);
      _selectedWaypointIndex = null;
    });
  }

  void _loadMission(Mission mission, int index) {
    setState(() {
      _editorWaypoints = List<Waypoint>.from(mission.waypoints);
      _selectedWaypointIndex = null;
      _editingExisting = true;
      _editingMissionIndex = index;
    });
  }

  void _saveMission(BuildContext context, MissionService service) {
    if (_editingExisting) {
      final existing = service.savedMissions[_editingMissionIndex];
      service.updateMission(
        _editingMissionIndex,
        Mission(
          name: existing.name,
          waypoints: _editorWaypoints,
          createdAt: existing.createdAt,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission updated'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      _showNameDialog(context, service);
    }
  }

  void _showNameDialog(BuildContext context, MissionService service) {
    final controller = TextEditingController(
      text: 'Mission ${service.savedMissions.length + 1}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Mission'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Mission name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                service.createMission(name, _editorWaypoints);
                _editingExisting = true;
                _editingMissionIndex = service.savedMissions.length - 1;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mission "$name" saved'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose;
  }

  void _confirmDelete(
      BuildContext context, MissionService service, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mission?'),
        content:
            Text('Delete "${service.savedMissions[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteMission(index);
              if (_editingExisting && _editingMissionIndex == index) {
                _editingExisting = false;
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _actionLabel(WaypointAction action) {
    switch (action) {
      case WaypointAction.none:
        return 'None';
      case WaypointAction.photo:
        return 'RGB Photo';
      case WaypointAction.thermalPhoto:
        return 'Thermal Photo';
      case WaypointAction.photoAll:
        return 'All Photos';
      case WaypointAction.hover:
        return 'Hover';
    }
  }

  IconData _statusIcon(MissionStatus status) {
    switch (status) {
      case MissionStatus.idle:
        return Icons.circle_outlined;
      case MissionStatus.uploading:
        return Icons.cloud_upload;
      case MissionStatus.ready:
        return Icons.check_circle;
      case MissionStatus.running:
        return Icons.play_circle;
      case MissionStatus.paused:
        return Icons.pause_circle;
      case MissionStatus.completed:
        return Icons.task_alt;
      case MissionStatus.error:
        return Icons.error;
    }
  }

  Color _statusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.idle:
        return Colors.grey;
      case MissionStatus.uploading:
        return Colors.blue;
      case MissionStatus.ready:
        return Colors.green;
      case MissionStatus.running:
        return Colors.blue;
      case MissionStatus.paused:
        return Colors.orange;
      case MissionStatus.completed:
        return Colors.green;
      case MissionStatus.error:
        return Colors.red;
    }
  }

  String _statusLabel(MissionStatus status) {
    switch (status) {
      case MissionStatus.idle:
        return 'Idle';
      case MissionStatus.uploading:
        return 'Uploading...';
      case MissionStatus.ready:
        return 'Ready';
      case MissionStatus.running:
        return 'Running';
      case MissionStatus.paused:
        return 'Paused';
      case MissionStatus.completed:
        return 'Completed';
      case MissionStatus.error:
        return 'Error';
    }
  }
}
