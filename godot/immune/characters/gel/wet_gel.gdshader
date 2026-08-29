shader_type spatial;
// Ambient is disabled because it is the one light path that bypasses the body's
// ceiling. It arrives as a flat multiple of ALBEDO added outside light(), so it put an
// unbounded floor under every channel -- including the one a gel needs at essentially
// zero. That floor is what held blue flat at 0.08 through the deepest core where the
// reference sits at 0.004, and a flat blue floor is precisely what stops saturation
// rising with depth. With it off, every photon this material emits is inside the
// ceiling, and the shaded side is carried by light_wrap into deep_color instead.
render_mode depth_draw_opaque, cull_back, ambient_light_disabled;

// Translucent wet-gel body for the six IMMUNE base cells.
//
// The look is built from four stacked cues, because a closed opaque blob has no
// real thickness to sample:
//   1. wrapped diffuse with a saturated interior tint  -> soft gel terminator
//   2. a back-light transmission lobe gated by thinness -> limbs/skirt glow through
//   3. fresnel emission                                 -> bright silhouette rim + bloom
//   4. two specular lobes (broad + tight coat)          -> small sharp wet highlights
//
// Thinness is estimated from the view fresnel: on a blob the places where the
// surface turns away from the camera are also the places light has the least
// material to cross (limb tips, skirt edges, the flare of the bell).
//
// Dark features (almond eyes, pore hole, mouth line) come from the baked
// basecolor texture, not from geometry. Everything gel-flavoured is multiplied by
// (1 - ink) so those features stay flat, dark and glossy.
//
// Cellular dimples are procedural: object-space triplanar Voronoi driving a
// derivative-based normal perturbation. No extra triangles, no tangent or UV
// dependency, so a replacement mesh needs no re-authoring.

group_uniforms colour;
// Body albedo. Derived from ImmuneFamilyLook.JELLY with its saturation pushed up:
// a gel of this colour absorbs its complement almost completely, so the channel
// opposite the family hue has to sit near zero. Leaving the palette's own blue in
// (T is 0.16) is what made the old material read as pale clay -- every light in the
// scene lifted that channel and greyed the body.
uniform vec4 body_color : source_color = vec4(1.0, 0.42, 0.01, 1.0);
// Saturated interior the light picks up crossing a thick part. Deeper/redder than jelly.
uniform vec4 deep_color : source_color = vec4(0.90, 0.20, 0.02, 1.0);
// What a thin part glows: less material absorbed the light, so hotter and yellower.
uniform vec4 transmit_color : source_color = vec4(1.0, 0.72, 0.33, 1.0);
// Silhouette rim. Slightly hotter and lighter than jelly.
uniform vec4 rim_color : source_color = vec4(1.0, 0.66, 0.28, 1.0);
uniform float albedo_gain : hint_range(0.0, 2.0) = 1.0;
// Spectral absorption, applied to the interior light paths only (the wrapped
// bleed and the transmission lobe). Light that crossed the body comes back in the
// family hue whatever colour went in, so a cool fill or a cool rim cannot wash the
// gel out from inside. Surface specular keeps the lamp's own colour, which is why
// the only near-white pixels end up being genuine highlights.
uniform float absorption : hint_range(0.0, 1.0) = 0.85;

group_uniforms surface;
uniform float body_roughness : hint_range(0.0, 1.0) = 0.16;
// How much of the family hue the broad lobe carries. The broad sheen on a gel is
// near-surface scatter, so it is absorbed and comes back coloured; only the tight
// coat lobe is a true surface reflection and stays the lamp's own colour. Keeping
// these separate is what lets the body have a big bright sheen without going white.
uniform float spec_tint : hint_range(0.0, 1.0) = 0.7;
uniform float coat_roughness : hint_range(0.005, 0.4) = 0.045;
uniform float coat_strength : hint_range(0.0, 6.0) = 2.2;
uniform float spec_energy : hint_range(0.0, 12.0) = 3.4;
uniform float spec_f0 : hint_range(0.0, 0.3) = 0.06;
// Godot's ambient/reflection specular. Left at 0 because with no sky or probe it
// is a flat unfiltered wash that greys the gel; the analytic lobes below carry
// all the reflection this material needs.
uniform float env_specular : hint_range(0.0, 1.0) = 0.0;

group_uniforms gel;
// Diffuse wrap: how far light creeps past the terminator.
uniform float light_wrap : hint_range(0.0, 0.95) = 0.60;
// How strongly the wrapped band takes on deep_color instead of albedo.
uniform float sss_amount : hint_range(0.0, 4.0) = 1.35;
uniform float transmit_power : hint_range(0.5, 24.0) = 2.6;
uniform float transmit_strength : hint_range(0.0, 8.0) = 2.6;
uniform float transmit_distort : hint_range(0.0, 1.0) = 0.30;

