shader_type canvas_item;

// Makes white/light pixels transparent for sprite sheets with white backgrounds
uniform float threshold : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Calculate brightness (average of RGB)
	float brightness = (tex.r + tex.g + tex.b) / 3.0;

	// Make bright pixels (near white) transparent
	if (brightness > threshold) {
		COLOR = vec4(tex.rgb, 0.0);
	} else {
		// Keep darker pixels, boost saturation slightly for the eye glow
		COLOR = tex;
	}
}
