"""
ULTRA aggressive background removal.
Remove ANY light gray/white pixel regardless of exact value.
"""

from PIL import Image
import numpy as np
import os

SOURCES = {
    "btn_new_game.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254.png",
    "btn_continue.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254 (3).png",
    "btn_continue_disabled.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254 (1).png",
    "btn_settings.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254 (4).png",
    "btn_quit.png": r"C:\Users\Conner\Downloads\Gemini_Generated_Image_z254znz254znz254 (2).png",
}

def process_button(source_path, output_path, size=512):
    print(f"Processing: {os.path.basename(output_path)}")

    img = Image.open(source_path).convert('RGBA')
    img = img.resize((size, size), Image.Resampling.LANCZOS)

    data = np.array(img)
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # ULTRA AGGRESSIVE: Remove ANY pixel where ALL of R, G, B are above 180
    # This catches all variations of the light background
    is_light = (r > 180) & (g > 180) & (b > 180)

    # Make light pixels transparent
    data[is_light, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)

    removed = np.sum(is_light)
    total = data.shape[0] * data.shape[1]
    print(f"  Removed {removed}/{total} pixels ({100*removed/total:.1f}%)")

def main():
    output_dir = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\buttons"

    for btn_name, source in SOURCES.items():
        if os.path.exists(source):
            output_path = os.path.join(output_dir, btn_name)
            process_button(source, output_path, size=512)

    print("\nDone!")

if __name__ == "__main__":
    main()
