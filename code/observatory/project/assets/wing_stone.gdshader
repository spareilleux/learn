shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;

// The library wing's outside (scripts/library_wing.gd): its stone walls on their podium, its lead roof
// and the paved esplanade round it behind the hall. As assets/palace_garden.gdshader, it lights itself:
// the galactic core (core_dir), a faint sky ambient, floodlights at the foot of the walls, the lamps
// along the esplanade and the night city's blue from below, so no light is added to the scene. Joints
// are in the mesh's own frame (the wing's: x across, z along), since the walls run straight out from
// the hall, where the garden shader's joints, round the hall, would not change along them.
//   kind 0: stone, in courses of ashlar (cylinder 1: round the world's origin, for the hall's plinth)
//   kind 1: the roof's lead, in sheets between standing seams down the slope
//   kind 2: the esplanade's paving, slabs in the world's x and z, lamp-lit
//   kind 3: a lamp's glass, its own light

uniform int kind = 0;
uniform vec3 albedo : source_color = vec3(0.56, 0.53, 0.48);
uniform vec2 ashlar = vec2(1.5, 0.75);           // metres: a block's length and a course's height
uniform float cylinder = 0.0;
uniform float bevel = 0.03;                      // m: each block's chamfer (kind 0)
uniform float rustic = 0.0;                      // 1: channelled rustication, the courses' joints deep
uniform sampler2D detail_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float stone_detail = 0.0;
uniform vec3 core_dir = vec3(-0.468, 0.867, -0.170);
// Linear light values, as the garden's.
uniform vec3 core_light = vec3(0.9, 0.8, 0.66);
uniform float core_energy = 0.35;
uniform vec3 ambient = vec3(0.07, 0.08, 0.11);
uniform vec3 lamp_colour : source_color = vec3(1.0, 0.72, 0.42);
uniform float uplight = 0.6;
uniform float base_y = -10.0;                    // the foot of the floodlit walls (world)
uniform float up_reach = 14.0;
uniform vec3 city : source_color = vec3(0.12, 0.42, 0.75);  // the city's light, from the horizon
uniform float city_energy = 0.1;
uniform float sheen = 0.05;
uniform float seam = 0.6;                        // m between the roof's seams
uniform float slab = 1.5;                        // m: the esplanade's slabs
// The esplanade's lamps: in two rows along the wing, either side of its axis, in the wing's frame.
uniform vec3 wing_origin = vec3(0.0);
uniform vec3 wing_x = vec3(1.0, 0.0, 0.0);
uniform vec3 wing_z = vec3(0.0, 0.0, 1.0);
uniform float lamp_x = 11.0;
uniform float lamp_step = 9.6;
uniform float lamp_z0 = 2.0;
uniform float lamp_z1 = 50.0;
uniform float lamp_y = 3.5;                      // over the esplanade
uniform float lamp_reach = 6.0;
uniform float lamp_energy = 1.2;
uniform vec3 haze = vec3(0.016, 0.02, 0.036);
uniform float haze_distance = 900.0;

varying vec3 v_wpos;
varying vec3 v_local;
varying vec3 v_lnorm;
varying vec3 v_wnorm;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_local = VERTEX;
	v_lnorm = NORMAL;
	v_wnorm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// The share of [x - fw/2, x + fw/2] on a line `w` wide at each integer: a joint or a seam that never
// shimmers, blurred to its average once under a pixel.
float lines(float x, float w, float fw) {
	fw = max(fw, 1e-4);
	float d = abs(fract(x + 0.5) - 0.5);
	return (1.0 - smoothstep(w * 0.5 - fw * 0.5, w * 0.5 + fw * 0.5, d)) * min(1.0, w / max(fw, w));
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), f.x), mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), f.x), f.y);
}

// A block's height at b (in blocks, `size` metres each): 1 on its face, 0 at its joints, over a chamfer
// bw.x wide on its ends and bw.y on its beds.
float block_height(vec2 b, vec2 size, vec2 bw) {
	vec2 e = min(fract(b), 1.0 - fract(b)) * size;
	return smoothstep(0.0, bw.x, e.x) * smoothstep(0.0, bw.y, e.y);
}

// A lamp at q lighting p, as a pool.
float pool(vec3 p, vec3 q, float reach) {
	vec3 d = p - q;
	return exp(-dot(d, d) / (reach * reach));
}

// The esplanade's lamps at p: the nearest in each row.
float lamps(vec3 p) {
	vec3 d = p - wing_origin;
	float lx = dot(d, wing_x);
	float lz = dot(d, wing_z);
	float zl = clamp(lamp_z0 + lamp_step * floor((lz - lamp_z0) / lamp_step + 0.5), lamp_z0, lamp_z1);
	float l = 0.0;
	for (int s = -1; s <= 1; s += 2) {
		vec3 q = wing_origin + wing_x * (float(s) * lamp_x) + wing_z * zl;
		q.y = base_y + lamp_y;
		l += pool(p, q, lamp_reach);
	}
	return l;
}

