"""Sensor plugin system: ABC + manager + registry."""
from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from companion.config import SensorEntry

log = logging.getLogger(__name__)


class Sensor(ABC):
    """Base class for all sensors."""

    @property
    @abstractmethod
    def name(self) -> str: ...

    @abstractmethod
    async def init(self) -> bool:
        """Initialize hardware. Return True if successful."""
        ...

    @abstractmethod
    async def read(self) -> dict[str, float]:
        """Read sensor data. Return name->value pairs."""
        ...

    @abstractmethod
    async def close(self) -> None: ...


# Registry: type name -> sensor class
SENSOR_REGISTRY: dict[str, type[Sensor]] = {}


def register_sensor(type_name: str, cls: type[Sensor]) -> None:
    SENSOR_REGISTRY[type_name] = cls


def create_sensor(cfg: SensorEntry) -> Sensor:
    cls = SENSOR_REGISTRY.get(cfg.type)
    if cls is None:
        raise ValueError(f"Unknown sensor type: {cfg.type}")
    return cls(cfg)


class SensorManager:
    """Manages all sensors with per-sensor graceful degradation."""

    def __init__(self, configs: list[SensorEntry], simulation: bool) -> None:
        from companion.sensors.sim_sensors import SimSensor

        self._sensors: list[Sensor] = []
        for cfg in configs:
            if not cfg.enabled:
                continue
            if simulation:
                self._sensors.append(SimSensor(cfg.type))
            else:
                try:
                    self._sensors.append(create_sensor(cfg))
                except ValueError:
                    log.warning("Unknown sensor type '%s', using simulation", cfg.type)
                    self._sensors.append(SimSensor(cfg.type))

    async def init_all(self) -> None:
        from companion.sensors.sim_sensors import SimSensor

        for i, sensor in enumerate(self._sensors):
            try:
                ok = await sensor.init()
                if not ok:
                    log.warning("Sensor %s init failed, using simulation", sensor.name)
                    self._sensors[i] = SimSensor(sensor.name)
                    await self._sensors[i].init()
                else:
                    log.info("Sensor %s initialized", sensor.name)
            except Exception as e:
                log.warning("Sensor %s error: %s, using simulation", sensor.name, e)
                self._sensors[i] = SimSensor(sensor.name)
                await self._sensors[i].init()

    async def read_all(self) -> dict[str, float]:
        result: dict[str, float] = {}
        for sensor in self._sensors:
            try:
                data = await sensor.read()
                result.update(data)
            except Exception as e:
                log.warning("Sensor %s read error: %s", sensor.name, e)
        return result

    async def close_all(self) -> None:
        for sensor in self._sensors:
            try:
                await sensor.close()
            except Exception:
                pass
