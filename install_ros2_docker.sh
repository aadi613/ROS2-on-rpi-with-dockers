#!/bin/bash

# =============================================================================
#  ROS 2 Humble on Raspberry Pi (Docker) — Installation Script
#  Target OS : Raspberry Pi OS Lite 64-bit (Debian Bookworm / Trixie)
#  Author    : aadi_1234
#  Usage     : bash install_ros2_docker.sh
# =============================================================================

set -e

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}   Docker Setup Complete!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${YELLOW}  Re-login or run 'newgrp docker' before next steps.${NC}"
echo ""
