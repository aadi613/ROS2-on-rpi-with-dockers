# ROS 2 on Raspberry Pi with Docker 🤖

> **Headless setup** — Raspberry Pi OS Lite (64-bit) · ROS 2 Humble · Docker

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Important Notes After Installation](#important-notes-after-installation)
4. [Sequential Setup Guide](#sequential-setup-guide)
5. [Publisher–Subscriber Test](#publishersubscriber-test)
6. [Daily Workflow](#daily-workflow)
7. [Common Errors & Fixes](#common-errors--fixes)
8. [Script Reference](#script-reference)

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
```

> ⚠️ **After the install script finishes — you MUST log out and log back in once:**
> ```bash
> exit                              # log out of Pi
> ssh aadi_1234@<PI_IP_ADDRESS>    # log back in
> ```
> This activates the `docker` group so you can use Docker **without** `sudo`.

```bash
# 5 — Run the Publisher–Subscriber demo test
bash ros2_demo_test.sh
```

---

## Important Notes After Installation

### 🔑 Docker Group — One-time Re-login Required

The install script automatically adds your user (`aadi_1234`) to the `docker` group so you can run Docker **without `sudo`**. However, this change **only takes effect after you log out and log back in**.

```bash
# Step 1 — After install_ros2_docker.sh finishes, exit the SSH session
exit

# Step 2 — SSH back in
ssh aadi_1234@<PI_IP_ADDRESS>

# Step 3 — Now you can use docker WITHOUT sudo
docker ps
docker exec -it ros2_humble bash
```

> **Why does this happen?**
> Linux group membership is read at login time. Adding a user to a group mid-session doesn't update the running shell. A fresh login picks up the new group.

> **What if I skip the re-login?**
> The script uses `sudo docker` internally so installation still completes correctly.
> But until you re-login, you'll get `permission denied` errors when running `docker` without `sudo`.

### ⚡ Quick Fix (without re-login)
If you don't want to log out right away, run this in the current session:
```bash
newgrp docker
```
This opens a new shell with the `docker` group active — valid only for that terminal session.

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

### Step 2 — Find Raspberry Pi IP Address

> 📺 **Prefer watching instead of reading?** See the [YouTube reference links](#youtube-reference) at the end of this section.

There are **3 methods** — try them in order:

---

#### ✅ Method 1 — `ping` with hostname (Easiest, try this first)

**Windows (PowerShell / CMD) and Ubuntu Terminal:**
```bash
ping raspberrypi.local
```
If it replies, the IP will show in the output, e.g.:
```
Reply from 10.139.37.39: bytes=32 time=4ms TTL=64
```
> ⚠️ This only works if mDNS is active on your network. If it times out, use Method 2.

---

#### ✅ Method 2 — Router Device List (Most Reliable)

1. Find your **router's IP (gateway):**

   **Windows** — open CMD / PowerShell:
   ```cmd
   ipconfig
   ```
   Look for **Default Gateway**, e.g. `192.168.1.1`

   **Ubuntu** — open Terminal:
   ```bash
   ip route | grep default
   ```
   Look for the IP after `via`, e.g. `192.168.1.1`

2. Type that IP into your **browser** → log in with your router credentials
3. Find a page called **"Connected Devices"**, **"DHCP Clients"**, or **"Device List"**
4. Look for a device named **`raspberrypi`** or your custom hostname → that's your Pi's IP ✅

---

#### ✅ Method 3 — Network Scan with `nmap`

**Windows** — Download & install [nmap](https://nmap.org/download.html), then in CMD:
```cmd
nmap -sn 192.168.1.0/24
```

**Ubuntu** — Install and run:
```bash
sudo apt install nmap
sudo nmap -sn 192.168.1.0/24
```

> Replace `192.168.1.0/24` with your actual subnet (from `ipconfig` / `ip addr`).

Look for a line mentioning **"Raspberry Pi Trading"** — that row has your Pi's IP.

**Windows alternative** — [Advanced IP Scanner](https://www.advanced-ip-scanner.com/) (free GUI tool):
1. Download and run it — no install needed
2. Click **Scan**
3. Look for `raspberrypi` in the device list

---

#### Example IP
```
10.139.37.39
```

---

#### 📺 YouTube Reference

> **Best video for this step (Windows + Ubuntu, ~5 mins):**
> ▶️ [How to Find Raspberry Pi IP Address — Full Guide](https://youtu.be/NOqunlnD7Cc?si=srVvQl-hTAeM4d1H)


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
sudo docker start ros2_humble
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

> ✅ If you have already done the one-time re-login after installation, you can use `docker` **without** `sudo`.

```bash
# 1 — SSH into Pi
ssh aadi_1234@10.139.37.39

# 2 — Check container status
docker ps

# 3 — Start container if it is stopped
docker start ros2_humble

# 4 — Enter the container
docker exec -it ros2_humble bash

# 5 — Enable ROS 2
source /opt/ros/humble/setup.bash

# 6 — Verify
echo $ROS_DISTRO   # → humble
```

> ⚠️ If `docker: permission denied` appears, either run `newgrp docker` or prefix commands with `sudo` until you re-login.

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

### Error 5 — `docker: permission denied` / `Got permission denied while trying to connect`

This happens when your user is not yet active in the `docker` group.

**Fix A — Re-login (permanent fix):**
```bash
exit
ssh aadi_1234@<PI_IP_ADDRESS>
```

**Fix B — Current session only:**
```bash
newgrp docker
```

**Fix C — Use sudo (always works):**
```bash
sudo docker exec -it ros2_humble bash
```

---

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
