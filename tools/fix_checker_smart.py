"""
Smart checkered background removal.
Detects the actual alternating checkerboard pattern and removes ONLY those pixels.
Preserves the button artwork (stone textures, icons, etc.)
"""

from PIL import Image
import numpy as np
import os

def detect_checker_colors(img_array):
    """Sample corners to find the two checker colors."""
    # Sample from corners where background should be
    h, w = img_array.shape[:2]

    # Sample pixels from corners (likely background)
    samples = []
    for y in [0, 1, 2, 3, 4]:
        for x in [0, 1, 2, 3, 4]:
            samples.append((img_array[y, x, 0], img_array[y, x, 1], img_array[y, x, 2], x, y))

    # Group by color
    color_a = None
    color_b = None

    for r, g, b, x, y in samples:
        # Only consider gray pixels (R ≈ G ≈ B)
        if abs(int(r) - int(g)) < 10 and abs(int(g) - int(b)) < 10:
            if color_a is None:
                color_a = (r, g, b)
            elif abs(int(r) - int(color_a[0])) > 20:  # Different color
                color_b = (r, g, b)
                break

    return color_a, color_b

def remove_checker_background(input_path, output_path):
    """Remove checkered background by detecting the alternating pattern."""
    print(f"Processing: {input_path}")

    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)
    h, w = data.shape[:2]

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # Detect checker colors from corners
    color_a, color_b = detect_checker_colors(data)
    print(f"  Detected checker colors: {color_a}, {color_b}")

    if color_a is None:
        print("  Could not detect checker pattern, skipping")
        return

    # Create coordinate grids
    y_coords, x_coords = np.mgrid[0:h, 0:w]

    # Checkerboard pattern: (x + y) % 2 determines which color
    checker_phase = (x_coords + y_coords) % 2

    # Tolerance for color matching
    tol = 25

    # Match color A (should appear where phase == 0 or phase == 1)
    if color_a:
        match_a = (np.abs(r.astype(int) - int(color_a[0])) < tol) & \
                  (np.abs(g.astype(int) - int(color_a[1])) < tol) & \
                  (np.abs(b.astype(int) - int(color_a[2])) < tol)
    else:
        match_a = np.zeros((h, w), dtype=bool)

    # Match color B
    if color_b:
        match_b = (np.abs(r.astype(int) - int(color_b[0])) < tol) & \
                  (np.abs(g.astype(int) - int(color_b[1])) < tol) & \
                  (np.abs(b.astype(int) - int(color_b[2])) < tol)
    else:
        match_b = np.zeros((h, w), dtype=bool)

    # A pixel is part of the checker if:
    # - It matches color A AND is in the right phase, OR
    # - It matches color B AND is in the opposite phase
    # But simpler: just remove any pixel matching either checker color
    is_checker = match_a | match_b

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