group_uniforms thinness;
// View fresnel share of the thinness estimate. Higher power hugs the silhouette.
uniform float thin_power : hint_range(0.25, 8.0) = 2.6;
uniform float thin_fresnel : hint_range(0.0, 2.0) = 0.75;
uniform float thin_floor : hint_range(0.0, 1.0) = 0.0;
// Curvature share, measured as 1/radius in world units: a limb of radius 0.05
// reads around 20 across its whole surface while a 0.4 head reads about 2.5. This
// is what fills a limb with glow rather than just outlining it -- fresnel alone
// only ever lights the silhouette, and on a closed blob that is not enough to say
// "light is coming through here". Resolution-independent because the normal
// derivative is divided by the world-space pixel footprint.
uniform float curv_low : hint_range(0.0, 40.0) = 5.0;
uniform float curv_high : hint_range(0.0, 80.0) = 22.0;
uniform float thin_curvature : hint_range(0.0, 2.0) = 0.6;

group_uniforms glow;
uniform float thin_glow : hint_range(0.0, 4.0) = 0.9;
uniform float core_glow : hint_range(0.0, 2.0) = 0.05;
uniform float rim_power : hint_range(0.5, 16.0) = 6.5;
uniform float rim_energy : hint_range(0.0, 8.0) = 1.0;
// Beer-Lambert extinction density for the interior paths. Thickness REMOVES light
// per channel rather than thinness ADDING it, which is the only way both channels
// move across a limb: a thick shoulder absorbs green and blue and reads deep
// saturated, a thin edge absorbs nothing and reads hot and pale. The additive
// version this replaced could only ever brighten, so on a warm hue the dominant
// channel pinned at 1.0 and the thick-to-thin gradient died with it.
uniform float extinction_density : hint_range(0.0, 8.0) = 3.0;
// Neutral extinction, applied to every channel including the family's own. Keep it
// SMALL. It is tempting to lean on this because a large value stops the dominant
// channel flooding the body -- but that is the wrong cure for the right disease. A
// neutral term is a darkener: at 0.35 of density 3.0 it costs the dominant channel
// exp(-1.05) at full thickness, flattening the exposure it was meant to modulate,
// and the body then measures both darker and less saturated, which is exactly how an
// opaque surface measures. Flooding is bounded by `body_budget` below instead, and
// this is left as the small sag real gel has (the reference's own dominant channel
// only falls 0.98 -> 0.93 from shell to deepest core).
uniform float extinction_base : hint_range(0.0, 4.0) = 0.03;
// Spectral share of the extinction: how much harder the complement is absorbed than
// the family's own channel. This now carries essentially the whole gradient, which is
// how the reference works -- its thickness ramp lives entirely in the non-dominant
// channels while the dominant one holds a near-flat plateau.
uniform float extinction_spread : hint_range(0.0, 2.0) = 1.0;
// Curve on the spectral weight, so the weakest channel is absorbed disproportionately
// faster than the middle one instead of merely proportionally. Measured on the
// reference, green halves through the body while blue falls by a factor of 26; a
// linear weight cannot open that wide a gap between two channels of the same tint.
uniform float extinction_shape : hint_range(0.25, 4.0) = 1.35;
// Hue-preserving ceilings on the interior and rim radiance. Scaling a colour by
// budget/peak keeps the channel ratios exactly, so limiting here costs saturation
// nothing; letting the hardware clip each channel independently is what turns a
// gradient into a flat plateau and drags the hue toward white.
uniform float interior_budget : hint_range(0.0, 4.0) = 0.85;
uniform float rim_budget : hint_range(0.0, 4.0) = 0.55;
// The same ceiling, on the lit body itself. This is the counterpart that makes a hot
// albedo drive safe: the body can be driven hard enough to sit just under clipping
// across the whole shell, and wherever the drive would overshoot this scales the
// colour down as a whole instead of letting the hardware clip one channel at a time.
// Hue and the green/blue thickness gradient survive the limit; per-channel clipping
// would destroy both. Without this, holding the dominant channel high is only
// achievable by dimming everything, and with it the two are independent.
uniform float body_budget : hint_range(0.0, 4.0) = 1.0;
// Width of the soft knee under every budget above, as a fraction of that budget. 0 is
// a hard clamp. Wider trades a little peak brightness for a plateau that rolls off
// instead of sitting on one value.
uniform float peak_knee : hint_range(0.0, 1.0) = 0.35;
// How much thickness darkens the body albedo. This, not the additive glow, is what
// carries the thick-to-thin gradient. Under a warm key a warm albedo already sits
// near the top of the range, so there is no headroom to ADD interior light on a
// thick part -- but there is plenty of room to take light away, and absorption is
// subtractive in reality anyway. Multiplicative, so it can only ever deepen the
// colour and can never be the thing that clips.
uniform float body_absorb : hint_range(0.0, 1.0) = 0.55;
// How much of the family hue the transmitted light carries on top of what absorption
// already did to it. Low on purpose. Light that crossed a thin edge has had almost
// nothing taken out of it, so it should emerge close to the lamp's own colour --
// yellow-white, blue intact. Multiplying transmission by a saturated transmit_color
// instead caps its blue at the palette's blue at every thickness, so no edge can ever
// desaturate and a thin limb reads as brighter paint rather than as light coming
// through. The spectral falloff from white edge to deep core is the cue.
uniform float transmit_tint : hint_range(0.0, 1.0) = 0.25;
// Concentrates interior energy at the very thin end. The hot ribbon in the reference
// is a narrow band right at the silhouette, so the energy has to be biased there
// rather than spread over the whole body -- that is what lets the ribbon run hot
// underneath the ceiling without the broad flood that caused the plateau.
uniform float thin_bias : hint_range(1.0, 8.0) = 3.0;
// Falloff of the hot band, independent of thin_power. These are two different
// questions that were sharing one control: thin_power sets how deep absorption
// darkens the body, and this sets how far in from the silhouette light still escapes.
// Widening the band through thin_power also un-darkened the core, so the clip
// fraction rose every time the ribbon was widened. Separating them lets the glow
// reach across the whole outer shell -- where the reference is hot for its full 5% --
// while absorption keeps the deep core exactly as deep as it measured correct.
uniform float glow_power : hint_range(0.2, 8.0) = 1.5;
// Overdrive on the hot band, clamped. Above 1.0 the band reaches full strength some
// way in from the silhouette and stays there, so the hot zone is a flat-topped
// plateau across the outer shell rather than a spike at the outline. That is the
// shape the reference actually has -- it is equally hot right across its outer 5%,
// not brightest at the very edge -- and clamping means widening the zone no longer
// also raises its peak, which is what made every earlier attempt overshoot.
uniform float glow_gain : hint_range(1.0, 8.0) = 1.0;
// Gates the hot band by the baked map's own occlusion. Curvature, even signed, cannot
// tell a limb tip from the raised lip around an eye socket: both bulge, so both were
// snapped to full glow by the plateau and every facial feature picked up a pale chalky
// halo the reference does not have. The bake already darkens exactly those crevices,
// and baked occlusion is a direct statement about where light does not get back out,
// so it is the right cue -- and it costs nothing, since the texture is already sampled.
// Read from a coarse mip rather than the sharp map: a blurred fetch is dark only in
// the neighbourhood of a feature, so it dilates the eyes, pore and mouth into a small
// keep-out zone for the glow. Gating on the sharp map's absolute level instead
// suppressed the glow everywhere, because the body's own baked value is not much
// brighter than the crevices are.
uniform float glow_ao_strength : hint_range(0.0, 1.0) = 0.0;
uniform float glow_ao_low : hint_range(0.0, 1.0) = 0.45;
uniform float glow_ao_high : hint_range(0.0, 1.0) = 0.72;
uniform float glow_ao_lod : hint_range(0.0, 8.0) = 3.0;

