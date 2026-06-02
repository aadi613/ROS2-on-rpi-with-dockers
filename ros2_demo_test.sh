#!/bin/bash

# =============================================================================
#  ROS 2 Humble — Publisher / Subscriber Demo Test
#  Runs BOTH talker & listener inside the ros2_humble container,
#  captures output for 5 seconds, then verifies messages were exchanged.
#
#  Usage  : bash ros2_demo_test.sh
#  Prereq : install_ros2_docker.sh must have been run first.
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

CONTAINER="ros2_humble"
ROS_SETUP="source /opt/ros/humble/setup.bash"

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}   ROS 2 Humble  ·  Publisher–Subscriber Demo Test${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# ── Prerequisite checks ───────────────────────────────────────────────────────
info "Checking prerequisites..."

command -v docker &>/dev/null || error "Docker is not installed. Run install_ros2_docker.sh first."

if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    error "Container '${CONTAINER}' not found. Run install_ros2_docker.sh first."
fi

# ── Ensure container is running ───────────────────────────────────────────────
info "Ensuring container '${CONTAINER}' is running..."
sudo docker start "${CONTAINER}" &>/dev/null
success "Container is running."

# ── Verify ROS_DISTRO ─────────────────────────────────────────────────────────
info "Verifying ROS 2 environment inside container..."
DISTRO=$(sudo docker exec "${CONTAINER}" bash -c "${ROS_SETUP} && echo \$ROS_DISTRO" 2>/dev/null)
[ "$DISTRO" = "humble" ] && success "ROS_DISTRO=$DISTRO" \
    || error "ROS 2 environment check failed (got: '${DISTRO}')."

# ── Verify topic list ─────────────────────────────────────────────────────────
info "Checking ROS 2 topic list..."
TOPICS=$(sudo docker exec "${CONTAINER}" bash -c "${ROS_SETUP} && ros2 topic list 2>/dev/null")
echo "$TOPICS"
if echo "$TOPICS" | grep -q "/rosout"; then
    success "ROS 2 topic list OK."
else
    warn "Expected topics not fully visible — this is normal before nodes start."
fi

# ── Launch talker (publisher) in background ───────────────────────────────────
info "Starting talker (publisher) node for 6 seconds..."
sudo docker exec "${CONTAINER}" bash -c \
    "${ROS_SETUP} && timeout 6 ros2 run demo_nodes_cpp talker 2>&1" \
    > /tmp/ros2_talker_output.txt &
TALKER_PID=$!

sleep 2   # give the talker a moment to start publishing

# ── Launch listener (subscriber) in background ────────────────────────────────
info "Starting listener (subscriber) node for 4 seconds..."
sudo docker exec "${CONTAINER}" bash -c \
    "${ROS_SETUP} && timeout 4 ros2 run demo_nodes_cpp listener 2>&1" \
    > /tmp/ros2_listener_output.txt &
LISTENER_PID=$!

# ── Wait for both to finish ───────────────────────────────────────────────────
wait $TALKER_PID   2>/dev/null || true
wait $LISTENER_PID 2>/dev/null || true

# ── Show captured output ──────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}─── Talker Output ───────────────────────────────────────────${NC}"
cat /tmp/ros2_talker_output.txt

echo ""
echo -e "${CYAN}─── Listener Output ─────────────────────────────────────────${NC}"
cat /tmp/ros2_listener_output.txt
echo ""

# ── Validate results ──────────────────────────────────────────────────────────
info "Validating demo results..."

TALKER_OK=false
LISTENER_OK=false

grep -qi "Publishing: Hello World" /tmp/ros2_talker_output.txt   && TALKER_OK=true
grep -qi "I heard: Hello World"    /tmp/ros2_listener_output.txt && LISTENER_OK=true

if $TALKER_OK && $LISTENER_OK; then
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}   Demo Test PASSED ✓${NC}"
    echo -e "${GREEN}   Publisher and Subscriber are communicating correctly!${NC}"
    echo -e "${GREEN}============================================================${NC}"
else
    echo -e "${RED}============================================================${NC}"
    echo -e "${RED}   Demo Test FAILED ✗${NC}"
    $TALKER_OK   || echo -e "${RED}   Talker output not found / empty.${NC}"
    $LISTENER_OK || echo -e "${RED}   Listener did not receive messages.${NC}"
    echo -e "${RED}============================================================${NC}"
    echo ""
    warn "Tip: Make sure 'ros-humble-demo-nodes-cpp' is installed inside the container:"
    warn "  sudo docker exec -it ${CONTAINER} bash"
    warn "  apt update && apt install -y ros-humble-demo-nodes-cpp"
    exit 1
fi

echo ""

# ── Clean up temp files ───────────────────────────────────────────────────────
rm -f /tmp/ros2_talker_output.txt /tmp/ros2_listener_output.txt

# ── Daily workflow reminder ───────────────────────────────────────────────────
echo -e "${CYAN}Daily Workflow (after every Pi boot):${NC}"
echo "  sudo docker ps                          # check container status"
echo "  sudo docker start ${CONTAINER}   # start if stopped"
echo "  sudo docker exec -it ${CONTAINER} bash  # enter container"
echo "  source /opt/ros/humble/setup.bash       # enable ROS 2"
echo "  echo \$ROS_DISTRO                        # verify → humble"
echo ""
