shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Warm limestone inside the library wing (scripts/library_wing.gd): its piers, entablature, end walls
// and vestibule; and with `checker`, its floor of polished marble laid on the diagonal. The gardens'
// photographed stone (assets/garden_stone.png, divided by its mean colour and stored halved: 0.5 is no
// change, artpass/gardens/NOTES.md) under a tint, triplanar in the mesh's own frame (the wing's).
// Relief without a normal map: each ashlar block is bevelled at its joints and the stone's grain
// raised a little, by tilting the normal along the face's own axes (the merged meshes carry no
// tangents); blocks differ in tone, the stone is darker at its foot and sooted towards the vault.
// The tints are linear under both renderers: no source_color, which Compatibility would not convert.

uniform sampler2D detail_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float detail = 1.0;
uniform vec3 tint = vec3(0.42, 0.33, 0.22);
uniform float tile = 2.4;                // metres across the detail image
uniform vec2 ashlar = vec2(1.2, 0.6);   // a block's length and a course's height; 0: no joints
uniform float joint_depth = 0.45;
uniform float bevel = 0.025;             // m: the chamfer on each block's edges
uniform float grain_relief = 0.6;        // how far the stone's grain tilts the normal
uniform float variation = 0.22;          // blocks' tone, from one to the next
uniform float soot_from = 8.0;           // m: the vault's springing darkens above this
uniform float roughness = 0.78;
// The floor: squares `checker` metres wide (0: none) on the diagonal, in cream marble veined grey,
// with a small dark square (a cabochon) at each crossing; polished, unevenly.
uniform float checker = 0.0;
uniform vec3 tint2 = vec3(0.11, 0.09, 0.08);
uniform float cabochon = 0.26;           // the dark squares' width, in tiles
uniform float checker_roughness = 0.2;
uniform vec3 compat_fill = vec3(0.0);    // Compatibility only: the bounce SDFGI gives under Forward+

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

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		s += a * vnoise(p);
		p = p * 2.07 + vec2(5.2, 1.3);
		a *= 0.5;
	}
	return s;
}

// A block's height at s (in blocks): 1 on its face, falling to 0 over the bevel at its edges; `size`
// is a block's size in metres.
float block_height(vec2 s, vec2 size, float bw) {
	vec2 f = fract(s);
	vec2 e = min(f, 1.0 - f) * size;  // metres to the nearest edge, each way
	return smoothstep(0.0, bw, e.x) * smoothstep(0.0, bw, e.y);
}