group_uniforms dimples;
// Cells per object-space unit.
uniform float dimple_scale : hint_range(2.0, 200.0) = 34.0;
uniform float dimple_depth : hint_range(0.0, 3.0) = 0.035;
// Width of the crease between cells. Small = tight hexy creases.
uniform float dimple_crease : hint_range(0.02, 1.0) = 0.34;
// How much each cell is rounded into a dome versus left flat with a creased wall. 0 is
// the pure F2-F1 crease field, whose gradient lives only on the walls; 1 puts the
// curvature inside the cell so each one catches its own highlight. See cell_field.
uniform float dimple_round : hint_range(0.0, 1.0) = 0.85;
uniform float dimple_triplanar_sharpness : hint_range(1.0, 16.0) = 6.0;

group_uniforms bubbles;
// Compatibility-safe Jelly V2 air pockets. Unlike the legacy triplanar field,
// this samples an actual sparse 3D sphere distribution in object space. Any
// surface intersecting a sphere receives a round cap and shell from every view,
// with no UVs, tangent basis, texture fetches, or mesh modifications required.
uniform bool bubble_enabled = false;
uniform float bubble_scale : hint_range(1.0, 24.0) = 5.0;
uniform float bubble_density : hint_range(0.0, 1.0) = 0.5;
uniform float bubble_radius_min : hint_range(0.05, 0.45) = 0.17;
uniform float bubble_radius_max : hint_range(0.05, 0.48) = 0.32;
// Kept at or below 0.20. With radius <= 0.48 that bound guarantees the eight
// nearest cell centres contain every sphere that can touch the current point.
uniform float bubble_jitter : hint_range(0.0, 0.20) = 0.16;
uniform float bubble_softness : hint_range(0.01, 0.30) = 0.08;
uniform float bubble_depth : hint_range(0.0, 0.12) = 0.0;
// Air absorbs less than gel. This shortens the fake optical path at a cap so the
// centre becomes subtly brighter and less saturated without alpha sorting.
uniform float bubble_thinness : hint_range(0.0, 0.8) = 0.0;
uniform float bubble_shell_shadow : hint_range(0.0, 0.6) = 0.0;
uniform float bubble_emission : hint_range(0.0, 0.3) = 0.0;
// A real air pocket catches a pale ring before its centre glows. Keeping this
// separate from cap emission avoids the dark skin-pore read of a shadowed shell.
uniform float bubble_shell_emission : hint_range(0.0, 0.5) = 0.0;
uniform float bubble_seed : hint_range(0.0, 100.0) = 0.0;

