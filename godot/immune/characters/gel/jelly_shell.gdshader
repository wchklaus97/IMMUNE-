shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

// Compatibility-safe outer membrane. Alpha stays nearly zero across the face of
// the object and rises only at grazing angles, so it supplies the thick clear rim
// in the concept without bleaching the coloured core or requiring screen texture
// refraction (unsupported in the project's macOS Compatibility path).
uniform vec4 shell_color : source_color = vec4(0.88, 0.72, 1.0, 1.0);
uniform float face_alpha : hint_range(0.0, 0.2) = 0.01;
uniform float edge_alpha : hint_range(0.0, 0.8) = 0.34;
uniform float edge_power : hint_range(0.5, 10.0) = 3.2;
uniform float shell_roughness : hint_range(0.005, 0.3) = 0.035;
uniform float rim_emission : hint_range(0.0, 2.0) = 0.12;
// Authored bodies carry older, deliberately hot per-instance shell values.
// These V5 bounds live in the shader so every builder receives the same clear
// dielectric response without duplicating profile data or raising alpha.
uniform float shell_energy_scale : hint_range(0.0, 1.0) = 0.42;
uniform float shell_diffuse_strength : hint_range(0.0, 1.0) = 0.18;
uniform float shell_specular_level : hint_range(0.0, 1.0) = 0.48;
uniform float shell_emission_limit : hint_range(0.0, 0.2) = 0.025;
uniform float shell_alpha_limit : hint_range(0.0, 0.8) = 0.28;
uniform float shell_white_mix : hint_range(0.0, 1.0) = 0.0;
// V6-only analytic reflection cards. Defaults are inert for the accepted V5 path.
uniform float studio_reflection_strength : hint_range(0.0, 1.0) = 0.0;
uniform float studio_reflection_alpha : hint_range(0.0, 0.3) = 0.0;
uniform float studio_reflection_budget : hint_range(0.0, 0.2) = 0.0;
// Zero preserves the separately scaled authored M/N/A/D shell meshes. Imported
// T/B bodies use this shader as a next pass and opt into a small normal-space
// expansion, avoiding z-fighting without duplicating their mesh hierarchy.
uniform float shell_thickness : hint_range(0.0, 0.03) = 0.0;

void vertex() {
	VERTEX += NORMAL * shell_thickness;
}

void fragment() {
	float fresnel = clamp(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float edge = pow(fresnel, max(edge_power * 0.78, 0.5));
	vec3 reflection_vector = reflect(-normalize(VIEW), normalize(NORMAL));
	float studio_front = smoothstep(-0.18, 0.62, reflection_vector.z);
	vec2 key_delta = reflection_vector.xy - vec2(-0.38, 0.42);
	vec2 cool_delta = reflection_vector.xy - vec2(0.62, 0.02);
	float studio_key = exp(-(
		key_delta.x * key_delta.x * 4.0 + key_delta.y * key_delta.y * 13.0))
		* studio_front;
	float studio_cool = exp(-(
		cool_delta.x * cool_delta.x * 16.0 + cool_delta.y * cool_delta.y * 3.5))
		* studio_front;
	float studio_mask = clamp(studio_key + studio_cool * 0.72, 0.0, 1.0);
	vec3 studio = (
		vec3(0.90, 0.97, 1.0) * studio_key
		+ vec3(0.24, 0.48, 1.0) * studio_cool * 0.72
	) * studio_reflection_strength;
	vec3 clear_shell_color = mix(shell_color.rgb, vec3(1.0), shell_white_mix);
	ALBEDO = clear_shell_color * shell_diffuse_strength;
	ROUGHNESS = max(shell_roughness, 0.04);
	METALLIC = 0.0;
	SPECULAR = shell_specular_level;
	ALPHA = min(
		face_alpha + edge_alpha * edge * shell_energy_scale
		+ studio_mask * studio_reflection_alpha,
		shell_alpha_limit);
	float bounded_emission = min(
		rim_emission * edge * shell_energy_scale,
		shell_emission_limit);
	float studio_peak = max(max(studio.r, studio.g), studio.b);
	vec3 bounded_studio = studio_peak > studio_reflection_budget
		? studio * (studio_reflection_budget / max(studio_peak, 0.0001))
		: studio;
	EMISSION = clear_shell_color * bounded_emission + bounded_studio;
}
