shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The runner down the library wing's aisle (scripts/library_wing.gd), woven rather than plain red: a
// crimson field under a lattice of lozenges, gold guard lines, an ochre border with a running pattern,
// and a medallion under each chandelier (every `repeat` metres from `z0`). The pile's grain tilts the
// normal; the middle is worn paler, where it is walked. In the mesh's frame (the wing's): x across,
// z along. Colours are linear under both renderers (no source_color).

uniform vec3 field = vec3(0.3, 0.035, 0.03);
uniform vec3 field_dark = vec3(0.17, 0.018, 0.02);
uniform vec3 gold = vec3(0.5, 0.33, 0.1);
uniform vec3 blue = vec3(0.05, 0.09, 0.22);
uniform float half_width = 1.2;
uniform float border = 0.3;
uniform float z0 = 4.6;
uniform float repeat = 4.8;
uniform float lattice = 0.55;

varying vec3 v_pos;
varying vec3 v_n;

void vertex() {
	v_pos = VERTEX;
	v_n = NORMAL;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), f.x), mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), f.x), f.y);
}

// A line `w` wide at x = 0, blurred to its average once under a pixel.
float line(float x, float w) {
	float fw = max(fwidth(x), 1e-5);
	return (1.0 - smoothstep(w * 0.5 - fw * 0.5, w * 0.5 + fw * 0.5, abs(x))) * min(1.0, w / fw);
}

void fragment() {
	float x = v_pos.x;
	float z = v_pos.z;
	float ax = abs(x);
	vec3 c = field;
	// The lattice of lozenges, alternate ones darker, outlined in gold.
	vec2 p = vec2(x + z, x - z) / lattice * 0.70710678;
	vec2 cell = floor(p);
	vec2 f = fract(p) - 0.5;
	c = mix(c, field_dark, step(0.5, mod(cell.x + cell.y, 2.0)) * 0.6);
	c = mix(c, gold, max(line(0.5 - abs(f.x), 0.018), line(0.5 - abs(f.y), 0.018)) * 0.7);
	// A small gold quatrefoil in each lozenge's middle.
	float qf = length(f) - 0.09 - 0.03 * cos(4.0 * atan(f.y, f.x));
	c = mix(c, gold * 0.9, line(qf, 0.025));
	// The medallion under each chandelier: a blue ground, a gold ring and petals.
	float m = mod(z - z0, repeat) - repeat * 0.5;
	vec2 md = vec2(x / 0.72, m / 1.05);
	float r = length(md);
	float petals = 0.55 + 0.12 * cos(8.0 * atan(md.y, md.x));
	if (r < 1.0) {
		// Ivory-gold petals on the red, a blue heart, a blue band inside the gold ring.
		c = mix(gold * 1.2 + vec3(0.04, 0.03, 0.02), field, smoothstep(petals - 0.02, petals + 0.02, r));
		c = mix(c, blue, 1.0 - smoothstep(0.27, 0.29, r));
		c = mix(c, blue, smoothstep(0.84, 0.86, r));
		c = mix(c, gold * 0.7, line(r - petals, 0.035));
		c = mix(c, gold, line(r - 0.93, 0.05));
		c = mix(c, gold * 1.1, 1.0 - smoothstep(0.1, 0.13, r));
	}
	// The border: guard lines, an ochre band with a running pattern of dark squares turned on edge.
	float b0 = half_width - border;
	if (ax > b0) {
		float t = (ax - b0) / border;  // 0 inside edge to 1 outside
		c = mix(gold * 0.55, field_dark, step(0.82, t));
		vec2 rp = vec2(z / (border * 0.6), (t - 0.42) / 0.3);
		vec2 rf = fract(rp) - 0.5;
		float lozenge = abs(rf.x) + abs(rp.y);
		c = mix(c, field_dark * 1.2, (1.0 - step(0.42, lozenge)) * step(0.0, 0.8 - t));
		c = mix(c, gold, line(t - 0.06, 0.06) + line(t - 0.78, 0.04));
	}
	c = mix(c, gold, line(ax - b0, 0.02));
	// The pile: its grain, and the middle worn paler where it is walked.
	float pile = vnoise(vec2(x, z) * 180.0) * 0.6 + vnoise(vec2(x, z) * 37.0) * 0.4;
	c *= 0.88 + 0.24 * pile;
	float wear = (1.0 - smoothstep(0.2, 0.8, ax)) * (0.6 + 0.4 * vnoise(vec2(x * 2.0, z * 0.7)));
	c = mix(c, c * vec3(1.25, 1.15, 1.12) + vec3(0.01), wear * 0.35);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// Compatibility shades in sRGB, with no conversion at the end (as the hall's materials there):
	// the linear colours given as they would show.
	c = pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
	float mpp = length(fwidth(v_pos.xz));
	float k = 1.0 - smoothstep(0.002, 0.008, mpp);
	vec2 gp = vec2(dFdx(pile), dFdy(pile));
	NORMAL = normalize(NORMAL - vec3(gp.x, -gp.y, 0.0) * 2.0 * k);
}
