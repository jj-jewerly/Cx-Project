"""Shared drone state. Single asyncio thread, no locks needed."""
from dataclasses import dataclass, field
import time


@dataclass
class Attitude:
    roll: float = 0.0
    pitch: float = 0.0
    yaw: float = 0.0


@dataclass
class BatteryState:
    voltage: float = 12.6
    percent: int = 100
    current: float = 0.0


@dataclass
class Position:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0


@dataclass
class RcChannels:
    """Normalized joystick input (-1.0 to 1.0)."""
    roll: float = 0.0
    pitch: float = 0.0
    throttle: float = 0.0
    yaw: float = 0.0
    last_update: float = 0.0

    def update(self, r: float, p: float, t: float, y: float) -> None:
        self.roll = r
        self.pitch = p
        self.throttle = t
        self.yaw = y
        self.last_update = time.time()


@dataclass
class DroneState:
    armed: bool = False
    mode: str = "manual"
    attitude: Attitude = field(default_factory=Attitude)
    altitude: float = 0.0
    battery: BatteryState = field(default_factory=BatteryState)
    position: Position = field(default_factory=Position)
    sensor_data: dict[str, float] = field(default_factory=dict)
    rc: RcChannels = field(default_factory=RcChannels)

    def reset(self) -> None:
        self.armed = False
        self.mode = "manual"
        self.attitude = Attitude()
        self.altitude = 0.0
        self.position = Position()
        self.rc = RcChannels()
