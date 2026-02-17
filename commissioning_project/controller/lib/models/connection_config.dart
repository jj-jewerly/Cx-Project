enum ConnectionMode { rpiAp, siteWifi }

class ConnectionConfig {
  final ConnectionMode mode;
  final String droneIp;
  final int wsPort;
  final int udpPort;
  final int rgbCameraPort;
  final int thermalCameraPort;

  const ConnectionConfig({
    this.mode = ConnectionMode.rpiAp,
    this.droneIp = '192.168.4.1',
    this.wsPort = 8765,
    this.udpPort = 8766,
    this.rgbCameraPort = 8080,
    this.thermalCameraPort = 8081,
  });

  String get wsUrl => 'ws://$droneIp:$wsPort';
  String get rgbStreamUrl => 'http://$droneIp:$rgbCameraPort/stream';
  String get thermalStreamUrl => 'http://$droneIp:$thermalCameraPort/stream';

  ConnectionConfig copyWith({
    ConnectionMode? mode,
    String? droneIp,
    int? wsPort,
    int? udpPort,
    int? rgbCameraPort,
    int? thermalCameraPort,
  }) {
    return ConnectionConfig(
      mode: mode ?? this.mode,
      droneIp: droneIp ?? this.droneIp,
      wsPort: wsPort ?? this.wsPort,
      udpPort: udpPort ?? this.udpPort,
      rgbCameraPort: rgbCameraPort ?? this.rgbCameraPort,
      thermalCameraPort: thermalCameraPort ?? this.thermalCameraPort,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'drone_ip': droneIp,
        'ws_port': wsPort,
        'udp_port': udpPort,
        'rgb_camera_port': rgbCameraPort,
        'thermal_camera_port': thermalCameraPort,
      };

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) =>
      ConnectionConfig(
        mode: ConnectionMode.values.byName(json['mode'] as String),
        droneIp: json['drone_ip'] as String,
        wsPort: json['ws_port'] as int,
        udpPort: json['udp_port'] as int,
        rgbCameraPort: json['rgb_camera_port'] as int,
        thermalCameraPort: json['thermal_camera_port'] as int,
      );
}
