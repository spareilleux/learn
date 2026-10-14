shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;

// Trantor's Upperside round the observatory's roof (scripts/upperside.gd): the roof itself, the
// drum's outer face, and the domes that cover the world to the horizon. It lights itself: the
// galactic core (core_dir, as in assets/night_sky.gdshader) and a faint sky ambient, so no light
// is added to the scene and the hall stays as it was. Distance fades into the sky's haze below
// the horizon. Small details fade to their average before they are a few pixels wide: a grid of
// plates or of windows seen from far off would shimmer as the view moves.

uniform vec3 albedo : source_color = vec3(0.25, 0.27, 0.3);
uniform float sheen = 0.3;        // a metal's glint of the core
uniform float plates = 0.0;       // 1: a grid of plates on the surface
uniform float plate_size = 4.0;   // metres
uniform float windows = 0.0;      // the share of lit windows, 0 for none
uniform vec3 window_colour : source_color = vec3(1.0, 0.72, 0.42);
uniform float window_energy = 1.6;
uniform float moss = 0.0;         // patches of dark growth, as Upperside has in places
uniform vec3 core_dir = vec3(-0.468, 0.867, -0.170);
// Light, in linear values: as source_color, an ambient of 0.1 became 0.01 and faces turned from
// the core went black.
uniform vec3 core_light = vec3(0.9, 0.8, 0.66);
uniform float core_energy = 0.8;
uniform vec3 ambient = vec3(0.08, 0.085, 0.11);
// The sky just above the horizon (assets/night_sky.gdshader), where distance fades to.
uniform vec3 haze = vec3(0.012, 0.016, 0.03);
uniform float haze_distance = 1400.0;
// Dressed stone with a grain of metal (artpass/exterior/): an albedo whose alpha is the metal,
// and a normal map whose x and y run along the texture's u and v, one tile a UV unit.
uniform float ashlar = 0.0;
uniform sampler2D ashlar_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ashlar_normal : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float metal_sheen = 0.9;
// A round hole: x and z of its centre and its radius, 0 for none. The roof has one round the lift's
// shaft, where the lift's kiosk stands (scripts/lift.gd).
uniform vec3 hole = vec3(0.0);

varying vec3 v_wpos;
varying vec3 v_wnorm;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnorm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash13(vec3(i, 0.0));
	float b = hash13(vec3(i + vec2(1.0, 0.0), 0.0));
	float c = hash13(vec3(i + vec2(0.0, 1.0), 0.0));
	float d = hash13(vec3(i + vec2(1.0, 1.0), 0.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	if (hole.z > 0.0 && distance(v_wpos.xz, hole.xy) < hole.z) {
		discard;
	}
	vec3 n = normalize(v_wnorm);
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	vec3 to_eye = eye - v_wpos;
	float dist = length(to_eye);
	vec3 v = to_eye / max(dist, 1e-4);
	vec3 l = normalize(core_dir);
	// How many metres a pixel covers here.
	float m_px = max(length(dFdx(v_wpos)), length(dFdy(v_wpos))) + 1e-5;

	vec3 a = albedo;
	vec3 wc = window_colour;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There, the textures arrive in linear values but the uniform colours as they were set, in sRGB.
	a = pow(a, vec3(2.2));
	wc = pow(wc, vec3(2.2));
#endif
	float sh = sheen;
	if (ashlar > 0.0) {
		vec4 t = texture(ashlar_albedo, UV);
		a = t.rgb;
		sh = mix(sheen, metal_sheen, t.a);
		vec3 tn = texture(ashlar_normal, UV).rgb * 2.0 - 1.0;
		// The frame of u and v on the surface, from the derivatives (a cotangent frame): no tangents
		// in the mesh.
		vec3 dp1 = dFdx(v_wpos);
		vec3 dp2 = dFdy(v_wpos);
		vec2 duv1 = dFdx(UV);
		vec2 duv2 = dFdy(UV);
		vec3 dp2perp = cross(dp2, n);
		vec3 dp1perp = cross(n, dp1);
		vec3 tu = dp2perp * duv1.x + dp1perp * duv2.x;
		vec3 tv = dp2perp * duv1.y + dp1perp * duv2.y;
		float k = inversesqrt(max(max(dot(tu, tu), dot(tv, tv)), 1e-24));
		n = normalize(tu * k * tn.x + tv * k * tn.y + n * tn.z);
	}
	if (moss > 0.0) {
		float g = noise2(v_wpos.xz * 0.01) * 0.6 + noise2(v_wpos.xz * 0.05) * 0.4;
		a = mix(a, vec3(0.07, 0.1, 0.06), smoothstep(0.55, 0.75, g) * moss);
	}
	if (plates > 0.0 && ashlar <= 0.0) {
		// Seams between plates, darker, faded out once a plate is under eight pixels.
		vec3 q = v_wpos / plate_size;
		vec3 f = abs(fract(q) - 0.5);
		float w = 0.02 + m_px / plate_size;
		float seam = 1.0 - smoothstep(0.5 - w, 0.5, max(max(f.x, f.z), f.y * step(0.5, 1.0 - abs(n.y))));
		float show = 1.0 - smoothstep(plate_size / 16.0, plate_size / 8.0, m_px);
		a *= 1.0 - 0.35 * (1.0 - seam) * show * plates;
		a *= 0.9 + 0.2 * hash13(floor(q)) * show;
	}
	vec3 col = a * (ambient + core_light * core_energy * max(dot(n, l), 0.0));
	vec3 h = normalize(l + v);
	col += core_light * core_energy * sh * pow(max(dot(n, h), 0.0), 48.0);

	vec3 glow = vec3(0.0);
	if (windows > 0.0) {
		// Rows of windows on the sides of things, some lit; far off, their average glow.
		vec3 cell_size = vec3(3.0, 2.6, 3.0);
		vec3 cell = floor(v_wpos / cell_size);
		vec3 f = fract(v_wpos / cell_size);
		float side = 1.0 - smoothstep(0.55, 0.8, abs(n.y));
		float lit = step(1.0 - windows, hash13(cell));
		float pane = step(0.3, f.y) * step(f.y, 0.62) * step(0.3, max(f.x, f.z)) * step(min(f.x, f.z), 0.7);
		float near = 1.0 - smoothstep(0.35, 0.8, m_px);
		float detail = lit * pane;
		float average = windows * 0.12;
		glow = wc * window_energy * side * mix(average, detail, near);
	}
	float fade = exp(-dist / haze_distance);
	ALBEDO = mix(haze, col, fade) + glow * mix(0.25, 1.0, fade);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// Compatibility writes ALBEDO out as it is, read as sRGB: the light above is in linear values.
	ALBEDO = pow(max(ALBEDO, vec3(0.0)), vec3(1.0 / 2.2));
#endif
}
