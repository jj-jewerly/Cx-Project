# Cx Drone - Hardware Shopping List

Indoor building commissioning drone.
Search keywords included for easy Googling.

---

## Frame & Propulsion

| Item | Spec | Search Keyword | Notes |
|------|------|----------------|-------|
| Drone frame | 3-5" indoor frame (or custom 3D print) | "3 inch drone frame indoor" / "5 inch drone frame kit" | Custom frame designed in Siemens NX, 3D printed. Or buy a ready-made micro frame for prototyping |
| Brushless motors x4 | 1404-2004 size, ~3000-4000KV (for 3") or 2205 ~2300KV (for 5") | "1404 brushless motor drone" / "2205 2300kv motor" | Match to frame size |
| ESC 4-in-1 | 20-35A, BLHeli_S or BLHeli_32 | "4in1 ESC 20A BLHeli_S" | Integrated with FC preferred |
| Propellers | Match frame size (3" or 5") | "3 inch propeller drone" / "5040 propeller" | Buy extras, they break |
| LiPo battery | 3S or 4S, 650-1300mAh (3") or 1300-1500mAh (5") | "3S 650mah lipo" / "4S 1300mah lipo XT60" | At least 2 batteries |
| LiPo charger | Balance charger, supports 3S-4S | "lipo balance charger" / "ISDT Q6 charger" | Essential for safety |
| Battery straps | Rubberized straps | "lipo battery strap drone" | |
| XT60 connectors | XT60 male/female pair | "XT60 connector" | If not included |

## Flight Controller

| Item | Spec | Search Keyword | Notes |
|------|------|----------------|-------|
| FC board | Betaflight compatible, F4 or F7 | "F405 flight controller" / "F722 flight controller" | F4 is budget, F7 is better. Many come as FC+ESC stack |
| FC+ESC stack (combo) | All-in-one FC + 4in1 ESC | "F4 AIO flight controller ESC stack" / "SpeedyBee F405 V4 stack" | Recommended: buy as stack to save wiring |

## Companion Computer (Raspberry Pi)

| Item | Spec | Search Keyword | Notes |
|------|------|----------------|-------|
| Raspberry Pi | Pi 4B (2GB+) or Pi 5 | "Raspberry Pi 4B 4GB" / "Raspberry Pi 5" | Pi 5 is faster but heavier. Pi Zero 2W for ultra-light |
| RPi camera (RGB) | Pi Camera Module v2 or v3 | "Raspberry Pi camera module v3" | Official module, CSI connector |
| Thermal camera | FLIR Lepton 3.5 + breakout, or MLX90640 | "FLIR Lepton 3.5 breakout" / "MLX90640 thermal camera raspberry pi" | Lepton = better resolution (160x120), MLX90640 = cheaper (32x24) |
| MicroSD card | 32GB+ Class 10 / A2 | "microSD 32GB A2" | For RPi OS |
| USB-C power cable | Short, for RPi power from drone battery | "USB-C power cable short" | Or use BEC from FC |
| BEC / voltage regulator | 5V 3A, from battery voltage | "5V 3A BEC drone" / "UBEC 5V" | Power RPi from drone battery |
| UART cable | For RPi <-> FC serial connection | "UART TTL cable" / "JST-SH 1.0mm cable" | Check FC UART pinout |

## Sensors

| Item | Spec | Search Keyword | Notes |
|------|------|----------------|-------|
| Optical flow sensor | PMW3901 or PAA5100JE | "PMW3901 optical flow sensor" / "Bitcraze Flow deck" | Indoor positioning (no GPS) |
| ToF range sensor | VL53L1X (up to 4m) | "VL53L1X time of flight sensor" | Altitude hold, obstacle avoidance |
| Environment sensor | BME280 (temp/humidity/pressure) or SHT31 | "BME280 sensor module" / "SHT31 temperature humidity" | I2C, connect to RPi |
| Dust/PM2.5 sensor | PMS5003 or SDS011 | "PMS5003 PM2.5 sensor" / "SDS011 air quality" | PMS5003 is lighter for drone |
| LED strip (optional) | WS2812B short strip | "WS2812B LED strip short" | Status indicator on drone |

## Communication

| Item | Spec | Search Keyword | Notes |
|------|------|----------------|-------|
| WiFi (built-in) | RPi has built-in WiFi | - | RPi acts as WiFi AP, no extra hardware needed |
| WiFi antenna (optional) | External antenna for RPi | "Raspberry Pi external WiFi antenna" | Better range if needed |

## Tools & Accessories

| Item | Spec | Search Keyword | Notes |
|------|------|----------------|-------|
| Soldering iron | Temperature controlled, fine tip | "soldering iron station TS100" / "Pinecil soldering iron" | For wiring FC, ESC, sensors |
| Solder wire | 0.8mm, 60/40 or lead-free | "solder wire 0.8mm" | |
| Heat shrink tubing | Assorted sizes | "heat shrink tubing assortment" | |
| Wire | Silicone 20-28 AWG assortment | "silicone wire AWG assortment drone" | |
| Hex drivers | 1.5mm, 2mm, 2.5mm | "hex screwdriver set metric" | For M2, M3 frame bolts |
| Prop removal tool | Prop nut wrench | "drone prop wrench" | Match motor shaft |
| Lipo safe bag | Fireproof charging bag | "lipo safe bag" | NEVER charge without one |
| Double-sided tape | 3M VHB or foam tape | "3M VHB tape drone" | Mounting sensors, RPi |
| Zip ties | Small, assorted | "zip ties small" | Cable management |
| Standoffs | M2/M3 nylon standoffs | "M3 nylon standoff set" | Mounting FC, RPi |

## 3D Printing (already available)

| Item | Notes |
|------|-------|
| Siemens NX | Frame design (already set up) |
| 3D Printer | For custom frame, sensor mounts, RPi mount |
| PLA/PETG filament | PETG for frame (stronger), PLA for mounts |

---

## Priority Order (what to buy first)

### Round 1: Basic Flight Test
1. FC+ESC stack (or FC + 4in1 ESC)
2. Motors x4
3. Propellers
4. LiPo battery x2 + charger + safe bag
5. Frame (3D print or buy)
6. Basic tools (soldering iron, hex drivers)

### Round 2: Companion Computer
7. Raspberry Pi 4B/5
8. MicroSD card
9. BEC (5V power for RPi)
10. UART cable (RPi <-> FC)

### Round 3: Cameras & Sensors
11. RPi Camera Module (RGB)
12. Optical flow sensor (PMW3901)
13. ToF sensor (VL53L1X)
14. Environment sensor (BME280)

### Round 4: Advanced
15. Thermal camera (FLIR Lepton or MLX90640)
16. PM2.5 sensor (PMS5003)
17. External WiFi antenna (if range is an issue)
