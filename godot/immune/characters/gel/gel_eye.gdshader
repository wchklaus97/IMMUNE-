shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec4 eye_color : source_color = vec4(0.003, 0.002, 0.006, 1.0);
uniform float studio_strength : hint_range(0.0, 1.0) = 0.55;
uniform float studio_budget : hint_range(0.0, 1.0) = 0.42;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.055;

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

void vertex() {
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

		body_normal = normalize(vec3(
			body_normal.x / lateral_scale,
			body_normal.y / vertical_scale,
			body_normal.z / lateral_scale));
		VERTEX += (body_to_part * (body_position - original_body_position))
			/ safe_part_scale;
		NORMAL = normalize((body_to_part * body_normal) * safe_part_scale);
	}
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 reflection_vector = reflect(-normalize(VIEW), n);
	float studio_front = smoothstep(-0.20, 0.70, reflection_vector.z);
	vec2 main_delta = reflection_vector.xy - vec2(-0.34, 0.42);
	vec2 pin_delta = reflection_vector.xy - vec2(0.42, 0.58);
	float main_card = exp(-(
		main_delta.x * main_delta.x * 7.0
		+ main_delta.y * main_delta.y * 16.0)) * studio_front;
	float pin_card = exp(-(
		pin_delta.x * pin_delta.x * 34.0
		+ pin_delta.y * pin_delta.y * 34.0)) * studio_front;
	vec3 studio = (
		vec3(0.94, 0.98, 1.0) * main_card
		+ vec3(0.45, 0.68, 1.0) * pin_card * 0.55) * studio_strength;
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
