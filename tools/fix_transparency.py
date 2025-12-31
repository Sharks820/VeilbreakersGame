"""
Fix transparency issues in game assets:
1. Convert fake checkered backgrounds to true transparency
2. Clean up logo alpha bleeding
"""

from PIL import Image
import numpy as np
import os
import sys

def remove_checkered_background(image_path, output_path):
    """Convert checkered background pattern to true transparency."""
    img = Image.open(image_path).convert('RGBA')
    data = np.array(img)

    # Checkered patterns typically use these color ranges
    # Light squares: ~(192-255, 192-255, 192-255)
    # Dark squares: ~(128-192, 128-192, 128-192)

    # Create mask for checkered pattern detection
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # Detect gray checkered pixels (where R≈G≈B and in the gray range)
    is_gray = (np.abs(r.astype(int) - g.astype(int)) < 15) & \
              (np.abs(g.astype(int) - b.astype(int)) < 15) & \
              (np.abs(r.astype(int) - b.astype(int)) < 15)

    # Light gray (200-255) or medium gray (140-200) - typical checker colors
    is_checker_light = is_gray & (r >= 190) & (r <= 255)
    is_checker_dark = is_gray & (r >= 135) & (r <= 195)

    # Combine checker detection
    is_checker = is_checker_light | is_checker_dark

    # Make checkered pixels transparent
    data[is_checker, 3] = 0

    # Save result
    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)
    print(f"Fixed: {output_path}")

def clean_logo_edges(image_path, output_path, threshold=20):
    """Remove faint bleeding pixels around logo edges."""
    img = Image.open(image_path).convert('RGBA')
    data = np.array(img)

    # Get alpha channel
    alpha = data[:,:,3]

    # Remove very faint pixels (alpha < threshold)
    # These are the "bleeding" semi-transparent pixels
    data[alpha < threshold, 3] = 0

    # Also clean up near-white pixels with low alpha (the halo effect)
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    is_near_white = (r > 240) & (g > 240) & (b > 240)
    is_low_alpha = (a > 0) & (a < 100)
    data[is_near_white & is_low_alpha, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)
    print(f"Fixed: {output_path}")

def main():
    base_path = r"C:\Users\Conner\Downloads\VeilbreakersGame"

    # Fix buttons (remove checkered background)
    buttons = [
        "btn_new_game.png",
        "btn_continue.png",
        "btn_continue_disabled.png",
        "btn_settings.png",
        "btn_quit.png"
    ]

    buttons_dir = os.path.join(base_path, "assets", "ui", "buttons")

    for btn in buttons:
        input_path = os.path.join(buttons_dir, btn)
        if os.path.exists(input_path):
            # Create fixed version (overwrite original)
            output_path = input_path
            remove_checkered_background(input_path, output_path)

    # Fix logo (clean bleeding edges)
    logo_path = os.path.join(base_path, "assets", "ui", "title", "title_logo.png")
    if os.path.exists(logo_path):
        clean_logo_edges(logo_path, logo_path)

    print("\nAll assets fixed!")

if __name__ == "__main__":
    main()
