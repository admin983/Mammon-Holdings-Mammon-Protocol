// lwma_difficulty.h
// LWMA (Linearly Weighted Moving Average) Difficulty Algorithm
// Responds to hashrate changes within hours rather than weeks
// Prevents timestamp manipulation attacks

#pragma once

#include <cstdint>
#include <vector>
#include <algorithm>
#include "mammon_config.h"

namespace mammon {

// LWMA-1 implementation
// Based on zawy12's LWMA algorithm used by many privacy coins
// https://github.com/zawy12/difficulty-algorithms/issues/3

class LWMADifficulty {
public:
    static constexpr uint64_t N = DIFFICULTY_WINDOW;  // 60 blocks
    static constexpr uint64_t T = DIFFICULTY_TARGET;  // 120 seconds
    
    // Minimum and maximum timestamp adjustments
    static constexpr int64_t TIMESTAMP_MIN = -T * 7;   // -840 seconds (can't be too far in past)
    static constexpr int64_t TIMESTAMP_MAX = T * 7 * 2; // +1680 seconds (limit future timestamps)
    
    struct BlockData {
        uint64_t timestamp;
        uint64_t difficulty;
    };
    
    static uint64_t calculate_next_difficulty(
        const std::vector<BlockData>& blocks,
        uint64_t height,
        bool testnet = false
    ) {
        size_t n = blocks.size();
        
        // Not enough blocks yet - return minimum difficulty
        if (n < 2) {
            return testnet ? MAMMON_TESTNET_MIN_DIFFICULTY : 1;
        }
        
        // Use smaller window if we don't have enough blocks
        uint64_t window = std::min(static_cast<uint64_t>(n - 1), N);
        
        // LWMA calculation
        uint64_t L = 0;      // Sum of weighted solve times
        uint64_t sum_w = 0;  // Sum of weights
        uint64_t sum_d = 0;  // Sum of difficulties
        
        for (uint64_t i = 1; i <= window; i++) {
            size_t idx = n - window - 1 + i;
            
            // Calculate solve time with sanity bounds
            int64_t solvetime = static_cast<int64_t>(blocks[idx].timestamp) - 
                               static_cast<int64_t>(blocks[idx - 1].timestamp);
            
            // Clamp solvetime to prevent manipulation
            solvetime = std::max(solvetime, TIMESTAMP_MIN);
            solvetime = std::min(solvetime, TIMESTAMP_MAX);
            
            // Weight increases linearly (more recent blocks weighted higher)
            uint64_t weight = i;
            
            L += static_cast<uint64_t>(solvetime) * weight;
            sum_w += weight;
            sum_d += blocks[idx].difficulty;
        }
        
        // Calculate next difficulty
        // D = sum(difficulties) * T * sum(weights) / (L * window)
        // Using integer math to avoid floating point
        
        // Prevent division by zero
        if (L == 0) {
            L = 1;
        }
        
        // Target solve time for window
        uint64_t target_time = T * sum_w;
        
        // Calculate new difficulty
        // We want: D_new = D_avg * (target_time / actual_time)
        uint64_t avg_difficulty = sum_d / window;
        
        // Scale factor (multiply first, then divide to preserve precision)
        // D_new = avg_difficulty * target_time / L
        uint64_t next_diff = (avg_difficulty * target_time) / L;
        
        // Apply minimum difficulty for testnet
        if (testnet && next_diff < MAMMON_TESTNET_MIN_DIFFICULTY) {
            next_diff = MAMMON_TESTNET_MIN_DIFFICULTY;
        }
        
        // Minimum difficulty of 1 for mainnet
        if (next_diff < 1) {
            next_diff = 1;
        }
        
        return next_diff;
    }
    
    // Validate block timestamp
    static bool validate_timestamp(
        uint64_t proposed_timestamp,
        const std::vector<BlockData>& recent_blocks,
        uint64_t current_time
    ) {
        if (recent_blocks.empty()) {
            return true;  // Genesis or early blocks
        }
        
        // Can't be before median of last N/2 blocks
        size_t median_window = std::min(recent_blocks.size(), static_cast<size_t>(N / 2));
        std::vector<uint64_t> timestamps;
        for (size_t i = recent_blocks.size() - median_window; i < recent_blocks.size(); i++) {
            timestamps.push_back(recent_blocks[i].timestamp);
        }
        std::sort(timestamps.begin(), timestamps.end());
        uint64_t median = timestamps[timestamps.size() / 2];
        
        if (proposed_timestamp <= median) {
            return false;  // Timestamp before median - reject
        }
        
        // Can't be too far in the future
        if (proposed_timestamp > current_time + static_cast<uint64_t>(TIMESTAMP_MAX)) {
            return false;
        }
        
        return true;
    }
};

}  // namespace mammon
