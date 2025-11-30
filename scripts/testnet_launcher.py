#!/usr/bin/env python3
"""
Mammon Protocol - Testnet Launcher
===================================
Quick setup script for running a local testnet.

This script handles:
1. Building from source (if needed)
2. Generating testnet wallets for treasury/insurance
3. Launching seed node
4. Mining setup

Requirements:
- Monero source (we fork from it)
- cmake, gcc/clang, libboost-all-dev
- Python 3.8+

Usage:
    python testnet_launcher.py [command]
    
Commands:
    build     - Clone and build Mammon from source
    init      - Initialize testnet (generate wallets, genesis)
    start     - Start seed node
    mine      - Start CPU mining
    status    - Check node status
    clean     - Clean testnet data
"""

import os
import sys
import json
import subprocess
import shutil
import time
import hashlib
from pathlib import Path
from datetime import datetime

# Configuration
MAMMON_ROOT = Path(__file__).parent.parent
CONFIG_FILE = MAMMON_ROOT / "config" / "chain_params.json"
DATA_DIR = MAMMON_ROOT / "testnet_data"
WALLET_DIR = DATA_DIR / "wallets"
BLOCKCHAIN_DIR = DATA_DIR / "blockchain"
LOG_DIR = DATA_DIR / "logs"

# Load chain parameters
def load_config():
    with open(CONFIG_FILE) as f:
        return json.load(f)

CONFIG = load_config()

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

def log(msg, color=Colors.GREEN):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"{color}[{timestamp}] {msg}{Colors.END}")

def log_error(msg):
    log(msg, Colors.FAIL)

def log_info(msg):
    log(msg, Colors.CYAN)

def log_warn(msg):
    log(msg, Colors.WARNING)

def banner():
    print(f"""{Colors.BOLD}{Colors.WARNING}
    ███╗   ███╗ █████╗ ███╗   ███╗███╗   ███╗ ██████╗ ███╗   ██╗
    ████╗ ████║██╔══██╗████╗ ████║████╗ ████║██╔═══██╗████╗  ██║
    ██╔████╔██║███████║██╔████╔██║██╔████╔██║██║   ██║██╔██╗ ██║
    ██║╚██╔╝██║██╔══██║██║╚██╔╝██║██║╚██╔╝██║██║   ██║██║╚██╗██║
    ██║ ╚═╝ ██║██║  ██║██║ ╚═╝ ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
    {Colors.CYAN}PROTOCOL{Colors.END}
    
    {Colors.GREEN}"The devil you can audit"{Colors.END}
    {Colors.BLUE}Testnet Launcher v0.1.0{Colors.END}
    """)

def init_dirs():
    """Create necessary directories."""
    for d in [DATA_DIR, WALLET_DIR, BLOCKCHAIN_DIR, LOG_DIR]:
        d.mkdir(parents=True, exist_ok=True)
    log("Directories initialized")

def generate_genesis_block():
    """Generate genesis block data."""
    genesis = {
        "timestamp": int(time.time()),
        "nonce": 0,
        "difficulty": 1,
        "message": CONFIG["genesis"]["message"],
        "message_hash": hashlib.sha256(CONFIG["genesis"]["message"].encode()).hexdigest()
    }
    
    genesis_file = DATA_DIR / "genesis.json"
    with open(genesis_file, 'w') as f:
        json.dump(genesis, f, indent=2)
    
    log(f"Genesis block created: {genesis_file}")
    log_info(f"Genesis message: {genesis['message']}")
    return genesis

def generate_wallet_addresses():
    """
    Generate placeholder addresses for treasury and insurance.
    In production, these would be actual Mammon addresses.
    """
    # For testnet, we generate deterministic addresses from seeds
    treasury_seed = "mammon_treasury_testnet_2025"
    insurance_seed = "mammon_insurance_testnet_2025"
    
    # Simple hash-based address generation (placeholder)
    treasury_addr = "MAM" + hashlib.sha256(treasury_seed.encode()).hexdigest()[:60]
    insurance_addr = "MAM" + hashlib.sha256(insurance_seed.encode()).hexdigest()[:60]
    
    addresses = {
        "treasury": {
            "address": treasury_addr,
            "purpose": "10% of block rewards - Mammon's Hoard (gold backing)",
            "created": datetime.now().isoformat()
        },
        "insurance": {
            "address": insurance_addr,
            "purpose": "5% of block rewards - Oh Shit Fund (MDIC)",
            "created": datetime.now().isoformat()
        }
    }
    
    addr_file = WALLET_DIR / "testnet_addresses.json"
    with open(addr_file, 'w') as f:
        json.dump(addresses, f, indent=2)
    
    log("Testnet addresses generated:")
    log_info(f"Treasury: {treasury_addr[:20]}...")
    log_info(f"Insurance: {insurance_addr[:20]}...")
    
    return addresses

