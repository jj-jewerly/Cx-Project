class DroneCommand {
  final String type;
  final Map<String, dynamic> payload;
  final int timestamp;

  DroneCommand({
    required this.type,
    this.payload = const {},
  }) : timestamp = DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'type': type,
        ...payload,
        'ts': timestamp,
      };

  factory DroneCommand.arm(bool armed) => DroneCommand(
        type: 'arm',
        payload: {'armed': armed},
      );

  factory DroneCommand.estop() => DroneCommand(type: 'estop');

  factory DroneCommand.mode(String mode) => DroneCommand(
        type: 'mode',
        payload: {'mode': mode},
      );

  factory DroneCommand.missionUpload(
          List<Map<String, dynamic>> waypoints) =>
      DroneCommand(
        type: 'mission_upload',
        payload: {'waypoints': waypoints},
      );

  factory DroneCommand.missionCtrl(String action) => DroneCommand(
        type: 'mission_ctrl',
        payload: {'action': action},
      );

  factory DroneCommand.camera(String camera, String action) =>
      DroneCommand(
        type: 'camera',
        payload: {'camera': camera, 'action': action},
      );

  factory DroneCommand.ping() => DroneCommand(type: 'ping');
}
