"""
Aggressively remove checkered background from buttons.
The checkered pattern uses specific gray values - we detect and remove them.
"""

from PIL import Image
import numpy as np
import os

def analyze_and_fix_button(input_path, output_path):
    """Remove checkered background using color analysis."""
    print(f"Fixing: {input_path}")

    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # The checkered pattern consists of two alternating gray colors
    # Typically around (204, 204, 204) and (153, 153, 153) or similar

    # Detect pixels that are purely gray (R ≈ G ≈ B)
    tolerance = 15
    is_gray = (np.abs(r.astype(int) - g.astype(int)) <= tolerance) & \
              (np.abs(g.astype(int) - b.astype(int)) <= tolerance) & \
              (np.abs(r.astype(int) - b.astype(int)) <= tolerance)

    # Gray values in typical checkered backgrounds: 140-220 range
    in_checker_range = (r >= 130) & (r <= 230)

    # Combined: gray pixels in the checker range
    is_background = is_gray & in_checker_range

    # Make these pixels transparent
    data[is_background, 3] = 0

    # Also remove any remaining light gray edge pixels
    light_gray = is_gray & (r >= 200)
    data[light_gray, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)

    # Count how many pixels were made transparent
    transparent_count = np.sum(data[:,:,3] == 0)
    total_pixels = data.shape[0] * data.shape[1]
    print(f"  Made {transparent_count}/{total_pixels} pixels transparent ({100*transparent_count/total_pixels:.1f}%)")

def main():
    buttons_dir = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\buttons"

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
            analyze_and_fix_button(btn_path, btn_path)

    print("\nDone!")

if __name__ == "__main__":
    main()
