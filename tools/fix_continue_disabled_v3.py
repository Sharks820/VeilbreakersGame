"""
Fix the disabled continue button - remove BOTH dark gray checker colors.
Dark squares: RGB ~37-42
Medium squares: RGB ~96-102
"""

from PIL import Image
import numpy as np

def main():
    source = r"C:\Users\Conner\Downloads\asset_DbVPT8inznZRdPELQisLLmWQ_battlechasers style game menu button DISABLED STATE, single button, transparent background,_GREYED OUT CONTINUE BUTTON_ same dark metal jagged frame BUT desaturated, NO RED GLOW just.png"
    output = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\buttons\btn_continue_disabled.png"

    print("Loading disabled continue button...")
    img = Image.open(source).convert('RGBA')
    img = img.resize((512, 512), Image.Resampling.LANCZOS)

    data = np.array(img)
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # DARK gray checker squares (~35-45)
    is_dark = (r > 30) & (r < 50) & \
              (g > 30) & (g < 50) & \
              (b > 30) & (b < 50) & \
              (np.abs(r.astype(int) - g.astype(int)) < 8) & \
              (np.abs(g.astype(int) - b.astype(int)) < 8)

    # MEDIUM gray checker squares (~90-110)
    is_medium = (r > 85) & (r < 115) & \
                (g > 85) & (g < 115) & \
                (b > 85) & (b < 115) & \
                (np.abs(r.astype(int) - g.astype(int)) < 10) & \
                (np.abs(g.astype(int) - b.astype(int)) < 10)

    # Combine both
    is_checker = is_dark | is_medium

    # Make checker pixels transparent
    data[is_checker, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output)

    dark_removed = np.sum(is_dark)
    medium_removed = np.sum(is_medium)
    total = data.shape[0] * data.shape[1]
    print(f"Removed {dark_removed} dark gray pixels")
    print(f"Removed {medium_removed} medium gray pixels")
    print(f"Total: {dark_removed + medium_removed}/{total} ({100*(dark_removed + medium_removed)/total:.1f}%)")
    print(f"Saved: {output}")

if __name__ == "__main__":
    main()
