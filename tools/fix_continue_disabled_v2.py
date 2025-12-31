"""
Fix the disabled continue button - remove DARK gray checkered background.
"""

from PIL import Image
import numpy as np

def main():
    source = r"C:\Users\Conner\Downloads\asset_DbVPT8inznZRdPELQisLLmWQ_battlechasers style game menu button DISABLED STATE, single button, transparent background,_GREYED OUT CONTINUE BUTTON_ same dark metal jagged frame BUT desaturated, NO RED GLOW just.png"
    output = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\buttons\btn_continue_disabled.png"

    print("Loading disabled continue button...")
    img = Image.open(source).convert('RGBA')

    # Resize to 512x512
    img = img.resize((512, 512), Image.Resampling.LANCZOS)

    data = np.array(img)
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # Remove DARK gray pixels (the checkered background around RGB 90-110)
    is_dark_gray = (r > 85) & (r < 115) & \
                   (g > 85) & (g < 115) & \
                   (b > 85) & (b < 115) & \
                   (np.abs(r.astype(int) - g.astype(int)) < 10) & \
                   (np.abs(g.astype(int) - b.astype(int)) < 10)

    # Make dark gray pixels transparent
    data[is_dark_gray, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output)

    removed = np.sum(is_dark_gray)
    total = data.shape[0] * data.shape[1]
    print(f"Removed {removed}/{total} dark gray pixels ({100*removed/total:.1f}%)")
    print(f"Saved: {output}")

if __name__ == "__main__":
    main()
