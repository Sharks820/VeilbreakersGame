"""
Final button fix - restore from originals and remove gray background.
The Gemini images have a light gray background (RGB 215-235 range).
"""

from PIL import Image
import numpy as np
import os

# Source files (original Gemini downloads)
SOURCES = {
    "btn_new_game.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254.png",
    "btn_continue.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254 (3).png",
    "btn_continue_disabled.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254 (1).png",
    "btn_settings.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254 (4).png",
    "btn_quit.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254 (2).png",
}

def process_button(source_path, output_path, size=512):
    """Load original, resize, remove gray background."""
    print(f"Processing: {os.path.basename(output_path)}")
    print(f"  Source: {source_path}")

    # Load original
    img = Image.open(source_path).convert('RGBA')
    print(f"  Original size: {img.size}")

    # Resize to target
    img = img.resize((size, size), Image.Resampling.LANCZOS)

    data = np.array(img)
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # The background is light gray where R ≈ G ≈ B and all values are 210-240
    is_gray = (np.abs(r.astype(int) - g.astype(int)) < 20) & \
              (np.abs(g.astype(int) - b.astype(int)) < 20) & \
              (np.abs(r.astype(int) - b.astype(int)) < 20)

    is_light = (r > 200) & (g > 200) & (b > 200)

    # Background = gray AND light
    is_background = is_gray & is_light

    # Make background transparent
    data[is_background, 3] = 0

    # Save
    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)

    removed = np.sum(is_background)
    total = data.shape[0] * data.shape[1]
    print(f"  Removed {removed}/{total} background pixels ({100*removed/total:.1f}%)")

def main():
    output_dir = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\buttons"

    for btn_name, source in SOURCES.items():
        if os.path.exists(source):
            output_path = os.path.join(output_dir, btn_name)
            process_button(source, output_path, size=512)
        else:
            print(f"WARNING: Source not found: {source}")

    print("\nDone! All buttons processed.")

if __name__ == "__main__":
    main()
