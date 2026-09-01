shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec4 eye_color : source_color = vec4(0.003, 0.002, 0.006, 1.0);
uniform float studio_strength : hint_range(0.0, 1.0) = 0.55;
uniform float studio_budget : hint_range(0.0, 1.0) = 0.42;

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
	ROUGHNESS = 0.055;
	METALLIC = 0.0;
	SPECULAR = 1.0;
	EMISSION = studio;
}
