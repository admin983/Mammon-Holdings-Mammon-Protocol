# Mammon Protocol - Project State

> **Last Updated**: 2025-11-30
> **Read this file at the start of every new session**

## Quick Status

| Component | Status | Notes |
|-----------|--------|-------|
| Fee Split (85/10/5) | ✅ Implemented | Code complete in cryptonote_tx_utils.cpp |
| Emission Schedule | ✅ Implemented | 100/75/50/25/10 MAM per year |
| RandomX Mining | ✅ Working | ~2 min initialization time |
| Testnet Daemon | ✅ Built | v0.1.0-testnet |
| Block Mining | ⏳ Pending Verification | Need to mine blocks and verify coinbase outputs |
| Mainnet Launch | 🔜 TODO | Requires security audit |

---

## 1. Patches Applied

### Core Fee Split Patch
- **File**: `/opt/mammon/src/cryptonote_core/cryptonote_tx_utils.cpp` (on VM)
- **Description**: Modified `construct_miner_tx()` to split block rewards 85/10/5
- **Status**: Applied and compiled

```cpp
// Key implementation in construct_miner_tx():
uint64_t treasury_amount = (total_reward * 10) / 100;   // 10%
uint64_t insurance_amount = (total_reward * 5) / 100;   // 5%
uint64_t miner_amount = total_reward - treasury_amount - insurance_amount;  // 85%
```

### Emission Schedule Patch
- **File**: `src/mammon_config.h`
- **Description**: Custom emission curve (100→75→50→25→10 MAM)
- **Status**: Applied

### Network Identity Patch
- **Files**: Various config files
- **Description**: Changed network magic bytes, ports, ticker to MAM
- **Status**: Applied

---

## 2. Daemon Version & Build Status

```
Version: Mammon v0.1.0-testnet
Base: Monero fork (CryptoNote)
Algorithm: RandomX
Block Time: 120 seconds
Build Status: SUCCESS
Build Location: /opt/mammon/build/release/bin/
```

### Binaries Available
- `monerod` - Daemon (renamed functionally to Mammon)
- `monero-wallet-cli` - CLI wallet
- `monero-wallet-rpc` - RPC wallet server

---

## 3. Wallet Addresses (Public - Testnet)

### Treasury Wallet ("Mammon's Hoard")
- **Purpose**: 10% of block rewards - Gold backing fund
- **Address**: `4218Z6qrhKs9gNn2Y94mQ12H9ir7jEa2aMGUwESPffWne3VdLMTEVod7mtHWEFNWQc8ybe5K2ee6hGZThJPLv1xbU9eDPCJ`

### Insurance Wallet ("Oh Shit Fund" / MDIC)
- **Purpose**: 5% of block rewards - Emergency insurance
- **Address**: `45tjbVVD79pPVpGTyx9PjnPiRrxvduhjiHRNXkqtiwiE5ToXQmSij8fcEJ82Gi5C7LBt2aohC9a9YWP1wXQ6ba2xKPfvzoB`

> ⚠️ **SECURITY NOTE**: Seeds and private keys are stored ONLY on the VM in `/opt/mammon/wallets/` and are NOT in this repository.

---

## 4. Infrastructure Status

### GCP Virtual Machine
| Property | Value |
|----------|-------|
| IP Address | 34.10.218.161 |
| GCP Project | mammon-protocol |
| Zone | us-central1-a |
| Instance Name | mammon-testnet-node |

### Network Ports
| Port | Service | Bind IP |
|------|---------|---------|
| 28080 | P2P | 0.0.0.0 |
| 28081 | RPC | 127.0.0.1 |
| 28082 | ZMQ | 127.0.0.1 |
| 28088 | Wallet RPC | 127.0.0.1 |

### Services
```bash
# Check daemon status
curl http://127.0.0.1:28081/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}' -H 'Content-Type: application/json'

# Start daemon
/opt/mammon/build/release/bin/monerod --testnet --data-dir /opt/mammon/testnet_data --detach

# Start wallet RPC
/opt/mammon/build/release/bin/monero-wallet-rpc --testnet --rpc-bind-port 28088 --wallet-file /opt/mammon/wallets/miner_wallet --password "" --disable-rpc-login
```

---

## 5. Implementation Status

