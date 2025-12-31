"""
Create verified 3x3 eye sprite sheet with ONE best frame per direction.
Each frame visually confirmed for correct gaze direction.
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
OUTPUT_PATH = os.path.join(PROJECT_DIR, "assets", "ui", "demon_eyes_3x3.png")
FRAME_SIZE = 256

# VERIFIED BEST FRAMES - one per direction
# 3x3 grid layout:
#   [0] UP-LEFT    [1] UP       [2] UP-RIGHT
#   [3] LEFT       [4] CENTER   [5] RIGHT
#   [6] DOWN-LEFT  [7] DOWN     [8] DOWN-RIGHT

VERIFIED_FRAMES = [
    # Row 0: UP directions
    ("vid1", 24),   # 0: UP-LEFT - vid1 f24 clear up-left
    ("vid3", 24),   # 1: UP - vid3 f24 clear up
    ("vid3", 6),    # 2: UP-RIGHT - vid3 f6 clear up-right

    # Row 1: Horizontal
    ("vid1", 48),   # 3: LEFT - vid1 f48 clear left
    ("vid1", 1),    # 4: CENTER - vid1 f1 center/forward
    ("vid2", 60),   # 5: RIGHT - vid2 f60 clear right

    # Row 2: DOWN directions
    ("vid4", 66),   # 6: DOWN-LEFT - vid4 f66 clear down-left
    ("vid4", 24),   # 7: DOWN - vid4 f24 clear down
    ("vid2", 36),   # 8: DOWN-RIGHT - vid2 f36 clear down-right
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
            print(f"  API error: {response.status_code}")
            return None
    except Exception as e:
        print(f"  Error: {e}")
        return None

def load_and_process(video, frame_num):
    """Load frame and remove background."""
    frame_dir = FRAME_DIRS.get(video)
    frame_path = os.path.join(frame_dir, f"frame_{frame_num:03d}.png")

    if not os.path.exists(frame_path):
        print(f"  Frame not found: {frame_path}")
        return None

    print(f"  Processing {video} frame {frame_num}...")

    # Load original
    img = Image.open(frame_path)

    # Save temp for API
    temp_path = os.path.join(PROJECT_DIR, "temp_eye.png")
    img.save(temp_path)

    # Remove background
    result = remove_bg_api(temp_path)

    # Cleanup
    if os.path.exists(temp_path):
        os.remove(temp_path)

    if result:
        if result.size != (FRAME_SIZE, FRAME_SIZE):
            result = result.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
        return result

    # Fallback to original
    if img.size != (FRAME_SIZE, FRAME_SIZE):
        img = img.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
    return img

def create_spritesheet():
    """Create 3x3 verified sprite sheet."""
    COLS = 3
    ROWS = 3
    sheet_width = COLS * FRAME_SIZE
    sheet_height = ROWS * FRAME_SIZE

    spritesheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    directions = ["UP-LEFT", "UP", "UP-RIGHT", "LEFT", "CENTER", "RIGHT", "DOWN-LEFT", "DOWN", "DOWN-RIGHT"]

    print("Creating verified 3x3 sprite sheet...")
    for idx, (video, frame_num) in enumerate(VERIFIED_FRAMES):
        col = idx % COLS
        row = idx // COLS
        direction = directions[idx]

        print(f"[{idx}] {direction}: {video} frame {frame_num}")

        img = load_and_process(video, frame_num)
        if img:
            x = col * FRAME_SIZE
            y = row * FRAME_SIZE
            spritesheet.paste(img, (x, y))

    spritesheet.save(OUTPUT_PATH, "PNG")
    print(f"\nSaved: {OUTPUT_PATH}")
    print(f"Size: {sheet_width}x{sheet_height} (3x3 = 9 frames)")

    print("\n" + "=" * 50)
    print("GDSCRIPT FRAME INDICES:")
    print("=" * 50)
    print("""
# 3x3 grid - one frame per direction
const EYE_COLS: int = 3
const EYE_ROWS: int = 3

const FRAME_UP_LEFT: int = 0
const FRAME_UP: int = 1
const FRAME_UP_RIGHT: int = 2
const FRAME_LEFT: int = 3
const FRAME_CENTER: int = 4
const FRAME_RIGHT: int = 5
const FRAME_DOWN_LEFT: int = 6
const FRAME_DOWN: int = 7
const FRAME_DOWN_RIGHT: int = 8
""")

if __name__ == "__main__":
    create_spritesheet()
