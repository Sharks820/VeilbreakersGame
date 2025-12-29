// HIT FLASH SHADER - White flash on damage
shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool preserve_alpha = true;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (preserve_alpha) {
        COLOR = mix(tex_color, vec4(flash_color.rgb, tex_color.a), flash_amount);
    } else {
        COLOR = mix(tex_color, flash_color, flash_amount);
    }
}
