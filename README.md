# Cx - Indoor Drone Commissioning System

Indoor building commissioning drone for construction site inspection.
Captures RGB/thermal images and environmental data (temperature, humidity, dust) in offline environments.

## System Architecture

```
[Flutter Controller App]  <--WiFi-->  [Raspberry Pi]  <--Serial/MSP-->  [Betaflight FC]
   (Windows PC / Android)               (Companion)                      (Motor Control)
```

| Component | Technology | Role |
|-----------|-----------|------|
| Controller App | Flutter (Dart) | PC + tablet drone control UI |
| Companion Computer | Python (Raspberry Pi) | Camera, comms, telemetry relay, sensors |
| Flight Controller | Betaflight (off-the-shelf FC) | Motor control, PID stabilization |
| Frame | Siemens NX + 3D Print | Custom indoor-optimized frame |
| Communication | WiFi (RPi as AP) | Offline, no internet required |

## Communication Protocol

| Channel | Protocol | Port | Purpose |
|---------|----------|------|---------|
| Commands / Telemetry | WebSocket (JSON) | 8765 | Arm, mode, mission, alerts, telemetry @10Hz |
| Joystick | UDP (JSON) | 8766 | Roll/pitch/throttle/yaw @50Hz |
| RGB Camera | HTTP MJPEG | 8080 | Live video stream |
| Thermal Camera | HTTP MJPEG | 8081 | Thermal video stream |

## Project Structure

```
Cx/
└── commissioning_project/
    ├── controller/              # Flutter app (PC + Android)
    │   ├── lib/
    │   │   ├── main.dart        # App entry, MultiProvider setup
    │   │   ├── models/          # Data models (telemetry, mission, config, commands)
    │   │   ├── services/        # Connection, telemetry, camera, mission, settings
    │   │   ├── screens/         # Dashboard, flight, camera, mission, data, settings
    │   │   └── widgets/         # Joystick, attitude indicator, MJPEG viewer, etc.
    │   ├── test/                # Unit + widget tests
    │   ├── android/             # Android platform
    │   ├── windows/             # Windows platform
    │   └── web/                 # Web platform
    ├── companion/               # Raspberry Pi code (Python)
    │   └── test_server.py       # Mock server for development without hardware
    └── planning/                # Design docs
        ├── hardware_shopping_list.md
        └── frame_design_spec.md
```

## Getting Started

### Prerequisites

- Flutter SDK 3.41+ ([install](https://docs.flutter.dev/get-started/install))
- Python 3.10+ with `websockets` package (for mock server)
- Android SDK 36 (for Android builds)
- Visual Studio Build Tools 2022 (for Windows builds)
- Optional: `Pillow` Python package (for dynamic mock camera frames)

### Run the Controller App

```bash
# 1. Start the mock drone server (for testing without hardware)
cd commissioning_project/companion
pip install websockets
python test_server.py

# 2. Run the Flutter app
cd commissioning_project/controller
flutter pub get
flutter run -d windows    # or: flutter run -d chrome
```

3. In the app: Settings > set Drone IP to `127.0.0.1` > Dashboard > Connect

### Build

```bash
flutter build windows     # Windows executable
flutter build apk         # Android APK
flutter build web         # Web app
```

## Controller App Features

- **Dashboard**: Connection controls, arm/disarm, telemetry summary, sensor gauges, alerts
- **Flight Control**: Dual virtual joystick (Mode 2), keyboard support (WASD/arrows), attitude indicator, flight mode selector
- **Camera**: Live RGB + thermal MJPEG feeds, snapshot capture, recording toggle
- **Mission Planning**: 2D grid waypoint editor, waypoint actions (photo/hold), mission upload/execute/pause
- **Data Review**: Flight log charts, sensor history, snapshot gallery
- **Settings**: Network config, drone parameters, joystick calibration
- **Safety**: Persistent E-STOP button on every screen, connection loss detection, wakelock during flight

## Key Design Decisions

- **Offline-first**: Construction sites have no internet. RPi acts as WiFi AP.
- **Betaflight FC**: No custom PID code. Off-the-shelf FC handles all flight stabilization.
- **Indoor-optimized**: Optical flow + ToF for positioning (no GPS indoors).
- **Field-friendly UI**: Dark theme, large touch targets, persistent E-STOP button.

## Hardware

- [Hardware Shopping List](planning/hardware_shopping_list.md) - Full parts list with search keywords
- [Frame Design Spec](planning/frame_design_spec.md) - 250mm quadcopter frame spec for Siemens NX

## Next Steps

- Raspberry Pi companion software (Python: WebSocket server, camera pipeline, MSP to FC, sensor reading)
- Drone frame CAD design in Siemens NX
- Hardware assembly and integration testing

## License

MIT License - see [LICENSE](LICENSE.txt)

## Contact

gnt8521@gmail.com
