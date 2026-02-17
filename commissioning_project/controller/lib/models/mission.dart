enum WaypointAction { none, photo, thermalPhoto, photoAll, hover }

enum MissionStatus { idle, uploading, ready, running, paused, completed, error }

class Waypoint {
  final int id;
  final double x;
  final double y;
  final double z;
  final double heading;
  final WaypointAction action;
  final int holdSeconds;

  const Waypoint({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    this.heading = 0,
    this.action = WaypointAction.none,
    this.holdSeconds = 0,
  });

  Waypoint copyWith({
    int? id,
    double? x,
    double? y,
    double? z,
    double? heading,
    WaypointAction? action,
    int? holdSeconds,
  }) {
    return Waypoint(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      heading: heading ?? this.heading,
      action: action ?? this.action,
      holdSeconds: holdSeconds ?? this.holdSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'z': z,
        'heading': heading,
        'action': action.name,
        'hold_sec': holdSeconds,
      };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
        id: json['id'] as int,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        z: (json['z'] as num).toDouble(),
        heading: (json['heading'] as num?)?.toDouble() ?? 0,
        action: WaypointAction.values
            .byName(json['action'] as String? ?? 'none'),
        holdSeconds: (json['hold_sec'] as num?)?.toInt() ?? 0,
      );
}

class Mission {
  final String name;
  final List<Waypoint> waypoints;
  final DateTime createdAt;

  const Mission({
    required this.name,
    required this.waypoints,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        name: json['name'] as String,
        waypoints: (json['waypoints'] as List)
            .map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
