#!/bin/bash

# =============================================================================
#  ROS 2 Humble on Raspberry Pi (Docker) — Installation Script
#  Target OS : Raspberry Pi OS Lite 64-bit (Debian Bookworm / Trixie)
#  Author    : aadi_1234
#  Usage     : bash install_ros2_docker.sh
# =============================================================================

set -e  # Exit immediately on any error

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Colour

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}   ROS 2 Humble  ·  Raspberry Pi  ·  Docker Setup${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# ── Step 1 : Verify OS ────────────────────────────────────────────────────────
info "Step 1 — Verifying OS..."
if [ -f /etc/os-release ]; then
    source /etc/os-release
    success "OS detected: $PRETTY_NAME"
else
    error "/etc/os-release not found. Are you running Raspberry Pi OS?"
fi

# ── Step 2 : Update system packages ──────────────────────────────────────────
info "Step 2 — Updating system packages..."
sudo apt-get update -qq && sudo apt-get upgrade -y -qq
success "System packages updated."

# ── Step 3 : Install prerequisites ───────────────────────────────────────────
info "Step 3 — Installing prerequisites (curl, ca-certificates)..."
sudo apt-get install -y curl ca-certificates gnupg lsb-release -qq
success "Prerequisites installed."

# ── Step 4 : Install Docker ───────────────────────────────────────────────────
info "Step 4 — Installing Docker..."

if command -v docker &>/dev/null; then
    warn "Docker is already installed: $(docker --version)"
else
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    success "Docker installed: $(docker --version)"
fi

# ── Step 5 : Add current user to docker group ─────────────────────────────────
info "Step 5 — Adding '$USER' to the docker group..."
sudo usermod -aG docker "$USER"
warn "You must log out and back in (or run 'newgrp docker') for group changes to take effect."
warn "For this script, subsequent docker commands will use 'sudo'."

# ── Step 6 : Verify Docker with hello-world ───────────────────────────────────
info "Step 6 — Verifying Docker installation with hello-world..."
sudo docker run --rm hello-world | grep -q "Hello from Docker" \
    && success "Docker is working correctly!" \
    || error "Docker hello-world test failed."

# ── Step 7 : Pull ROS 2 Humble image ─────────────────────────────────────────
info "Step 7 — Pulling ROS 2 Humble Docker image (this may take a few minutes)..."
sudo docker pull ros:humble-ros-base
success "ROS 2 Humble image pulled successfully."

# ── Step 8 : Create the ROS 2 container ──────────────────────────────────────
info "Step 8 — Creating ROS 2 container 'ros2_humble'..."

if sudo docker ps -a --format '{{.Names}}' | grep -q "^ros2_humble$"; then
    warn "Container 'ros2_humble' already exists. Skipping creation."
else
    sudo docker create -it --name ros2_humble ros:humble-ros-base
    success "Container 'ros2_humble' created."
fi

# ── Step 9 : Start the container & install demo nodes ────────────────────────
info "Step 9 — Starting container and installing demo nodes..."
sudo docker start ros2_humble

sudo docker exec ros2_humble bash -c "
    apt-get update -qq && \
    apt-get install -y ros-humble-demo-nodes-cpp -qq && \
    echo 'Demo nodes installed.'
"
success "ros-humble-demo-nodes-cpp installed inside container."

# ── Step 10 : Verify ROS 2 ───────────────────────────────────────────────────
info "Step 10 — Verifying ROS 2 installation..."
ROS_DISTRO_CHECK=$(sudo docker exec ros2_humble bash -c "source /opt/ros/humble/setup.bash && echo \$ROS_DISTRO")
if [ "$ROS_DISTRO_CHECK" = "humble" ]; then
    success "ROS 2 Humble is correctly installed. ROS_DISTRO=$ROS_DISTRO_CHECK"
else
    error "ROS 2 verification failed. Got: '$ROS_DISTRO_CHECK'"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "  Container name : ${CYAN}ros2_humble${NC}"
echo -e "  Enter container: ${CYAN}sudo docker exec -it ros2_humble bash${NC}"
echo -e "  Enable ROS 2   : ${CYAN}source /opt/ros/humble/setup.bash${NC}"
echo ""
echo -e "  Run the demo   : ${CYAN}bash ros2_demo_test.sh${NC}"
echo ""
