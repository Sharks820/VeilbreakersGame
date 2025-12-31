"""
Aggressively fix logo bleeding pixels.
Remove all semi-transparent edge artifacts.
"""

from PIL import Image
import numpy as np
import os

def fix_logo_aggressive(input_path, output_path):
    """Aggressively clean logo edges - remove ALL semi-transparent bleeding."""
    print(f"Fixing logo: {input_path}")

    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # AGGRESSIVE: Remove all pixels with alpha < 128 (50%)
    # This cuts off the bleeding semi-transparent edges
    low_alpha = a < 128
    data[low_alpha, 3] = 0

    # Also remove near-white pixels even if they have high alpha
    # (these are the "blotchy" artifacts)
    near_white = (r > 220) & (g > 220) & (b > 220)
    not_fully_opaque = a < 250
    data[near_white & not_fully_opaque, 3] = 0

    # Remove light gray artifacts around edges
    light_gray = (r > 180) & (g > 180) & (b > 180)
    is_gray = (np.abs(r.astype(int) - g.astype(int)) < 20) & \
              (np.abs(g.astype(int) - b.astype(int)) < 20)
    data[light_gray & is_gray & not_fully_opaque, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)

    transparent_count = np.sum(data[:,:,3] == 0)
    total = data.shape[0] * data.shape[1]
    print(f"  Made {transparent_count}/{total} pixels transparent ({100*transparent_count/total:.1f}%)")

def main():
    logo_path = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\title\title_logo.png"
    fix_logo_aggressive(logo_path, logo_path)
    print("Done!")

if __name__ == "__main__":
    main()
