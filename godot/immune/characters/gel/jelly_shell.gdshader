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
// Zero preserves the separately scaled authored M/N/A/D shell meshes. Imported
// T/B bodies use this shader as a next pass and opt into a small normal-space
// expansion, avoiding z-fighting without duplicating their mesh hierarchy.
uniform float shell_thickness : hint_range(0.0, 0.03) = 0.0;

void vertex() {
	VERTEX += NORMAL * shell_thickness;
}

void fragment() {
	float fresnel = clamp(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float edge = pow(fresnel, edge_power);
	ALBEDO = shell_color.rgb;
	ROUGHNESS = shell_roughness;
	METALLIC = 0.0;
	SPECULAR = 0.95;
	ALPHA = face_alpha + edge_alpha * edge;
	EMISSION = shell_color.rgb * rim_emission * edge;
}
