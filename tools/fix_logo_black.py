"""
Remove black background from logo.
"""

from PIL import Image
import numpy as np

def main():
    source = r"C:\Users\Conner\Downloads\asset_nVAndsSL8gpej9rHhuwYu6RT_battlechasers style fantasy RPG game logo, VEILBREAKERS title text, epic dramatic logo design,_TITLE_ _VEILBREAKERS_ text in SHATTERED METALLIC LETTERS, each letter CRACKED WITH PURP.png"
    output = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\title\title_logo.png"

    print("Loading logo...")
    img = Image.open(source).convert('RGBA')
    data = np.array(img)

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # Remove dark/black pixels (all RGB < 30)
    is_black = (r < 35) & (g < 35) & (b < 35)

    # Make black pixels transparent
    data[is_black, 3] = 0

    result = Image.fromarray(data, 'RGBA')
    result.save(output)

    removed = np.sum(is_black)
    total = data.shape[0] * data.shape[1]
    print(f"Removed {removed}/{total} black pixels ({100*removed/total:.1f}%)")
    print(f"Saved: {output}")

if __name__ == "__main__":
    main()
