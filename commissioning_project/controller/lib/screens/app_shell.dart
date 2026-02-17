import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/connection_service.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/estop_button.dart';
import 'camera_screen.dart';
import 'dashboard_screen.dart';
import 'data_screen.dart';
import 'flight_screen.dart';
import 'mission_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _wakelockActive = false;

  static const _destinations = [
    _NavItem(icon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.flight, label: 'Flight'),
    _NavItem(icon: Icons.videocam, label: 'Camera'),
    _NavItem(icon: Icons.map, label: 'Mission'),
    _NavItem(icon: Icons.folder, label: 'Data'),
    _NavItem(icon: Icons.settings, label: 'Settings'),
  ];

  static const _screens = [
    DashboardScreen(),
    FlightScreen(),
    CameraScreen(),
    MissionScreen(),
    DataScreen(),
    SettingsScreen(),
  ];

  @override
  void dispose() {
    if (_wakelockActive) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  void _updateWakelock(bool connected) {
    if (connected && !_wakelockActive) {
      WakelockPlus.enable();
      _wakelockActive = true;
    } else if (!connected && _wakelockActive) {
      WakelockPlus.disable();
      _wakelockActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionService>();
    _updateWakelock(conn.isConnected);

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(
            child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
          ),
        ],
      ),
      floatingActionButton: const EstopButton(),
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          labelType: NavigationRailLabelType.all,
          destinations: _destinations
              .map((d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ))
              .toList(),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return IndexedStack(
      index: _selectedIndex,
      children: _screens,
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: _destinations
          .map((d) => NavigationDestination(
                icon: Icon(d.icon),
                label: d.label,
              ))
          .toList(),
    );
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
