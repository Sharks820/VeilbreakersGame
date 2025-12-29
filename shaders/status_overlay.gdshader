// STATUS EFFECT OVERLAY SHADER - Poison bubbles, burn, etc.
shader_type canvas_item;

uniform int status_type = 0; // 0=poison, 1=burn, 2=freeze, 3=shock
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D noise_texture;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (tex_color.a < 0.1) {
        discard;
    }

    float noise = texture(noise_texture, UV + vec2(TIME * 0.1, TIME * 0.05)).r;
    vec3 effect_color = vec3(0.0);

    if (status_type == 0) { // Poison - green bubbles
        effect_color = vec3(0.2, 0.8, 0.2);
        float bubbles = step(0.8, noise) * step(0.5 + sin(TIME * 3.0 + UV.y * 10.0) * 0.3, UV.y);
        effect_color *= bubbles + 0.3;
    } else if (status_type == 1) { // Burn - orange flicker
        effect_color = vec3(1.0, 0.5, 0.1);
        effect_color *= 0.5 + noise * 0.5 + sin(TIME * 10.0) * 0.2;
    } else if (status_type == 2) { // Freeze - blue ice
        effect_color = vec3(0.3, 0.6, 1.0);
        effect_color *= 0.7 + step(0.7, noise) * 0.3;
    } else if (status_type == 3) { // Shock - yellow sparks
        effect_color = vec3(1.0, 1.0, 0.3);
        float spark = step(0.95, noise + sin(TIME * 20.0 + UV.x * 30.0) * 0.1);
        effect_color *= 0.3 + spark * 0.7;
    }

    vec3 final_color = mix(tex_color.rgb, effect_color, intensity * 0.5);
    COLOR = vec4(final_color, tex_color.a);
}
