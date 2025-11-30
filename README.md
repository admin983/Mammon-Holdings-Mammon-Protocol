# Mammon Protocol

**"The devil you can audit."**

A proof-of-work cryptocurrency with partial gold backing, AI governance, and radical transparency. Monero fork using RandomX.

## Live Testnet

| Service | URL |
|---------|-----|
| Block Explorer | http://34.10.218.161:8080 |
| Testnet Faucet | http://34.10.218.161:8081 |
| RPC Endpoint | http://34.10.218.161:28081/json_rpc |
| P2P Seed Node | 34.10.218.161:28080 |

## Key Features

- **RandomX Mining** - CPU-friendly, ASIC-resistant proof-of-work
- **120-second Block Time** - Faster than Monero's 2 minutes
- **LWMA Difficulty** - Linear Weighted Moving Average for stable difficulty adjustment
- **Fee Split Model**:
  - 85% to miners
  - 10% to Treasury (Mammon's Hoard - gold backing fund)
  - 5% to Insurance (Oh Shit Fund - MDIC)

## Emission Schedule

| Year | Block Reward | Annual Emission | Cumulative Supply |
|------|--------------|-----------------|-------------------|
| 1 | 100 MAM | 26.28M | 26.28M |
| 2 | 75 MAM | 19.71M | 45.99M |
| 3 | 50 MAM | 13.14M | 59.13M |
| 4 | 25 MAM | 6.57M | 65.70M |
| 5+ | 10 MAM | 2.63M/year | perpetual |

Blocks per year: 262,980 (at 120s target)

## Quick Start

### Connect to Testnet

```bash
# Run a testnet node
./mammmond --testnet --add-peer 34.10.218.161:28080

# Or with full options
./mammmond --testnet \
    --data-dir ~/.mammon/testnet \
    --p2p-bind-port 28080 \
    --rpc-bind-port 28081 \
    --add-peer 34.10.218.161:28080
```

### Create a Wallet

```bash
./mammon-wallet-cli --testnet --generate-new-wallet mywalletname
```

### Get Test Coins

Visit the [Testnet Faucet](http://34.10.218.161:8081) to receive free test MAM.

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
    libhidapi-dev libusb-1.0-0-dev \
    libprotobuf-dev protobuf-compiler libudev-dev git
```

**macOS:**
```bash
brew install boost openssl zmq libpgm unbound libsodium \
    miniupnpc ldns expat doxygen graphviz qt hidapi \
    libusb protobuf
```

### Build

```bash
# Clone Monero and apply patches
git clone --recursive https://github.com/monero-project/monero.git mammon
cd mammon

# Apply Mammon patches (from this repository)
cp -r ../Mammon-Protocol/patches/* .
cp ../Mammon-Protocol/src/mammon_config.h src/
cp ../Mammon-Protocol/src/lwma_difficulty.h src/cryptonote_basic/

# Build
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)

# Binaries in build/bin/
ls build/bin/
# mammmond, mammon-wallet-cli, mammon-wallet-rpc, etc.
```

## Network Ports

| Network | P2P | RPC | ZMQ |
|---------|-----|-----|-----|
| Mainnet | 18080 | 18081 | 18082 |
| Testnet | 28080 | 28081 | 28082 |

## Mining

```bash
# Start mining from CLI wallet
start_mining YOUR_ADDRESS 4  # 4 threads

# Or via RPC
curl -X POST http://127.0.0.1:28081/json_rpc \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "id": "0",
        "method": "start_mining",
        "params": {
            "miner_address": "YOUR_ADDRESS",
            "threads_count": 4
        }
    }'
```

## Node Configuration

Example config file (`mammon.conf`):

```ini
# Network
testnet=1
p2p-bind-ip=0.0.0.0
p2p-bind-port=28080
rpc-bind-ip=0.0.0.0
rpc-bind-port=28081

# Seed nodes
add-peer=34.10.218.161:28080

# Data
data-dir=/var/lib/mammon/blockchain
log-file=/var/log/mammon/mammmond.log
log-level=1

# Performance
db-sync-mode=fast
prep-blocks-threads=4
```

Run with config:
```bash
./mammmond --config-file mammon.conf
```

## Systemd Service

```ini
[Unit]
Description=Mammon Protocol Daemon (Testnet)
After=network-online.target

[Service]
Type=simple
User=mammon
ExecStart=/opt/mammon/build/bin/mammmond --config-file /etc/mammon/mammon.conf --non-interactive
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```

## RPC API

Standard Monero-compatible JSON-RPC:

```bash
# Get blockchain info
curl -s http://34.10.218.161:28081/json_rpc \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}'

# Get block by height
curl -s http://34.10.218.161:28081/json_rpc \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_block","params":{"height":0}}'

# Get current height
curl -s http://34.10.218.161:28081/json_rpc \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_height"}'
```

## Project Structure

```
Mammon-Protocol/
├── src/
│   ├── mammon_config.h      # Network constants
│   └── lwma_difficulty.h    # LWMA difficulty algorithm
├── patches/
│   ├── cryptonote_config.patch
│   ├── emission_schedule.patch
│   └── fee_split.patch
├── scripts/
│   ├── gcp_deploy.sh        # GCP deployment
│   ├── vm_setup.sh          # VM setup script
│   └── emission_calculator.py
├── config/
│   └── mammon-testnet.conf
└── docs/
    └── BUILD.md
```

## Technical Specifications

| Parameter | Value |
|-----------|-------|
| Algorithm | RandomX |
| Block Time | 120 seconds |
| Difficulty Window | 60 blocks (LWMA) |
| Max Supply | Infinite (tail emission) |
| Initial Reward | 100 MAM |
| Tail Emission | 10 MAM/block |
| Fee Split | 85/10/5 (miner/treasury/insurance) |
| Ring Size | 11 |
| Address Prefix | 9 (testnet) |

## Network IDs

```
Mainnet: 0x6d, 0x61, 0x6d, 0x6d, 0x6f, 0x6e, 0x30, 0x30  (mammon00)
Testnet: 0x6d, 0x61, 0x6d, 0x74, 0x65, 0x73, 0x74, 0x30  (mamtest0)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Same as Monero - BSD-3-Clause

## Links

- [Block Explorer](http://34.10.218.161:8080)
- [Testnet Faucet](http://34.10.218.161:8081)
- [Monero Project](https://github.com/monero-project/monero)

---

*"I might be a demon, but at least my couch feels good."* - Mammon
