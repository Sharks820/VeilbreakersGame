"""
Create a larger sprite sheet with smooth transitions between all gaze directions.
Uses frames from all 4 videos to provide multiple frames per direction for fluid animation.
"""
import os
import requests
from PIL import Image
import io
import math

API_KEY = "iqLbPPtTeKDmLoYxfFMPm5Zd"
API_URL = "https://api.remove.bg/v1.0/removebg"

PROJECT_DIR = r"C:\Users\Conner\Downloads\VeilbreakersGame"
FRAME_DIRS = {
    "vid1": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "new_eye_anim"),
    "vid2": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid2"),
    "vid3": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid3"),
    "vid4": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid4"),
}
OUTPUT_DIR = os.path.join(PROJECT_DIR, "assets", "ui", "frames", "smooth_eyes")
SPRITESHEET_PATH = os.path.join(PROJECT_DIR, "assets", "ui", "demon_eyes_smooth.png")

FRAME_SIZE = 256

# Extended frame mapping with multiple frames per direction for smooth transitions
# Format: direction -> [(video, frame), ...]
# More frames = smoother animation
DIRECTION_FRAMES = {
    # CENTER - multiple frames for idle variation
    "center": [
        ("vid1", 1), ("vid1", 2), ("vid1", 3), ("vid1", 4), ("vid1", 5),
        ("vid3", 60), ("vid3", 61)
    ],

    # LEFT - sequence of left-looking frames
    "left": [
        ("vid1", 44), ("vid1", 45), ("vid1", 46), ("vid1", 47), ("vid1", 48),
        ("vid3", 84), ("vid3", 85)
    ],

    # RIGHT - sequence of right-looking frames
    "right": [
        ("vid2", 58), ("vid2", 59), ("vid2", 60), ("vid2", 61), ("vid2", 62)
    ],

    # UP - sequence of up-looking frames
    "up": [
        ("vid3", 22), ("vid3", 23), ("vid3", 24), ("vid3", 25), ("vid3", 26),
        ("vid2", 82), ("vid2", 83), ("vid2", 84)
    ],

    # DOWN - sequence of down-looking frames
    "down": [
        ("vid2", 22), ("vid2", 23), ("vid2", 24), ("vid2", 25), ("vid2", 26),
        ("vid4", 58), ("vid4", 59), ("vid4", 60)
    ],

    # UP-LEFT - sequence
    "up_left": [
        ("vid1", 22), ("vid1", 23), ("vid1", 24), ("vid1", 25), ("vid1", 26),
        ("vid3", 46), ("vid3", 47), ("vid3", 48)
    ],

    # UP-RIGHT - sequence
    "up_right": [
        ("vid2", 46), ("vid2", 47), ("vid2", 48), ("vid2", 49), ("vid2", 50)
    ],

    # DOWN-LEFT - sequence
    "down_left": [
        ("vid2", 70), ("vid2", 71), ("vid2", 72), ("vid2", 73), ("vid2", 74),
        ("vid4", 46), ("vid4", 47), ("vid4", 48)
    ],

    # DOWN-RIGHT - sequence
    "down_right": [
        ("vid2", 34), ("vid2", 35), ("vid2", 36), ("vid2", 37), ("vid2", 38)
    ],

    # BLINK - full blink sequence
    "blink": [
        ("vid4", 68), ("vid4", 69), ("vid4", 70), ("vid4", 71), ("vid4", 72),
        ("vid4", 73), ("vid4", 74), ("vid4", 75)
    ]
}

# Layout for 8x8 grid = 64 frames total
# This gives us plenty of frames for smooth animation
GRID_COLS = 8
GRID_ROWS = 8

# Frame layout in the sprite sheet:
# Row 0-1: Center (idle variations + transitions)
# Row 2: Up sequence
# Row 3: Down sequence
# Row 4: Left sequence
# Row 5: Right sequence
# Row 6: Diagonals (up-left, up-right, down-left, down-right)
# Row 7: Blink sequence

def remove_bg_api(image_path):
    """Remove background using remove.bg API."""
    try:
        with open(image_path, 'rb') as f:
            response = requests.post(
                API_URL,
                files={'image_file': f},
                data={'size': 'auto'},
                headers={'X-Api-Key': API_KEY}
            )
        if response.status_code == requests.codes.ok:
            return Image.open(io.BytesIO(response.content))
        else:
            print(f"    API error: {response.status_code}")
            return None
    except Exception as e:
        print(f"    Error: {e}")
        return None

