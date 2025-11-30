#!/bin/bash
# Mammon Protocol CPU Mining Script
# Uses RandomX (same as Monero)

POOL_URL="127.0.0.1:28081"
WALLET="$1"
THREADS="${2:-$(nproc)}"

if [ -z "$WALLET" ]; then
    echo "Usage: $0 <wallet_address> [threads]"
    echo "Example: $0 MAM... 4"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════╗"
echo "║           MAMMON PROTOCOL - CPU MINING                   ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║ Wallet: ${WALLET:0:20}...                              ║"
echo "║ Threads: $THREADS                                        ║"
echo "║ Pool: $POOL_URL                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"

# For testnet solo mining via RPC
curl -s -X POST http://$POOL_URL/json_rpc \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "id": "0",
        "method": "start_mining",
        "params": {
            "miner_address": "'$WALLET'",
            "threads_count": '$THREADS',
            "do_background_mining": false,
            "ignore_battery": true
        }
    }'

echo ""
echo "Mining started. Check logs at /home/claude/mammon-protocol/testnet_data/logs/mammond.log"
