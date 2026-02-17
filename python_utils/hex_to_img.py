import numpy as np
import cv2
import os

OUTPUT_W, OUTPUT_H = 384 * 3, 216 * 3
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
HEX_FILE = os.path.join(SCRIPT_DIR, "../sim/output_image.hex")
RESULT_IMG = os.path.join(SCRIPT_DIR, "final_result.png")

def hex_to_img():
    pixels = []
    with open(HEX_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                if 'x' in line.lower():
                    pixels.append([0, 0, 0])
                else:
                    val = int(line, 16)
                    r = (val >> 16) & 0xFF
                    g = (val >> 8) & 0xFF
                    b = val & 0xFF
                    pixels.append([b, g, r]) # OpenCV uses BGR

    arr = np.array(pixels, dtype=np.uint8)
    print(f"Total Pixels Read: {len(arr)}")
    
    if len(arr) != (OUTPUT_W * OUTPUT_H):
        print("ERROR: Vivado did not finish the simulation! You must type 'run all' in the Tcl console.")
        return
        
    arr = arr.reshape((OUTPUT_H, OUTPUT_W, 3))
    cv2.imwrite(RESULT_IMG, arr)
    print(f"Success! Image saved to {RESULT_IMG}")

if __name__ == "__main__":
    hex_to_img()