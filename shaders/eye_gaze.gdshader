shader_type canvas_item;

// Gaze direction: -1.0 to 1.0 for both axes
uniform vec2 gaze_direction = vec2(0.0, 0.0);

// How much the pupils can shift (in pixels, scaled by texture size)
uniform float gaze_strength = 0.05;

// Sprite sheet configuration
uniform int hframes = 12;
uniform int vframes = 8;
uniform int current_frame = 0;

// Eye centers within a single frame (0-1 normalized to frame)
uniform vec2 left_eye_center = vec2(0.7, 0.5);
uniform vec2 right_eye_center = vec2(0.3, 0.5);
uniform float pupil_radius = 0.25;

void fragment() {
    // Calculate frame position in grid
    int frame_x = current_frame % hframes;
    int frame_y = current_frame / hframes;

    // Calculate UV bounds for current frame
    float frame_width = 1.0 / float(hframes);
    float frame_height = 1.0 / float(vframes);

    float frame_u_start = float(frame_x) * frame_width;
    float frame_v_start = float(frame_y) * frame_height;

    // Convert global UV to local frame UV (0-1 within frame)
    vec2 local_uv;
    local_uv.x = (UV.x - frame_u_start) / frame_width;
    local_uv.y = (UV.y - frame_v_start) / frame_height;

    // Calculate offset based on gaze direction
    vec2 offset = gaze_direction * gaze_strength;

    // Calculate distance from each eye center (in local frame space)
    float dist_left = distance(local_uv, left_eye_center);
    float dist_right = distance(local_uv, right_eye_center);

    // Apply offset with falloff based on distance from eye centers
    float left_influence = smoothstep(pupil_radius, 0.0, dist_left);
    float right_influence = smoothstep(pupil_radius, 0.0, dist_right);
    float influence = max(left_influence, right_influence);

    // Apply offset in local space, then convert back to global UV
    vec2 shifted_local = local_uv - offset * influence;
    vec2 shifted_uv;
    shifted_uv.x = frame_u_start + shifted_local.x * frame_width;
    shifted_uv.y = frame_v_start + shifted_local.y * frame_height;

    // Clamp to frame bounds to prevent bleeding
    shifted_uv.x = clamp(shifted_uv.x, frame_u_start, frame_u_start + frame_width - 0.001);
    shifted_uv.y = clamp(shifted_uv.y, frame_v_start, frame_v_start + frame_height - 0.001);

    COLOR = texture(TEXTURE, shifted_uv);
}
