"""
Aggressive checkered background removal.
Gemini uses pink/white checker pattern. Remove ALL checker colors.
"""

from PIL import Image
import numpy as np
import os

def remove_checker_background(input_path, output_path):
    """Remove checkered background - targets pink/white Gemini pattern."""
    print(f"Processing: {input_path}")

    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)
    h, w = data.shape[:2]

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # Gemini checker pattern uses:
    # Light squares: ~(255, 255, 255) white
    # Pink squares: ~(255, 192, 203) or similar pink
    # Also light gray: ~(220-230, 220-230, 220-230)

    # Remove near-white pixels
    near_white = (r > 240) & (g > 240) & (b > 240)

    # Remove pink pixels (R high, G/B medium-high)
    is_pink = (r > 230) & (g > 180) & (g < 230) & (b > 180) & (b < 230)

    # Remove light gray pixels (the other checker color)
    is_light_gray = (r > 210) & (r < 240) & \
                    (g > 210) & (g < 240) & \
                    (b > 210) & (b < 240) & \
                    (np.abs(r.astype(int) - g.astype(int)) < 15) & \
                    (np.abs(g.astype(int) - b.astype(int)) < 15)

    # Combine all checker patterns
    is_checker = near_white | is_pink | is_light_gray

    # Make checker pixels transparent
    data[is_checker, 3] = 0

    # Save result
    result = Image.fromarray(data, 'RGBA')
    result.save(output_path)

    removed = np.sum(is_checker)
    total = h * w
    print(f"  Removed {removed}/{total} pixels ({100*removed/total:.1f}%)")

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
            remove_checker_background(btn_path, btn_path)

    print("\nDone!")

if __name__ == "__main__":
    main()