def create_node_config():
    """Create daemon configuration file."""
    node_config = f"""# Mammon Protocol Testnet Node Configuration
# Generated: {datetime.now().isoformat()}

# Network
testnet=1
p2p-bind-ip=0.0.0.0
p2p-bind-port={CONFIG['network']['p2p_port']}
rpc-bind-ip=127.0.0.1
rpc-bind-port={CONFIG['network']['rpc_port']}
zmq-rpc-bind-ip=127.0.0.1
zmq-rpc-bind-port={CONFIG['network']['zmq_port']}

# Data
data-dir={BLOCKCHAIN_DIR}
log-file={LOG_DIR}/mammond.log
log-level=1

# Mining
start-mining=MAM_MINER_ADDRESS_HERE
mining-threads=2

# Network
confirm-external-bind=1
restricted-rpc=0

# Testnet specific
fixed-difficulty=100
offline=0
"""
    
    config_file = DATA_DIR / "mammon.conf"
    with open(config_file, 'w') as f:
        f.write(node_config)
    
    log(f"Node config created: {config_file}")
    return config_file

def create_mining_script():
    """Create CPU mining helper script."""
    mining_script = f"""#!/bin/bash
# Mammon Protocol CPU Mining Script
# Uses RandomX (same as Monero)

POOL_URL="127.0.0.1:{CONFIG['network']['rpc_port']}"
WALLET="$1"
THREADS="${{2:-$(nproc)}}"

if [ -z "$WALLET" ]; then
    echo "Usage: $0 <wallet_address> [threads]"
    echo "Example: $0 MAM... 4"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════╗"
echo "║           MAMMON PROTOCOL - CPU MINING                   ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║ Wallet: ${{WALLET:0:20}}...                              ║"
echo "║ Threads: $THREADS                                        ║"
echo "║ Pool: $POOL_URL                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"

# For testnet solo mining via RPC
curl -s -X POST http://$POOL_URL/json_rpc \\
    -H "Content-Type: application/json" \\
    -d '{{
        "jsonrpc": "2.0",
        "id": "0",
        "method": "start_mining",
        "params": {{
            "miner_address": "'$WALLET'",
            "threads_count": '$THREADS',
            "do_background_mining": false,
            "ignore_battery": true
        }}
    }}'

echo ""
echo "Mining started. Check logs at {LOG_DIR}/mammond.log"
"""
    
    script_file = MAMMON_ROOT / "scripts" / "mine.sh"
    with open(script_file, 'w') as f:
        f.write(mining_script)
    os.chmod(script_file, 0o755)
    
    log(f"Mining script created: {script_file}")