group_uniforms microbubbles;
// Optional second frequency for the dense champagne-sized inclusions visible in
// the locked jelly references. It is off by default so existing families and GPU
// cost remain unchanged until a profile explicitly opts in.
uniform bool microbubble_enabled = false;
uniform float microbubble_scale : hint_range(8.0, 64.0) = 30.0;
uniform float microbubble_density : hint_range(0.0, 1.0) = 0.65;
uniform float microbubble_radius_min : hint_range(0.04, 0.35) = 0.10;
uniform float microbubble_radius_max : hint_range(0.04, 0.40) = 0.24;
uniform float microbubble_jitter : hint_range(0.0, 0.20) = 0.16;
uniform float microbubble_softness : hint_range(0.01, 0.30) = 0.10;
uniform float microbubble_depth : hint_range(0.0, 0.08) = 0.0;
uniform float microbubble_thinness : hint_range(0.0, 0.6) = 0.0;
uniform float microbubble_shell_shadow : hint_range(0.0, 0.4) = 0.0;
uniform float microbubble_emission : hint_range(0.0, 0.4) = 0.0;
uniform float microbubble_shell_emission : hint_range(0.0, 0.5) = 0.0;
uniform float microbubble_seed : hint_range(0.0, 100.0) = 0.0;

group_uniforms inclusions;
// Fine irregular inclusions fill the visual gap between the two explicit bubble
// radii. They are emission-only: no high-frequency normal means no sparkle crawl
// when the character shrinks to gameplay size.
uniform bool inclusion_enabled = false;
uniform float inclusion_scale : hint_range(16.0, 240.0) = 140.0;
uniform float inclusion_threshold : hint_range(0.3, 0.95) = 0.70;
uniform float inclusion_softness : hint_range(0.01, 0.25) = 0.06;
uniform float inclusion_emission : hint_range(0.0, 0.5) = 0.0;
uniform float inclusion_seed : hint_range(0.0, 100.0) = 0.0;

group_uniforms features;
// The mesh's own baked basecolor. Only its darkness is used, never its hue.
uniform sampler2D feature_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_feature_tex = true;
// Gamma-space luminance window that separates ink from body. Eyes sit near 0.05,
// the baked body sits above 0.4, so this window has plenty of margin.
uniform float ink_low : hint_range(0.0, 1.0) = 0.10;
uniform float ink_high : hint_range(0.0, 1.0) = 0.28;
uniform vec4 ink_color : source_color = vec4(0.014, 0.013, 0.018, 1.0);
uniform float ink_roughness : hint_range(0.0, 1.0) = 0.05;
// Optional trace of the baked texture's value variation on the body.
uniform float tex_tint_mix : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_obj_pos;
varying vec3 v_obj_normal;
// fragment -> light handoff
varying float v_ink;
varying vec3 v_filter;
// One path length, one throughput. The glow envelope stays separate as a scalar.
varying vec3 v_through;
varying float v_hot;


// Absorption filter for anything that travelled inside the body. Max-normalised
// so it shifts hue without changing exposure of the dominant channel.
vec3 absorb_filter() {
	vec3 c = body_color.rgb;
	vec3 tint = c / max(max(c.r, c.g), max(c.b, 1e-4));
	return mix(vec3(1.0), tint, absorption);
}


// Scale a colour down only if its brightest channel exceeds `budget`, keeping the
// channel ratios intact. This is the whole defence against a clipped plateau: a
// per-channel clamp would flatten the dominant channel and shift the hue, while
// this leaves hue and the relative gradient untouched and is a no-op wherever the
// colour was already in range. Palette-agnostic -- it reads the peak it is given.
vec3 peak_limit(vec3 c, float budget) {
	float peak = max(max(c.r, c.g), c.b);
	float k = budget * clamp(peak_knee, 0.001, 1.0);
	float knee = budget - k;
	if (peak <= knee) {
		return c;
	}
	// Soft knee rather than a hard clamp, approaching `budget` asymptotically. A hard
	// clamp mapped every overshooting pixel onto exactly one output value, which made
	// the plateau a knife edge: one code value of mis-calibration moved the whole shell
	// from "sits at 251" to "sits at 255", and the two are 43 points apart on the metric
	// that matters. The reference's own dominant channel is not a single value either --
	// it rolls 247 to 251 across the shell -- so a gentle roll-off is both more robust
	// and closer to the thing being matched. Continuous and slope-1 at the knee, so it
	// is still a no-op well below budget.
	// 1-exp(-t) rather than the cheaper t/(1+t): both are smooth at the knee and
	// asymptote to `budget`, but the rational form approaches it far more slowly and
	// measurably fails to hold the dominant channel up at 250-253 across the core.
	// Cost was measured either way and the difference was inside run-to-run noise.
	float limited = knee + k * (1.0 - exp(-(peak - knee) / k));
	return c * (limited / max(peak, 1e-5));
}


