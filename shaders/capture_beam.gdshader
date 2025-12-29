// CAPTURE BEAM SHADER - Swirling capture effect
shader_type canvas_item;

uniform vec4 beam_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float swirl_speed : hint_range(0.0, 20.0) = 5.0;
uniform float beam_width : hint_range(0.0, 1.0) = 0.3;
uniform sampler2D noise_texture;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 to_center = UV - center;
    float dist = length(to_center);
    float angle = atan(to_center.y, to_center.x);

    // Swirl
    float swirl = angle + TIME * swirl_speed + dist * 10.0;
    float noise = texture(noise_texture, vec2(swirl * 0.1, dist)).r;

    // Beam shape
    float beam = smoothstep(beam_width, 0.0, dist);
    beam *= smoothstep(0.0, 0.2, progress);
    beam *= noise;

    // Convergence at center based on progress
    float convergence = smoothstep(1.0 - progress, 1.0, 1.0 - dist);

    float final_alpha = (beam + convergence * 0.5) * beam_color.a;
    COLOR = vec4(beam_color.rgb, final_alpha);
}
