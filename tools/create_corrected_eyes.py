"""
CORRECTED sprite sheet with VERIFIED gaze directions.
Each frame visually confirmed before mapping.
"""
import os
from PIL import Image

PROJECT_DIR = r"C:\Users\Conner\Downloads\VeilbreakersGame"
FRAME_DIRS = {
    "vid1": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "new_eye_anim"),
    "vid2": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid2"),
    "vid3": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid3"),
    "vid4": os.path.join(PROJECT_DIR, "assets", "ui", "frames", "eye_vid4"),
}
OUTPUT_PATH = os.path.join(PROJECT_DIR, "assets", "ui", "demon_eyes_corrected.png")
FRAME_SIZE = 256
COLS = 6
ROWS = 6

def get_brightness(r, g, b):
    return int(0.299 * r + 0.587 * g + 0.114 * b)

def threshold_remove_bg(img):
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size
    BRIGHTNESS_THRESH = 145
    SAT_THRESH = 90

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            brightness = get_brightness(r, g, b)
            max_rgb = max(r, g, b)
            min_rgb = min(r, g, b)
            saturation = max_rgb - min_rgb

            if brightness > BRIGHTNESS_THRESH and saturation < SAT_THRESH:
                pixels[x, y] = (0, 0, 0, 0)
            elif brightness > BRIGHTNESS_THRESH - 25 and saturation < SAT_THRESH - 15:
                alpha = int(255 * (1 - (brightness - (BRIGHTNESS_THRESH - 25)) / 40))
                pixels[x, y] = (r, g, b, max(0, min(255, alpha)))
    return img

# CORRECTED FRAME MAPPINGS - Each verified by viewing the actual frame
# Pattern: 4 consecutive frames per direction
CORRECTED_FRAMES = {
    # UP-LEFT: vid1 frames 36-39 (VERIFIED - pupils upper-left)
    "up_left": [("vid1", 36), ("vid1", 37), ("vid1", 38), ("vid1", 39)],

    # UP: vid3 frames 22-25 (VERIFIED - pupils looking up)
    "up": [("vid3", 22), ("vid3", 23), ("vid3", 24), ("vid3", 25)],

    # UP-RIGHT: vid1 frames 20-23 (pupils upper-right)
    "up_right": [("vid1", 20), ("vid1", 21), ("vid1", 22), ("vid1", 23)],

    # LEFT: vid1 frames 44-47 (VERIFIED - pupils looking left)
    "left": [("vid1", 44), ("vid1", 45), ("vid1", 46), ("vid1", 47)],

    # CENTER: vid1 frames 1-4 (VERIFIED - pupils centered)
    "center": [("vid1", 1), ("vid1", 2), ("vid1", 3), ("vid1", 4)],

    # RIGHT: vid2 frames 60-63 (VERIFIED - pupils looking right)
    "right": [("vid2", 60), ("vid2", 61), ("vid2", 62), ("vid2", 63)],

    # DOWN-LEFT: vid4 frames 64-67 (VERIFIED - pupils lower-left)
    "down_left": [("vid4", 64), ("vid4", 65), ("vid4", 66), ("vid4", 67)],

    # DOWN: vid4 frames 20-23 (VERIFIED - pupils looking down)
    "down": [("vid4", 20), ("vid4", 21), ("vid4", 22), ("vid4", 23)],

    # DOWN-RIGHT: vid2 frames 34-37 (VERIFIED - pupils lower-right)
    "down_right": [("vid2", 34), ("vid2", 35), ("vid2", 36), ("vid2", 37)],
}

DIRECTION_ORDER = ["up_left", "up", "up_right", "left", "center", "right", "down_left", "down", "down_right"]

def load_and_process(video, frame_num):
    frame_dir = FRAME_DIRS.get(video)
    frame_path = os.path.join(frame_dir, f"frame_{frame_num:03d}.png")
    if not os.path.exists(frame_path):
        print(f"  NOT FOUND: {frame_path}")
        return None
    img = Image.open(frame_path)
    result = threshold_remove_bg(img)
    if result.size != (FRAME_SIZE, FRAME_SIZE):
        result = result.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
    return result

def main():
    sheet_width = COLS * FRAME_SIZE
    sheet_height = ROWS * FRAME_SIZE
    spritesheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    print("=" * 60)
    print("CORRECTED Eye Sprite Sheet - Verified Frame Mappings")
    print("=" * 60)

    frame_idx = 0
    for direction in DIRECTION_ORDER:
        frames = CORRECTED_FRAMES[direction]
        print(f"\n{direction.upper()}:")
        for video, frame_num in frames:
            col = frame_idx % COLS
            row = frame_idx // COLS
            print(f"  [{frame_idx:02d}] {video} f{frame_num} -> ({col},{row})")

            img = load_and_process(video, frame_num)
            if img:
                spritesheet.paste(img, (col * FRAME_SIZE, row * FRAME_SIZE))
            frame_idx += 1

    spritesheet.save(OUTPUT_PATH, "PNG")
    print(f"\n{'=' * 60}")
    print(f"Saved: {OUTPUT_PATH}")
    print(f"Grid: {COLS}x{ROWS} = {COLS*ROWS} frames")

    print("""
GDSCRIPT - Copy this to main_menu_controller.gd:

const EYE_COLS: int = 6
const EYE_ROWS: int = 6
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
    main()
