#!/bin/bash
# ============================================================================
# MAMMON PROTOCOL - VM Setup Script
# ============================================================================
# This script runs on a fresh Ubuntu 22.04 VM to:
# 1. Install all build dependencies
# 2. Clone Monero source
# 3. Apply Mammon patches
# 4. Build from source
# 5. Start testnet node
#
# Usage: bash vm_setup.sh [--build-only] [--no-start]
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MAMMON_DIR="/opt/mammon"
MONERO_REPO="https://github.com/monero-project/monero.git"
MONERO_VERSION="v0.18.3.4"  # Latest stable
BUILD_THREADS=$(nproc)
DATA_DIR="/var/lib/mammon"

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"
}

banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           MAMMON PROTOCOL - VM Setup Script                  ║"
    echo "║                  \"The devil you can audit\"                   ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  RandomX | 120s blocks | LWMA difficulty                     ║"
    echo "║  Fee split: 85% miner / 10% treasury / 5% insurance          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

install_dependencies() {
    log "Installing build dependencies..."

    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        pkg-config \
        libboost-all-dev \
        libssl-dev \
        libzmq3-dev \
        libunbound-dev \
        libsodium-dev \
        libunwind8-dev \
        liblzma-dev \
        libreadline6-dev \
        libldns-dev \
        libexpat1-dev \
        doxygen \
        graphviz \
        libpgm-dev \
        libhidapi-dev \
        libusb-1.0-0-dev \
        libprotobuf-dev \
        protobuf-compiler \
        libudev-dev \
        git \
        ccache \
        htop \
        screen \
        jq

    log "Dependencies installed successfully"
}

clone_monero() {
    log "Cloning Monero source (tag: $MONERO_VERSION)..."

    if [ -d "$MAMMON_DIR" ]; then
        log_warn "Directory $MAMMON_DIR exists, removing..."
        sudo rm -rf "$MAMMON_DIR"
    fi

    sudo mkdir -p "$MAMMON_DIR"
    sudo chown $(whoami):$(whoami) "$MAMMON_DIR"

    git clone --recursive --depth 1 --branch "$MONERO_VERSION" \
        "$MONERO_REPO" "$MAMMON_DIR"

    cd "$MAMMON_DIR"
    git submodule update --init --recursive --force

    log "Monero source cloned successfully"
}

