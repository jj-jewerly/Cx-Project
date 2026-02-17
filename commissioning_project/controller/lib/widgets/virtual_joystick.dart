import 'package:flutter/material.dart';

class VirtualJoystick extends StatefulWidget {
  final double size;
  final ValueChanged<Offset> onChanged;
  final bool returnToCenter;
  final String? label;

  const VirtualJoystick({
    super.key,
    this.size = 180,
    required this.onChanged,
    this.returnToCenter = true,
    this.label,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _stickPosition = Offset.zero;

  double get _radius => widget.size / 2;
  double get _knobRadius => widget.size * 0.18;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        GestureDetector(
          onPanStart: _onPan,
          onPanUpdate: _onPan,
          onPanEnd: (_) => _onRelease(),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _JoystickPainter(
                stickPosition: _stickPosition,
                radius: _radius,
                knobRadius: _knobRadius,
                baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                knobColor: Theme.of(context).colorScheme.primary,
                crosshairColor:
                    Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(60),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onPan(dynamic details) {
    final localPos = (details as dynamic).localPosition as Offset;
    final center = Offset(_radius, _radius);
    var delta = localPos - center;

    final distance = delta.distance;
    if (distance > _radius - _knobRadius) {
      delta = delta / distance * (_radius - _knobRadius);
    }

    setState(() {
      _stickPosition = delta;
    });

    final maxRange = _radius - _knobRadius;
    widget.onChanged(Offset(
      (delta.dx / maxRange).clamp(-1.0, 1.0),
      (-delta.dy / maxRange).clamp(-1.0, 1.0),
    ));
  }

  void _onRelease() {
    if (widget.returnToCenter) {
      setState(() {
        _stickPosition = Offset.zero;
      });
      widget.onChanged(Offset.zero);
    }
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset stickPosition;
  final double radius;
  final double knobRadius;
  final Color baseColor;
  final Color knobColor;
  final Color crosshairColor;

  _JoystickPainter({
    required this.stickPosition,
    required this.radius,
    required this.knobRadius,
    required this.baseColor,
    required this.knobColor,
    required this.crosshairColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(radius, radius);

    // Base circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill,
    );

    // Base border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = crosshairColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Crosshair lines
    final crossPaint = Paint()
      ..color = crosshairColor
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, radius),
      Offset(radius * 2, radius),
      crossPaint,
    );
    canvas.drawLine(
      Offset(radius, 0),
      Offset(radius, radius * 2),
      crossPaint,
    );

    // Knob shadow
    canvas.drawCircle(
      center + stickPosition + const Offset(1, 2),
      knobRadius,
      Paint()..color = Colors.black.withAlpha(40),
    );

    // Knob
    canvas.drawCircle(
      center + stickPosition,
      knobRadius,
      Paint()..color = knobColor,
    );

    // Knob inner highlight
    canvas.drawCircle(
      center + stickPosition,
      knobRadius * 0.5,
      Paint()..color = knobColor.withAlpha(200),
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) {
    return stickPosition != oldDelegate.stickPosition;
  }
}
