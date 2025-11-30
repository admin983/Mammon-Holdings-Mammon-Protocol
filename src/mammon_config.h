// mammon_config.h
// Mammon Protocol - Chain Configuration
// Fork of Monero with modified emission and fee distribution
// "The devil you can audit"

#pragma once

#define MAMMON_VERSION_MAJOR 0
#define MAMMON_VERSION_MINOR 1
#define MAMMON_VERSION_PATCH 0
#define MAMMON_VERSION_TAG "testnet"

// --- NETWORK IDENTITY ---
#define CRYPTONOTE_NAME "Mammon"
#define CRYPTONOTE_TICKER "MAM"

// Network magic bytes (unique to Mammon)
#define CRYPTONOTE_NETWORK_ID {{ 0x4d, 0x41, 0x4d, 0x4d, 0x4f, 0x4e, 0x50, 0x52, 0x4f, 0x54, 0x4f, 0x43, 0x4f, 0x4c, 0x30, 0x31 }}  // "MAMMONPROTOCOL01"

// --- EMISSION SCHEDULE ---
// Year 1: 100 MAM/block = 26,280,000 MAM
// Year 2: 75 MAM/block  = 19,710,000 MAM
// Year 3: 50 MAM/block  = 13,140,000 MAM
// Year 4: 25 MAM/block  = 6,570,000 MAM
// Year 5+: 10 MAM/block = 2,628,000 MAM/year (perpetual tail)

#define MAMMON_ATOMIC_UNITS 12  // 1 MAM = 10^12 atomic units
#define COIN ((uint64_t)1000000000000)

// Block reward schedule (in atomic units)
#define MAMMON_YEAR1_REWARD ((uint64_t)100 * COIN)  // 100 MAM
#define MAMMON_YEAR2_REWARD ((uint64_t)75 * COIN)   // 75 MAM
#define MAMMON_YEAR3_REWARD ((uint64_t)50 * COIN)   // 50 MAM
#define MAMMON_YEAR4_REWARD ((uint64_t)25 * COIN)   // 25 MAM
#define MAMMON_TAIL_REWARD  ((uint64_t)10 * COIN)   // 10 MAM perpetual

// Blocks per year at 120-second block time
// 365.25 days * 24 hours * 60 minutes * 60 seconds / 120 = 262,980
#define MAMMON_BLOCKS_PER_YEAR 262980
#define MAMMON_YEAR1_END (MAMMON_BLOCKS_PER_YEAR * 1)
#define MAMMON_YEAR2_END (MAMMON_BLOCKS_PER_YEAR * 2)
#define MAMMON_YEAR3_END (MAMMON_BLOCKS_PER_YEAR * 3)
#define MAMMON_YEAR4_END (MAMMON_BLOCKS_PER_YEAR * 4)

// --- FEE DISTRIBUTION ---
// Miner: 85%, Treasury: 10%, Insurance: 5%
#define MAMMON_MINER_FEE_PERCENT 85
#define MAMMON_TREASURY_FEE_PERCENT 10
#define MAMMON_INSURANCE_FEE_PERCENT 5

// Treasury and Insurance addresses (testnet - replace for mainnet)
#define MAMMON_TREASURY_ADDRESS_TESTNET "MAMtreasury1testnetaddressplaceholder"
#define MAMMON_INSURANCE_ADDRESS_TESTNET "MAMinsurance1testnetaddressplaceholder"

// --- CONSENSUS PARAMETERS ---
#define DIFFICULTY_TARGET 120  // 120 seconds = 2 minutes
#define DIFFICULTY_WINDOW 60   // 60 blocks for LWMA calculation
#define DIFFICULTY_LAG 0
#define DIFFICULTY_CUT 0

// Minimum difficulty (testnet)
#define MAMMON_TESTNET_MIN_DIFFICULTY 100

// RandomX parameters (same as Monero v12+)
#define RANDOMX_EPOCH_BLOCKS 2048  // Recalculate dataset every 2048 blocks

// --- BLOCK PARAMETERS ---
#define CRYPTONOTE_MAX_BLOCK_NUMBER 500000000
#define CRYPTONOTE_BLOCK_GRANTED_FULL_REWARD_ZONE 300000  // 300KB
#define CRYPTONOTE_LONG_TERM_BLOCK_WEIGHT_WINDOW_SIZE 100000
#define CRYPTONOTE_SHORT_TERM_BLOCK_WEIGHT_SURGE_FACTOR 50

// --- TRANSACTION PARAMETERS ---
#define CRYPTONOTE_DEFAULT_TX_SPENDABLE_AGE 10
#define CRYPTONOTE_MINED_MONEY_UNLOCK_WINDOW 60
#define CRYPTONOTE_MAX_TX_SIZE 1000000  // 1MB

// --- NETWORK PORTS ---
#define P2P_DEFAULT_PORT_TESTNET 28080
#define RPC_DEFAULT_PORT_TESTNET 28081
#define ZMQ_DEFAULT_PORT_TESTNET 28082

#define P2P_DEFAULT_PORT_MAINNET 18080
#define RPC_DEFAULT_PORT_MAINNET 18081
#define ZMQ_DEFAULT_PORT_MAINNET 18082

// --- GENESIS BLOCK ---
#define GENESIS_TIMESTAMP 0
#define GENESIS_NONCE 0
#define GENESIS_BLOCK_MESSAGE "I might be a demon, but at least my couch feels good. - Mammon, 2025"

// --- PREMINE ---
#define MAMMON_PREMINE 0  // Fair launch. No premine. No founder allocation.

namespace mammon {
    // Calculate block reward based on height
    inline uint64_t get_block_reward(uint64_t height) {
        if (height < MAMMON_YEAR1_END) {
            return MAMMON_YEAR1_REWARD;
        } else if (height < MAMMON_YEAR2_END) {
            return MAMMON_YEAR2_REWARD;
        } else if (height < MAMMON_YEAR3_END) {
            return MAMMON_YEAR3_REWARD;
        } else if (height < MAMMON_YEAR4_END) {
            return MAMMON_YEAR4_REWARD;
        } else {
            return MAMMON_TAIL_REWARD;  // Perpetual tail emission
        }
    }
    
    // Calculate fee distribution
    struct fee_distribution {
        uint64_t miner_amount;
        uint64_t treasury_amount;
        uint64_t insurance_amount;
    };
    
    inline fee_distribution calculate_fee_split(uint64_t total_reward) {
        fee_distribution dist;
        dist.miner_amount = (total_reward * MAMMON_MINER_FEE_PERCENT) / 100;
        dist.treasury_amount = (total_reward * MAMMON_TREASURY_FEE_PERCENT) / 100;
        dist.insurance_amount = (total_reward * MAMMON_INSURANCE_FEE_PERCENT) / 100;
        
        // Handle rounding - give remainder to miner
        uint64_t distributed = dist.miner_amount + dist.treasury_amount + dist.insurance_amount;
        dist.miner_amount += (total_reward - distributed);
        
        return dist;
    }
}
