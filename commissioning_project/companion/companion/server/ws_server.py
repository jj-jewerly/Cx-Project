"""WebSocket server: command dispatch + telemetry broadcast."""
from __future__ import annotations

import asyncio
import json
import logging
import time
from typing import TYPE_CHECKING

import websockets

from companion.state import DroneState

if TYPE_CHECKING:
    from companion.camera.base import CameraManager
    from companion.config import ServerConfig
    from companion.mission.executor import MissionExecutor

log = logging.getLogger(__name__)


class WebSocketServer:
    """WebSocket server handling commands and broadcasting telemetry."""

    def __init__(
        self,
        config: ServerConfig,
        state: DroneState,
        cameras: CameraManager,
        mission: MissionExecutor,
    ) -> None:
        self._bind = config.bind_address
        self._port = config.ws_port
        self._state = state
        self._cameras = cameras
        self._mission = mission
        self._clients: set = set()

    async def run(self) -> None:
        async with websockets.serve(
            self._handler,
            self._bind,
            self._port,
        ):
            log.info("WebSocket server on ws://%s:%d", self._bind, self._port)
            await asyncio.Future()  # Run forever

    async def broadcast(self, message: str) -> None:
        if not self._clients:
            return
        disconnected = set()
        for ws in self._clients:
            try:
                await ws.send(message)
            except websockets.ConnectionClosed:
                disconnected.add(ws)
        self._clients -= disconnected

    async def _handler(self, ws) -> None:
        self._clients.add(ws)
        addr = ws.remote_address
        log.info("Client connected: %s", addr)

        try:
            async for raw in ws:
                try:
                    msg = json.loads(raw)
                    response = await self._dispatch(msg)
                    if response:
                        await ws.send(json.dumps(response))
                except json.JSONDecodeError:
                    log.warning("Invalid JSON from %s", addr)
        except websockets.ConnectionClosed:
            pass
        finally:
            self._clients.discard(ws)
            log.info("Client disconnected: %s", addr)

    async def _dispatch(self, msg: dict) -> dict | None:
        cmd_type = msg.get("type")

        if cmd_type == "ping":
            return {"type": "pong", "ts": msg.get("ts")}

        elif cmd_type == "arm":
            armed = msg.get("armed", False)
            self._state.armed = armed
            if armed:
                self._state.altitude = 0.5
            else:
                self._state.altitude = 0.0
            log.info("Arm: %s", armed)
            return None

        elif cmd_type == "estop":
            self._state.armed = False
            self._state.altitude = 0.0
            self._state.attitude.roll = 0.0
            self._state.attitude.pitch = 0.0
            log.warning("E-STOP activated")
            return {
                "type": "alert",
                "level": "warning",
                "message": "Emergency stop activated",
                "ts": _now_ms(),
            }

        elif cmd_type == "mode":
            self._state.mode = msg.get("mode", "manual")
            log.info("Mode: %s", self._state.mode)
            return None

        elif cmd_type == "mission_upload":
            self._mission.upload(msg.get("waypoints", []))
            return None

        elif cmd_type == "mission_ctrl":
            await self._mission.control(msg.get("action", ""))
            return None

        elif cmd_type == "camera":
            camera_name = msg.get("camera", "rgb")
            action = msg.get("action", "snapshot")
            return await self._cameras.handle_action(camera_name, action)

        else:
            log.debug("Unknown command type: %s", cmd_type)
            return None


def _now_ms() -> int:
    return int(time.time() * 1000)
