"""
Fix image quality issues:
1. Logo - clean up bleeding edges and blotches
2. Buttons - remove checkered background, add true transparency
"""

from PIL import Image
import numpy as np
import os

def fix_logo(input_path, output_path):
    """Clean up logo bleeding edges and blotches."""
    print(f"Fixing logo: {input_path}")

    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # Remove very faint semi-transparent pixels (bleeding)
    # These are pixels with very low alpha that create the "halo" effect
    faint_mask = (a > 0) & (a < 30)
    data[faint_mask, 3] = 0

    # Remove near-white semi-transparent pixels (blotches around edges)
    near_white = (r > 230) & (g > 230) & (b > 230)
    low_alpha = (a > 0) & (a < 80)
    data[near_white & low_alpha, 3] = 0

    # Clean up edge artifacts - pixels that are very light with medium alpha
    light_pixels = (r > 200) & (g > 200) & (b > 200)
    medium_alpha = (a > 30) & (a < 150)
    data[light_pixels & medium_alpha, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)
    print(f"  Saved: {output_path}")

def fix_button(input_path, output_path):
    """Remove checkered background pattern and add true transparency."""
    print(f"Fixing button: {input_path}")

    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)

    r, g, b = data[:,:,0], data[:,:,1], data[:,:,2]

    # Detect gray checkered pattern pixels
    # Checkered patterns use alternating light/dark gray squares
    is_gray = (np.abs(r.astype(int) - g.astype(int)) < 20) & \
              (np.abs(g.astype(int) - b.astype(int)) < 20)

    # Light gray squares (typically 190-255)
    is_light_gray = is_gray & (r >= 180) & (r <= 255)

    # Dark gray squares (typically 128-190)
    is_dark_gray = is_gray & (r >= 120) & (r < 190)

    # Combine - these are the checkered background pixels
    is_checker = is_light_gray | is_dark_gray

    # Make checkered pixels fully transparent
    data[is_checker, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)
    print(f"  Saved: {output_path}")

def main():
    base = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets"

    # Fix logo
    logo_path = os.path.join(base, "ui", "title", "title_logo.png")
    if os.path.exists(logo_path):
        fix_logo(logo_path, logo_path)

    # Fix buttons
    buttons_dir = os.path.join(base, "ui", "buttons")
    buttons = [
        "btn_new_game.png",
        "btn_continue.png",
        "btn_continue_disabled.png",
        "btn_settings.png",
        "btn_quit.png"
    ]

    for btn in buttons:
        btn_path = os.path.join(buttons_dir, btn)
        if os.path.exists(btn_path):
            fix_button(btn_path, btn_path)

    print("\nDone! All assets fixed.")

if __name__ == "__main__":
    main()
