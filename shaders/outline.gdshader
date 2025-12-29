// OUTLINE SHADER - Selection/target highlighting
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform bool outline_only = false;
uniform float pulse_speed : hint_range(0.0, 10.0) = 0.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;

    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(-size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a * 0.707;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a * 0.707;
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a * 0.707;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a * 0.707;
    outline = min(outline, 1.0);

    vec4 tex_color = texture(TEXTURE, UV);

    float pulse = 1.0;
    if (pulse_speed > 0.0) {
        pulse = mix(pulse_min, 1.0, (sin(TIME * pulse_speed) + 1.0) * 0.5);
    }

    vec4 final_outline = vec4(outline_color.rgb, outline * outline_color.a * pulse);

    if (outline_only) {
        COLOR = vec4(outline_color.rgb, outline * (1.0 - tex_color.a) * pulse);
    } else {
        COLOR = mix(final_outline, tex_color, tex_color.a);
    }
}
