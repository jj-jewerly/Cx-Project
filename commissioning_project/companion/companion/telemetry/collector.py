"""Telemetry aggregation: DroneState + sensors -> JSON broadcast at 10Hz."""
from __future__ import annotations

import asyncio
import json
import logging
import math
import random
import time
from typing import TYPE_CHECKING

from companion.state import DroneState

if TYPE_CHECKING:
    from companion.config import ServerConfig
    from companion.sensors.base import SensorManager

log = logging.getLogger(__name__)


class TelemetryCollector:
    """Reads drone state and sensor data, builds telemetry JSON, broadcasts."""

    def __init__(
        self,
        config: ServerConfig,
        state: DroneState,
        sensors: SensorManager,
    ) -> None:
        self._hz = config.telemetry_hz
        self._state = state
        self._sensors = sensors
        self._broadcast_fn = None
        self._tick = 0

    def set_broadcast(self, fn) -> None:
        self._broadcast_fn = fn

    async def run(self) -> None:
        interval = 1.0 / self._hz
        log.info("Telemetry collector running at %d Hz", self._hz)

        while True:
            self._tick += 1
            await self._update_sensors()
            self._simulate_dynamics()

            msg = self._build_telemetry()
            if self._broadcast_fn:
                await self._broadcast_fn(msg)

            await asyncio.sleep(interval)

    async def _update_sensors(self) -> None:
        try:
            data = await self._sensors.read_all()
            self._state.sensor_data.update(data)
        except Exception as e:
            log.warning("Sensor read error: %s", e)

    def _simulate_dynamics(self) -> None:
        """Update drone state based on RC input (simulation mode).
        When real FC is connected, fc_link writes to state directly instead."""
        s = self._state
        rc = s.rc

        # Apply joystick to attitude
        s.attitude.roll = rc.roll * 30
        s.attitude.pitch = rc.pitch * 30

        # Yaw accumulation
        s.attitude.yaw = (s.attitude.yaw + rc.yaw * 5) % 360

        # Altitude from throttle (only when armed)
        if s.armed:
            s.altitude = max(0, rc.throttle * 3.0)
            if s.altitude == 0 and rc.throttle <= 0:
                s.altitude = 0.5  # Hover minimum
        else:
            s.altitude = 0.0

        # Position follows attitude slightly
        s.position.x += rc.roll * 0.01
        s.position.y += rc.pitch * 0.01
        s.position.z = s.altitude

        # Battery simulation (slow drain)
        t = self._tick / self._hz
        drain = 0.001 * math.sin(t / 10)
        s.battery.voltage = max(9.0, 11.8 - t * 0.0005 + drain)
        s.battery.percent = max(0, min(100, int((s.battery.voltage - 9.0) / 3.6 * 100)))
        s.battery.current = 2.5 + random.uniform(-0.3, 0.3) if s.armed else 0.1

    def _build_telemetry(self) -> str:
        s = self._state
        sd = s.sensor_data

        return json.dumps({
            "type": "telemetry",
            "ts": int(time.time() * 1000),
            "attitude": {
                "roll": round(s.attitude.roll, 2),
                "pitch": round(s.attitude.pitch, 2),
                "yaw": round(s.attitude.yaw, 2),
            },
            "altitude": round(s.altitude, 2),
            "battery": {
                "voltage": round(s.battery.voltage, 2),
                "percent": s.battery.percent,
                "current": round(s.battery.current, 2),
            },
            "position": {
                "x": round(s.position.x, 3),
                "y": round(s.position.y, 3),
                "z": round(s.position.z, 3),
            },
            "armed": s.armed,
            "mode": s.mode,
            "sensors": {
                "temp": round(sd.get("temp", 22.0), 1),
                "humidity": round(sd.get("humidity", 45.0), 1),
                "dust_pm25": round(sd.get("dust_pm25", 10.0), 1),
            },
        })
