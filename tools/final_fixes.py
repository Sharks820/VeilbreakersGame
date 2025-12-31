"""
Final fixes:
1. Title logo - remove black background
2. Continue disabled button - remove ALL gray background more aggressively
"""

from PIL import Image
import numpy as np

def fix_logo():
    source = r"C:\Users\Conner\Downloads\asset_nVAndsSL8gpej9rHhuwYu6RT_battlechasers style fantasy RPG game logo, VEILBREAKERS title text, epic dramatic logo design,_TITLE_ _VEILBREAKERS_ text in SHATTERED METALLIC LETTERS, each letter CRACKED WITH PURP.png"
    output = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\title\title_logo.png"

    print("Fixing title logo...")
    img = Image.open(source).convert('RGBA')
    data = np.array(img)

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # Remove black/very dark pixels
    is_black = (r < 40) & (g < 40) & (b < 40)
    data[is_black, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output)
    print(f"  Saved logo: {output}")

def fix_continue_button():
    source = r"C:\Users\Conner\Downloads\asset_DbVPT8inznZRdPELQisLLmWQ_battlechasers style game menu button DISABLED STATE, single button, transparent background,_GREYED OUT CONTINUE BUTTON_ same dark metal jagged frame BUT desaturated, NO RED GLOW just.png"
    output = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\buttons\btn_continue_disabled.png"

    print("Fixing continue disabled button...")
    img = Image.open(source).convert('RGBA')
    img = img.resize((512, 512), Image.Resampling.LANCZOS)

    data = np.array(img)
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # ULTRA AGGRESSIVE - remove ANY gray pixel where R≈G≈B and value is 30-120
    is_gray = (np.abs(r.astype(int) - g.astype(int)) < 15) & \
              (np.abs(g.astype(int) - b.astype(int)) < 15)

    is_checker_range = ((r > 25) & (r < 125))

    is_background = is_gray & is_checker_range
    data[is_background, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output)

    removed = np.sum(is_background)
    total = data.shape[0] * data.shape[1]
    print(f"  Removed {removed}/{total} pixels ({100*removed/total:.1f}%)")
    print(f"  Saved: {output}")

def main():
    fix_logo()
    fix_continue_button()
    print("\nDone!")

if __name__ == "__main__":
    main()
