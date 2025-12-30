shader_type canvas_item;

uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.7;
uniform float shadow_offset : hint_range(0.0, 30.0) = 8.0;
uniform float shadow_softness : hint_range(1.0, 20.0) = 6.0;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Sample for shadow (offset upward and to the side for depth)
	vec2 shadow_uv = UV - vec2(shadow_offset * 0.3, shadow_offset) * TEXTURE_PIXEL_SIZE;

	// Multi-sample for soft shadow
	float shadow = 0.0;
	float samples = 0.0;
	for (float x = -shadow_softness; x <= shadow_softness; x += 2.0) {
		for (float y = -shadow_softness; y <= shadow_softness; y += 2.0) {
			vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
			shadow += texture(TEXTURE, shadow_uv + offset).a;
			samples += 1.0;
		}
	}
	shadow = shadow / samples;

	// Shadow only where there's no original pixel
	float shadow_mask = shadow * (1.0 - tex_color.a) * shadow_intensity;

	// Blend: shadow behind, original on top
	vec4 final_shadow = shadow_color * shadow_mask;
	COLOR = mix(final_shadow, tex_color, tex_color.a);
	COLOR.a = max(tex_color.a, shadow_mask);
}
