"""
Use remove.bg API to clean backgrounds from eye animation frames.
"""
import os
import requests
from PIL import Image
import io

API_KEY = "iqLbPPtTeKDmLoYxfFMPm5Zd"
API_URL = "https://api.remove.bg/v1.0/removebg"

PROJECT_DIR = r"C:\Users\Conner\Downloads\VeilbreakersGame"
INPUT_DIR = os.path.join(PROJECT_DIR, "assets", "ui", "frames", "processed_eyes")
OUTPUT_DIR = os.path.join(PROJECT_DIR, "assets", "ui", "frames", "removebg_eyes")
SPRITESHEET_PATH = os.path.join(PROJECT_DIR, "assets", "ui", "demon_eyes_directional.png")

FRAME_SIZE = 256
COLS = 4
ROWS = 3

DIRECTIONS = [
    "up_left", "up", "up_right", "blink",
    "left", "center", "right", "blink",
    "down_left", "down", "down_right", "center"
]

def remove_bg_api(image_path):
    """Remove background using remove.bg API."""
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
        print(f"  Error: {response.status_code} - {response.text}")
        return None

def process_frames():
    """Process each direction frame through remove.bg."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    processed = {}
    for direction in set(DIRECTIONS):  # Use set to avoid duplicates
        input_path = os.path.join(INPUT_DIR, f"{direction}.png")
        if not os.path.exists(input_path):
            print(f"  {direction}: file not found at {input_path}")
            continue

        print(f"  Processing {direction}...")
        result = remove_bg_api(input_path)

        if result:
            output_path = os.path.join(OUTPUT_DIR, f"{direction}.png")
            result.save(output_path, "PNG")
            processed[direction] = result
            print(f"    Saved to {output_path}")
        else:
            # Use original as fallback
            processed[direction] = Image.open(input_path)
            print(f"    Using original (API failed)")

    return processed

def create_spritesheet(frames):
    """Create sprite sheet from processed frames."""
    sheet_width = COLS * FRAME_SIZE
    sheet_height = ROWS * FRAME_SIZE
    spritesheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    for row in range(ROWS):
        for col in range(COLS):
            idx = row * COLS + col
            direction = DIRECTIONS[idx]

            if direction in frames:
                img = frames[direction]
                # Resize if needed
                if img.size != (FRAME_SIZE, FRAME_SIZE):
                    img = img.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)

                x = col * FRAME_SIZE
                y = row * FRAME_SIZE
                spritesheet.paste(img, (x, y))

    spritesheet.save(SPRITESHEET_PATH, "PNG")
    print(f"\nSprite sheet saved to: {SPRITESHEET_PATH}")

def main():
    print("=" * 60)
    print("Remove.bg Background Cleanup")
    print("=" * 60)

    print("\nProcessing individual frames...")
    frames = process_frames()

    print(f"\nCreating sprite sheet...")
    create_spritesheet(frames)

    print("\nDone!")

if __name__ == "__main__":
    main()