// Per-channel Beer-Lambert throughput for light that crossed `thickness` of gel.
// Extinction is derived from the family's own transmit hue, so the channel the
// family owns passes freely and its complement is absorbed first. That derivation
// is why this works for all six families without a per-hue constant.
vec3 gel_throughput(float thickness) {
	vec3 c = transmit_color.rgb;
	vec3 norm = c / max(max(c.r, c.g), max(c.b, 1e-4));
	// `norm` is exactly 1.0 on the channel the family owns, so the spectral term is
	// 0.0 there and the dominant channel is left with `extinction_base` alone. That
	// is deliberate: the gradient belongs in the channels the gel actually absorbs.
	vec3 spectral = pow(max(1.0 - norm, vec3(0.0)), vec3(extinction_shape));
	vec3 sigma = (extinction_base + spectral * extinction_spread) * extinction_density;
	return exp(-sigma * clamp(thickness, 0.0, 1.0));
}


// sin-free hash: the Voronoi below runs it nine times per plane, and three
// trig calls per sample is real cost at ten characters on screen.
vec2 cell_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	q += dot(q, q.yzx + 33.33);
	return fract((q.xx + q.yz) * q.zy);
}


// Dave Hoskins-style, sin-free 3D hash. One call supplies position jitter,
// radius variation, and a deterministic density decision for a lattice cell.
vec3 bubble_hash3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}


// Smooth object-space value noise for sub-bubble inclusions. Eight hashes are
// enough because this layer never drives normals or silhouettes.
float inclusion_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = bubble_hash3(cell + vec3(0.0, 0.0, 0.0)).x;
	float n100 = bubble_hash3(cell + vec3(1.0, 0.0, 0.0)).x;
	float n010 = bubble_hash3(cell + vec3(0.0, 1.0, 0.0)).x;
	float n110 = bubble_hash3(cell + vec3(1.0, 1.0, 0.0)).x;
	float n001 = bubble_hash3(cell + vec3(0.0, 0.0, 1.0)).x;
	float n101 = bubble_hash3(cell + vec3(1.0, 0.0, 1.0)).x;
	float n011 = bubble_hash3(cell + vec3(0.0, 1.0, 1.0)).x;
	float n111 = bubble_hash3(cell + vec3(1.0, 1.0, 1.0)).x;
	float n00 = mix(n000, n100, f.x);
	float n10 = mix(n010, n110, f.x);
	float n01 = mix(n001, n101, f.x);
	float n11 = mix(n011, n111, f.x);
	return mix(mix(n00, n10, f.y), mix(n01, n11, f.y), f.z);
}


// Returns (spherical cap, shell). Sampling the eight centres around p is enough
// because the profile bounds jitter and radius so a more distant cell cannot
// intersect this point. This is substantially cheaper than 27-sample Worley and
// makes the expensive path opt-in per family.
vec2 bubble_volume_at(
	vec3 p,
	float density,
	float radius_minimum,
	float radius_maximum,
	float jitter,
	float softness,
	float seed
) {
	vec3 base = floor(p - vec3(0.5));
	float nearest = 1e4;
	for (int z = 0; z <= 1; z++) {
		for (int y = 0; y <= 1; y++) {
			for (int x = 0; x <= 1; x++) {
				vec3 cell = base + vec3(float(x), float(y), float(z));
				vec3 rnd = bubble_hash3(cell + vec3(
					seed,
					seed * 1.37 + 7.0,
					seed * 2.11 + 13.0));
				float presence = fract(dot(rnd, vec3(0.73, 1.37, 2.17)));
				if (presence <= density) {
					vec3 centre = cell + vec3(0.5) + (rnd - vec3(0.5)) * (2.0 * jitter);
					float radius = mix(
						min(radius_minimum, radius_maximum),
						max(radius_minimum, radius_maximum),
						rnd.y);
					nearest = min(nearest, length(p - centre) / max(radius, 0.001));
				}
			}
		}
	}
	float soft = max(softness, 0.001);
	float inside = 1.0 - smoothstep(1.0 - soft, 1.0 + soft, nearest);
	float cap = sqrt(max(1.0 - min(nearest * nearest, 1.0), 0.0)) * inside;
	float shell = 1.0 - smoothstep(soft, soft * 3.0, abs(nearest - 1.0));
	return vec2(cap, shell);
}


