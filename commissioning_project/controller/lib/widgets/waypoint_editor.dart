import 'dart:math';

import 'package:flutter/material.dart';

import '../models/mission.dart';

/// 2D grid-based waypoint editor.
///
/// Tap to add waypoints, drag to move them, long-press to edit properties.
/// Grid represents the indoor space in meters.
class WaypointEditor extends StatefulWidget {
  final List<Waypoint> waypoints;
  final int? activeWaypointIndex;
  final ValueChanged<List<Waypoint>> onChanged;
  final ValueChanged<int>? onWaypointTap;
  final double gridSizeMeters;

  const WaypointEditor({
    super.key,
    required this.waypoints,
    required this.onChanged,
    this.activeWaypointIndex,
    this.onWaypointTap,
    this.gridSizeMeters = 10.0,
  });

  @override
  State<WaypointEditor> createState() => _WaypointEditorState();
}

class _WaypointEditorState extends State<WaypointEditor> {
  int? _draggingIndex;
  Offset? _dragOffset;

  Offset _worldToCanvas(double x, double y, Size size) {
    final scale = min(size.width, size.height) / widget.gridSizeMeters;
    return Offset(
      size.width / 2 + x * scale,
      size.height / 2 - y * scale,
    );
  }

  Offset _canvasToWorld(Offset pos, Size size) {
    final scale = min(size.width, size.height) / widget.gridSizeMeters;
    return Offset(
      (pos.dx - size.width / 2) / scale,
      -(pos.dy - size.height / 2) / scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapUp: (details) => _onTap(details.localPosition, size),
          onPanStart: (details) => _onDragStart(details.localPosition, size),
          onPanUpdate: (details) => _onDragUpdate(details.localPosition, size),
          onPanEnd: (_) => _onDragEnd(),
          onLongPressStart: (details) =>
              _onLongPress(details.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _WaypointGridPainter(
              waypoints: widget.waypoints,
              activeIndex: widget.activeWaypointIndex,
              draggingIndex: _draggingIndex,
              dragOffset: _dragOffset,
              gridSizeMeters: widget.gridSizeMeters,
              gridColor:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(30),
              waypointColor: Theme.of(context).colorScheme.primary,
              activeColor: Theme.of(context).colorScheme.tertiary,
              pathColor:
                  Theme.of(context).colorScheme.primary.withAlpha(100),
              textColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }

  int? _hitTest(Offset canvasPos, Size size) {
    const hitRadius = 20.0;
    for (int i = widget.waypoints.length - 1; i >= 0; i--) {
      final wp = widget.waypoints[i];
      final wpPos = _worldToCanvas(wp.x, wp.y, size);
      if ((canvasPos - wpPos).distance < hitRadius) {
        return i;
      }
    }
    return null;
  }

  void _onTap(Offset pos, Size size) {
    final hitIndex = _hitTest(pos, size);
    if (hitIndex != null) {
      widget.onWaypointTap?.call(hitIndex);
      return;
    }

    // Add new waypoint
    final world = _canvasToWorld(pos, size);
    final newId = widget.waypoints.isEmpty
        ? 1
        : widget.waypoints.map((w) => w.id).reduce(max) + 1;
    final newWp = Waypoint(
      id: newId,
      x: double.parse(world.dx.toStringAsFixed(2)),
      y: double.parse(world.dy.toStringAsFixed(2)),
      z: 1.5,
    );
    widget.onChanged([...widget.waypoints, newWp]);
  }

  void _onDragStart(Offset pos, Size size) {
    final hitIndex = _hitTest(pos, size);
    if (hitIndex != null) {
      setState(() {
        _draggingIndex = hitIndex;
        _dragOffset = pos;
      });
    }
  }

  void _onDragUpdate(Offset pos, Size size) {
    if (_draggingIndex == null) return;
    setState(() => _dragOffset = pos);

    final world = _canvasToWorld(pos, size);
    final updated = List<Waypoint>.from(widget.waypoints);
    updated[_draggingIndex!] = updated[_draggingIndex!].copyWith(
      x: double.parse(world.dx.toStringAsFixed(2)),
      y: double.parse(world.dy.toStringAsFixed(2)),
    );
    widget.onChanged(updated);
  }

  void _onDragEnd() {
    setState(() {
      _draggingIndex = null;
      _dragOffset = null;
    });
  }

  void _onLongPress(Offset pos, Size size) {
    final hitIndex = _hitTest(pos, size);
    if (hitIndex != null) {
      widget.onWaypointTap?.call(hitIndex);
    }
  }
}

class _WaypointGridPainter extends CustomPainter {
  final List<Waypoint> waypoints;
  final int? activeIndex;
  final int? draggingIndex;
  final Offset? dragOffset;
  final double gridSizeMeters;
  final Color gridColor;
  final Color waypointColor;
  final Color activeColor;
  final Color pathColor;
  final Color textColor;

  _WaypointGridPainter({
    required this.waypoints,
    required this.activeIndex,
    required this.draggingIndex,
    required this.dragOffset,
    required this.gridSizeMeters,
    required this.gridColor,
    required this.waypointColor,
    required this.activeColor,
    required this.pathColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width, size.height) / gridSizeMeters;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw grid
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final halfGrid = gridSizeMeters / 2;
    for (double m = -halfGrid; m <= halfGrid; m += 1.0) {
      // Vertical lines
      final x = cx + m * scale;
      if (x >= 0 && x <= size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      // Horizontal lines
      final y = cy - m * scale;
      if (y >= 0 && y <= size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Draw axis lines
    final axisPaint = Paint()
      ..color = gridColor.withAlpha(80)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), axisPaint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), axisPaint);

    // Draw origin marker
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()..color = textColor.withAlpha(80),
    );

    // Draw path lines
    if (waypoints.length >= 2) {
      final pathPaint = Paint()
        ..color = pathColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < waypoints.length; i++) {
        final wp = waypoints[i];
        final pos = Offset(cx + wp.x * scale, cy - wp.y * scale);
        if (i == 0) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
      canvas.drawPath(path, pathPaint);
    }

    // Draw waypoints
    for (int i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final pos = Offset(cx + wp.x * scale, cy - wp.y * scale);
      final isActive = i == activeIndex;
      final color = isActive ? activeColor : waypointColor;
      final radius = isActive ? 12.0 : 10.0;

      // Outer circle
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // Border
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = color.withAlpha(200)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Action indicator
      if (wp.action != WaypointAction.none) {
        canvas.drawCircle(
          pos + const Offset(8, -8),
          4,
          Paint()..color = activeColor,
        );
      }

      // Number label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Scale indicator
    final scaleBarLength = scale; // 1 meter
    final scaleBarY = size.height - 20;
    final scaleBarX = 16.0;
    canvas.drawLine(
      Offset(scaleBarX, scaleBarY),
      Offset(scaleBarX + scaleBarLength, scaleBarY),
      Paint()
        ..color = textColor.withAlpha(120)
        ..strokeWidth = 2,
    );
    final scalePainter = TextPainter(
      text: TextSpan(
        text: '1m',
        style: TextStyle(color: textColor.withAlpha(120), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    scalePainter.layout();
    scalePainter.paint(
      canvas,
      Offset(scaleBarX + scaleBarLength + 4, scaleBarY - 6),
    );
  }

  @override
  bool shouldRepaint(covariant _WaypointGridPainter oldDelegate) {
    return waypoints != oldDelegate.waypoints ||
        activeIndex != oldDelegate.activeIndex ||
        draggingIndex != oldDelegate.draggingIndex;
  }
}
