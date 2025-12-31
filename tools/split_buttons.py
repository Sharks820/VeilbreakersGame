"""
Split the 2x2 button grid and copy the disabled button.
All source images already have proper transparency.
"""

from PIL import Image
import os

def main():
    output_dir = r"C:\Users\Conner\Downloads\VeilbreakersGame\assets\ui\buttons"

    # Source: 2x2 grid with transparency
    grid_path = r"C:\Users\Conner\Downloads\asset_NyxLATwLSc44fu5dDHmBjkGx_background-removal_1766894232.png"

    # Source: Disabled continue button
    disabled_path = r"C:\Users\Conner\Downloads\asset_DbVPT8inznZRdPELQisLLmWQ_battlechasers style game menu button DISABLED STATE, single button, transparent background,_GREYED OUT CONTINUE BUTTON_ same dark metal jagged frame BUT desaturated, NO RED GLOW just.png"

    # Load and split the 2x2 grid
    print("Loading 2x2 grid...")
    grid = Image.open(grid_path).convert('RGBA')
    w, h = grid.size
    half_w, half_h = w // 2, h // 2

    # Grid layout:
    # [New Game] [Continue]
    # [Settings] [Quit]

    buttons = {
        "btn_new_game.png": grid.crop((0, 0, half_w, half_h)),
        "btn_continue.png": grid.crop((half_w, 0, w, half_h)),
        "btn_settings.png": grid.crop((0, half_h, half_w, h)),
        "btn_quit.png": grid.crop((half_w, half_h, w, h)),
    }

    # Resize and save each button
    target_size = (512, 512)
    for name, img in buttons.items():
        resized = img.resize(target_size, Image.Resampling.LANCZOS)
        output_path = os.path.join(output_dir, name)
        resized.save(output_path)
        print(f"Saved: {name} ({resized.size})")

    # Handle disabled continue button
    print("\nProcessing disabled continue button...")
    disabled = Image.open(disabled_path).convert('RGBA')
    disabled_resized = disabled.resize(target_size, Image.Resampling.LANCZOS)
    disabled_output = os.path.join(output_dir, "btn_continue_disabled.png")
    disabled_resized.save(disabled_output)
    print(f"Saved: btn_continue_disabled.png ({disabled_resized.size})")

    print("\nDone! All 5 buttons ready.")

if __name__ == "__main__":
    main()