// F2 - F1 Voronoi: ~0 on cell walls, larger inside cells. Gives organic
// membrane creases rather than a regular bump grid.
//
// F2-F1 alone is the wrong SHAPE for this cue, though, and the difference is visible
// rather than subtle. That field is flat across a cell interior and drops only at the
// wall, so all of its gradient -- and therefore every highlight the bump produces --
// sits on the cell BORDERS. Under a sharp coat that renders as a bright cracked net,
// not as dimpling. What the reference shows is each cell catching its OWN highlight,
// which needs curvature spread across the cell interior. F1 supplies exactly that: it
// is the distance to the nearest cell centre, so it rounds each cell into a shallow
// dome with the highlight landing mid-cell, which is also what makes each cell count
// as one distinct small highlight rather than contributing to a continuous ridge.
// Kept as a blend so `dimple_round` 0 reproduces the pure-crease field exactly.
float cell_field(vec2 p) {
	vec2 ip = floor(p);
	vec2 fp = p - ip;
	float f1 = 8.0;
	float f2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			float d = length(g + cell_hash(ip + g) - fp);
			if (d < f1) {
				f2 = f1;
				f1 = d;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	// 0.75 is a little over the half-diagonal of a unit cell, so the dome spans the
	// whole interior instead of bottoming out before it reaches the wall.
	float dome = 1.0 - smoothstep(0.0, 0.75, f1);
	float wall = smoothstep(0.0, dimple_crease, f2 - f1);
	return wall * mix(1.0, dome, dimple_round);
}


// Seamless over any UV layout: blend three axis-aligned Voronoi slices by normal.
// The mesh's UVs are a fragmented atlas, so a UV-space pattern would put a hard
// crease along every island border once the height goes through a derivative.
// Most pixels have one dominant plane, so skipping negligible weights pays for the
// branch divergence at the blend seams.
float cell_triplanar(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(dimple_triplanar_sharpness));
	w /= max(w.x + w.y + w.z, 1e-4);
	float h = 0.0;
	if (w.x > 0.02) {
		h += cell_field(p.zy) * w.x;
	}
	if (w.y > 0.02) {
		h += cell_field(p.xz) * w.y;
	}
	if (w.z > 0.02) {
		h += cell_field(p.xy) * w.z;
	}
	return h;
}


// Mikkelsen surface-gradient bump: perturbs a normal from a scalar height using
// screen-space derivatives, so it needs no tangent or binormal from the mesh.
vec3 bump_normal(vec3 n, vec3 view_pos, float height, float strength) {
	vec3 dpx = dFdx(view_pos);
	vec3 dpy = dFdy(view_pos);
	float dhx = dFdx(height);
	float dhy = dFdy(height);
	vec3 r1 = cross(dpy, n);
	vec3 r2 = cross(n, dpx);
	float det = dot(dpx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * n - strength * grad);
}


float d_ggx(float ndh, float rough) {
	float a = rough * rough;
	float a2 = a * a;
	float d = ndh * ndh * (a2 - 1.0) + 1.0;
	return a2 / max(PI * d * d, 1e-6);
}


float spec_lobe(vec3 n, vec3 v, vec3 l, float rough) {
	float ndl = max(dot(n, l), 0.0);
	if (ndl <= 0.0) {
		return 0.0;
	}
	vec3 h = normalize(v + l);
	float ndv = max(dot(n, v), 1e-4);
	float ndh = max(dot(n, h), 0.0);
	float a = rough * rough;
	float k = a * 0.5;
	float gv = ndv / (ndv * (1.0 - k) + k);
	float gl = ndl / (ndl * (1.0 - k) + k);
	float vis = gv * gl / max(4.0 * ndv * ndl, 1e-4);
	return d_ggx(ndh, rough) * vis * ndl;
}


void vertex() {
	v_obj_pos = VERTEX;
	v_obj_normal = NORMAL;
}


