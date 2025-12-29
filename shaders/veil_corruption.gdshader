// VEIL CORRUPTION SHADER - The Veil's influence
shader_type canvas_item;

uniform float corruption : hint_range(0.0, 1.0) = 0.0;
uniform vec4 veil_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // RED
uniform sampler2D crack_texture;
uniform float crack_glow : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (corruption < 0.01) {
        COLOR = tex_color;
        return;
    }

    // Cracks spread based on corruption level
    float cracks = texture(crack_texture, UV).r;
    float crack_threshold = 1.0 - corruption;
    float crack_visible = smoothstep(crack_threshold, crack_threshold + 0.1, cracks);

    // Glow from cracks
    vec3 glow = veil_color.rgb * crack_visible * crack_glow;

    // Desaturate and darken uncorrupted areas
    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 darkened = mix(tex_color.rgb, vec3(gray) * 0.7, corruption * 0.5);

    // Final composition
    vec3 final_color = darkened + glow;
    COLOR = vec4(final_color, tex_color.a);
}
