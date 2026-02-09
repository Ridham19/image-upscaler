import os

# ==========================================
# CONFIGURATION
# ==========================================
# This must match where your Testbench looks for files
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "../sim/coeffs.txt")

def generate_bicubic_coeffs():
    print("Generating Bicubic Coefficients...")
    
    # We are doing 3x Scaling.
    # This means we need 3 sets of weights (Phases):
    # Phase 0: Aligned (0.0 offset)
    # Phase 1: 1/3rd offset (0.33)
    # Phase 2: 2/3rd offset (0.66)
    
    # These are the pre-calculated Fixed Point (S1.7) values.
    # Logic: Float_Weight * 128 -> Rounded -> Converted to Hex
    
    # Phase 0 (Offset 0.0) -> Weights: [0, 1, 0, 0]
    # 1.0 * 128 = 128 (0x80)
    p0 = ["00", "80", "00", "00"]
    
    # Phase 1 (Offset 0.33) -> Weights approx: [-0.03, 0.89, 0.18, -0.04]
    # Fixed Point: [-4, 114, 23, -5]
    # Hex (2's complement for negatives):
    # -4  -> FD
    # 114 -> 72
    # 23  -> 17
    # -5  -> FB
    p1 = ["FD", "72", "17", "FB"]
    
    # Phase 2 (Offset 0.66) -> Mirror of Phase 1
    # Fixed Point: [-5, 23, 114, -4]
    p2 = ["FB", "17", "72", "FD"]
    
    # Combine them (12 total coefficients)
    all_coeffs = p0 + p1 + p2
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    with open(OUTPUT_FILE, "w") as f:
        # We write them one per line because our Verilog ROM is defined as:
        # reg signed [8:0] coeff_rom [0:11];
        # This is a 1D array of 12 entries.
        for val in all_coeffs:
            f.write(f"{val}\n")
            
    print(f"Success! Coefficients saved to: {os.path.abspath(OUTPUT_FILE)}")
    print("Format: 12 lines of Hex values.")

if __name__ == "__main__":
    generate_bicubic_coeffs()