apply_patches() {
    log "Applying Mammon Protocol patches..."

    cd "$MAMMON_DIR"

    # Copy mammon_config.h
    if [ -f "/tmp/mammon-patches/src/mammon_config.h" ]; then
        cp /tmp/mammon-patches/src/mammon_config.h src/
        log "Copied mammon_config.h"
    fi

    # Copy LWMA difficulty header
    if [ -f "/tmp/mammon-patches/src/lwma_difficulty.h" ]; then
        cp /tmp/mammon-patches/src/lwma_difficulty.h src/cryptonote_basic/
        log "Copied lwma_difficulty.h"
    fi

    # Apply patch files
    for patch in /tmp/mammon-patches/patches/*.patch; do
        if [ -f "$patch" ]; then
            log "Applying $(basename $patch)..."
            # Use --forward to skip already applied patches
            patch -p1 --forward < "$patch" || true
        fi
    done

    # Manual modifications for key files
    apply_manual_modifications

    log "Patches applied successfully"
}

apply_manual_modifications() {
    log "Applying manual source modifications..."

    # Modify cryptonote_config.h directly if patches didn't apply cleanly
    CONFIG_FILE="$MAMMON_DIR/src/cryptonote_config.h"

    # Replace network name
    sed -i 's/#define CRYPTONOTE_NAME.*"bitmonero"/#define CRYPTONOTE_NAME                                 "mammon"/' "$CONFIG_FILE"

    # Update difficulty target to 120 seconds
    sed -i 's/#define DIFFICULTY_TARGET_V2.*60/#define DIFFICULTY_TARGET_V2                          120/' "$CONFIG_FILE"

    # Update difficulty window to 60 blocks (LWMA)
    sed -i 's/#define DIFFICULTY_WINDOW.*720/#define DIFFICULTY_WINDOW                             60/' "$CONFIG_FILE"
    sed -i 's/#define DIFFICULTY_LAG.*15/#define DIFFICULTY_LAG                                0/' "$CONFIG_FILE"
    sed -i 's/#define DIFFICULTY_CUT.*60/#define DIFFICULTY_CUT                                0/' "$CONFIG_FILE"

    log "Manual modifications complete"
}

build_mammon() {
    log "Building Mammon Protocol (using $BUILD_THREADS threads)..."

    cd "$MAMMON_DIR"

    mkdir -p build
    cd build

    cmake -DCMAKE_BUILD_TYPE=Release \
          -DSTATIC=ON \
          -DBUILD_TESTS=OFF \
          ..

    make -j$BUILD_THREADS

    log "Build complete!"
    log "Binaries located in: $MAMMON_DIR/build/bin/"

    # List built binaries
    ls -la "$MAMMON_DIR/build/bin/"
}

setup_data_dirs() {
    log "Setting up data directories..."

    sudo mkdir -p "$DATA_DIR"/{blockchain,wallets,logs}
    sudo chown -R $(whoami):$(whoami) "$DATA_DIR"

    # Create testnet config
    cat > "$DATA_DIR/mammon-testnet.conf" << EOF
# Mammon Protocol Testnet Configuration
# Generated: $(date -Iseconds)

# Network
testnet=1
p2p-bind-ip=0.0.0.0
p2p-bind-port=28080
rpc-bind-ip=0.0.0.0
rpc-bind-port=28081
zmq-rpc-bind-ip=0.0.0.0
zmq-rpc-bind-port=28082

# Data
data-dir=$DATA_DIR/blockchain
log-file=$DATA_DIR/logs/mammmond.log
log-level=1

# RPC access
confirm-external-bind=1
restricted-rpc=0
rpc-login=mammon:testnet123

# Performance
db-sync-mode=fast
block-sync-size=10
prep-blocks-threads=$BUILD_THREADS

# Testnet specific
offline=0
EOF

    log "Data directories and config created"
}

create_systemd_service() {
    log "Creating systemd service..."

    sudo tee /etc/systemd/system/mammmond.service > /dev/null << EOF
[Unit]
Description=Mammon Protocol Daemon (Testnet)
After=network.target

[Service]
Type=simple
User=$(whoami)
ExecStart=$MAMMON_DIR/build/bin/monerod --config-file $DATA_DIR/mammon-testnet.conf --non-interactive
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable mammmond

    log "Systemd service created (mammmond.service)"
}

start_testnet() {
    log "Starting Mammon Protocol testnet node..."

    # Start in screen session for easy monitoring
    screen -dmS mammon "$MAMMON_DIR/build/bin/monerod" \
        --config-file "$DATA_DIR/mammon-testnet.conf" \
        --non-interactive

    sleep 5

    log "Testnet node started!"
    log "Monitor with: screen -r mammon"
    log "RPC endpoint: http://localhost:28081/json_rpc"
}

check_status() {
    log "Checking node status..."

    sleep 3

    curl -s -X POST http://127.0.0.1:28081/json_rpc \
        -u mammon:testnet123 \
        -H "Content-Type: application/json" \
        -d '{
            "jsonrpc": "2.0",
            "id": "0",
            "method": "get_info"
        }' | jq .result 2>/dev/null || log_warn "Node not responding yet (may still be starting)"
}

# Parse arguments
BUILD_ONLY=false
NO_START=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --no-start)
            NO_START=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Main execution
main() {
    banner

    log "Starting Mammon Protocol VM setup..."
    log "Build threads: $BUILD_THREADS"
    log "Install directory: $MAMMON_DIR"
    log "Data directory: $DATA_DIR"
    echo ""

    install_dependencies
    clone_monero
    apply_patches
    build_mammon

    if [ "$BUILD_ONLY" = true ]; then
        log "Build-only mode. Skipping runtime setup."
        exit 0
    fi

    setup_data_dirs
    create_systemd_service

    if [ "$NO_START" = false ]; then
        start_testnet
        sleep 5
        check_status
    fi

    echo ""
    log "=============================================="
    log "Mammon Protocol setup complete!"
    log "=============================================="
    log ""
    log "Useful commands:"
    log "  Start node:    sudo systemctl start mammmond"
    log "  Stop node:     sudo systemctl stop mammmond"
    log "  Node logs:     journalctl -u mammmond -f"
    log "  Screen:        screen -r mammon"
    log "  RPC status:    curl -s http://localhost:28081/json_rpc -d '{\"method\":\"get_info\"}'"
    log ""
    log "Testnet ports: P2P=28080, RPC=28081, ZMQ=28082"
    log ""
}

main "$@"
