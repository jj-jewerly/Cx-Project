"""Mission execution engine. Waypoint state machine."""
from __future__ import annotations

import asyncio
import json
import logging
import time

from companion.state import DroneState

log = logging.getLogger(__name__)


class MissionExecutor:
    """Manages waypoint mission upload, execution, pause, cancel."""

    def __init__(self, state: DroneState) -> None:
        self._state = state
        self._waypoints: list[dict] = []
        self._status = "idle"  # idle, running, paused, completed, error
        self._current_wp = 0
        self._total_wp = 0
        self._task: asyncio.Task | None = None
        self._pause_event = asyncio.Event()
        self._pause_event.set()  # Not paused initially
        # Callback for broadcasting messages
        self._broadcast_fn = None

    @property
    def status(self) -> str:
        return self._status

    def set_broadcast(self, fn) -> None:
        """Set the broadcast function for sending progress updates."""
        self._broadcast_fn = fn

    def upload(self, waypoints: list[dict]) -> None:
        self._waypoints = waypoints
        self._total_wp = len(waypoints)
        self._current_wp = 0
        self._status = "idle"
        log.info("Mission uploaded: %d waypoints", self._total_wp)

    async def control(self, action: str) -> None:
        if action == "start":
            if not self._waypoints:
                log.warning("No waypoints uploaded")
                return
            if self._status == "paused":
                self._pause_event.set()
                self._status = "running"
                log.info("Mission resumed")
                return
            if self._status == "running":
                return
            self._status = "running"
            self._current_wp = 0
            self._task = asyncio.ensure_future(self._run_mission())
            log.info("Mission started")

        elif action == "pause":
            if self._status == "running":
                self._status = "paused"
                self._pause_event.clear()
                log.info("Mission paused at waypoint %d", self._current_wp)

        elif action == "cancel":
            self._status = "idle"
            self._pause_event.set()
            if self._task and not self._task.done():
                self._task.cancel()
                self._task = None
            log.info("Mission cancelled")

    async def _run_mission(self) -> None:
        try:
            for i, wp in enumerate(self._waypoints):
                if self._status not in ("running", "paused"):
                    break

                self._current_wp = i + 1
                await self._broadcast_progress()

                # Wait if paused
                await self._pause_event.wait()
                if self._status not in ("running", "paused"):
                    break

                log.info(
                    "Waypoint %d/%d: (%.1f, %.1f, %.1f)",
                    i + 1, self._total_wp,
                    wp.get("x", 0), wp.get("y", 0), wp.get("z", 0),
                )

                # Simulate navigation (3 seconds per waypoint)
                hold = wp.get("hold_sec", 0)
                await asyncio.sleep(3.0 + hold)

                if self._status not in ("running", "paused"):
                    break

            if self._status == "running":
                self._status = "completed"
                await self._broadcast_progress()
                log.info("Mission completed")

        except asyncio.CancelledError:
            log.info("Mission task cancelled")
        except Exception as e:
            self._status = "error"
            log.error("Mission error: %s", e)
            await self._broadcast_progress()

    async def _broadcast_progress(self) -> None:
        if self._broadcast_fn is None:
            return
        msg = json.dumps({
            "type": "mission_progress",
            "current_wp": self._current_wp,
            "total_wp": self._total_wp,
            "status": self._status,
        })
        await self._broadcast_fn(msg)
