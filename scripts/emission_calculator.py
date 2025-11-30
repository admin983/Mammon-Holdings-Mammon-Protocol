#!/usr/bin/env python3
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
