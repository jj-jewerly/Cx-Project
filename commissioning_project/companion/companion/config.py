"""Configuration loader. TOML -> dataclasses."""
import logging
from dataclasses import dataclass, field
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    # Python < 3.11 fallback
    import tomli as tomllib  # type: ignore[no-redef]

log = logging.getLogger(__name__)


@dataclass(frozen=True)
class ServerConfig:
    ws_port: int = 8765
    udp_port: int = 8766
    rgb_mjpeg_port: int = 8080
    thermal_mjpeg_port: int = 8081
    telemetry_hz: int = 10
    bind_address: str = "0.0.0.0"


@dataclass(frozen=True)
class FcConfig:
    enabled: bool = True
    serial_port: str = "/dev/ttyACM0"
    baud_rate: int = 115200


@dataclass(frozen=True)
class SensorEntry:
    type: str
    enabled: bool = True
    bus: str = ""
    address: int = 0
    poll_hz: int = 10


@dataclass(frozen=True)
class CameraEntry:
    type: str = "sim"
    enabled: bool = True
    resolution: tuple[int, int] = (640, 480)
    fps: int = 10


@dataclass(frozen=True)
class AppConfig:
    simulation: bool = True
    log_level: str = "INFO"
    snapshot_dir: str = "snapshots"
    server: ServerConfig = field(default_factory=ServerConfig)
    fc: FcConfig = field(default_factory=FcConfig)
    sensors: list[SensorEntry] = field(default_factory=list)
    cameras: dict[str, CameraEntry] = field(default_factory=dict)


def _parse_camera(raw: dict) -> CameraEntry:
    res = raw.get("resolution", [640, 480])
    return CameraEntry(
        type=raw.get("type", "sim"),
        enabled=raw.get("enabled", True),
        resolution=(res[0], res[1]) if isinstance(res, list) else res,
        fps=raw.get("fps", 10),
    )


def load_config(path: str = "config.toml") -> AppConfig:
    config_path = Path(path)
    if not config_path.exists():
        log.warning("Config file not found at %s, using defaults (simulation mode)", path)
        return AppConfig()

    with open(config_path, "rb") as f:
        raw = tomllib.load(f)

    return AppConfig(
        simulation=raw.get("simulation", True),
        log_level=raw.get("log_level", "INFO"),
        snapshot_dir=raw.get("snapshot_dir", "snapshots"),
        server=ServerConfig(**raw.get("server", {})),
        fc=FcConfig(**raw.get("fc", {})),
        sensors=[SensorEntry(**s) for s in raw.get("sensors", [])],
        cameras={k: _parse_camera(v) for k, v in raw.get("cameras", {}).items()},
    )
