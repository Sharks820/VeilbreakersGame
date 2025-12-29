// SCREEN DAMAGE VIGNETTE - Post-process for low health
// Apply to ColorRect covering screen
shader_type canvas_item;

uniform float health_percent : hint_range(0.0, 1.0) = 1.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 damage_color : source_color = vec4(0.5, 0.0, 0.0, 1.0);

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center) * 2.0;

    // Vignette gets stronger as health decreases
    float health_factor = 1.0 - health_percent;
    float vignette_strength = health_factor * 0.8;

    // Pulse when low health
    float pulse = 0.0;
    if (health_percent < 0.3) {
        pulse = sin(TIME * 4.0) * 0.5 + 0.5;
        pulse *= pulse_intensity * (0.3 - health_percent) / 0.3;
    }

    float vignette = smoothstep(0.3, 1.0, dist) * (vignette_strength + pulse);

    COLOR = vec4(damage_color.rgb, vignette * damage_color.a);
}