def load_frame(video, frame_num):
    """Load a frame from disk."""
    frame_dir = FRAME_DIRS.get(video)
    if not frame_dir:
        return None
    frame_path = os.path.join(frame_dir, f"frame_{frame_num:03d}.png")
    if os.path.exists(frame_path):
        return Image.open(frame_path)
    return None

def process_frame_with_api(video, frame_num, cache):
    """Load and process a frame, using cache to avoid duplicate API calls."""
    cache_key = f"{video}_{frame_num}"
    if cache_key in cache:
        return cache[cache_key]

    img = load_frame(video, frame_num)
    if img is None:
        return None

    # Save temp file for API
    temp_path = os.path.join(OUTPUT_DIR, f"temp_{cache_key}.png")
    img.save(temp_path)

    # Process with remove.bg
    result = remove_bg_api(temp_path)

    # Clean up temp file
    if os.path.exists(temp_path):
        os.remove(temp_path)

    if result:
        # Resize to standard size
        if result.size != (FRAME_SIZE, FRAME_SIZE):
            result = result.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
        cache[cache_key] = result
        return result

    # Fallback to original
    if img.size != (FRAME_SIZE, FRAME_SIZE):
        img = img.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
    cache[cache_key] = img
    return img

def create_smooth_spritesheet():
    """Create the smooth animation sprite sheet."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 8x8 grid
    sheet_width = GRID_COLS * FRAME_SIZE
    sheet_height = GRID_ROWS * FRAME_SIZE
    spritesheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    cache = {}
    frame_idx = 0

    # Order of directions to fill the grid
    directions_order = [
        "center",      # Row 0-1 (16 frames for center/idle)
        "up",          # Row 2 (8 frames)
        "down",        # Row 3 (8 frames)
        "left",        # Row 4 (8 frames)
        "right",       # Row 5 (8 frames)
        "up_left", "up_right", "down_left", "down_right",  # Row 6 (8 frames, 2 each)
        "blink"        # Row 7 (8 frames)
    ]

    print("\nProcessing frames...")

    for direction in directions_order:
        frames_for_dir = DIRECTION_FRAMES.get(direction, [])
        print(f"  {direction}: {len(frames_for_dir)} source frames")

        for video, frame_num in frames_for_dir:
            if frame_idx >= GRID_COLS * GRID_ROWS:
                break

            print(f"    Processing {video} frame {frame_num}...")
            img = process_frame_with_api(video, frame_num, cache)

            if img:
                col = frame_idx % GRID_COLS
                row = frame_idx // GRID_COLS
                x = col * FRAME_SIZE
                y = row * FRAME_SIZE
                spritesheet.paste(img, (x, y))
                frame_idx += 1

    # Fill remaining slots with center frames if needed
    print(f"\n  Filled {frame_idx} frames, padding remaining...")
    center_frames = DIRECTION_FRAMES.get("center", [])
    while frame_idx < GRID_COLS * GRID_ROWS:
        cf = center_frames[frame_idx % len(center_frames)]
        img = process_frame_with_api(cf[0], cf[1], cache)
        if img:
            col = frame_idx % GRID_COLS
            row = frame_idx // GRID_COLS
            x = col * FRAME_SIZE
            y = row * FRAME_SIZE
            spritesheet.paste(img, (x, y))
        frame_idx += 1

    spritesheet.save(SPRITESHEET_PATH, "PNG")
    print(f"\nSprite sheet saved to: {SPRITESHEET_PATH}")
    print(f"Size: {sheet_width}x{sheet_height} ({GRID_COLS}x{GRID_ROWS} = {GRID_COLS*GRID_ROWS} frames)")

    # Generate frame index map for GDScript
    print("\n" + "=" * 60)
    print("FRAME INDEX MAP FOR GDSCRIPT:")
    print("=" * 60)

    idx = 0
    for direction in directions_order:
        frames = DIRECTION_FRAMES.get(direction, [])
        start_idx = idx
        end_idx = min(idx + len(frames) - 1, GRID_COLS * GRID_ROWS - 1)
        print(f"const FRAMES_{direction.upper()}: Array[int] = range({start_idx}, {end_idx + 1})")
        idx += len(frames)

    return spritesheet

def main():
    print("=" * 60)
    print("Smooth Eye Animation Sprite Sheet Generator")
    print("=" * 60)

    print("\nSource directories:")
    for name, path in FRAME_DIRS.items():
        if os.path.exists(path):
            count = len([f for f in os.listdir(path) if f.endswith('.png')])
            print(f"  {name}: {count} frames")

    create_smooth_spritesheet()
    print("\nDone!")

if __name__ == "__main__":
    main()
