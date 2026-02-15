import cv2
import numpy as np
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_IMAGE_PATH = os.path.join(SCRIPT_DIR, "images/img2.png") 
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "../sim")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "input_image.hex")

TARGET_W, TARGET_H = 128, 72

def convert_image():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    img = cv2.imread(INPUT_IMAGE_PATH, cv2.IMREAD_COLOR)
    
    if img is None:
        print("Error: Image not found!")
        return
        
    img = cv2.resize(img, (TARGET_W, TARGET_H))
    print(f"Converting {TARGET_W}x{TARGET_H} RGB image to 24-bit Hex...")
    
    with open(OUTPUT_FILE, "w") as f:
        for y in range(TARGET_H):
            for x in range(TARGET_W):
                b, g, r = img[y, x] # OpenCV loads as BGR
                # Pack as RRGGBB (24 bits = 6 Hex characters)
                f.write(f"{r:02X}{g:02X}{b:02X}\n")
    
    print(f"Success! Saved to {os.path.abspath(OUTPUT_FILE)}")

if __name__ == "__main__":
    convert_image()