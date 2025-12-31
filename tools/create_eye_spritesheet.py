"""
Create comprehensive eye tracking sprite sheet from multiple video frames.
Uses rembg for AI-powered background removal (install: pip install rembg)
Falls back to threshold-based removal if rembg unavailable.
"""
import os
import sys
from PIL import Image

# Try to import rembg for AI background removal
try:
    from rembg import remove as rembg_remove
    HAS_REMBG = True
    print("Using rembg for AI background removal")
except ImportError:
    HAS_REMBG = False
    print("rembg not found, using threshold-based removal")
    print("For better results: pip install rembg")

# Paths
PROJECT_DIR = r"C:\Users\Conner\Downloads\VeilbreakersGame"
FRAME_DIRS = {
    "vid1": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "new_eye_anim"),
    "vid2": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid2"),
    "vid3": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid3"),
    "vid4": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid4"),
}
OUTPUT_DIR = os.path.join(PROJECT_DIR, "assets", "ui", "frames", "processed_eyes")
SPRITESHEET_PATH = os.path.join(PROJECT_DIR, "assets", "ui", "demon_eyes_directional.png")

# Frame size
FRAME_SIZE = 256

# Direction mapping based on frame analysis
# Format: "direction": [(video, frame_number), ...]
# Multiple options for each direction, will pick the clearest one
DIRECTION_FRAMES = {
    "center": [("vid1", 1), ("vid2", 1), ("vid3", 1), ("vid4", 1), ("vid3", 60)],
    "left": [("vid1", 48), ("vid1", 72), ("vid3", 84)],
    "right": [("vid2", 60)],
    "up": [("vid3", 24), ("vid2", 84)],
    "down": [("vid2", 24), ("vid4", 60)],
    "up_left": [("vid1", 24), ("vid3", 48)],
    "up_right": [("vid2", 60)],  # Will mirror left for up-right if needed
    "down_left": [("vid2", 72), ("vid4", 48)],
    "down_right": [("vid2", 36), ("vid2", 48)],
    "blink": [("vid4", 72), ("vid4", 36), ("vid3", 36)],
}

# Sprite sheet layout: 4 columns x 3 rows = 12 frames
# Row 0: up_left, up, up_right, blink
# Row 1: left, center, right, blink2
# Row 2: down_left, down, down_right, center2
SHEET_LAYOUT = [
    ["up_left", "up", "up_right", "blink"],
    ["left", "center", "right", "blink"],
    ["down_left", "down", "down_right", "center"],
]
COLS = 4
ROWS = 3


def get_brightness(r, g, b):
    """Calculate perceived brightness."""
    return int(0.299 * r + 0.587 * g + 0.114 * b)


def threshold_remove_background(img):
    """Remove light background using threshold (fallback method)."""
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    # More aggressive thresholds for cleaner removal
    BRIGHTNESS_THRESHOLD = 160
    SATURATION_THRESHOLD = 100

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            brightness = get_brightness(r, g, b)

            max_rgb = max(r, g, b)
            min_rgb = min(r, g, b)
            saturation = (max_rgb - min_rgb) if max_rgb > 0 else 0

            # Background is light AND low saturation (grayish/beige)
            if brightness > BRIGHTNESS_THRESHOLD and saturation < SATURATION_THRESHOLD:
                pixels[x, y] = (0, 0, 0, 0)  # Fully transparent
            elif brightness > BRIGHTNESS_THRESHOLD - 40 and saturation < SATURATION_THRESHOLD - 20:
                # Gradual transparency for edge blending
                alpha = int(255 * (1 - (brightness - (BRIGHTNESS_THRESHOLD - 40)) / 60))
                alpha = max(0, min(255, alpha))
                pixels[x, y] = (r, g, b, alpha)

    return img


def remove_background(img):
    """Remove background from image using best available method."""
    if HAS_REMBG:
        # Use AI-powered background removal
        return rembg_remove(img)
    else:
        # Fall back to threshold-based removal
        return threshold_remove_background(img)


