"""Application orchestrator: initializes all subsystems and runs the event loop."""
from __future__ import annotations

import asyncio
import logging

from companion.camera.base import CameraManager
from companion.config import load_config
from companion.log import setup_logging
from companion.mission.executor import MissionExecutor
from companion.sensors.base import SensorManager
from companion.server.mjpeg_server import MjpegServer
from companion.server.udp_server import UdpServer
from companion.server.ws_server import WebSocketServer
from companion.state import DroneState
from companion.telemetry.collector import TelemetryCollector

log = logging.getLogger(__name__)


class Application:
    """Main application. Wires everything together and runs."""

    async def run(self, config_path: str = "config.toml") -> None:
        config = load_config(config_path)
        setup_logging(config.log_level)

        log.info("Cx Companion starting (simulation=%s)", config.simulation)

        # Shared state
        state = DroneState()

        # Subsystems
        sensors = SensorManager(config.sensors, config.simulation)
        cameras = CameraManager(config.cameras, config.simulation, config.snapshot_dir)
        mission = MissionExecutor(state)

        # Initialize hardware (or sim fallbacks)
        await sensors.init_all()
        await cameras.init_all()

        # Servers
        ws = WebSocketServer(config.server, state, cameras, mission)
        udp = UdpServer(config.server, state)
        mjpeg_rgb = MjpegServer(
            config.server.rgb_mjpeg_port,
            cameras.get("rgb"),
            config.server.bind_address,
        )
        mjpeg_thermal = MjpegServer(
            config.server.thermal_mjpeg_port,
            cameras.get("thermal"),
            config.server.bind_address,
        )

        # Telemetry collector
        telemetry = TelemetryCollector(config.server, state, sensors)

        # Wire broadcast functions
        telemetry.set_broadcast(ws.broadcast)
        mission.set_broadcast(ws.broadcast)

        log.info("All subsystems initialized. Starting servers...")

        # Run everything concurrently
        try:
            await asyncio.gather(
                ws.run(),
                udp.run(),
                mjpeg_rgb.run(),
                mjpeg_thermal.run(),
                telemetry.run(),
            )
        except asyncio.CancelledError:
            log.info("Shutting down...")
        finally:
            await sensors.close_all()
            await cameras.close_all()
            log.info("Cx Companion stopped")
