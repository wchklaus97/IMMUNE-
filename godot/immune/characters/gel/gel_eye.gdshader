shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec4 eye_color : source_color = vec4(0.003, 0.002, 0.006, 1.0);
uniform float studio_strength : hint_range(0.0, 1.0) = 0.55;
uniform float studio_budget : hint_range(0.0, 1.0) = 0.42;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.055;
uniform vec2 main_card_center = vec2(-0.34, 0.42);
uniform vec2 main_card_shape = vec2(7.0, 16.0);
uniform vec2 pin_card_center = vec2(0.42, 0.58);
uniform vec2 pin_card_shape = vec2(34.0, 34.0);
uniform float eye_catchlight_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 eye_catchlight_center = vec2(-0.34, 0.38);
uniform vec2 eye_catchlight_shape = vec2(54.0, 58.0);
// V8.4 embeds these shallow marks into a translucent body. Reject them once
// the authored face axis turns behind the camera so transparency ordering can
// never reveal a second set of eyes/mouth through the back of the gel.
uniform float face_visibility_gate : hint_range(0.0, 1.0) = 0.0;
varying vec3 v_face_forward_view;
varying vec3 v_eye_local_normal;

// V8.1 deformation inputs mirror wet_gel and jelly_shell. All values are inert
// by default, preserving the exact V6-V8 eye/cavity geometry and shading.
uniform float liquid_flow_motion_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec3 liquid_flow_direction = vec3(0.0, 0.0, -1.0);
uniform float liquid_body_deform_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 liquid_body_lag = vec3(0.0);
uniform float liquid_body_squash : hint_range(0.0, 0.2) = 0.0;
uniform float liquid_body_space_enabled : hint_range(0.0, 1.0) = 0.0;
uniform vec3 liquid_part_origin = vec3(0.0);
uniform vec3 liquid_part_scale = vec3(1.0);
uniform mat3 liquid_part_basis = mat3(1.0);
uniform float liquid_turn_shear : hint_range(-0.2, 0.2) = 0.0;
uniform float liquid_contact_amount : hint_range(-1.0, 1.0) = 0.0;
uniform vec3 liquid_contact_normal = vec3(0.0);
uniform float liquid_wobble_strength : hint_range(0.0, 0.04) = 0.0;
uniform float liquid_wobble_speed : hint_range(0.0, 2.0) = 0.0;
uniform float liquid_wobble_scale : hint_range(0.2, 6.0) = 1.0;
uniform float liquid_wobble_phase : hint_range(0.0, 6.2832) = 0.0;
// V8.5-only analytic normal follow. Zero preserves V8.4 eye reflections and
// catchlights while an opted-in profile bends both with the moving gel mass.
uniform float liquid_wobble_normal_follow : hint_range(0.0, 1.0) = 0.0;

vec3 liquid_wobble_offset(vec3 body_position) {
	if (liquid_wobble_strength <= 0.0001) {
		return vec3(0.0);
	}
	float phase = TIME * liquid_wobble_speed + liquid_wobble_phase;
	float scale = liquid_wobble_scale;
	float sole_anchor = smoothstep(-0.02, 0.34, body_position.y);
	float activity = mix(0.46, 1.0, clamp(liquid_flow_motion_mix, 0.0, 1.0));
	vec3 wave = vec3(
		sin(body_position.y * scale * 1.70
			+ body_position.z * scale * 0.55 + phase) * 0.72,
		sin(body_position.x * scale * 1.15
			- body_position.z * scale * 0.82 + phase * 0.71) * 0.30,
		cos(body_position.y * scale * 1.43
			- body_position.x * scale * 0.48 - phase * 0.83) * 0.56);
	return wave * liquid_wobble_strength * sole_anchor * activity;
}

vec3 liquid_wobble_surface_normal(vec3 body_position, vec3 body_normal) {
	if (liquid_wobble_normal_follow <= 0.0001
			|| liquid_wobble_strength <= 0.0001) {
		return body_normal;
	}
	float phase = TIME * liquid_wobble_speed + liquid_wobble_phase;
	float scale = liquid_wobble_scale;
	float activity = mix(0.46, 1.0, clamp(liquid_flow_motion_mix, 0.0, 1.0));
	float amplitude = liquid_wobble_strength * activity;
	float anchor_t = clamp((body_position.y + 0.02) / 0.36, 0.0, 1.0);
	float sole_anchor = anchor_t * anchor_t * (3.0 - 2.0 * anchor_t);
	float anchor_dy = 6.0 * anchor_t * (1.0 - anchor_t) / 0.36;

	float phase_x = body_position.y * scale * 1.70
		+ body_position.z * scale * 0.55 + phase;
	float phase_y = body_position.x * scale * 1.15
		- body_position.z * scale * 0.82 + phase * 0.71;
	float phase_z = body_position.y * scale * 1.43
		- body_position.x * scale * 0.48 - phase * 0.83;
	float sin_x = sin(phase_x);
	float cos_x = cos(phase_x);
	float sin_y = sin(phase_y);
	float cos_y = cos(phase_y);
	float sin_z = sin(phase_z);
	float cos_z = cos(phase_z);
	vec3 wave = vec3(
		sin_x * 0.72,
		sin_y * 0.30,
		cos_z * 0.56);
	vec3 displacement_dx = amplitude * sole_anchor * vec3(
		0.0,
		cos_y * 0.30 * scale * 1.15,
		sin_z * 0.56 * scale * 0.48);
	vec3 displacement_dy = amplitude * (
		sole_anchor * vec3(
			cos_x * 0.72 * scale * 1.70,
			0.0,
			-sin_z * 0.56 * scale * 1.43)
		+ wave * anchor_dy);
	vec3 displacement_dz = amplitude * sole_anchor * vec3(
		cos_x * 0.72 * scale * 0.55,
		-cos_y * 0.30 * scale * 0.82,
		0.0);

	vec3 jacobian_x = vec3(1.0, 0.0, 0.0) + displacement_dx;
	vec3 jacobian_y = vec3(0.0, 1.0, 0.0) + displacement_dy;
	vec3 jacobian_z = vec3(0.0, 0.0, 1.0) + displacement_dz;
	vec3 followed_normal = normalize(
		cross(jacobian_y, jacobian_z) * body_normal.x
		+ cross(jacobian_z, jacobian_x) * body_normal.y
		+ cross(jacobian_x, jacobian_y) * body_normal.z);
	return normalize(mix(
		body_normal,
		followed_normal,
		clamp(liquid_wobble_normal_follow, 0.0, 1.0)));
}

