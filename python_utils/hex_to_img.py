import numpy as np
import cv2
import os

# CONFIGURATION (Must match your Testbench!)
OUTPUT_W = 128 * 3  # 384
OUTPUT_H = 72 * 3   # 216

# Dynamic Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
HEX_FILE = os.path.join(SCRIPT_DIR, "../sim/output_image.hex") # Adjust if Vivado saved it elsewhere
RESULT_IMG = os.path.join(SCRIPT_DIR, "final_result.png")

def hex_to_img():
    print(f"Reading {HEX_FILE}...")
    
    if not os.path.exists(HEX_FILE):
        # Fallback: Check Vivado's deep simulation directory if not found in sim/
        print("File not found in sim/. You might need to find where Vivado saved 'output_image.hex'")
        return

    pixels = []
    with open(HEX_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                # If Verilog spit out 'xx' or 'XX', treat it as a black pixel (0)
                if 'x' in line.lower():
                    pixels.append(0)
                else:
                    pixels.append(int(line, 16))

    # Convert to Numpy Array
    arr = np.array(pixels, dtype=np.uint8)
    
    print(f"Total Pixels Read: {len(arr)}")
    expected_pixels = OUTPUT_W * OUTPUT_H
    
    if len(arr) != expected_pixels:
        print(f"Warning: Expected {expected_pixels} pixels, got {len(arr)}.")
        # Resize/Crop to fit
        arr = np.resize(arr, (OUTPUT_H, OUTPUT_W))
    else:
        arr = arr.reshape((OUTPUT_H, OUTPUT_W))

    # Save
    cv2.imwrite(RESULT_IMG, arr)
    print(f"Success! Image saved to {RESULT_IMG}")

if __name__ == "__main__":
    hex_to_img()