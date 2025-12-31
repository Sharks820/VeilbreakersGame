"""
Fix the disabled continue button - remove light gray background.
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

    # Remove light gray pixels (the checkered background)
    # For the disabled button, the checker uses similar light gray values
    is_light = (r > 180) & (g > 180) & (b > 180)

    # Make light pixels transparent
    data[is_light, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output)

    removed = np.sum(is_light)
    total = data.shape[0] * data.shape[1]
    print(f"Removed {removed}/{total} pixels ({100*removed/total:.1f}%)")
    print(f"Saved: {output}")

if __name__ == "__main__":
    main()