void fragment() {
	// --- dark features from the baked texture -----------------------------
	vec4 baked = vec4(1.0);
	if (use_feature_tex) {
		baked = texture(feature_tex, UV);
	}
	// Approximate gamma space so the threshold window reads like the JPG's own
	// pixel values instead of tiny linear numbers.
	float lum = dot(baked.rgb, vec3(0.2126, 0.7152, 0.0722));
	float lum_g = sqrt(max(lum, 0.0));
	float ink = 1.0 - smoothstep(ink_low, max(ink_high, ink_low + 0.001), lum_g);
	float gel_mask = 1.0 - ink;

	// --- thinness, measured before dimples so creases do not read as limbs ---
	vec3 base_n = normalize(NORMAL);
	float px = max(length(dFdx(VERTEX)), 1e-5);
	float py = max(length(dFdy(VERTEX)), 1e-5);
	// Signed, not magnitude. Light escapes through thin CONVEX protrusions -- a limb
	// tip, the edge of the skirt -- but a concave crease is a fold of thick gel and has
	// to stay dark. Curvature magnitude cannot tell the two apart, so it lit the eye
	// sockets, the pore and the mouth line as brightly as the limbs and put a pale
	// chalky halo around every one of them. The divergence of the surface normal
	// carries the sign: positive where the surface bulges, negative where it folds in.
	// For a sphere of radius R it lands near 2/R, so the thresholds are curvature radii.
	float conv = dot(dFdx(base_n), dFdx(VERTEX)) / (px * px)
		+ dot(dFdy(base_n), dFdy(VERTEX)) / (py * py);
	float thin_c = smoothstep(curv_low, max(curv_high, curv_low + 0.01), conv);

	// --- cellular dimples + volumetric round bubbles ----------------------
	vec3 n = base_n;
	if (dimple_depth > 0.001) {
		float height = cell_triplanar(v_obj_pos * dimple_scale, normalize(v_obj_normal));
		float strength = dimple_depth * gel_mask / max(dimple_scale, 0.001);
		n = bump_normal(n, VERTEX, height, strength);
	}
	vec2 bubble = vec2(0.0);
	if (bubble_enabled && bubble_depth > 0.001 && bubble_density > 0.001) {
		bubble = bubble_volume_at(
			v_obj_pos * bubble_scale,
			bubble_density,
			bubble_radius_min,
			bubble_radius_max,
			bubble_jitter,
			bubble_softness,
			bubble_seed);
		// A very shallow positive lens lets the existing coat lobes draw a soft
		// crescent. A negative dent made the shell read as a dark skin pore.
		n = bump_normal(
			n,
			VERTEX,
			bubble.x,
			bubble_depth * gel_mask / max(bubble_scale, 0.001));
	}
	vec2 microbubble = vec2(0.0);
	if (microbubble_enabled && microbubble_depth > 0.001 && microbubble_density > 0.001) {
		microbubble = bubble_volume_at(
			v_obj_pos * microbubble_scale,
			microbubble_density,
			microbubble_radius_min,
			microbubble_radius_max,
			microbubble_jitter,
			microbubble_softness,
			microbubble_seed);
		n = bump_normal(
			n,
			VERTEX,
			microbubble.x,
			microbubble_depth * gel_mask / max(microbubble_scale, 0.001));
	}
	NORMAL = n;

	float fres = clamp(1.0 - abs(dot(n, VIEW)), 0.0, 1.0);
	float thin = clamp(
		thin_floor + thin_fresnel * pow(fres, thin_power) + thin_curvature * thin_c,
		0.0, 1.0);

	// --- surface -----------------------------------------------------------
	vec3 filt = absorb_filter();
	// Thickness deepens the albedo per channel: a thick shoulder has absorbed most
	// of its green and blue and reads deep saturated orange, a thin edge has
	// absorbed almost nothing and stays hot. Both channels therefore move across a
	// limb, which is the cue the flat clipped plateau used to destroy.
	float local_thickness = clamp(
		1.0 - thin
		- bubble.x * bubble_thinness
		- microbubble.x * microbubble_thinness,
		0.0,
		1.0);
	vec3 through = gel_throughput(local_thickness);
	vec3 body = body_color.rgb * albedo_gain * mix(vec3(1.0), through, body_absorb);
	body = mix(body, body * (0.35 + 1.3 * lum), tex_tint_mix);
	body *= 1.0 - (
		bubble.y * bubble_shell_shadow
		+ microbubble.y * microbubble_shell_shadow) * gel_mask;
	ALBEDO = mix(body, ink_color.rgb, ink);
	METALLIC = 0.0;
	float gel_roughness = mix(
		body_roughness,
		max(body_roughness * 0.72, 0.04),
		max(bubble.x, microbubble.x));
	ROUGHNESS = mix(gel_roughness, ink_roughness, ink);
	SPECULAR = env_specular;

	// --- inner glow + rim --------------------------------------------------
	// `through` IS the colour of the interior radiance, not just its strength. At a
	// thin edge nothing has been absorbed so it is near-white and carries its blue;
	// at a thick core green and blue have been eaten and it is deep orange. That
	// ramp is the spectral cue -- the edge desaturates toward yellow-white while the
	// core stays saturated, which is what reads as light travelling through gel.
	// transmit_tint adds back a controllable amount of family hue without putting a
	// floor back under the blue.
	// The band the interior light escapes through, on its own falloff so it can be
	// wide without lightening the core. Biased toward the thin end so the energy is
	// spent at the silhouette: a body-wide flood is what pinned the red channel into a
	// flat plateau, whereas the same energy concentrated in the outer shell buys an
	// incandescent edge and leaves the deep core untouched.
	float glow_band = clamp(
		thin_floor + thin_fresnel * pow(fres, glow_power) + thin_curvature * thin_c,
		0.0, 1.0);
	float open = 1.0;
	if (use_feature_tex && glow_ao_strength > 0.001) {
		vec3 near = textureLod(feature_tex, UV, glow_ao_lod).rgb;
		float near_g = sqrt(max(dot(near, vec3(0.2126, 0.7152, 0.0722)), 0.0));
		open = smoothstep(glow_ao_low, max(glow_ao_high, glow_ao_low + 0.001), near_g);
	}
	float hot = clamp(pow(glow_band, thin_bias) * glow_gain, 0.0, 1.0)
		* mix(1.0, open, glow_ao_strength);
	// Only the ambient interior term lives here now. The thin-band glow moved into
	// light(), inside the body's own ceiling, because it has to be summed with the lit
	// body before that ceiling is applied rather than stacked on top of it afterwards.
	vec3 inner = deep_color.rgb * core_glow * filt;
	// The rim stays separate and stays emissive: it is a silhouette effect on geometry
	// only a pixel or two wide, it is meant to bloom, and it is outside the eroded core
	// the body plateau is measured over. Limited on its own so a wide flooded band
	// cannot read as an emissive stripe painted on the outline.
	vec3 rim = rim_color.rgb * rim_energy * pow(fres, rim_power);
	float inclusion = 0.0;
	if (inclusion_enabled && inclusion_emission > 0.001) {
		float inoise = inclusion_noise(
			v_obj_pos * inclusion_scale
			+ vec3(inclusion_seed, inclusion_seed * 1.31, inclusion_seed * 2.17));
		// Widen the transition by the on-screen footprint. This turns the field into
		// stable sub-pixel sparkle density instead of a shimmering binary pattern.
		float aa = max(inclusion_softness, fwidth(inoise) * 0.85);
		inclusion = smoothstep(inclusion_threshold - aa, inclusion_threshold + aa, inoise);
	}
	vec3 bubble_glow = transmit_color.rgb * (
		bubble_emission * bubble.x
		+ bubble_shell_emission * bubble.y
		+ microbubble_emission * microbubble.x
		+ microbubble_shell_emission * microbubble.y
		+ inclusion_emission * inclusion) * (0.25 + 0.75 * fres);
	EMISSION = (
		peak_limit(inner + bubble_glow, interior_budget)
		+ peak_limit(rim, rim_budget)) * gel_mask;

	v_ink = ink;
	v_hot = hot;
	v_filter = filt;
	v_through = through;
}


