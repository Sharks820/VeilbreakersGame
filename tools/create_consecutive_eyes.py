"""
Create sprite sheet with CONSECUTIVE frames per direction for smooth animation.
Using frames that are sequential in the source video = similar appearance = smooth transitions.
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
OUTPUT_PATH = os.path.join(PROJECT_DIR, "assets", "ui", "demon_eyes_final.png")
FRAME_SIZE = 256

# 6x6 grid = 36 frames
# 4 CONSECUTIVE frames per direction for smooth animation
COLS = 6
ROWS = 6

# CONSECUTIVE frames from each direction sequence
# Using sequential frames ensures visual similarity
FRAME_SEQUENCES = {
    # UP-LEFT: vid1 frames 22-25 (consecutive up-left sequence)
    "up_left": [("vid1", 22), ("vid1", 23), ("vid1", 24), ("vid1", 25)],

    # UP: vid3 frames 22-25 (consecutive up sequence)
    "up": [("vid3", 22), ("vid3", 23), ("vid3", 24), ("vid3", 25)],

    # UP-RIGHT: vid3 frames 4-7 (consecutive up-right sequence)
    "up_right": [("vid3", 4), ("vid3", 5), ("vid3", 6), ("vid3", 7)],

    # LEFT: vid1 frames 46-49 (consecutive left sequence)
    "left": [("vid1", 46), ("vid1", 47), ("vid1", 48), ("vid1", 49)],

    # CENTER: vid1 frames 1-4 (consecutive center sequence)
    "center": [("vid1", 1), ("vid1", 2), ("vid1", 3), ("vid1", 4)],

    # RIGHT: vid2 frames 60-63 (consecutive right sequence)
    "right": [("vid2", 60), ("vid2", 61), ("vid2", 62), ("vid2", 63)],

    # DOWN-LEFT: vid4 frames 64-67 (consecutive down-left sequence)
    "down_left": [("vid4", 64), ("vid4", 65), ("vid4", 66), ("vid4", 67)],

    # DOWN: vid4 frames 22-25 (consecutive down sequence)
    "down": [("vid4", 22), ("vid4", 23), ("vid4", 24), ("vid4", 25)],

    # DOWN-RIGHT: vid2 frames 34-37 (consecutive down-right sequence)
    "down_right": [("vid2", 34), ("vid2", 35), ("vid2", 36), ("vid2", 37)],
}

# Order for sprite sheet layout
DIRECTION_ORDER = [
    "up_left", "up", "up_right",
    "left", "center", "right",
    "down_left", "down", "down_right"
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
            print(f"    API error: {response.status_code}")
            return None
    except Exception as e:
        print(f"    Error: {e}")
        return None

def get_brightness(r, g, b):
    """Calculate perceived brightness."""
    return int(0.299 * r + 0.587 * g + 0.114 * b)

def threshold_remove_bg(img):
    """Remove light background using threshold method."""
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    BRIGHTNESS_THRESH = 150
    SAT_THRESH = 100

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            brightness = get_brightness(r, g, b)
            max_rgb = max(r, g, b)
            min_rgb = min(r, g, b)
            saturation = max_rgb - min_rgb

            if brightness > BRIGHTNESS_THRESH and saturation < SAT_THRESH:
                pixels[x, y] = (0, 0, 0, 0)
            elif brightness > BRIGHTNESS_THRESH - 30 and saturation < SAT_THRESH - 20:
                alpha = int(255 * (1 - (brightness - (BRIGHTNESS_THRESH - 30)) / 50))
                alpha = max(0, min(255, alpha))
                pixels[x, y] = (r, g, b, alpha)

    return img

def load_and_process(video, frame_num, cache):
    """Load frame and remove background with caching."""
    cache_key = f"{video}_{frame_num}"
    if cache_key in cache:
        return cache[cache_key]

    frame_dir = FRAME_DIRS.get(video)
    frame_path = os.path.join(frame_dir, f"frame_{frame_num:03d}.png")

    if not os.path.exists(frame_path):
        print(f"    Frame not found: {frame_path}")
        return None

    img = Image.open(frame_path)

    # Try remove.bg API first
    temp_path = os.path.join(PROJECT_DIR, "temp_eye_proc.png")
    img.save(temp_path)
    result = remove_bg_api(temp_path)
    if os.path.exists(temp_path):
        os.remove(temp_path)

    if result:
        if result.size != (FRAME_SIZE, FRAME_SIZE):
            result = result.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
        cache[cache_key] = result
        return result

    # Fallback to threshold method
    print(f"    Using threshold fallback")
    result = threshold_remove_bg(img)
    if result.size != (FRAME_SIZE, FRAME_SIZE):
        result = result.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
    cache[cache_key] = result
    return result

def create_spritesheet():
    """Create 6x6 sprite sheet with consecutive frames."""
    sheet_width = COLS * FRAME_SIZE
    sheet_height = ROWS * FRAME_SIZE
    spritesheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    cache = {}
    frame_idx = 0

    print("Creating 6x6 sprite sheet with consecutive frames...")
    print("=" * 60)

    for direction in DIRECTION_ORDER:
        frames = FRAME_SEQUENCES[direction]
        print(f"\n{direction.upper()}:")

        for video, frame_num in frames:
            col = frame_idx % COLS
            row = frame_idx // COLS

            print(f"  [{frame_idx:02d}] {video} frame {frame_num} -> ({col}, {row})")

            img = load_and_process(video, frame_num, cache)
            if img:
                x = col * FRAME_SIZE
                y = row * FRAME_SIZE
                spritesheet.paste(img, (x, y))

            frame_idx += 1

    spritesheet.save(OUTPUT_PATH, "PNG")
    print(f"\n{'=' * 60}")
    print(f"Saved: {OUTPUT_PATH}")
    print(f"Size: {sheet_width}x{sheet_height} ({COLS}x{ROWS} = {COLS*ROWS} frames)")

    print("\n" + "=" * 60)
    print("GDSCRIPT CODE:")
    print("=" * 60)
    print("""
# 6x6 grid - 4 consecutive frames per direction
const EYE_COLS: int = 6
const EYE_ROWS: int = 6

# Frame arrays - consecutive frames for smooth animation
const FRAMES_UP_LEFT: Array[int] = [0, 1, 2, 3]
const FRAMES_UP: Array[int] = [4, 5, 6, 7]
const FRAMES_UP_RIGHT: Array[int] = [8, 9, 10, 11]
const FRAMES_LEFT: Array[int] = [12, 13, 14, 15]
const FRAMES_CENTER: Array[int] = [16, 17, 18, 19]
const FRAMES_RIGHT: Array[int] = [20, 21, 22, 23]
const FRAMES_DOWN_LEFT: Array[int] = [24, 25, 26, 27]
const FRAMES_DOWN: Array[int] = [28, 29, 30, 31]
const FRAMES_DOWN_RIGHT: Array[int] = [32, 33, 34, 35]
""")

if __name__ == "__main__":
    create_spritesheet()
