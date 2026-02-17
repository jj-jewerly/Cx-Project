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
├── commissioning_project/
│   ├── controller/              # Flutter app (PC + Android)
│   │   ├── lib/
│   │   │   ├── main.dart        # App entry, MultiProvider setup
│   │   │   ├── models/          # Data models (telemetry, mission, config)
│   │   │   ├── services/        # Connection, telemetry, settings
│   │   │   ├── screens/         # Dashboard, flight, camera, mission, data, settings
│   │   │   └── widgets/         # Reusable UI components
│   │   ├── android/             # Android platform
│   │   ├── windows/             # Windows platform
│   │   └── web/                 # Web platform
│   ├── companion/               # Raspberry Pi code (Python)
│   │   └── test_server.py       # Mock server for testing without hardware
│   ├── planning/                # Design docs, hardware list
│   │   └── hardware_shopping_list.md
│   ├── arduino_code/            # Legacy (replaced by Betaflight FC)
│   ├── raspberry_pi_code/       # Legacy skeleton code
│   └── config/                  # Configuration files
└── CLAUDE.md                    # AI assistant project rules
```

## Getting Started

### Prerequisites

- Flutter SDK 3.41+ ([install](https://docs.flutter.dev/get-started/install))
- Python 3.10+ (for mock server)
- Android SDK 36 (for Android builds)
- Visual Studio Build Tools 2022 (for Windows builds)

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

## Development Status

- [x] Phase 1: Foundation (connection, telemetry, dashboard)
- [ ] Phase 2: Manual flight control (joystick, attitude indicator)
- [ ] Phase 3: Camera feeds (RGB + thermal MJPEG)
- [ ] Phase 4: Mission planning (waypoint editor)
- [ ] Phase 5: Data review (sensor display, image gallery)
- [ ] Phase 6: Settings, polish, testing

## Key Design Decisions

- **Offline-first**: Construction sites have no internet. RPi acts as WiFi AP.
- **Betaflight FC**: No custom PID code. Off-the-shelf FC handles all flight stabilization.
- **Indoor-optimized**: Optical flow + ToF for positioning (no GPS indoors).
- **Field-friendly UI**: Dark theme, large touch targets, persistent E-STOP button.

## Hardware

See [hardware_shopping_list.md](planning/hardware_shopping_list.md) for full parts list with search keywords.

## License

MIT License - see [LICENSE](LICENSE.txt)

## Contact

gnt8521@gmail.com
