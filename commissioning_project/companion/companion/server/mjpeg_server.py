"""MJPEG HTTP stream server using aiohttp."""
from __future__ import annotations

import asyncio
import logging
from typing import TYPE_CHECKING

from aiohttp import web

if TYPE_CHECKING:
    from companion.camera.base import Camera

log = logging.getLogger(__name__)


class MjpegServer:
    """Serves MJPEG stream on a given port for a single camera."""

    def __init__(self, port: int, camera: Camera | None, bind: str = "0.0.0.0") -> None:
        self._port = port
        self._camera = camera
        self._bind = bind

    async def run(self) -> None:
        if self._camera is None:
            log.warning("No camera for MJPEG server on port %d, skipping", self._port)
            return

        app = web.Application()
        app.router.add_get("/stream", self._handle_stream)

        runner = web.AppRunner(app, access_log=None)
        await runner.setup()
        site = web.TCPSite(runner, self._bind, self._port)
        await site.start()
        log.info(
            "MJPEG server (%s) on http://%s:%d/stream",
            self._camera.name, self._bind, self._port,
        )

        await asyncio.Future()  # Run forever

    async def _handle_stream(self, request: web.Request) -> web.StreamResponse:
        response = web.StreamResponse()
        response.content_type = "multipart/x-mixed-replace; boundary=frame"
        response.headers["Cache-Control"] = "no-cache"
        response.headers["Connection"] = "close"
        await response.prepare(request)

        interval = 1.0 / self._camera.fps
        try:
            while True:
                frame = await self._camera.get_frame()
                header = (
                    b"--frame\r\n"
                    b"Content-Type: image/jpeg\r\n"
                    b"Content-Length: " + str(len(frame)).encode() + b"\r\n"
                    b"\r\n"
                )
                await response.write(header + frame + b"\r\n")
                await asyncio.sleep(interval)
        except (ConnectionResetError, ConnectionAbortedError):
            pass

        return response
