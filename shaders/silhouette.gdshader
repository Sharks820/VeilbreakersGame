// SILHOUETTE SHADER - For obscured enemies
shader_type canvas_item;

uniform vec4 silhouette_color : source_color = vec4(0.2, 0.2, 0.2, 0.8);
uniform bool show_silhouette = true;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (show_silhouette && tex_color.a > 0.1) {
        COLOR = vec4(silhouette_color.rgb, tex_color.a * silhouette_color.a);
    } else {
        COLOR = tex_color;
    }
}
