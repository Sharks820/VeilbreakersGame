"""
FINAL smooth eye tracking sprite sheet - 6x6 grid (36 frames)
4 frames per direction for smooth animation transitions.
"""
import os
import requests
from PIL import Image
import io

API_KEY = "iqLbPPtTeKDmLoYxfFMPm5Zd"
API_URL = "https://api.remove.bg/v1.0/removebg"

PROJECT_DIR = r"C:\Users\Conner\Downloads\VeilbreakersGame"
FRAME_DIRS = {
    "vid1": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "new_eye_anim"),
    "vid2": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid2"),
    "vid3": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid3"),
    "vid4": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid4"),
}
OUTPUT_DIR = os.path.join(PROJECT_DIR, "assets", "ui", "frames", "final_eyes")
SPRITESHEET_PATH = os.path.join(PROJECT_DIR, "assets", "ui", "demon_eyes_smooth.png")

FRAME_SIZE = 256
GRID_COLS = 6
GRID_ROWS = 6

# VERIFIED FRAME MAPPING - 4 frames per direction for smooth animation
# Based on comprehensive frame-by-frame analysis
FRAME_MAP = [
    # Row 0: UP-LEFT (4), UP (4), UP-RIGHT (4) - frames 0-11
    ("vid1", 12), ("vid1", 18), ("vid1", 24), ("vid3", 48),  # UP-LEFT
    ("vid3", 18), ("vid3", 24), ("vid2", 84), ("vid3", 22),  # UP
    ("vid3", 6), ("vid3", 8), ("vid3", 10), ("vid2", 48),    # UP-RIGHT

    # Row 1: LEFT (4), CENTER (4), RIGHT (4) - frames 12-23
    ("vid1", 36), ("vid1", 42), ("vid1", 44), ("vid1", 48),  # LEFT
    ("vid1", 1), ("vid1", 6), ("vid3", 54), ("vid3", 60),    # CENTER
    ("vid2", 60), ("vid2", 62), ("vid2", 64), ("vid2", 66),  # RIGHT

    # Row 2: DOWN-LEFT (4), DOWN (4), DOWN-RIGHT (4) - frames 24-35
    ("vid4", 42), ("vid4", 48), ("vid4", 66), ("vid2", 72),  # DOWN-LEFT
    ("vid4", 18), ("vid4", 24), ("vid4", 54), ("vid4", 60),  # DOWN
    ("vid2", 36), ("vid2", 42), ("vid2", 48), ("vid2", 54),  # DOWN-RIGHT
]

# Also add BLINK frames at the end (replacing last row with blink sequence)
BLINK_FRAMES = [
    ("vid1", 66), ("vid1", 68), ("vid1", 70), ("vid4", 72),
    ("vid3", 78), ("vid4", 74),
]

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
            print(f"    API error {response.status_code}: {response.text[:100]}")
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
    print(f"    Frame not found: {frame_path}")
    return None

def process_frame(video, frame_num, cache):
    """Process a frame with remove.bg, using cache."""
    cache_key = f"{video}_{frame_num}"
    if cache_key in cache:
        return cache[cache_key]

    img = load_frame(video, frame_num)
    if img is None:
        return None

    # Save temp for API
    temp_path = os.path.join(OUTPUT_DIR, f"temp_{cache_key}.png")
    img.save(temp_path)

    result = remove_bg_api(temp_path)

    if os.path.exists(temp_path):
        os.remove(temp_path)

    if result:
        if result.size != (FRAME_SIZE, FRAME_SIZE):
            result = result.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
        cache[cache_key] = result
        return result

    # Fallback
    if img.size != (FRAME_SIZE, FRAME_SIZE):
        img = img.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
    cache[cache_key] = img
    return img

def create_spritesheet():
    """Create the final smooth sprite sheet."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    sheet_width = GRID_COLS * FRAME_SIZE
    sheet_height = GRID_ROWS * FRAME_SIZE
    spritesheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    cache = {}

    print("\nProcessing directional frames...")
    for idx, (video, frame_num) in enumerate(FRAME_MAP):
        col = idx % GRID_COLS
        row = idx // GRID_COLS
        print(f"  [{idx:02d}] {video} frame {frame_num} -> ({col}, {row})")

        img = process_frame(video, frame_num, cache)
        if img:
            x = col * FRAME_SIZE
            y = row * FRAME_SIZE
            spritesheet.paste(img, (x, y))

    # Fill remaining with blink frames
    remaining_start = len(FRAME_MAP)
    print("\nProcessing blink frames...")
    for i, (video, frame_num) in enumerate(BLINK_FRAMES):
        idx = remaining_start + i
        if idx >= GRID_COLS * GRID_ROWS:
            break
        col = idx % GRID_COLS
        row = idx // GRID_COLS
        print(f"  [{idx:02d}] {video} frame {frame_num} -> ({col}, {row}) BLINK")

        img = process_frame(video, frame_num, cache)
        if img:
            x = col * FRAME_SIZE
            y = row * FRAME_SIZE
            spritesheet.paste(img, (x, y))

    spritesheet.save(SPRITESHEET_PATH, "PNG")
    print(f"\nSprite sheet saved: {SPRITESHEET_PATH}")
    print(f"Size: {sheet_width}x{sheet_height} ({GRID_COLS}x{GRID_ROWS} = {GRID_COLS*GRID_ROWS} frames)")

    # Print GDScript constants
    print("\n" + "=" * 60)
    print("GDSCRIPT FRAME INDICES:")
    print("=" * 60)
    print("""
# 6x6 grid layout - 4 frames per direction
const EYE_COLS: int = 6
const EYE_ROWS: int = 6

# Direction frame ranges (start index, 4 frames each)
const FRAMES_UP_LEFT: Array[int] = [0, 1, 2, 3]
const FRAMES_UP: Array[int] = [4, 5, 6, 7]
const FRAMES_UP_RIGHT: Array[int] = [8, 9, 10, 11]
const FRAMES_LEFT: Array[int] = [12, 13, 14, 15]
const FRAMES_CENTER: Array[int] = [16, 17, 18, 19]
const FRAMES_RIGHT: Array[int] = [20, 21, 22, 23]
const FRAMES_DOWN_LEFT: Array[int] = [24, 25, 26, 27]
const FRAMES_DOWN: Array[int] = [28, 29, 30, 31]
const FRAMES_DOWN_RIGHT: Array[int] = [32, 33, 34, 35]
const FRAMES_BLINK: Array[int] = [32, 33, 34, 35]  # Reuse last row or add more
""")

def main():
    print("=" * 60)
    print("FINAL Smooth Eye Animation Sprite Sheet")
    print("=" * 60)
    create_spritesheet()
    print("\nDone!")

if __name__ == "__main__":
    main()
