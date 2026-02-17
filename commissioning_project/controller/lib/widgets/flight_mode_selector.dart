import 'package:flutter/material.dart';

enum FlightMode { manual, waypoint, hold }

class FlightModeSelector extends StatelessWidget {
  final FlightMode selected;
  final ValueChanged<FlightMode> onChanged;

  const FlightModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<FlightMode>(
      segments: const [
        ButtonSegment(
          value: FlightMode.manual,
          label: Text('Manual'),
          icon: Icon(Icons.gamepad, size: 18),
        ),
        ButtonSegment(
          value: FlightMode.waypoint,
          label: Text('Waypoint'),
          icon: Icon(Icons.route, size: 18),
        ),
        ButtonSegment(
          value: FlightMode.hold,
          label: Text('Hold'),
          icon: Icon(Icons.pause_circle, size: 18),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}
