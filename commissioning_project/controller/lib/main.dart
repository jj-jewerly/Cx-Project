import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/app_shell.dart';
import 'services/camera_service.dart';
import 'services/connection_service.dart';
import 'services/mission_service.dart';
import 'services/settings_service.dart';
import 'services/telemetry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsService();
  await settings.load();

  runApp(CxControllerApp(settings: settings));
}

class CxControllerApp extends StatelessWidget {
  final SettingsService settings;

  const CxControllerApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionService()),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProxyProvider<ConnectionService, TelemetryService>(
          create: (_) => TelemetryService(),
          update: (_, conn, telemetry) {
            telemetry!.listenTo(conn.messageStream);
            return telemetry;
          },
        ),
        ChangeNotifierProxyProvider<ConnectionService, CameraService>(
          create: (context) => CameraService(context.read<ConnectionService>()),
          update: (_, conn, camera) => camera!,
        ),
        ChangeNotifierProxyProvider<ConnectionService, MissionService>(
          create: (context) => MissionService(context.read<ConnectionService>()),
          update: (_, conn, mission) => mission!,
        ),
      ],
      child: MaterialApp(
        title: 'Cx Controller',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}
