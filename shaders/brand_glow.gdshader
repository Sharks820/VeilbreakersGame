// BRAND GLOW SHADER - Elemental aura effect
shader_type canvas_item;

uniform vec4 brand_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float glow_size : hint_range(0.0, 20.0) = 4.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float inner_glow : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Outer glow
    float glow = 0.0;
    vec2 size = TEXTURE_PIXEL_SIZE * glow_size;

    for (float x = -2.0; x <= 2.0; x += 1.0) {
        for (float y = -2.0; y <= 2.0; y += 1.0) {
            if (x == 0.0 && y == 0.0) continue;
            float dist = length(vec2(x, y));
            glow += texture(TEXTURE, UV + vec2(x, y) * size).a / dist;
        }
    }
    glow = clamp(glow / 8.0, 0.0, 1.0);

    // Pulse
    float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
    float final_intensity = glow_intensity * (0.7 + pulse * 0.3);

    // Inner glow on sprite
    vec3 inner = tex_color.rgb + brand_color.rgb * inner_glow * tex_color.a;

    // Combine
    vec4 outer = vec4(brand_color.rgb * final_intensity, glow * (1.0 - tex_color.a));
    COLOR = mix(outer, vec4(inner, tex_color.a), tex_color.a);
}
