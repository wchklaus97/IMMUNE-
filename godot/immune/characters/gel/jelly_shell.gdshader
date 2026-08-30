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
uniform float shell_energy_scale : hint_range(0.0, 1.0) = 0.38;
uniform float shell_diffuse_strength : hint_range(0.0, 1.0) = 0.22;
uniform float shell_specular_level : hint_range(0.0, 1.0) = 0.38;
uniform float shell_emission_limit : hint_range(0.0, 0.2) = 0.02;
uniform float shell_alpha_limit : hint_range(0.0, 0.8) = 0.24;
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
	ALBEDO = shell_color.rgb * shell_diffuse_strength;
	ROUGHNESS = max(shell_roughness, 0.055);
	METALLIC = 0.0;
	SPECULAR = shell_specular_level;
	ALPHA = min(face_alpha + edge_alpha * edge * shell_energy_scale, shell_alpha_limit);
	float bounded_emission = min(
		rim_emission * edge * shell_energy_scale,
		shell_emission_limit);
	EMISSION = shell_color.rgb * bounded_emission;
}
