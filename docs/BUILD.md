# Building Mammon Protocol

Mammon Protocol is a fork of [Monero](https://github.com/monero-project/monero) with modified emission schedule and fee distribution.

## Quick Start (Testnet)

```bash
# Initialize testnet environment
python scripts/testnet_launcher.py init

# This creates:
# - testnet_data/genesis.json
# - testnet_data/wallets/testnet_addresses.json
# - testnet_data/mammon.conf
# - scripts/mine.sh
# - scripts/emission_calculator.py
```

## Building from Source

### Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y build-essential cmake pkg-config \
    libboost-all-dev libssl-dev libzmq3-dev \
    libunbound-dev libsodium-dev libunwind8-dev \
    liblzma-dev libreadline6-dev libldns-dev \
    libexpat1-dev doxygen graphviz libpgm-dev \
    qttools5-dev-tools libhidapi-dev libusb-1.0-0-dev \
    libprotobuf-dev protobuf-compiler libudev-dev git
```

**macOS:**
```bash
brew install boost openssl zmq libpgm unbound libsodium \
    miniupnpc ldns expat doxygen graphviz qt hidapi \
    libusb protobuf
```

### Clone and Patch

```bash
# Clone Monero (our base)
git clone --recursive https://github.com/monero-project/monero.git mammon
cd mammon

# Apply Mammon patches
# (In production, these would be maintained as a patch set)
```

### Key Files to Modify

#### 1. `src/cryptonote_config.h`
Replace constants with Mammon values. See `src/mammon_config.h` for reference.

Key changes:
- `CRYPTONOTE_NAME` → "Mammon"
- `DIFFICULTY_TARGET_V2` → 120 (seconds)
- Network magic bytes
- Port numbers

#### 2. `src/cryptonote_core/cryptonote_tx_utils.cpp`
Modify `construct_miner_tx()` to implement fee split:

```cpp
// Original: all rewards to miner
// Modified: 85% miner, 10% treasury, 5% insurance

uint64_t total_reward = block_reward + fee;
uint64_t miner_reward = (total_reward * 85) / 100;
uint64_t treasury_reward = (total_reward * 10) / 100;
uint64_t insurance_reward = total_reward - miner_reward - treasury_reward;

// Add outputs to treasury and insurance addresses
// (addresses defined in mammon_config.h)
```

#### 3. `src/cryptonote_basic/difficulty.cpp`
Replace difficulty calculation with LWMA. See `src/lwma_difficulty.h`.

#### 4. `src/cryptonote_core/blockchain.cpp`
Modify `get_block_reward()` to use Mammon emission schedule:

```cpp
uint64_t blockchain::get_block_reward(uint64_t height) {
    // Mammon emission schedule
    const uint64_t BLOCKS_PER_YEAR = 262980;
    const uint64_t COIN = 1000000000000ULL;
    
    if (height < BLOCKS_PER_YEAR * 1) return 100 * COIN;
    if (height < BLOCKS_PER_YEAR * 2) return 75 * COIN;
    if (height < BLOCKS_PER_YEAR * 3) return 50 * COIN;
    if (height < BLOCKS_PER_YEAR * 4) return 25 * COIN;
    return 10 * COIN;  // Tail emission forever
}
```

### Build

```bash
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)

# Binaries will be in build/bin/
# mammmond - Node daemon
# mammon-wallet-cli - Wallet
# mammon-wallet-rpc - Wallet RPC server
```

### Run Testnet

```bash
./mammmond --testnet --data-dir /path/to/testnet_data \
    --p2p-bind-port 28080 --rpc-bind-port 28081
```

## Network Ports

| Network | P2P | RPC | ZMQ |
|---------|-----|-----|-----|
| Mainnet | 18080 | 18081 | 18082 |
| Testnet | 28080 | 28081 | 28082 |

## Emission Schedule

| Year | Block Reward | Annual Emission | Cumulative |
|------|--------------|-----------------|------------|
| 1 | 100 MAM | 26.28M | 26.28M |
| 2 | 75 MAM | 19.71M | 45.99M |
| 3 | 50 MAM | 13.14M | 59.13M |
| 4 | 25 MAM | 6.57M | 65.70M |
| 5+ | 10 MAM | 2.63M/year | perpetual |

## Fee Distribution

Every block reward is automatically split:
- **85%** → Miner
- **10%** → Treasury (Mammon's Hoard - gold backing)
- **5%** → Insurance (Oh Shit Fund - MDIC)

## Verification

To verify the build:

```bash
# Check emission calculator
python scripts/emission_calculator.py 10

# Verify block reward at height 0
./mammmond --testnet --offline --print-genesis-block

# Run unit tests
make test
```

## Docker (Coming Soon)

```bash
docker build -t mammon-protocol .
docker run -d -p 28080:28080 -p 28081:28081 mammon-protocol --testnet
```

---

*"I might be a demon, but at least my couch feels good."* - Mammon