### ✅ COMPLETED
- [x] Fork Monero codebase
- [x] Modify network identity (magic bytes, ticker MAM)
- [x] Implement emission schedule (100/75/50/25/10)
- [x] Implement 85/10/5 fee split in coinbase
- [x] Configure RandomX mining
- [x] Set up testnet configuration
- [x] Create treasury wallet
- [x] Create insurance wallet
- [x] Create miner wallet
- [x] Build daemon successfully
- [x] Set up GCP VM infrastructure
- [x] Configure GitHub repo with deploy key
- [x] Remove sensitive data from public repo

### ⏳ IN PROGRESS
- [ ] Mine test blocks and verify fee split in coinbase outputs
- [ ] Document verification of 85/10/5 split with actual block data

### 🔜 TODO
- [ ] Add seed nodes for testnet
- [ ] Create block explorer integration
- [ ] Security audit of fee split code
- [ ] Test wallet synchronization
- [ ] Stress test network
- [ ] Create mainnet configuration
- [ ] GUI wallet (optional)
- [ ] Mobile wallet (optional)
- [ ] Exchange integration documentation

---

## 6. Key File Paths

### Local Repository (GitHub)
```
/home/drew913s/Mammon/Mammon-Protocol/
├── src/
│   └── mammon_config.h          # Core chain configuration
├── config/
│   └── chain_params.json        # JSON chain parameters
├── testnet_data/
│   ├── mammon.conf              # Daemon configuration
│   └── wallets/
│       └── testnet_addresses.json  # Public addresses (placeholders in repo)
├── .gitignore                   # Protects sensitive files
├── README.md                    # Project documentation
└── PROJECT_STATE.md             # This file
```

### VM Paths (/opt/mammon/)
```
/opt/mammon/
├── build/release/bin/           # Compiled binaries
│   ├── monerod
│   ├── monero-wallet-cli
│   └── monero-wallet-rpc
├── src/cryptonote_core/
│   └── cryptonote_tx_utils.cpp  # Fee split implementation
├── testnet_data/                # Blockchain data
├── wallets/                     # Wallet files (SENSITIVE)
│   ├── treasury_wallet
│   ├── insurance_wallet
│   └── miner_wallet
└── logs/                        # Daemon logs
```

### SSH Keys
```
~/.ssh/mammon_deploy_key         # GitHub deploy key for admin983
```

---

## 7. Common Commands

### On VM (SSH in first)
```bash
# SSH to VM
gcloud compute ssh mammon-testnet-node --zone=us-central1-a --project=mammon-protocol

# Check daemon status
curl -s http://127.0.0.1:28081/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}' -H 'Content-Type: application/json' | jq .

# Get block count
curl -s http://127.0.0.1:28081/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_block_count"}' -H 'Content-Type: application/json' | jq .

# Mine blocks (requires daemon running with mining enabled)
curl -s http://127.0.0.1:28081/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"generateblocks","params":{"amount_of_blocks":10,"wallet_address":"MINER_ADDRESS"}}' -H 'Content-Type: application/json' | jq .

# Get block details
curl -s http://127.0.0.1:28081/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_block","params":{"height":1}}' -H 'Content-Type: application/json' | jq .
```

### Local Git Operations
```bash
cd /home/drew913s/Mammon/Mammon-Protocol

# Push changes
GIT_SSH_COMMAND="ssh -i ~/.ssh/mammon_deploy_key" git push origin main

# Pull changes
GIT_SSH_COMMAND="ssh -i ~/.ssh/mammon_deploy_key" git pull origin main
```

---

## 8. Known Issues

1. **RandomX Initialization**: Takes 1-2+ minutes to build dataset (~2GB). `generateblocks` returns "BUSY" during this time. Just wait.

2. **Port Conflicts**: If daemon won't start, kill existing processes:
   ```bash
   sudo pkill -9 monerod
   sudo fuser -k 28080/tcp 28081/tcp
   ```

3. **Wallet Addresses in Repo**: The public repo uses placeholder addresses. Real addresses are documented above and stored on VM only.

---

## 9. Change Log

| Date | Change | Commit |
|------|--------|--------|
| 2025-11-30 | Removed real wallet addresses from repo, added placeholders | e5f3102 |
| 2025-11-30 | Implemented 85/10/5 fee split in cryptonote_tx_utils.cpp | - (VM only) |
| 2025-11-30 | Created treasury and insurance wallets | - |
| 2025-11-30 | Initial testnet configuration | - |
| 2025-11-30 | Created PROJECT_STATE.md | - |

---

*"The devil you can audit"* - Mammon Protocol
