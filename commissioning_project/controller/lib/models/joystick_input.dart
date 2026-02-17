class JoystickInput {
  final double roll;
  final double pitch;
  final double throttle;
  final double yaw;

  const JoystickInput({
    this.roll = 0,
    this.pitch = 0,
    this.throttle = 0,
    this.yaw = 0,
  });

  Map<String, dynamic> toJson() => {
        'r': double.parse(roll.toStringAsFixed(3)),
        'p': double.parse(pitch.toStringAsFixed(3)),
        't': double.parse(throttle.toStringAsFixed(3)),
        'y': double.parse(yaw.toStringAsFixed(3)),
      };

  static const zero = JoystickInput();
}