def load_frame(video, frame_num):
    """Load a specific frame from a video directory."""
    frame_dir = FRAME_DIRS.get(video)
    if not frame_dir:
        print(f"Unknown video: {video}")
        return None

    frame_path = os.path.join(frame_dir, f"frame_{frame_num:03d}.png")
    if not os.path.exists(frame_path):
        print(f"Frame not found: {frame_path}")
        return None

    return Image.open(frame_path)


def process_frame(video, frame_num):
    """Load, resize, and remove background from a frame."""
    img = load_frame(video, frame_num)
    if img is None:
        return None

    # Remove background
    img = remove_background(img)

    # Ensure correct size
    if img.size != (FRAME_SIZE, FRAME_SIZE):
        img = img.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)

    return img


def mirror_horizontal(img):
    """Mirror image horizontally."""
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def get_best_frame_for_direction(direction):
    """Get the best frame for a given direction."""
    candidates = DIRECTION_FRAMES.get(direction, [])

    if not candidates:
        print(f"No candidates for direction: {direction}")
        return None

    # Try each candidate until we find a valid one
    for video, frame_num in candidates:
        img = process_frame(video, frame_num)
        if img is not None:
            print(f"  {direction}: using {video} frame {frame_num}")
            return img

    print(f"  {direction}: no valid frame found!")
    return None


def create_spritesheet():
    """Create the final sprite sheet with all directions."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("\nCollecting frames for each direction...")

    # Get frames for each direction
    direction_images = {}
    for direction in DIRECTION_FRAMES.keys():
        img = get_best_frame_for_direction(direction)
        if img:
            direction_images[direction] = img
            # Save individual processed frame
            img.save(os.path.join(OUTPUT_DIR, f"{direction}.png"))

    # Handle up_right by mirroring up_left if not available
    if "up_right" not in direction_images or direction_images.get("up_right") == direction_images.get("right"):
        if "up_left" in direction_images:
            print("  up_right: mirroring up_left")
            direction_images["up_right"] = mirror_horizontal(direction_images["up_left"])

    # Create sprite sheet
    print("\nCreating sprite sheet...")
    sheet_width = COLS * FRAME_SIZE
    sheet_height = ROWS * FRAME_SIZE
    spritesheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    for row_idx, row in enumerate(SHEET_LAYOUT):
        for col_idx, direction in enumerate(row):
            img = direction_images.get(direction)
            if img:
                x = col_idx * FRAME_SIZE
                y = row_idx * FRAME_SIZE
                spritesheet.paste(img, (x, y))
            else:
                print(f"  Warning: Missing frame for {direction} at ({col_idx}, {row_idx})")

    # Save sprite sheet
    spritesheet.save(SPRITESHEET_PATH)
    print(f"\nSprite sheet saved to: {SPRITESHEET_PATH}")
    print(f"Size: {sheet_width}x{sheet_height} ({COLS}x{ROWS} frames)")

    # Print frame index reference
    print("\nFrame index reference (for GDScript):")
    print("# 4x3 grid layout:")
    for row_idx, row in enumerate(SHEET_LAYOUT):
        for col_idx, direction in enumerate(row):
            frame_idx = row_idx * COLS + col_idx
            print(f"#   Frame {frame_idx}: {direction}")

    return spritesheet


def main():
    print("=" * 60)
    print("Eye Tracking Sprite Sheet Generator")
    print("=" * 60)

    # Check directories exist
    for name, path in FRAME_DIRS.items():
        if os.path.exists(path):
            count = len([f for f in os.listdir(path) if f.endswith('.png')])
            print(f"  {name}: {count} frames")
        else:
            print(f"  {name}: NOT FOUND")

    create_spritesheet()

    print("\n" + "=" * 60)
    print("Done! Update your GDScript to use the new sprite sheet.")
    print("=" * 60)


if __name__ == "__main__":
    main()
