# ROS 2 on Raspberry Pi with Docker 🤖

> **Headless setup** — Raspberry Pi OS Lite (64-bit) · ROS 2 Humble · Docker

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Sequential Setup Guide](#sequential-setup-guide)
4. [Publisher–Subscriber Test](#publishersubscriber-test)
5. [Daily Workflow](#daily-workflow)
6. [Common Errors & Fixes](#common-errors--fixes)
7. [Script Reference](#script-reference)

---

## Prerequisites

### Hardware
| Item | Requirement |
|------|-------------|
| Raspberry Pi | 64-bit model (Pi 4 / Pi 5 recommended) |
| MicroSD Card | ≥ 16 GB (Class 10 or better) |
| Wi-Fi | Active internet connection |
| Laptop | Windows or Ubuntu |
| ESP32 | For future robotics integration |
| USB Cable | For flashing / serial comms |

### Software
| Item | Details |
|------|---------|
| Raspberry Pi OS Lite | **64-bit** (Bookworm / Trixie) |
| SSH | Enabled via Raspberry Pi Imager |
| Docker | Installed by the setup script |
| ROS 2 Humble | Pulled as Docker image `ros:humble-ros-base` |

---

## Quick Start

> **Run these two scripts in order on your Raspberry Pi.**

```bash
# 1 — SSH into your Pi
ssh aadi_1234@<PI_IP_ADDRESS>

# 2 — Clone this repository
git clone https://github.com/aadi613/ROS2-on-rpi-with-dockers.git
cd ROS2-on-rpi-with-dockers

# 3 — Make scripts executable
chmod +x install_ros2_docker.sh ros2_demo_test.sh

# 4 — Install Docker + ROS 2 (takes a few minutes)
bash install_ros2_docker.sh

# 5 — Run the Publisher–Subscriber demo test
bash ros2_demo_test.sh
```

---

## Sequential Setup Guide

### Step 1 — Flash Raspberry Pi
Use **Raspberry Pi Imager** to flash **Raspberry Pi OS Lite (64-bit)**.

During flashing, enable:
- ✅ SSH
- ✅ Wi-Fi (SSID + Password)
- ✅ Username: `aadi_1234`
- ✅ Password: *(your choice)*

---

### Step 2 — Find Raspberry Pi IP
Check your router's connected devices list, or use:
```bash
# From your laptop (Windows PowerShell or Ubuntu terminal)
ping raspberrypi.local
```
Example IP: `10.139.37.39`

---

### Step 3 — SSH into Raspberry Pi
```bash
# Windows CMD / PowerShell / Ubuntu Terminal
ssh aadi_1234@10.139.37.39
```

---

### Step 4 — Verify OS
```bash
cat /etc/os-release
```
**Expected output includes:**
```
Debian GNU/Linux 13 (trixie)
```

---

### Step 5 — Install Docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```
**Verify:**
```bash
docker --version
# Expected: Docker version 29.x.x
```

---

### Step 6 — Verify Docker Works
```bash
sudo docker run hello-world
# Expected: Hello from Docker!
```

---

### Step 7 — Download ROS 2 Humble Image
```bash
sudo docker pull ros:humble-ros-base
```

---

### Step 8 — Create ROS 2 Container
```bash
sudo docker run -it --name ros2_humble ros:humble-ros-base
# Expected prompt: root@xxxxxxxx:/#
```

---

### Step 9 — Verify ROS 2
```bash
ros2 --help
# Expected: ros2 is an extensible command-line tool for ROS 2
```

---

### Step 10 — Exit Container
```bash
exit
```

---

### Step 11 — Re-enter Existing Container
```bash
sudo docker exec -it ros2_humble bash
```

---

### Step 12 — Enable ROS 2 Environment
```bash
source /opt/ros/humble/setup.bash
echo $ROS_DISTRO
# Expected: humble
```

---

### Step 13 — Verify ROS 2 Topics
```bash
ros2 topic list
```
**Expected:**
```
/parameter_events
/rosout
```

---

### Step 14 — Install Demo Nodes
```bash
apt update
apt install -y ros-humble-demo-nodes-cpp
```

---

## Publisher–Subscriber Test

> Open **two separate SSH terminals** to your Raspberry Pi.

### Terminal 1 — Publisher (Talker)
```bash
ssh aadi_1234@10.139.37.39
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 run demo_nodes_cpp talker
```
**Expected output:**
```
[INFO] Publishing: Hello World: 1
[INFO] Publishing: Hello World: 2
...
```

### Terminal 2 — Subscriber (Listener)
```bash
ssh aadi_1234@10.139.37.39
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 run demo_nodes_cpp listener
```
**Expected output:**
```
[INFO] I heard: Hello World: 1
[INFO] I heard: Hello World: 2
...
```

---

## Daily Workflow

Run these commands **every time you power on the Raspberry Pi**:

```bash
# 1 — SSH into Pi
ssh aadi_1234@10.139.37.39

# 2 — Check container status
sudo docker ps

# 3 — Start container if it is stopped
sudo docker start ros2_humble

# 4 — Enter the container
sudo docker exec -it ros2_humble bash

# 5 — Enable ROS 2
source /opt/ros/humble/setup.bash

# 6 — Verify
echo $ROS_DISTRO   # → humble
```

---

## Common Errors & Fixes

### Error 1 — `ros2: command not found`
```bash
source /opt/ros/humble/setup.bash
```

### Error 2 — `Package 'demo_nodes_cpp' not found`
```bash
apt update
apt install -y ros-humble-demo-nodes-cpp
```

### Error 3 — `ssh: connect to host xxx port 22: Connection timed out`
- ✅ Check Raspberry Pi is powered on
- ✅ Verify Wi-Fi connection on the Pi
- ✅ Re-check the IP address (it may have changed)
- ✅ Try `ping <PI_IP>` from your laptop

### Error 4 — Container not running
```bash
# List all containers (including stopped ones)
sudo docker ps -a

# Start the stopped container
sudo docker start ros2_humble
```

---

## Script Reference

| Script | Purpose |
|--------|---------|
| [`install_ros2_docker.sh`](install_ros2_docker.sh) | Installs Docker, pulls ROS 2 Humble image, creates & configures the container, installs demo nodes |
| [`ros2_demo_test.sh`](ros2_demo_test.sh) | Runs talker + listener nodes, captures output, and validates that pub–sub communication works |

---

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         Raspberry Pi (64-bit)           │
│    OS: Raspberry Pi OS Lite (Debian)    │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │         Docker Engine             │  │
│  │                                   │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Container: ros2_humble     │  │  │
│  │  │  Image: ros:humble-ros-base │  │  │
│  │  │                             │  │  │
│  │  │  • ROS 2 Humble             │  │  │
│  │  │  • demo_nodes_cpp           │  │  │
│  │  │  • talker / listener        │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
         ▲
         │ SSH
         ▼
┌─────────────────┐
│  Laptop         │
│  Windows/Ubuntu │
└─────────────────┘
```

---

## License

MIT License — feel free to use and modify for your robotics projects.

---

*Made with ❤️ for ROS 2 + Raspberry Pi robotics projects.*
