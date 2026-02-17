"""
Mock RPi WebSocket server for testing the Cx Controller app.

Sends fake telemetry at 10Hz and responds to commands.
Also serves MJPEG test streams on HTTP ports 8080/8081.

Run: python test_server.py
Dependencies: pip install websockets Pillow
  (Pillow is optional - falls back to static frame without it)
"""

import asyncio
import io
import json
import math
import random
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
import threading

try:
    import websockets
except ImportError:
    print("Install websockets: pip install websockets")
    exit(1)

# Try to import Pillow for dynamic test frames
try:
    from PIL import Image, ImageDraw, ImageFont
    HAS_PILLOW = True
except ImportError:
    HAS_PILLOW = False
    print("[INFO] Pillow not installed. MJPEG streams will use a static test pattern.")
    print("       For dynamic frames: pip install Pillow")

PORT_WS = 8765
PORT_UDP = 8766
PORT_RGB = 8080
PORT_THERMAL = 8081

# Simulated drone state
drone_state = {
    "armed": False,
    "mode": "manual",
    "altitude": 0.0,
    "roll": 0.0,
    "pitch": 0.0,
    "yaw": 0.0,
    "battery_percent": 85,
    "battery_voltage": 11.8,
    "x": 0.0,
    "y": 0.0,
}

# Mission execution state
mission_state = {
    "waypoints": [],
    "running": False,
    "paused": False,
    "current_wp": 0,
    "task": None,
}

connected_clients = set()

# Minimal valid 8x8 JPEG (gray) as fallback when Pillow is not available
STATIC_JPEG = bytes([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x08,
    0x00, 0x08, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
    0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
    0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
    0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
    0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72,
    0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45,
    0x46, 0x47, 0x48, 0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
    0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 0x75,
    0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
    0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3,
    0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
    0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
    0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
    0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4,
    0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
    0x00, 0x00, 0x3F, 0x00, 0x7B, 0x94, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1F, 0xFF, 0xD9,
])


def generate_pillow_frame(camera_type, frame_num):
    """Generate a test JPEG frame using Pillow."""
    w, h = 320, 240
    t = frame_num / 10.0

    if camera_type == "rgb":
        r = int(40 + 30 * math.sin(t))
        g = int(60 + 30 * math.sin(t + 2))
        b = int(80 + 30 * math.sin(t + 4))
        img = Image.new("RGB", (w, h), (r, g, b))
        draw = ImageDraw.Draw(img)
        # Draw crosshair
        cx, cy = w // 2, h // 2
        draw.line([(cx - 20, cy), (cx + 20, cy)], fill=(0, 255, 0), width=1)
        draw.line([(cx, cy - 20), (cx, cy + 20)], fill=(0, 255, 0), width=1)
        # Draw frame counter
        draw.text((10, 10), f"RGB #{frame_num}", fill=(255, 255, 255))
        draw.text((10, h - 25), f"ALT: {drone_state['altitude']:.1f}m", fill=(255, 255, 255))
    else:
        # Thermal-like gradient
        base = int(128 + 40 * math.sin(t * 0.3))
        img = Image.new("RGB", (w, h))
        for y_pos in range(h):
            v = int(base + (y_pos / h) * 60)
            r = min(255, v + 40)
            g = min(255, v - 20)
            b = max(0, v - 80)
            for x_pos in range(w):
                img.putpixel((x_pos, y_pos), (r, g, b))
        draw = ImageDraw.Draw(img)
        draw.text((10, 10), f"THERMAL #{frame_num}", fill=(255, 255, 0))
        # Hot spot
        spot_x = int(w / 2 + 50 * math.sin(t * 0.5))
        spot_y = int(h / 2 + 30 * math.cos(t * 0.7))
        draw.ellipse(
            [(spot_x - 15, spot_y - 15), (spot_x + 15, spot_y + 15)],
            fill=(255, 100, 0),
        )

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=60)
    return buf.getvalue()


def generate_test_frame(camera_type, frame_num):
    """Generate a test JPEG frame."""
    if HAS_PILLOW:
        return generate_pillow_frame(camera_type, frame_num)
    return STATIC_JPEG


