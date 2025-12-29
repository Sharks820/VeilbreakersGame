// DISSOLVE SHADER - Death/spawn effect with brand colors
shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture : filter_linear;
uniform vec4 edge_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform float edge_glow : hint_range(0.0, 5.0) = 2.0;
uniform bool use_world_uv = false;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    vec2 noise_uv = use_world_uv ? (UV + vec2(TIME * 0.1, 0.0)) : UV;
    float noise = texture(noise_texture, noise_uv).r;

    float alpha_threshold = dissolve_amount;
    float edge_threshold = dissolve_amount + edge_width;

    if (noise < alpha_threshold) {
        discard;
    } else if (noise < edge_threshold) {
        float edge_factor = 1.0 - (noise - alpha_threshold) / edge_width;
        vec3 glow = edge_color.rgb * edge_glow * edge_factor;
        COLOR = vec4(tex_color.rgb + glow, tex_color.a);
    } else {
        COLOR = tex_color;
    }
}
