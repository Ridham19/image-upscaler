import cv2
import numpy as np
import os

# ==========================================
# 1. SETUP PATHS (The Bulletproof Way)
# ==========================================
# Get the folder where THIS script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Define paths relative to the script, not the terminal
# Assumes input image is in python_utils or you can specify a full path
INPUT_IMAGE_PATH = os.path.join(SCRIPT_DIR, "images/img2.png") 
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "../sim")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "input_image.hex")

# Target resolution for simulation
TARGET_W = 128
TARGET_H = 72

def convert_image():
    # 2. Check if SIM folder exists, if not create it
    if not os.path.exists(OUTPUT_DIR):
        print(f"Creating directory: {OUTPUT_DIR}")
        os.makedirs(OUTPUT_DIR)

    # 3. Load Image
    print(f"Looking for image at: {INPUT_IMAGE_PATH}")
    img = cv2.imread(INPUT_IMAGE_PATH, cv2.IMREAD_GRAYSCALE)
    
    if img is None:
        print("Warning: Image not found at path. Creating a dummy gradient pattern instead.")
        # Create a cool gradient pattern so you can still see results
        img = np.zeros((TARGET_H, TARGET_W), dtype=np.uint8)
        for y in range(TARGET_H):
            for x in range(TARGET_W):
                img[y, x] = (x + y) % 255
    else:
        # Resize to small target for simulation
        img = cv2.resize(img, (TARGET_W, TARGET_H))

    # 4. Save as Hex
    print(f"Converting {TARGET_W}x{TARGET_H} image to Hex...")
    with open(OUTPUT_FILE, "w") as f:
        # Flatten image to 1D array
        flat_img = img.flatten()
        for pixel in flat_img:
            # Write 2-digit Hex (e.g., 00, A5, FF)
            f.write(f"{pixel:02X}\n")
    
    print(f"Success! Saved to {os.path.abspath(OUTPUT_FILE)}")

if __name__ == "__main__":
    convert_image()