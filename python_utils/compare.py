import cv2
import matplotlib.pyplot as plt
import os

# Set up paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ORIGINAL_PATH = os.path.join(SCRIPT_DIR, "input_preview.png")
UPSCALED_PATH = os.path.join(SCRIPT_DIR, "final_result.png")

TARGET_W, TARGET_H = 384, 216
SCALE = 3

def main():
    print("Loading images...")
    
    # 1. Load the original image and resize it to the hardware input size
    orig_img = cv2.imread(ORIGINAL_PATH)
    if orig_img is None:
        print(f"Error: Could not find {ORIGINAL_PATH}")
        return
    orig_img = cv2.resize(orig_img, (TARGET_W, TARGET_H))
    
    # Scale it up 3x using Nearest Neighbor to show the "raw" pixels
    raw_pixel_img = cv2.resize(orig_img, (TARGET_W * SCALE, TARGET_H * SCALE), interpolation=cv2.INTER_NEAREST)
    
    # 2. Load your hardware-generated upscaled image
    hw_img = cv2.imread(UPSCALED_PATH)
    if hw_img is None:
        print(f"Error: Could not find {UPSCALED_PATH}. Did the simulation finish?")
        return

    # Convert BGR (OpenCV) to RGB (Matplotlib)
    raw_pixel_img = cv2.cvtColor(raw_pixel_img, cv2.COLOR_BGR2RGB)
    hw_img = cv2.cvtColor(hw_img, cv2.COLOR_BGR2RGB)

    print("Launching interactive viewer. Use the magnifying glass icon to zoom!")

    # 3. Create the Matplotlib plot with locked axes
    # sharex and sharey guarantee that zooming on one zooms the exact same spot on the other
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 7), sharex=True, sharey=True)
    
    fig.canvas.manager.set_window_title('Hardware DSP Verification')

    ax1.imshow(raw_pixel_img)
    ax1.set_title(f"Original Input ({TARGET_W}x{TARGET_H}) -> Raw {SCALE}x Pixels")
    ax1.axis('off')

    ax2.imshow(hw_img)
    ax2.set_title(f"Custom Hardware Output ({TARGET_W*SCALE}x{TARGET_H*SCALE}) -> Bicubic Smooth")
    ax2.axis('off')

    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()