"""
FINAL CORRECTED sprite sheet with ALL 9 directions + BLINK frames.
Each direction verified by visual inspection.
6x7 grid = 42 frames (36 direction + 4 blink + 2 spare)
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
OUTPUT_PATH = os.path.join(PROJECT_DIR, "assets", "ui", "demon_eyes_final.png")
FRAME_SIZE = 256
COLS = 6
ROWS = 7  # 42 frames total

def get_brightness(r, g, b):
    return int(0.299 * r + 0.587 * g + 0.114 * b)

def threshold_remove_bg(img):
    """Remove light/white background using threshold method."""
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

# FINAL VERIFIED FRAME MAPPINGS - All visually confirmed
FINAL_FRAMES = {
    # UP-LEFT: vid1 frames 36-39 (pupils in upper-left of each eye)
    "up_left": [("vid1", 36), ("vid1", 37), ("vid1", 38), ("vid1", 39)],

    # UP: vid3 frames 22-25 (round pupils looking upward)
    "up": [("vid3", 22), ("vid3", 23), ("vid3", 24), ("vid3", 25)],

    # UP-RIGHT: vid3 frames 4-7 (pupils in upper-right area)
    "up_right": [("vid3", 4), ("vid3", 5), ("vid3", 6), ("vid3", 7)],

    # LEFT: vid1 frames 44-47 (pupils shifted to left side)
    "left": [("vid1", 44), ("vid1", 45), ("vid1", 46), ("vid1", 47)],

    # CENTER: vid1 frames 1-4 (pupils centered, vertical slits)
    "center": [("vid1", 1), ("vid1", 2), ("vid1", 3), ("vid1", 4)],

    # RIGHT: vid2 frames 60-63 (pupils shifted to right side)
    "right": [("vid2", 60), ("vid2", 61), ("vid2", 62), ("vid2", 63)],

    # DOWN-LEFT: vid1 frames 62-65 (VERIFIED - clear lower-left gaze)
    "down_left": [("vid1", 62), ("vid1", 63), ("vid1", 64), ("vid1", 65)],

    # DOWN: vid1 frames 80-83 (pupils at bottom of eyes)
    "down": [("vid1", 80), ("vid1", 81), ("vid1", 82), ("vid1", 83)],

    # DOWN-RIGHT: vid4 frames 64-67 (VERIFIED - clear lower-right gaze)
    "down_right": [("vid4", 64), ("vid4", 65), ("vid4", 66), ("vid4", 67)],

    # BLINK: vid3 frames 38-41 (eyes squinting/closing)
    "blink": [("vid3", 38), ("vid3", 39), ("vid3", 40), ("vid3", 41)],
}

# Order for sprite sheet layout (matches 3x3 direction grid + blink)
DIRECTION_ORDER = [
    "up_left", "up", "up_right",
    "left", "center", "right",
    "down_left", "down", "down_right",
    "blink"
]

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
    print("FINAL Eye Sprite Sheet - All Directions + Blink")
    print("=" * 60)

    frame_idx = 0
    for direction in DIRECTION_ORDER:
        frames = FINAL_FRAMES[direction]
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
    print(f"Grid: {COLS}x{ROWS} = {COLS*ROWS} frames ({frame_idx} used)")

    print("""
============================================================
GDSCRIPT - Copy to main_menu_controller.gd:
============================================================

# 6x7 grid - 4 frames per direction + 4 blink frames
const EYE_COLS: int = 6
const EYE_ROWS: int = 7

# Direction frames (4 consecutive frames each)
const FRAMES_UP_LEFT: Array[int] = [0, 1, 2, 3]
const FRAMES_UP: Array[int] = [4, 5, 6, 7]
const FRAMES_UP_RIGHT: Array[int] = [8, 9, 10, 11]
const FRAMES_LEFT: Array[int] = [12, 13, 14, 15]
const FRAMES_CENTER: Array[int] = [16, 17, 18, 19]
const FRAMES_RIGHT: Array[int] = [20, 21, 22, 23]
const FRAMES_DOWN_LEFT: Array[int] = [24, 25, 26, 27]
const FRAMES_DOWN: Array[int] = [28, 29, 30, 31]
const FRAMES_DOWN_RIGHT: Array[int] = [32, 33, 34, 35]

# Blink frames
const FRAMES_BLINK: Array[int] = [36, 37, 38, 39]
const BLINK_ENABLED: bool = true
""")

if __name__ == "__main__":
    main()