void fragment() {
	vec3 n = normalize(v_n);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= w.x + w.y + w.z;
	vec3 q = v_pos / tile;
	vec3 d = texture(detail_tex, q.zy).rgb * w.x + texture(detail_tex, q.xz).rgb * w.y + texture(detail_tex, q.xy).rgb * w.z;
	vec3 grain = mix(vec3(1.0), d * 2.0, detail);
	vec3 a = tint * grain;
	float r = roughness;
	vec3 nl = n;  // the normal in the mesh's frame, tilted below
	// The face's own axes: u along it (the mesh's x or z, or x on a floor), v up it (or z on a floor).
	bool is_flat = abs(n.y) > 0.7;
	vec3 ua = is_flat ? vec3(1.0, 0.0, 0.0) : (abs(n.x) > abs(n.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0));
	vec3 va = is_flat ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
	vec2 uv = vec2(dot(v_pos, ua), dot(v_pos, va));
	// Metres a pixel spans: relief finer than that is faded out rather than left to shimmer.
	float mpp = length(fwidth(uv)) + 1e-5;
	if (checker > 0.0 && n.y > 0.7) {
		vec2 p = uv / checker;
		p = vec2(p.x + p.y, p.x - p.y) * 0.70710678;
		vec2 cell = floor(p);
		vec2 f = fract(p);
		// Cream marble, each slab a little different, veined along its own direction.
		float h = hash12(cell);
		vec3 cream = tint * (0.92 + 0.14 * h) * mix(vec3(1.0), vec3(0.97, 0.98, 1.02), hash12(cell + 4.0));
		float ang = h * 6.2832;
		vec2 dir = vec2(cos(ang), sin(ang));
		float warp = fbm(uv * 1.7 + cell * 3.7);
		float vein = 1.0 - smoothstep(0.0, 0.06, abs(sin((dot(uv, dir) * 2.2 + warp * 4.0) * 3.1416)));
		vein *= smoothstep(0.35, 0.7, fbm(uv * 0.9 + cell));
		cream *= 1.0 - 0.28 * vein;
		a = cream * grain;
		// The cabochons at the crossings, dark and finely flecked.
		vec2 cf = abs(fract(p + 0.5) - 0.5);
		float cab = step(max(cf.x, cf.y), cabochon * 0.5);
		a = mix(a, tint2 * (0.8 + 0.4 * fbm(uv * 9.0)), cab);
		// Joints, a hair recessed: the slabs' edges bevelled.
		float hgt = block_height(p, vec2(checker), 0.006);
		vec2 g = vec2(block_height(p + vec2(0.01, 0.0), vec2(checker), 0.006) - block_height(p - vec2(0.01, 0.0), vec2(checker), 0.006),
			block_height(p + vec2(0.0, 0.01), vec2(checker), 0.006) - block_height(p - vec2(0.0, 0.01), vec2(checker), 0.006)) / (0.02 * checker);
		// Back from the diagonal frame to u, v.
		vec2 guv = vec2(g.x + g.y, g.x - g.y) * 0.70710678;
		float kf = 1.0 - smoothstep(0.004, 0.012, mpp);
		nl = normalize(n - (ua * guv.x + va * guv.y) * 0.004 * kf);
		a *= mix(1.0, mix(0.55, 1.0, hgt), kf);
		// Waxed unevenly: the polish varies, worn duller along the aisle.
		r = checker_roughness * (0.7 + 0.8 * fbm(uv * 0.6 + 11.0));
		r = mix(r, 0.45, (1.0 - smoothstep(0.9, 1.6, abs(uv.x))) * 0.5);
		r = clamp(r, 0.05, 0.6);
	} else if (ashlar.x > 0.0 && !is_flat) {
		vec2 s = uv / ashlar;
		s.x += 0.5 * mod(floor(s.y), 2.0);  // courses staggered by half a block
		vec2 cell = floor(s);
		float h = hash12(cell);
		// Each block its own tone, a few greyer, a few warmer.
		a *= 1.0 - variation * 0.5 + variation * h;
		a *= mix(vec3(1.0), vec3(0.93, 0.96, 1.0), step(0.78, hash12(cell + 2.3)));
		a *= mix(vec3(1.0), vec3(1.05, 1.0, 0.92), step(0.85, hash12(cell + 5.9)));
		// The bevel: its width varies a little from block to block (worn arrises).
		float bw = bevel * (0.6 + 0.8 * hash12(cell + 8.1));
		float eps = 0.004;
		float h0 = block_height(s, ashlar, bw);
		float hu = (block_height(s + vec2(eps / ashlar.x, 0.0), ashlar, bw) - block_height(s - vec2(eps / ashlar.x, 0.0), ashlar, bw)) / (2.0 * eps);
		float hv = (block_height(s + vec2(0.0, eps / ashlar.y), ashlar, bw) - block_height(s - vec2(0.0, eps / ashlar.y), ashlar, bw)) / (2.0 * eps);
		// The grain raised: the detail image's luminance as a height, a few millimetres.
		float lum = dot(d, vec3(0.33));
		vec2 gg = vec2(dFdx(lum), dFdy(lum));
		float kb = 1.0 - smoothstep(bw * 0.5, bw * 1.5, mpp);
		nl = normalize(n - (ua * hu + va * hv) * bw * 0.6 * kb);
		a *= mix(1.0 - joint_depth * 0.08, mix(1.0 - joint_depth, 1.0, h0), kb);
		r = mix(0.95, roughness, h0);
		// Grime at the foot, soot from the candles towards the vault, a slow mottling.
		a *= 1.0 - 0.18 * (1.0 - smoothstep(0.0, 0.6, v_pos.y));
		a *= 1.0 - 0.3 * smoothstep(soot_from, soot_from + 5.0, v_pos.y);
		a *= 0.9 + 0.2 * fbm(uv * 0.45 + 3.0);
		// Grain relief in screen space: cheap, and as fine as the image.
		NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(nl, 0.0)).xyz);
		NORMAL = normalize(NORMAL - vec3(gg.x, -gg.y, 0.0) * grain_relief * 0.5 * (1.0 - smoothstep(0.003, 0.012, mpp)));
	}
	if (checker > 0.0 && n.y > 0.7) {
		NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(nl, 0.0)).xyz);
	}
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// Compatibility shades in sRGB, with no conversion at the end (as the hall's materials there):
	// the linear colours given as they would show.
	a = pow(max(a, vec3(0.0)), vec3(1.0 / 2.2));
	// No SDFGI there: the candlelight's bounce off the books and the stone, as a warm fill, so that the
	// sky's blue ambient doesn't take the shadows over.
	EMISSION = a * compat_fill;
#endif
	ALBEDO = a;
	ROUGHNESS = r;
}
