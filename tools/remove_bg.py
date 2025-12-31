"""Remove light background from eye animation frames and create transparent sprite sheet."""
from PIL import Image
import os

INPUT_DIR = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\frames\new_eye_anim"
OUTPUT_DIR = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\frames\transparent_eyes"
SPRITESHEET_PATH = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\demon_eyes_animated.png"

# Grid configuration
COLS = 12
ROWS = 8
FRAME_SIZE = 256

# Background removal threshold - pixels brighter than this become transparent
# The background is light gray/beige, eyes are dark orange/red
BRIGHTNESS_THRESHOLD = 180  # 0-255, higher = more aggressive removal
EDGE_FEATHER = 2  # Pixels to feather at edges

def get_brightness(r, g, b):
    """Calculate perceived brightness."""
    return int(0.299 * r + 0.587 * g + 0.114 * b)

def remove_background(img):
    """Remove light background from image, making it transparent."""
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            brightness = get_brightness(r, g, b)

            # Check if pixel is part of background (light colored)
            # Also check if it's grayish (low saturation)
            max_rgb = max(r, g, b)
            min_rgb = min(r, g, b)
            saturation = (max_rgb - min_rgb) / max(max_rgb, 1) * 255

            # Background is light AND low saturation (grayish)
            if brightness > BRIGHTNESS_THRESHOLD and saturation < 80:
                pixels[x, y] = (r, g, b, 0)  # Fully transparent
            elif brightness > BRIGHTNESS_THRESHOLD - 30 and saturation < 60:
                # Partial transparency for edge blending
                alpha = int(255 * (1 - (brightness - (BRIGHTNESS_THRESHOLD - 30)) / 30))
                alpha = max(0, min(255, alpha))
                pixels[x, y] = (r, g, b, alpha)

    return img

def process_frames():
    """Process all frames and remove backgrounds."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    frames = []
    for i in range(1, 97):  # frames 001-096
        filename = f"frame_{i:03d}.png"
        input_path = os.path.join(INPUT_DIR, filename)

        if os.path.exists(input_path):
            print(f"Processing {filename}...")
            img = Image.open(input_path)
            img_transparent = remove_background(img)

            output_path = os.path.join(OUTPUT_DIR, filename)
            img_transparent.save(output_path, "PNG")
            frames.append(img_transparent)
        else:
            print(f"Missing: {filename}")
            # Create blank transparent frame as placeholder
            frames.append(Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0)))

    return frames

def create_spritesheet(frames):
    """Create 12x8 sprite sheet from frames."""
    sheet_width = COLS * FRAME_SIZE
    sheet_height = ROWS * FRAME_SIZE

    spritesheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    for idx, frame in enumerate(frames):
        if idx >= COLS * ROWS:
            break
        col = idx % COLS
        row = idx // COLS
        x = col * FRAME_SIZE
        y = row * FRAME_SIZE

        # Resize if needed
        if frame.size != (FRAME_SIZE, FRAME_SIZE):
            frame = frame.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)

        spritesheet.paste(frame, (x, y))

    spritesheet.save(SPRITESHEET_PATH, "PNG")
    print(f"Sprite sheet saved to: {SPRITESHEET_PATH}")
    print(f"Size: {sheet_width}x{sheet_height}")

if __name__ == "__main__":
    print("Removing backgrounds from eye animation frames...")
    frames = process_frames()
    print(f"\nCreating sprite sheet from {len(frames)} frames...")
    create_spritesheet(frames)
    print("\nDone!")