void vertex() {
	v_eye_local_normal = normalize(NORMAL);
	v_face_forward_view = normalize(
		(MODELVIEW_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
	if (liquid_body_space_enabled >= 0.5) {
		vec3 safe_part_scale = max(abs(liquid_part_scale), vec3(0.0001));
		mat3 body_to_part = transpose(liquid_part_basis);
		vec3 body_position = liquid_part_origin
			+ liquid_part_basis * (VERTEX * safe_part_scale);
		vec3 original_body_position = body_position;
		vec3 body_normal = normalize(
			liquid_part_basis * (NORMAL / safe_part_scale));

		float body_squash = liquid_body_squash * liquid_body_deform_strength;
		float vertical_scale = max(1.0 - body_squash, 0.8);
		float lateral_scale = 1.0 + body_squash * 0.55;
		body_position.y *= vertical_scale;
		body_position.xz *= lateral_scale;

		vec2 move_direction = liquid_flow_direction.xz;
		if (length(move_direction) > 0.001) {
			move_direction = normalize(move_direction);
			float along = dot(body_position.xz, move_direction);
			body_position.xz += move_direction * along
				* liquid_flow_motion_mix * liquid_body_deform_strength * 0.035;
		}

		float upper_mass = smoothstep(0.0, 1.10, body_position.y);
		body_position += liquid_body_lag * upper_mass * liquid_body_deform_strength;

		vec3 turn_axis = vec3(-liquid_flow_direction.z, 0.0, liquid_flow_direction.x);
		if (length(turn_axis) > 0.001) {
			turn_axis = normalize(turn_axis);
			body_position += turn_axis * liquid_turn_shear * upper_mass;
			body_normal.y -= dot(body_normal, turn_axis) * liquid_turn_shear * 0.91;
		}

		vec3 contact_normal = liquid_contact_normal;
		float positive_contact = max(liquid_contact_amount, 0.0);
		if (positive_contact > 0.001 && length(contact_normal) > 0.001) {
			contact_normal = normalize(contact_normal);
			float contact_side = smoothstep(
				-0.08, 0.62, dot(body_position, -contact_normal));
			body_position += contact_normal * positive_contact * 0.055 * contact_side;
		}
		vec3 wobble_position = body_position;
		body_position += liquid_wobble_offset(wobble_position);

		vec3 scaled_body_normal = normalize(vec3(
			body_normal.x / lateral_scale,
			body_normal.y / vertical_scale,
			body_normal.z / lateral_scale));
		if (liquid_wobble_normal_follow > 0.0001) {
			body_normal = liquid_wobble_surface_normal(
				wobble_position,
				scaled_body_normal);
		} else {
			body_normal = scaled_body_normal;
		}
		VERTEX += (body_to_part * (body_position - original_body_position))
			/ safe_part_scale;
		NORMAL = normalize((body_to_part * body_normal) * safe_part_scale);
		if (liquid_wobble_normal_follow > 0.0001) {
			v_eye_local_normal = normalize(NORMAL);
		}
	}
}

void fragment() {
	if (face_visibility_gate > 0.5
			&& dot(normalize(v_face_forward_view), normalize(VIEW)) < -0.08) {
		discard;
	}
	vec3 n = normalize(NORMAL);
	vec3 reflection_vector = reflect(-normalize(VIEW), n);
	float studio_front = smoothstep(-0.20, 0.70, reflection_vector.z);
	vec2 main_delta = reflection_vector.xy - main_card_center;
	vec2 pin_delta = reflection_vector.xy - pin_card_center;
	float main_card = exp(-(
		main_delta.x * main_delta.x * main_card_shape.x
		+ main_delta.y * main_delta.y * main_card_shape.y)) * studio_front;
	float pin_card = exp(-(
		pin_delta.x * pin_delta.x * pin_card_shape.x
		+ pin_delta.y * pin_delta.y * pin_card_shape.y)) * studio_front;
	vec3 studio = (
		vec3(0.94, 0.98, 1.0) * main_card
		+ vec3(0.45, 0.68, 1.0) * pin_card * 0.55) * studio_strength;
	vec3 local_eye_normal = normalize(v_eye_local_normal);
	float eye_catchlight = exp(-(
		(local_eye_normal.x - eye_catchlight_center.x)
			* (local_eye_normal.x - eye_catchlight_center.x)
			* eye_catchlight_shape.x
		+ (local_eye_normal.y - eye_catchlight_center.y)
			* (local_eye_normal.y - eye_catchlight_center.y)
			* eye_catchlight_shape.y));
	studio += vec3(1.0, 0.98, 0.94) * eye_catchlight
		* eye_catchlight_strength;
	float peak = max(max(studio.r, studio.g), studio.b);
	if (peak > studio_budget) {
		studio *= studio_budget / max(peak, 0.0001);
	}
	ALBEDO = eye_color.rgb;
	ROUGHNESS = surface_roughness;
	METALLIC = 0.0;
	SPECULAR = 1.0;
	EMISSION = studio;
}