def create_emission_calculator():
    """Create a Python script to calculate emission schedule."""
    calc_script = '''#!/usr/bin/env python3
"""
Mammon Protocol Emission Calculator
Shows projected token supply over time.
"""

import sys

BLOCKS_PER_YEAR = 262980  # 120-second blocks
SCHEDULE = [
    (1, 100),   # Year 1: 100 MAM/block
    (2, 75),    # Year 2: 75 MAM/block
    (3, 50),    # Year 3: 50 MAM/block
    (4, 25),    # Year 4: 25 MAM/block
]
TAIL_EMISSION = 10  # Year 5+: 10 MAM/block forever

FEE_SPLIT = {
    "miner": 0.85,
    "treasury": 0.10,
    "insurance": 0.05
}

def calculate_supply(years=10):
    """Calculate total supply and distributions over time."""
    results = []
    total_supply = 0
    total_treasury = 0
    total_insurance = 0
    
    for year in range(1, years + 1):
        if year <= 4:
            reward = dict(SCHEDULE).get(year, TAIL_EMISSION)
        else:
            reward = TAIL_EMISSION
        
        annual_emission = BLOCKS_PER_YEAR * reward
        treasury_annual = annual_emission * FEE_SPLIT["treasury"]
        insurance_annual = annual_emission * FEE_SPLIT["insurance"]
        
        total_supply += annual_emission
        total_treasury += treasury_annual
        total_insurance += insurance_annual
        
        results.append({
            "year": year,
            "block_reward": reward,
            "annual_emission": annual_emission,
            "total_supply": total_supply,
            "treasury_annual": treasury_annual,
            "treasury_total": total_treasury,
            "insurance_annual": insurance_annual,
            "insurance_total": total_insurance
        })
    
    return results

def print_table(results):
    """Print emission schedule as ASCII table."""
    print()
    print("╔" + "═" * 78 + "╗")
    print("║" + " MAMMON PROTOCOL EMISSION SCHEDULE ".center(78) + "║")
    print("╠" + "═" * 78 + "╣")
    print("║ Year │ Block Reward │ Annual Emission │ Total Supply │ Treasury │ Insurance ║")
    print("╠" + "═" * 78 + "╣")
    
    for r in results:
        print(f"║ {r['year']:4d} │ {r['block_reward']:8d} MAM │ "
              f"{r['annual_emission']/1e6:12.2f}M │ "
              f"{r['total_supply']/1e6:10.2f}M │ "
              f"{r['treasury_total']/1e6:6.2f}M │ "
              f"{r['insurance_total']/1e6:7.2f}M ║")
    
    print("╚" + "═" * 78 + "╝")
    print()
    print(f"Note: Year 5+ continues at {TAIL_EMISSION} MAM/block perpetually (tail emission)")
    print(f"Fee split: Miners {FEE_SPLIT['miner']*100:.0f}% | "
          f"Treasury {FEE_SPLIT['treasury']*100:.0f}% | "
          f"Insurance {FEE_SPLIT['insurance']*100:.0f}%")

if __name__ == "__main__":
    years = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    results = calculate_supply(years)
    print_table(results)
'''
    
    script_file = MAMMON_ROOT / "scripts" / "emission_calculator.py"
    with open(script_file, 'w') as f:
        f.write(calc_script)
    os.chmod(script_file, 0o755)
    
    log(f"Emission calculator created: {script_file}")

def cmd_init():
    """Initialize testnet environment."""
    log_info("Initializing Mammon Protocol Testnet...")
    
    init_dirs()
    generate_genesis_block()
    generate_wallet_addresses()
    create_node_config()
    create_mining_script()
    create_emission_calculator()
    
    log("")
    log("Testnet initialization complete!")
    log_info("Next steps:")
    log_info("  1. Build mammmond from Monero fork (see docs/BUILD.md)")
    log_info("  2. Run: ./mammmond --config-file testnet_data/mammon.conf")
    log_info("  3. Mine: ./scripts/mine.sh <your_wallet_address>")

def cmd_status():
    """Check node status via RPC."""
    import urllib.request
    import json
    
    rpc_url = f"http://127.0.0.1:{CONFIG['network']['rpc_port']}/json_rpc"
    
    try:
        req = urllib.request.Request(
            rpc_url,
            data=json.dumps({
                "jsonrpc": "2.0",
                "id": "0",
                "method": "get_info"
            }).encode(),
            headers={"Content-Type": "application/json"}
        )
        
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
            info = data.get("result", {})
            
            log("Mammon Node Status:")
            log_info(f"  Height: {info.get('height', 'N/A')}")
            log_info(f"  Difficulty: {info.get('difficulty', 'N/A')}")
            log_info(f"  Hashrate: {info.get('difficulty', 0) / 120:.2f} H/s")
            log_info(f"  TX Pool: {info.get('tx_pool_size', 'N/A')}")
            log_info(f"  Connections: {info.get('outgoing_connections_count', 0) + info.get('incoming_connections_count', 0)}")
            
    except Exception as e:
        log_error(f"Cannot connect to node: {e}")
        log_warn("Is mammmond running?")

def cmd_clean():
    """Clean testnet data."""
    if DATA_DIR.exists():
        log_warn(f"This will delete all testnet data in {DATA_DIR}")
        confirm = input("Are you sure? (yes/no): ")
        if confirm.lower() == "yes":
            shutil.rmtree(DATA_DIR)
            log("Testnet data cleaned")
        else:
            log_info("Cancelled")

def cmd_help():
    """Show help."""
    print(__doc__)

COMMANDS = {
    "init": cmd_init,
    "status": cmd_status,
    "clean": cmd_clean,
    "help": cmd_help,
}

def main():
    banner()
    
    if len(sys.argv) < 2:
        cmd = "help"
    else:
        cmd = sys.argv[1]
    
    if cmd in COMMANDS:
        COMMANDS[cmd]()
    else:
        log_error(f"Unknown command: {cmd}")
        cmd_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
