import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/connection_config.dart';
import '../models/drone_command.dart';
import '../models/joystick_input.dart';

enum DroneConnectionState {
  disconnected,
  connecting,
  connected,
  degraded,
  lost,
}

class ConnectionService extends ChangeNotifier {
  DroneConnectionState _state = DroneConnectionState.disconnected;
  ConnectionConfig _config = const ConnectionConfig();
  int _latencyMs = 0;

  WebSocketChannel? _wsChannel;
  RawDatagramSocket? _udpSocket;
  StreamSubscription<dynamic>? _wsSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _lastPongTime = 0;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  DroneConnectionState get state => _state;
  ConnectionConfig get config => _config;
  int get latencyMs => _latencyMs;
  bool get isConnected => _state == DroneConnectionState.connected;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> connect(ConnectionConfig config) async {
    if (_state == DroneConnectionState.connecting) return;

    _config = config;
    _setState(DroneConnectionState.connecting);

    try {
      final wsUrl = Uri.parse(config.wsUrl);
      _wsChannel = WebSocketChannel.connect(wsUrl);
      await _wsChannel!.ready;

      _wsSubscription = _wsChannel!.stream.listen(
        _onWsMessage,
        onError: _onWsError,
        onDone: _onWsDone,
      );

      await _initUdpSocket();
      _startHeartbeat();
      _setState(DroneConnectionState.connected);
    } catch (e) {
      _setState(DroneConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
    _udpSocket?.close();
    _udpSocket = null;
    _setState(DroneConnectionState.disconnected);
  }

  void sendCommand(DroneCommand command) {
    if (_wsChannel == null) return;
    try {
      _wsChannel!.sink.add(jsonEncode(command.toJson()));
    } catch (_) {
      // WebSocket not ready
    }
  }

  void sendEstop() {
    sendCommand(DroneCommand.estop());
  }

  void sendJoystick(JoystickInput input) {
    if (_udpSocket == null) return;
    try {
      final data = utf8.encode(jsonEncode(input.toJson()));
      _udpSocket!.send(
        data,
        InternetAddress(_config.droneIp),
        _config.udpPort,
      );
    } catch (_) {
      // UDP send failed
    }
  }

  Future<void> _initUdpSocket() async {
    try {
      _udpSocket?.close();
      _udpSocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (_) {
      // UDP init failed, joystick won't work but commands still work via WS
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_wsChannel == null) return;

      sendCommand(DroneCommand.ping());

      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastPongTime > 0) {
        final elapsed = now - _lastPongTime;
        if (elapsed > 6000) {
          if (_state != DroneConnectionState.lost) {
            _setState(DroneConnectionState.lost);
            _scheduleReconnect();
          }
        } else if (elapsed > 3000) {
          if (_state != DroneConnectionState.degraded) {
            _setState(DroneConnectionState.degraded);
          }
        }
      }
    });
  }

  void _onWsMessage(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      if (type == 'pong') {
        final now = DateTime.now().millisecondsSinceEpoch;
        final ts = msg['ts'] as int? ?? now;
        _latencyMs = now - ts;
        _lastPongTime = now;
        if (_state == DroneConnectionState.degraded ||
            _state == DroneConnectionState.lost) {
          _setState(DroneConnectionState.connected);
        }
      }

      _messageController.add(msg);
    } catch (_) {
      // Malformed message
    }
  }

  void _onWsError(Object error) {
    _setState(DroneConnectionState.lost);
    _cleanup();
    _scheduleReconnect();
  }

  void _onWsDone() {
    if (_state != DroneConnectionState.disconnected) {
      _setState(DroneConnectionState.lost);
      _cleanup();
      _scheduleReconnect();
    }
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel = null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_state != DroneConnectionState.disconnected) {
        connect(_config);
      }
    });
  }

  void _setState(DroneConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}
