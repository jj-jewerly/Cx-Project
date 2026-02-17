"""Camera plugin system: ABC + manager."""
from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from companion.config import CameraEntry

log = logging.getLogger(__name__)


class Camera(ABC):
    """Base class for all cameras."""

    @property
    @abstractmethod
    def name(self) -> str: ...

    @property
    @abstractmethod
    def fps(self) -> int: ...

    @abstractmethod
    async def init(self) -> bool:
        """Initialize hardware. Return True if successful."""
        ...

    @abstractmethod
    async def get_frame(self) -> bytes:
        """Return a JPEG-encoded frame."""
        ...

    @abstractmethod
    async def snapshot(self, path: str) -> str:
        """Save a full-resolution snapshot. Return filename."""
        ...

    @abstractmethod
    async def close(self) -> None: ...


class CameraManager:
    """Manages RGB and thermal cameras with graceful degradation."""

    def __init__(
        self,
        configs: dict[str, CameraEntry],
        simulation: bool,
        snapshot_dir: str,
    ) -> None:
        from companion.camera.sim_camera import SimCamera

        self._cameras: dict[str, Camera] = {}
        self._snapshot_dir = Path(snapshot_dir)

        for name, cfg in configs.items():
            if not cfg.enabled:
                continue
            if simulation:
                self._cameras[name] = SimCamera(name, cfg.fps)
            else:
                # Real camera creation would go here (Phase 4)
                # For now, always use sim
                self._cameras[name] = SimCamera(name, cfg.fps)

    async def init_all(self) -> None:
        from companion.camera.sim_camera import SimCamera

        self._snapshot_dir.mkdir(parents=True, exist_ok=True)

        for name, camera in list(self._cameras.items()):
            try:
                ok = await camera.init()
                if not ok:
                    log.warning("Camera %s init failed, using simulation", name)
                    self._cameras[name] = SimCamera(name, camera.fps)
                    await self._cameras[name].init()
                else:
                    log.info("Camera %s initialized", camera.name)
            except Exception as e:
                log.warning("Camera %s error: %s, using simulation", name, e)
                self._cameras[name] = SimCamera(name, camera.fps)
                await self._cameras[name].init()

    def get(self, name: str) -> Camera | None:
        return self._cameras.get(name)

    async def handle_action(self, camera_name: str, action: str) -> dict | None:
        """Handle camera command from WebSocket. Returns response message or None."""
        import time

        camera = self._cameras.get(camera_name)
        if camera is None:
            return {
                "type": "alert",
                "level": "warning",
                "message": f"Camera '{camera_name}' not available",
                "ts": int(time.time() * 1000),
            }

        if action == "snapshot":
            filename = await camera.snapshot(str(self._snapshot_dir))
            return {
                "type": "snapshot_ready",
                "camera": camera_name,
                "filename": filename,
                "ts": int(time.time() * 1000),
            }

        # record_start / record_stop -- acknowledged but not fully implemented yet
        return None

    async def close_all(self) -> None:
        for camera in self._cameras.values():
            try:
                await camera.close()
            except Exception:
                pass
