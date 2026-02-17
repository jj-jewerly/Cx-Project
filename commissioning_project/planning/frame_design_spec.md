# Cx Drone Frame Design Specification

## 1. Design Goals

- Indoor building commissioning (offices, corridors, factory floors, warehouses)
- Ceiling height range: 2.5m ~ 10m+
- Must fit through standard doorways (800mm width)
- Collision-tolerant (prop guards mandatory)
- Modular payload mounting
- 3D-printable where possible, with option for carbon tube arms

---

## 2. Configuration

**Quadcopter X-frame** (most common, simple, well-supported by Betaflight)

```
    Motor 1 (CW)          Motor 2 (CCW)
         \                  /
          \                /
           [--- FC ---]
          /    [RPi]    \
         /                \
    Motor 3 (CCW)         Motor 4 (CW)
```

---

## 3. Key Dimensions

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| **Wheelbase (diagonal)** | 250mm | Good balance of stability and size for indoor |
| **Arm length (center to motor)** | ~125mm | From 250mm diagonal |
| **Prop size** | 5" (127mm) | Standard for 250 class, good thrust/efficiency |
| **Overall width (with guards)** | ~380mm | Fits through 800mm doors with margin |
| **Overall height** | ~120mm | Low profile for tight ceilings |
| **Prop guard outer diameter** | ~160mm per prop | Full surround, connected between arms |

---

## 4. Weight Budget

| Component | Est. Weight | Notes |
|-----------|-------------|-------|
| Frame (3D print / carbon) | 150-250g | Depends on material |
| Motors x4 (2205/2306 size) | 120g | ~30g each |
| ESC 4-in-1 | 30g | BLHeli_S or BLHeli_32 |
| Flight Controller | 15g | F4/F7 Betaflight board |
| Battery (4S 1300-1500mAh) | 160-180g | 8-12 min flight time target |
| Props x4 | 20g | 5" triblade |
| Raspberry Pi 4/5 | 45-50g | Companion computer |
| RGB Camera (Pi Camera v3) | 5g | |
| Thermal Camera (MLX90640) | 10g | I2C or SPI |
| Wiring, standoffs, misc | 30g | |
| **Subtotal** | **~600-650g** | |
| Sensor payload margin | 50-100g | Temp/humidity, ToF, LiDAR |
| **Target AUW** | **~700-750g** | All Up Weight |

**Thrust requirement**: At least 2:1 thrust-to-weight ratio
- 750g AUW -> need 1500g+ total thrust
- 4x 2205 motors with 5" props typically produce 500-700g thrust each
- Total available: ~2000-2800g -> ratio 2.5-3.7:1 (good)

---

## 5. Frame Structure

### 5.1 Center Plate (Main Body)

- Houses FC, ESC, battery
- Dimensions: ~100mm x 100mm
- Thickness: 3-4mm (3D print) or 2mm (carbon)
- Mounting pattern: 30.5x30.5mm (standard FC mount) + 20x20mm option
- Battery strap slots (top or bottom mount)

### 5.2 Arms (x4)

**Option A: 3D Printed**
- Cross-section: ~15mm x 10mm (rectangular tube)
- Material: PETG or Nylon (PLA too brittle for crashes)
- Integrated prop guard attachment points

**Option B: Carbon Tube**
- 10mm or 12mm round carbon tube
- 3D printed motor mounts press-fit onto tube ends
- 3D printed center hub joins all 4 arms
- Lighter and stiffer than full 3D print

### 5.3 Prop Guards

- Full 360-degree surround per prop
- Connected between adjacent props for rigidity
- Height: ~25mm (covers prop plane)
- Material: TPU (flexible, absorbs impact) or PETG
- Must not interfere with airflow significantly

### 5.4 Upper Deck (Payload Platform)

- Mounts above center plate on standoffs (25-30mm spacing)
- Dimensions: ~100mm x 80mm
- RPi mounting holes (58mm x 49mm pattern for Pi 4)
- Camera mount point (front-facing, adjustable tilt)
- Sensor mounting holes (M2.5 pattern, multiple positions)
- Vibration dampening (rubber grommets or TPU standoffs)