void fragment() {
	vec3 n = normalize(v_wnorm);
	vec3 ln = normalize(v_lnorm);
	vec3 n_flat = n;  // before the relief tilts it
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	float dist = length(eye - v_wpos);
	vec3 v = (eye - v_wpos) / max(dist, 1e-4);
	float m_px = max(length(dFdx(v_wpos)), length(dFdy(v_wpos))) + 1e-5;
	vec3 a = albedo;
	vec3 lc = lamp_colour;
	vec3 cc = city;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There, the uniform colours arrive as they were set, in sRGB (assets/upperside.gdshader).
	a = pow(a, vec3(2.2));
	lc = pow(lc, vec3(2.2));
	cc = pow(cc, vec3(2.2));
#endif
	if (kind == 3) {
		ALBEDO = lc * lamp_energy * 3.0;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		ALBEDO = pow(max(ALBEDO, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	} else {
		float sh = sheen;
		if (kind == 0) {
			vec3 an = abs(ln);
			bool top = an.y > 0.7;
			vec2 s;
			if (cylinder > 0.5) {
				s = top ? v_wpos.xz : vec2(atan(v_wpos.z, v_wpos.x) * length(v_wpos.xz), v_wpos.y);
			} else {
				s = top ? v_local.xz : vec2(an.x > an.z ? v_local.z : v_local.x, v_local.y);
			}
			vec2 size = top ? vec2(1.2) : ashlar;
			vec2 b = s / size;
			if (!top) {
				b.x += 0.5 * mod(floor(b.y), 2.0);  // courses staggered by half a block
			}
			vec2 cell = floor(b);
			if (stone_detail > 0.0) {
				vec2 win = size / 2.4;
				vec2 uv = fract(b) * win + vec2(hash12(cell + 3.1), hash12(cell + 7.7)) * (1.0 - win);
				a *= mix(vec3(1.0), textureGrad(detail_tex, uv, dFdx(b) * win, dFdy(b) * win).rgb * 2.0, stone_detail);
			}
			a *= 0.92 + 0.16 * hash12(cell + 1.3);
			vec2 fw = fwidth(b);
			float joint = max(lines(b.x, 0.012 / size.x, fw.x), lines(b.y, 0.012 / size.y, fw.y));
			a *= 1.0 - 0.45 * joint;
			if (!top && cylinder < 0.5) {
				// The chamfers, as a tilt of the normal along the face's own axes, faded out once
				// under a pixel or two.
				vec2 bw = rustic > 0.5 ? vec2(0.015, 0.07) : vec2(bevel);
				bw *= 0.7 + 0.6 * hash12(cell + 8.1);
				float eps = 0.005;
				float hu = (block_height(b + vec2(eps / size.x, 0.0), size, bw) - block_height(b - vec2(eps / size.x, 0.0), size, bw)) / (2.0 * eps);
				float hv = (block_height(b + vec2(0.0, eps / size.y), size, bw) - block_height(b - vec2(0.0, eps / size.y), size, bw)) / (2.0 * eps);
				float k = 1.0 - smoothstep(bw.y * 0.5, bw.y * 1.5, m_px);
				vec3 ua = an.x > an.z ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
				vec3 tl = normalize(ln - (ua * hu * bw.x + vec3(0.0, 1.0, 0.0) * hv * bw.y) * 0.8 * k);
				n = normalize(MODEL_NORMAL_MATRIX * tl);
				float hgt = block_height(b, size, bw);
				a *= mix(1.0, mix(rustic > 0.5 ? 0.45 : 0.7, 1.0, hgt), k);
				if (rustic > 0.5) {
					// Bossed faces: mottled, a little rough.
					a *= 0.86 + 0.28 * vnoise(s * 2.3 + cell * 5.0) * (0.6 + 0.4 * vnoise(s * 9.0));
				}
			}
		} else if (kind == 1) {
			// Lead: sheets between seams down the slope (along the wing's x), a little lighter on the
			// seams' rolls, which catch the core.
			float u = v_local.z / seam;
			float fu = fwidth(u);
			float roll = lines(u, 0.06, fu);
			a *= (0.9 + 0.2 * hash12(vec2(floor(u), floor(v_local.x / 2.4)))) * (1.0 + 0.8 * roll);
			sh = 0.25;
		} else if (kind == 2) {
			vec2 q = v_wpos.xz / slab;
			vec2 fw = fwidth(q);
			float joint = max(lines(q.x, 0.02, fw.x), lines(q.y, 0.02, fw.y));
			a *= (0.88 + 0.24 * hash12(floor(q))) * (1.0 - 0.4 * joint);
			if (stone_detail > 0.0) {
				vec2 cell = floor(q);
				vec2 uv = fract(q) * 0.45 + vec2(hash12(cell + 3.1), hash12(cell + 7.7)) * 0.55;
				a *= mix(vec3(1.0), textureGrad(detail_tex, uv, dFdx(q) * 0.45, dFdy(q) * 0.45).rgb * 2.0, stone_detail);
			}
		}
		vec3 l = normalize(core_dir);
		vec3 col = a * (ambient + core_light * core_energy * max(dot(n, l), 0.0) + lc * lamps(v_wpos) * lamp_energy);
		vec3 h = normalize(l + v);
		col += core_light * core_energy * sh * pow(max(dot(n, h), 0.0), 32.0);
		// The city's blue on the faces that look out at it, and from below on the soffits.
		col += a * cc * city_energy * (1.0 - 0.6 * max(n.y, 0.0));
		if (uplight > 0.0) {
			// Floodlit from the foot: warm, fading up the wall. The light comes up from in front, so
			// the chamfers that face down catch it and those that face up fall dark.
			float up = exp(-max(v_wpos.y - base_y, 0.0) / up_reach);
			vec3 lu = normalize(n_flat * 0.35 - vec3(0.0, 1.0, 0.0));
			float relief = clamp(max(dot(n, lu), 0.0) / max(dot(n_flat, lu), 0.15), 0.0, 1.6);
			col += a * lc * uplight * up * relief * (1.0 - smoothstep(0.7, 0.95, abs(n_flat.y)));
		}
		float fade = exp(-dist / haze_distance);
		ALBEDO = mix(haze, col, fade);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		ALBEDO = pow(max(ALBEDO, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	}
}
