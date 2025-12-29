// =============================================================================
// VEILBREAKERS AAA SHADER PACK
// Production-ready shaders for combat feel
// =============================================================================

// -----------------------------------------------------------------------------
// 1. HIT FLASH SHADER - White flash on damage
// -----------------------------------------------------------------------------
// File: hit_flash.gdshader

shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool preserve_alpha = true;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (preserve_alpha) {
        COLOR = mix(tex_color, vec4(flash_color.rgb, tex_color.a), flash_amount);
    } else {
        COLOR = mix(tex_color, flash_color, flash_amount);
    }
}

// -----------------------------------------------------------------------------
// 2. DISSOLVE SHADER - Death/spawn effect with brand colors
// -----------------------------------------------------------------------------
// File: dissolve.gdshader

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

// -----------------------------------------------------------------------------
// 3. OUTLINE SHADER - Selection/target highlighting
// -----------------------------------------------------------------------------
// File: outline.gdshader

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

// -----------------------------------------------------------------------------
// 4. DAMAGE TINT SHADER - Red flash + desaturation for hurt
// -----------------------------------------------------------------------------
// File: damage_tint.gdshader

shader_type canvas_item;

uniform float damage_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 damage_color : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;
uniform float shake_amount : hint_range(0.0, 10.0) = 0.0;

void fragment() {
    vec2 shake_offset = vec2(0.0);
    if (shake_amount > 0.0) {
        shake_offset = vec2(
            sin(TIME * 50.0) * shake_amount * TEXTURE_PIXEL_SIZE.x,
            cos(TIME * 50.0) * shake_amount * TEXTURE_PIXEL_SIZE.y
        );
    }

    vec4 tex_color = texture(TEXTURE, UV + shake_offset);

    // Desaturation
    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desaturated = mix(tex_color.rgb, vec3(gray), desaturation);

    // Damage tint
    vec3 final_color = mix(desaturated, damage_color.rgb, damage_amount);

    COLOR = vec4(final_color, tex_color.a);
}

// -----------------------------------------------------------------------------
// 5. BRAND GLOW SHADER - Elemental aura effect
// -----------------------------------------------------------------------------
// File: brand_glow.gdshader

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

// -----------------------------------------------------------------------------
// 6. SILHOUETTE SHADER - For obscured enemies
// -----------------------------------------------------------------------------
// File: silhouette.gdshader

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

// -----------------------------------------------------------------------------
// 7. CAPTURE BEAM SHADER - Swirling capture effect
// -----------------------------------------------------------------------------
// File: capture_beam.gdshader

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

// -----------------------------------------------------------------------------
// 8. STATUS EFFECT OVERLAY SHADER - Poison bubbles, burn, etc.
// -----------------------------------------------------------------------------
// File: status_overlay.gdshader

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

// -----------------------------------------------------------------------------
// 9. VEIL CORRUPTION SHADER - The Veil's influence
// -----------------------------------------------------------------------------
// File: veil_corruption.gdshader

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

// -----------------------------------------------------------------------------
// 10. SCREEN DAMAGE VIGNETTE - Post-process for low health
// -----------------------------------------------------------------------------
// File: damage_vignette.gdshader (Apply to ColorRect covering screen)

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