---

## 6. Payload Mounting

### Camera Mount

```
Front of drone
      |
  [RGB Camera]  - Fixed forward, slight downward tilt (~15 deg)
  [Thermal Cam] - Below or beside RGB, same direction
```

- Pi Camera V3: ribbon cable to RPi
- Thermal (MLX90640): I2C, small breakout board
- Mount should allow tilt adjustment (0-45 deg range)
- 3D printed gimbal optional (2-axis: pitch + roll stabilization)

### Sensor Bay

- Bottom or side-mounted
- BME280 / SHT31: temperature + humidity (I2C)
- SDS011 / PMS5003: particulate matter / dust (UART)
- VL53L1X / TFMini: ToF distance sensor for altitude (I2C/UART)
- Optional: PMW3901 optical flow sensor (bottom, SPI)

---

## 7. Electrical Layout

```
[Battery 4S] --> [PDB/ESC 4in1] --> [Motors x4]
                      |
                  [Betaflight FC]
                      |  (UART)
                  [Raspberry Pi]
                      |
              [Cameras + Sensors]
```

### Power Distribution

- Battery: 4S LiPo (14.8V nominal)
- FC + ESC: direct from battery
- RPi: 5V BEC (from FC or separate 5V regulator, 3A minimum)
- Cameras/sensors: powered from RPi 5V/3.3V pins

### Signal Connections

| From | To | Protocol | Notes |
|------|----|----------|-------|
| FC | RPi | UART (MSP) | TX/RX, 115200 baud |
| RPi | RGB Camera | CSI ribbon | Pi Camera connector |
| RPi | Thermal | I2C | SDA/SCL, 3.3V |
| RPi | ToF sensor | I2C | Same bus, different address |
| RPi | Dust sensor | UART | USB-serial adapter |
| RPi | Temp/humidity | I2C | Same bus |
| RPi | Optical flow | SPI | Bottom-facing |

---

## 8. NX Design Checklist

When modeling in Siemens NX:

- [ ] Center plate with FC/ESC mounting holes (30.5mm pattern)
- [ ] Battery strap slots (top or bottom)
- [ ] 4 arms (parametric length for easy wheelbase change)
- [ ] Motor mount at each arm end (matching motor bolt pattern)
- [ ] Prop guards (full surround, connected between arms)
- [ ] Upper deck with RPi mounting holes
- [ ] Camera mount bracket (adjustable tilt)
- [ ] Sensor bay / mounting points
- [ ] Standoff holes (M3, connecting center plate to upper deck)
- [ ] Wire routing channels in arms
- [ ] Assembly: check prop clearance, guard clearance
- [ ] Export STL for 3D printing (check wall thickness >= 1.5mm)

---

## 9. 3D Print Settings (Reference)

| Parameter | PLA | PETG | TPU (guards) |
|-----------|-----|------|--------------|
| Nozzle temp | 200-210 | 230-240 | 220-230 |
| Bed temp | 60 | 80 | 60 |
| Layer height | 0.2mm | 0.2mm | 0.2mm |
| Infill | 30-40% | 30-40% | 20-30% |
| Walls | 3 | 3-4 | 3 |
| Supports | minimal | minimal | none ideally |

Recommended: **PETG for structural parts** (arms, plates), **TPU for prop guards** (flexible on impact).

---

## 10. Reference Dimensions for NX

```
All dimensions in mm.

Motor mount bolt pattern: M3, 16mm x 19mm (common 2205/2306)
FC mount: M3, 30.5 x 30.5mm (with M2 20x20 option)
RPi 4 mount: M2.5, 58 x 49mm
Pi Camera V3: 25 x 24mm board, 2x M2 mount holes
Battery: ~75 x 35 x 30mm (1300mAh 4S typical)

Prop diameter: 127mm (5 inch)
Min prop-to-prop clearance: 5mm
Min prop-to-guard clearance: 3mm

Standoff heights: 25mm (center to upper deck)
M3 hardware throughout (except camera/RPi M2.5)
```
