// DAMAGE TINT SHADER - Red flash + desaturation for hurt
shader_type canvas_item;

uniform float damage_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 damage_color : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;
uniform float shake_amount : hint_range(0.0, 10.0) = 0.0;

void fragment() {
    vec2 shake_offset = vec2(0.0);
    if (shake_amount > 0.0) {
        shake_offset = vec2(
            sin(TIME * 50.0) * shake_amount * TEXTURE_PIXEL_SIZE.x,
            cos(TIME * 50.0) * shake_amount * TEXTURE_PIXEL_SIZE.y
        );
    }

    vec4 tex_color = texture(TEXTURE, UV + shake_offset);

    // Desaturation
    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desaturated = mix(tex_color.rgb, vec3(gray), desaturation);

    // Damage tint
    vec3 final_color = mix(desaturated, damage_color.rgb, damage_amount);

    COLOR = vec4(final_color, tex_color.a);
}