void light() {
	float gel_mask = 1.0 - v_ink;
	vec3 lc = LIGHT_COLOR * ATTENUATION;
	// ALBEDO's own near-zero complement channel already keeps the direct diffuse
	// saturated. This filter is for the interior paths, which do not go through
	// ALBEDO and would otherwise carry the lamp's colour straight out of the body.
	vec3 filt = mix(vec3(1.0), v_filter, gel_mask);

	// Wrapped diffuse: the band past the terminator is handed to deep_color, so
	// the shaded side reads as light bouncing inside the gel, not as grey clay.
	float ndl = dot(NORMAL, LIGHT);
	float front = max(ndl, 0.0);
	float w = clamp(light_wrap, 0.0, 0.95);
	float wrapped = clamp((ndl + w) / (1.0 + w), 0.0, 1.0);
	float bleed = max(wrapped - front, 0.0);
	vec3 body_lit = (ALBEDO * front + deep_color.rgb * filt * bleed * sss_amount * gel_mask) * lc / PI;

	// Light that escaped the gel near a thin part. `v_through` carries its colour, so
	// a short path emerges near the lamp's own warm white and only a long path comes
	// out saturated -- that ramp is the spectral cue that reads as light travelling
	// through material rather than bouncing off it.
	vec3 xmit_col = v_through * mix(vec3(1.0), transmit_color.rgb, transmit_tint);
	vec3 glow = xmit_col * thin_glow * v_hot * gel_mask * lc / PI;

	// Transmission. Deliberately unshadowed: this is light that crossed the body,
	// so the fact that the exit point faces away from the lamp is the whole point.
	vec3 tl = normalize(LIGHT + NORMAL * transmit_distort);
	float t = pow(clamp(dot(VIEW, -tl), 0.0, 1.0), transmit_power);
	vec3 xmit = xmit_col * t * transmit_strength * v_hot * gel_mask * LIGHT_COLOR / PI;

	// ONE ceiling over the RUNNING TOTAL, and both of those words are load-bearing.
	//
	// Over the total, because ceilinged separately each term stayed in budget while
	// their sum stacked straight through the clip point -- so every attempt to make thin
	// parts hot pinned the dominant channel at 255, which is what forced the previous
	// round to solve it by dimming instead. Summing first inverts that: the dominant
	// channel is already at the ceiling and physically cannot rise, so adding near-white
	// interior light raises the peak, the limiter scales the colour back to the same
	// ceiling, and what changes is the RATIO -- green and blue come up while red holds
	// the plateau. That is the reference's behaviour exactly (red flat at 0.98 while
	// green swings 0.29-0.57), and it means the interior drive can be as hot as the look
	// needs without ever being able to clip the body.
	//
	// Running, because light() is called once per lamp. Bounding each call left the
	// three-lamp stage free to reach three times the budget wherever two lamps overlap,
	// which is what spread the plateau instead of concentrating it: 24% of the body sat
	// above the clip point while the median sat below it. Reading the accumulator and
	// bounding the sum makes the ceiling a property of the body, not of one lamp.
	DIFFUSE_LIGHT = peak_limit(DIFFUSE_LIGHT + body_lit + glow + xmit, body_budget);

	// Two lobes so highlights are small and sharp but still sit on a smooth body.
	// The coat is NOT masked by ink: the eyes are wet too, and their tight bright
	// highlight is what keeps them reading as glossy black rather than as holes.
	float broad = spec_lobe(NORMAL, VIEW, LIGHT, max(ROUGHNESS, 0.02));
	float coat = spec_lobe(NORMAL, VIEW, LIGHT, coat_roughness) * coat_strength;
	vec3 h = normalize(VIEW + LIGHT);
	float f = spec_f0 + (1.0 - spec_f0) * pow(1.0 - max(dot(h, VIEW), 0.0), 5.0);
	vec3 broad_tint = mix(vec3(1.0), filt, spec_tint);
	SPECULAR_LIGHT += (broad * broad_tint + vec3(coat)) * f * spec_energy * lc;
}