class MjpegHandler(BaseHTTPRequestHandler):
    camera_type = "rgb"

    def do_GET(self):
        if self.path == "/stream":
            self.send_response(200)
            boundary = "frame"
            self.send_header(
                "Content-Type",
                f"multipart/x-mixed-replace; boundary={boundary}",
            )
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "close")
            self.end_headers()

            frame_num = 0
            try:
                while True:
                    frame = generate_test_frame(self.camera_type, frame_num)
                    self.wfile.write(f"--{boundary}\r\n".encode())
                    self.wfile.write(b"Content-Type: image/jpeg\r\n")
                    self.wfile.write(f"Content-Length: {len(frame)}\r\n\r\n".encode())
                    self.wfile.write(frame)
                    self.wfile.write(b"\r\n")
                    self.wfile.flush()
                    frame_num += 1
                    time.sleep(0.1)  # ~10 FPS
            except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
                pass
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


def start_mjpeg_server(port, camera_type):
    class Handler(MjpegHandler):
        pass
    Handler.camera_type = camera_type

    server = ThreadedHTTPServer(("0.0.0.0", port), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


def build_telemetry():
    t = time.time()
    noise = lambda: random.uniform(-0.5, 0.5)

    drone_state["roll"] += noise() * 0.3
    drone_state["pitch"] += noise() * 0.3
    drone_state["yaw"] = (drone_state["yaw"] + noise() * 0.2) % 360

    if drone_state["armed"]:
        drone_state["altitude"] = max(0, drone_state["altitude"] + random.uniform(-0.02, 0.03))
        drone_state["battery_percent"] = max(0, drone_state["battery_percent"] - 0.01)
        drone_state["battery_voltage"] = 10.0 + (drone_state["battery_percent"] / 100) * 2.6

    return {
        "type": "telemetry",
        "ts": int(t * 1000),
        "attitude": {
            "roll": round(drone_state["roll"], 2),
            "pitch": round(drone_state["pitch"], 2),
            "yaw": round(drone_state["yaw"], 2),
        },
        "altitude": round(drone_state["altitude"], 3),
        "battery": {
            "voltage": round(drone_state["battery_voltage"], 2),
            "percent": int(drone_state["battery_percent"]),
            "current": round(random.uniform(2.0, 6.0) if drone_state["armed"] else 0.3, 2),
        },
        "position": {
            "x": round(drone_state["x"], 3),
            "y": round(drone_state["y"], 3),
            "z": round(drone_state["altitude"], 3),
        },
        "armed": drone_state["armed"],
        "mode": drone_state["mode"],
        "sensors": {
            "temp": round(22.5 + random.uniform(-0.3, 0.3), 1),
            "humidity": round(45.0 + random.uniform(-1, 1), 1),
            "dust_pm25": round(12.0 + random.uniform(-2, 2), 1),
        },
    }


async def run_mission():
    """Simulate mission execution by progressing through waypoints."""
    total = len(mission_state["waypoints"])
    if total == 0:
        return

    print(f"  >> Mission started: {total} waypoints")
    while mission_state["current_wp"] < total and mission_state["running"]:
        if mission_state["paused"]:
            await asyncio.sleep(0.5)
            continue

        wp_index = mission_state["current_wp"]
        progress = {
            "type": "mission_progress",
            "current_wp": wp_index,
            "total_wp": total,
            "status": "running",
        }
        data = json.dumps(progress)
        dead = set()
        for ws in connected_clients:
            try:
                await ws.send(data)
            except websockets.exceptions.ConnectionClosed:
                dead.add(ws)
        connected_clients.difference_update(dead)

        print(f"  >> Mission WP {wp_index + 1}/{total}")
        await asyncio.sleep(3.0)  # 3 seconds per waypoint

        if mission_state["running"] and not mission_state["paused"]:
            mission_state["current_wp"] += 1

    if mission_state["running"] and mission_state["current_wp"] >= total:
        # Mission completed
        completed = {
            "type": "mission_progress",
            "current_wp": total - 1,
            "total_wp": total,
            "status": "completed",
        }
        data = json.dumps(completed)
        for ws in connected_clients:
            try:
                await ws.send(data)
            except websockets.exceptions.ConnectionClosed:
                pass
        print("  >> Mission completed")
        mission_state["running"] = False
        mission_state["current_wp"] = 0


def handle_command(msg):
    cmd_type = msg.get("type")
    response = None

    if cmd_type == "ping":
        response = {"type": "pong", "ts": msg.get("ts", int(time.time() * 1000))}

    elif cmd_type == "arm":
        drone_state["armed"] = msg.get("armed", False)
        status = "ARMED" if drone_state["armed"] else "DISARMED"
        print(f"  >> Drone {status}")
        if drone_state["armed"]:
            drone_state["altitude"] = 0.5

    elif cmd_type == "estop":
        drone_state["armed"] = False
        drone_state["altitude"] = 0.0
        drone_state["roll"] = 0.0
        drone_state["pitch"] = 0.0
        print("  >> EMERGENCY STOP")
        response = {
            "type": "alert",
            "level": "warning",
            "message": "Emergency stop activated",
            "ts": int(time.time() * 1000),
        }

    elif cmd_type == "mode":
        drone_state["mode"] = msg.get("mode", "manual")
        print(f"  >> Mode: {drone_state['mode']}")

    elif cmd_type == "mission_upload":
        waypoints = msg.get("waypoints", [])
        mission_state["waypoints"] = waypoints
        mission_state["current_wp"] = 0
        print(f"  >> Mission uploaded: {len(waypoints)} waypoints")

    elif cmd_type == "mission_ctrl":
        action = msg.get("action", "")
        print(f"  >> Mission control: {action}")
        if action == "start":
            mission_state["running"] = True
            mission_state["paused"] = False
            if mission_state["task"] is None or mission_state["task"].done():
                mission_state["task"] = asyncio.ensure_future(run_mission())
        elif action == "pause":
            mission_state["paused"] = True
        elif action == "cancel":
            mission_state["running"] = False
            mission_state["paused"] = False
            mission_state["current_wp"] = 0

    elif cmd_type == "camera":
        camera = msg.get("camera", "rgb")
        action = msg.get("action", "snapshot")
        print(f"  >> Camera {camera}: {action}")
        if action == "snapshot":
            response = {
                "type": "snapshot_ready",
                "camera": camera,
                "filename": f"img_{int(time.time())}.jpg",
                "ts": int(time.time() * 1000),
            }

    else:
        print(f"  >> Unknown command: {cmd_type}")

    return response


async def ws_handler(websocket):
    addr = websocket.remote_address
    print(f"[+] Client connected: {addr}")
    connected_clients.add(websocket)

    try:
        async for message in websocket:
            try:
                msg = json.loads(message)
                cmd_type = msg.get("type", "?")
                if cmd_type != "ping":
                    print(f"[CMD] {cmd_type} from {addr}")

                response = handle_command(msg)
                if response:
                    await websocket.send(json.dumps(response))
            except json.JSONDecodeError:
                print(f"[!] Invalid JSON from {addr}")
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        connected_clients.discard(websocket)
        print(f"[-] Client disconnected: {addr}")


async def telemetry_broadcaster():
    while True:
        if connected_clients:
            telemetry = build_telemetry()
            data = json.dumps(telemetry)
            dead = set()
            for ws in connected_clients:
                try:
                    await ws.send(data)
                except websockets.exceptions.ConnectionClosed:
                    dead.add(ws)
            connected_clients.difference_update(dead)
        await asyncio.sleep(0.1)  # 10Hz


async def udp_listener():
    loop = asyncio.get_event_loop()

    class UdpProtocol(asyncio.DatagramProtocol):
        def datagram_received(self, data, addr):
            try:
                msg = json.loads(data.decode())
                r = msg.get("r", 0)
                p = msg.get("p", 0)
                t = msg.get("t", 0)
                y = msg.get("y", 0)
                drone_state["roll"] = r * 30
                drone_state["pitch"] = p * 30
                if drone_state["armed"]:
                    drone_state["altitude"] = max(0, t * 3.0)
                drone_state["yaw"] = (drone_state["yaw"] + y * 5) % 360
            except Exception:
                pass

    transport, _ = await loop.create_datagram_endpoint(
        UdpProtocol, local_addr=("0.0.0.0", PORT_UDP)
    )

    try:
        await asyncio.Future()
    finally:
        transport.close()


async def main():
    print("=" * 50)
    print("  Cx Drone Mock Server")
    print("=" * 50)
    print(f"  WebSocket:  ws://0.0.0.0:{PORT_WS}")
    print(f"  UDP:        0.0.0.0:{PORT_UDP}")

    start_mjpeg_server(PORT_RGB, "rgb")
    print(f"  MJPEG RGB:  http://0.0.0.0:{PORT_RGB}/stream")
    start_mjpeg_server(PORT_THERMAL, "thermal")
    print(f"  MJPEG THM:  http://0.0.0.0:{PORT_THERMAL}/stream")

    print(f"  Telemetry:  10Hz broadcast")
    pillow_status = "Pillow (dynamic)" if HAS_PILLOW else "static fallback"
    print(f"  Frames:     {pillow_status}")
    print("=" * 50)
    print()

    async with websockets.serve(ws_handler, "0.0.0.0", PORT_WS):
        await asyncio.gather(
            telemetry_broadcaster(),
            udp_listener(),
        )


if __name__ == "__main__":
    asyncio.run(main())
