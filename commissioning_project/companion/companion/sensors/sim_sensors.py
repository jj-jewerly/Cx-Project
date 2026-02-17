"""Simulated sensors for desktop/testing mode."""
from __future__ import annotations

import math
import random
import time
from typing import TYPE_CHECKING

from companion.sensors.base import Sensor

if TYPE_CHECKING:
    from companion.config import SensorEntry


class SimSensor(Sensor):
    """Generates plausible fake data for any sensor type."""

    def __init__(self, sensor_type: str | SensorEntry) -> None:
        if isinstance(sensor_type, str):
            self._type = sensor_type
        else:
            self._type = sensor_type.type
        self._start = time.time()

    @property
    def name(self) -> str:
        return f"sim_{self._type}"

    async def init(self) -> bool:
        return True

    async def read(self) -> dict[str, float]:
        t = time.time() - self._start
        gen = _GENERATORS.get(self._type, _default_gen)
        return gen(t)

    async def close(self) -> None:
        pass


def _bme280_gen(t: float) -> dict[str, float]:
    return {
        "temp": 22.5 + 1.5 * math.sin(t / 30) + random.uniform(-0.2, 0.2),
        "humidity": 45.0 + 5.0 * math.sin(t / 60) + random.uniform(-0.5, 0.5),
    }


def _sds011_gen(t: float) -> dict[str, float]:
    return {
        "dust_pm25": max(0, 12.0 + 3.0 * math.sin(t / 45) + random.uniform(-1.5, 1.5)),
    }


def _vl53l1x_gen(t: float) -> dict[str, float]:
    return {
        "tof_altitude": max(0, 1.5 + random.uniform(-0.01, 0.01)),
    }


def _pmw3901_gen(t: float) -> dict[str, float]:
    return {
        "flow_dx": random.uniform(-0.3, 0.3),
        "flow_dy": random.uniform(-0.3, 0.3),
    }


def _default_gen(t: float) -> dict[str, float]:
    return {}


_GENERATORS: dict[str, object] = {
    "bme280": _bme280_gen,
    "sds011": _sds011_gen,
    "vl53l1x": _vl53l1x_gen,
    "pmw3901": _pmw3901_gen,
}
