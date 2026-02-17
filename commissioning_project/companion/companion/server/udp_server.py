"""UDP server: receives joystick input at 50Hz."""
from __future__ import annotations

import asyncio
import json
import logging
from typing import TYPE_CHECKING

from companion.state import DroneState

if TYPE_CHECKING:
    from companion.config import ServerConfig

log = logging.getLogger(__name__)


class _JoystickProtocol(asyncio.DatagramProtocol):
    """asyncio UDP protocol for receiving joystick data."""

    def __init__(self, state: DroneState) -> None:
        self._state = state

    def datagram_received(self, data: bytes, addr: tuple) -> None:
        try:
            msg = json.loads(data.decode())
            self._state.rc.update(
                r=float(msg.get("r", 0)),
                p=float(msg.get("p", 0)),
                t=float(msg.get("t", 0)),
                y=float(msg.get("y", 0)),
            )
        except (json.JSONDecodeError, ValueError, KeyError):
            pass

    def error_received(self, exc: Exception) -> None:
        log.warning("UDP error: %s", exc)


class UdpServer:
    """UDP joystick receiver."""

    def __init__(self, config: ServerConfig, state: DroneState) -> None:
        self._bind = config.bind_address
        self._port = config.udp_port
        self._state = state

    async def run(self) -> None:
        loop = asyncio.get_running_loop()
        transport, _ = await loop.create_datagram_endpoint(
            lambda: _JoystickProtocol(self._state),
            local_addr=(self._bind, self._port),
        )
        log.info("UDP server on %s:%d", self._bind, self._port)

        try:
            await asyncio.Future()  # Run forever
        finally:
            transport.close()
