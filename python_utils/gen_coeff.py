import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "../sim/coeffs.txt")

def generate_bicubic_coeffs():
    print("Generating 9-bit Bicubic Coefficients...")
    
    # Phase 0: [0, 128, 0, 0] -> 9-bit Hex: 000, 080, 000, 000
    p0 = ["000", "080", "000", "000"]
    
    # Phase 1: [-4, 114, 23, -5] 
    # 9-bit 2's complement: -4 = 1FC, 114 = 072, 23 = 017, -5 = 1FB
    p1 = ["1FC", "072", "017", "1FB"]
    
    # Phase 2: [-5, 23, 114, -4]
    p2 = ["1FB", "017", "072", "1FC"]
    
    all_coeffs = p0 + p1 + p2
    
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        for val in all_coeffs:
            f.write(f"{val}\n")
            
    print(f"Success! Coefficients saved to: {os.path.abspath(OUTPUT_FILE)}")

if __name__ == "__main__":
    generate_bicubic_coeffs()