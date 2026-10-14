shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_opaque, shadows_disabled;

// The palace gardens' near greenery (scripts/palace_gardens.gd), modelled in Blender and textured from
// Z-Image-Turbo's drawings (artpass/gardens/veg/): trees, clipped yews, and the sprays fringing the hedges.
// As assets/palace_garden.gdshader, it lights itself: the galactic core (core_dir), a faint sky ambient,
// the garden's own lamps, and a warm floodlight from the foot (uplight); distance fades into the haze.
//   kind 0: bark, its UV round the girth and along the branch (artpass/gardens/blender/tree_kit.py)
//   kind 1: leaves: cut-out sprigs on cards, their normal out of the crown, their vertex colour the shade
//           deep in it; light wraps round the crown's edge (wrap), as through leaves
//   kind 2: a clipped hedge's surface: the tile in world space along its three axes, and its normal map
//   kind 3: an orange
//   kind 4: a person of the crowd (scripts/garden_crowd.gd, artpass/gardens/blender/crowd_kit.py), its
//           part (skin, cloth, trim) chosen by `part`; walked here: the limbs swing about the hip and the
//           shoulder as UV.x says (+-2 an arm, else a leg's stride), a robe's hem as UV.y says, at the
//           walk's phase INSTANCE_CUSTOM.r (in cycles) and its pace INSTANCE_CUSTOM.g (0 standing, 1
//           walking); INSTANCE_CUSTOM.b picks the trim's colour, COLOR.rgb is the cloth's and COLOR.a the
//           skin's tone
// A tree near the eye is drawn here; out from near_r - band, its far view (assets/garden_impostor.gdshader)
// takes over pixel by pixel, the two dithered by the same pattern so that each pixel shows one of them.

uniform int kind = 1;
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ntex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 tint = vec3(1.0);       // linear, times the texture
uniform float cutoff = 0.5;
uniform float tile = 1.6;            // kind 2: metres a tile spans
uniform float bump = 1.0;            // kind 2: the normal map's strength
uniform float flowers = 0.0;         // kind 2: the share of 16 cm cells holding a flower, in the instance's colour
// kind 2: 1 for a bed seen from above (the parterre's mounds): the cells laid out in plan, so that the
// flowers cover it; in space, they met only its crest (artpass/foundation/gardens, live-08).
uniform float flower_plane = 0.0;
uniform float foot_y = -10.0;        // the ground
uniform float foot_dark = 0.0;       // darker towards the foot by this share, over foot_h (0: none)
uniform float foot_h = 2.4;
uniform float near_r = 0.0;          // trees: drawn out to here from the eye (0: always)
uniform float band = 8.0;
uniform float sway = 0.0;            // metres at a tree's top
uniform float tree_h = 14.0;         // the mesh's height, for the sway's profile
uniform float flutter = 0.0;         // leaves: metres
uniform float wrap = 0.35;
uniform float uplight = 0.0;         // the floodlight at the foot
uniform float uplight_h = 6.0;       // metres over which it fades up
uniform vec3 core_dir = vec3(-0.468, 0.867, -0.170);
uniform vec3 core_light = vec3(0.9, 0.8, 0.66);
uniform float core_energy = 0.35;
uniform vec3 ambient = vec3(0.07, 0.08, 0.11);
uniform vec3 lamp_colour : source_color = vec3(1.0, 0.72, 0.42);
uniform float lamp_energy = 1.5;
uniform float walk_x = 7.0;
uniform float lamp_step = 14.0;
uniform float lamp_z0 = 36.0;
uniform float lamp_z1 = 176.0;
uniform float lamp_y = -1.8;
uniform float terrace_r = 24.0;
uniform float lamp_arc = 0.1309;
uniform float terrace_y = 1.1;
uniform float terrace_reach = 3.5;
uniform vec3 haze = vec3(0.016, 0.02, 0.036);
uniform float haze_distance = 900.0;
uniform int part = 1;                // kind 4: 0 skin, 1 cloth, 2 trim
uniform float hip_y = 0.92;          // kind 4: the pivots, in the figure's own metres
uniform float shoulder_y = 1.42;
uniform float ankle_y = 0.07;        // kind 4: below it, the foot, carried flat (scripts/garden_crowd.gd LEG)
// The maze's lanterns (scripts/palace_gardens.gd _lantern_map): over lantern_rect (x0, z0, 1/width, 1/depth),
// R and G the way to the lanterns, B the root of their light's strength; lantern_energy 0: none.
uniform sampler2D lantern_map : filter_linear, repeat_disable;
uniform vec4 lantern_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float lantern_y = 0.0;
uniform float lantern_energy = 0.0;

varying vec3 v_wpos;
varying vec3 v_wnorm;
varying vec4 v_col;
varying float v_odist;
varying vec4 v_custom;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
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
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

// The same pattern as garden_impostor.gdshader's, so that near and far views share the band's pixels.
float dither(vec2 px) {
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	v_odist = length(eye - origin);
	if (near_r > 0.0 && v_odist > near_r) {
		// Its far view draws it out there: nothing of it here.
		VERTEX = vec3(0.0);
	} else if (kind == 4) {
		// The walk (artpass/gardens/crowd/gait_model.py): each foot half the cycle on the ground, held there
		// while the hip passes over it, the other half swung forward, eased, and lifted by a shortening of
		// the leg; the foot carried flat; the body lowered onto the supporting leg. INSTANCE_CUSTOM.r: the
		// phase in cycles, the left foot on the ground from 0, the right from 0.5; .g: the pace, the step's
		// length going as its root; .a: the figure's stride. scripts/garden_crowd.gd advances the phase by
		// the same step, so that a planted foot does not slide.
		float ph = INSTANCE_CUSTOM.r;
		float a = sqrt(clamp(INSTANCE_CUSTOM.g, 0.0, 1.0));
		float leg = hip_y - ankle_y;
		float reach = leg * sin(0.4 * INSTANCE_CUSTOM.a) * a;   // the ankle's offset at a step's ends
		// The supporting leg's offset, whichever leg it is, and how far the hip comes down over it.
		float x_st = reach * (1.0 - 2.0 * fract(ph * 2.0));
		float drop = leg - sqrt(leg * leg - x_st * x_st);
		float s = sin(ph * 6.2831853);
		if (UV.x != 0.0) {
			// Forward is -z: a positive turn about x brings a hanging limb forward.
			// An arm is marked 2 (a leg's top and an arm's inside overlap in x); a leg by its stride, 1 or 0.6,
			// + the left.
			bool arm = abs(UV.x) > 1.5;
			float py = arm ? shoulder_y : hip_y;
			float ang;
			float shorten = 1.0;
			if (arm) {
				// Against the leg on its side: the right arm forward as the left foot comes down.
				ang = sign(UV.x) * 0.42 * a * cos(ph * 6.2831853);
			} else {
				float u = fract(ph + (UV.x > 0.0 ? 0.0 : 0.5));
				float x = reach * (1.0 - 4.0 * u);
				if (u >= 0.5) {
					float t = (u - 0.5) * 2.0;
					x = reach * (2.0 * (0.5 - 0.5 * cos(3.14159265 * t)) - 1.0);
					shorten = 1.0 - sin(3.14159265 * t) * 0.07 * a * abs(UV.x) / leg;
				}
				ang = asin(clamp(x / leg, -1.0, 1.0));
			}
			float c = cos(ang);
			float sn = sin(ang);
			if (!arm && VERTEX.y < ankle_y) {
				// The foot: moved with its ankle, not turned.
				float da = (ankle_y - py) * shorten;
				VERTEX.yz += vec2(py + da * c, da * sn) - vec2(ankle_y, 0.0);
			} else {
				float dy = (VERTEX.y - py) * shorten;
				VERTEX.yz = vec2(py + dy * c - VERTEX.z * sn, dy * sn + VERTEX.z * c);
				NORMAL.yz = vec2(NORMAL.y * c - NORMAL.z * sn, NORMAL.y * sn + NORMAL.z * c);
			}
		}
		// The hem swings after the legs; the body comes down over the supporting foot and leans onto it.
		VERTEX.z -= UV.y * 0.07 * s * a;
		VERTEX.y -= drop;
		VERTEX.x -= 0.018 * a * s * smoothstep(0.6, 1.6, VERTEX.y);
		float pace = INSTANCE_CUSTOM.g;
		// Standing, a slow shift of weight, each at its own time.
		VERTEX.x += (1.0 - pace) * 0.012 * sin(TIME * 0.6 + INSTANCE_CUSTOM.r * 40.0) * smoothstep(0.3, 1.6, VERTEX.y);
	} else if (sway > 0.0 || flutter > 0.0) {
		float s2 = dot(MODEL_MATRIX[1].xyz, MODEL_MATRIX[1].xyz);
		float ph = INSTANCE_CUSTOM.y * 6.2831853;
		// As the far views sway, slowly, the top the most.
		float s = sin(TIME * 0.7 + ph) * 0.7 + sin(TIME * 1.9 + ph * 2.3) * 0.3;
		float top = clamp(VERTEX.y / tree_h, 0.0, 1.2);
		vec3 off = vec3(0.8, 0.0, 0.6) * s * sway * top * top;
		if (kind == 1) {
			off += NORMAL * flutter * sin(TIME * 4.3 + dot(VERTEX, vec3(3.1, 2.3, 1.7)) + ph);
		}
		// World metres into the mesh's frame: its basis is a turn and a uniform scale.
		VERTEX += transpose(mat3(MODEL_MATRIX)) * off / max(s2, 1e-6);
	}
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnorm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	v_col = COLOR;
	v_custom = INSTANCE_CUSTOM;
}

float lamp_pool(vec3 p, vec3 q, float reach) {
	vec3 d = p - q;
	return exp(-dot(d, d) / (reach * reach));
}

// As palace_garden.gdshader's lamps(): the two nearest walk lamps and the nearest terrace lamp.
float lamps(vec3 p) {
	float zl = clamp(lamp_z0 + lamp_step * floor((p.z - lamp_z0) / lamp_step + 0.5), lamp_z0, lamp_z1);
	float l = lamp_pool(p, vec3(walk_x, lamp_y, zl), 6.0) + lamp_pool(p, vec3(-walk_x, lamp_y, zl), 6.0);
	float a = atan(p.z, p.x);
	float al = lamp_arc * floor(a / lamp_arc + 0.5);
	l += lamp_pool(p, vec3(cos(al) * terrace_r, terrace_y, sin(al) * terrace_r), terrace_reach) * 0.8;
	return l;
}

vec3 srgb(vec3 c) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There, a source_color texture or uniform arrives in sRGB: to linear.
	return pow(max(c, vec3(0.0)), vec3(2.2));
#else
	return c;
#endif
}

void fragment() {
	if (near_r > 0.0) {
		float f = clamp((near_r - v_odist) / band, 0.0, 1.0);
		if (dither(FRAGCOORD.xy) >= f) {
			discard;
		}
	}
	vec3 n = normalize(v_wnorm);
	vec3 n_geo = n;
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	vec3 to_eye = eye - v_wpos;
	float dist = length(to_eye);
	vec3 v = to_eye / max(dist, 1e-4);
	vec3 l = normalize(core_dir);
	vec3 a;
	float sh = 0.0;
	if (kind == 0) {
		a = srgb(texture(tex, UV).rgb) * tint * v_col.rgb;
		if (!FRONT_FACING) {
			n = -n;
		}
	} else if (kind == 1) {
		vec4 t = texture(tex, UV);
		vec2 px = UV * vec2(textureSize(tex, 0));
		vec2 dx = dFdx(px);
		vec2 dy = dFdy(px);
		float mip = max(0.0, 0.5 * log2(max(dot(dx, dx), dot(dy, dy))));
		// Alpha rises with the mip level, or far crowns would thin out as their mipmaps blur.
		ALPHA = t.a * (1.0 + 0.25 * mip);
		ALPHA_SCISSOR_THRESHOLD = cutoff;
		a = srgb(t.rgb) * tint * v_col.rgb;
	} else if (kind == 2) {
		// Along the three axes, each weighted by how squarely the face meets it; the normal map's tilt
		// carried onto each axis's face (a whiteout blend).
		vec3 n0 = n;
		vec3 w = pow(abs(n), vec3(4.0));
		w /= w.x + w.y + w.z;
		vec2 ux = v_wpos.zy / tile;
		vec2 uy = v_wpos.xz / tile;
		vec2 uz = v_wpos.xy / tile;
		a = srgb(texture(tex, ux).rgb) * w.x + srgb(texture(tex, uy).rgb) * w.y + srgb(texture(tex, uz).rgb) * w.z;
		vec3 tx = texture(ntex, ux).rgb * 2.0 - 1.0;
		vec3 ty = texture(ntex, uy).rgb * 2.0 - 1.0;
		vec3 tz = texture(ntex, uz).rgb * 2.0 - 1.0;
		tx.xy *= bump;
		ty.xy *= bump;
		tz.xy *= bump;
		tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
		ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
		tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
		n = normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
		// Clipped hedges vary in patches, some greener, some darker.
		float patchy = noise2(v_wpos.xz * 0.3 + v_wpos.y * 0.21) * 0.7 + noise2(v_wpos.zx * 1.1 - v_wpos.y * 0.7) * 0.3;
		a *= tint * (0.85 + 0.3 * patchy);
		if (flowers > 0.0) {
			// Roses in bloom: in some of the 16 cm cells a flower about 9 cm across round a point of its
			// own, its rim in five scallops, its petals whorled round a shadowed heart, the leaves round it
			// in its shade; under a few pixels, their average. Round discs read as coins (shots-veg3).
			vec3 q = v_wpos / 0.16;
			if (flower_plane > 0.0) {
				q.y = 0.5;
			}
			vec3 cell = floor(q);
			vec3 c = cell + 0.25 + 0.5 * vec3(hash13(cell + 1.7), hash13(cell + 5.3), hash13(cell + 9.1));
			if (flower_plane > 0.0) {
				c.y = q.y;
			}
			vec3 d = q - c;
			float r = length(d);
			vec3 b1 = normalize(cross(n0, abs(n0.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
			float th = atan(dot(d, cross(n0, b1)), dot(d, b1)) + 6.2832 * hash13(cell + 3.1);
			float edge = 0.26 + 0.035 * cos(5.0 * th);
			float on = step(1.0 - flowers, hash13(cell));
			float bloom = on * (1.0 - smoothstep(edge - 0.03, edge, r));
			float whorl = 0.5 + 0.5 * sin(r * 45.0 - th * 2.0);
			vec3 petal = v_col.rgb * mix(0.45, 1.2, smoothstep(0.03, 0.15, r)) * (0.8 + 0.25 * whorl);
			float shade = on * (1.0 - smoothstep(edge, edge + 0.1, r)) * (1.0 - bloom);
			float m_px = max(length(dFdx(v_wpos)), length(dFdy(v_wpos)));
			float detail = 1.0 - smoothstep(0.02, 0.06, m_px);
			a = mix(mix(a, v_col.rgb, flowers * 0.4), mix(a * (1.0 - 0.4 * shade), petal, bloom), detail);
			// A bloom is smooth: the leaves' normal map not on it.
			n = normalize(mix(n, n0, bloom * detail));
		} else {
			a *= v_col.rgb;
		}
	} else if (kind == 4) {
		if (part == 0) {
			a = mix(vec3(0.62, 0.4, 0.29), vec3(0.13, 0.07, 0.045), v_col.a);
			sh = 0.12;
		} else if (part == 1) {
			// Cloth: a faint weave, so that a robe is not a plastic cone up close.
			a = v_col.rgb * (0.9 + 0.1 * hash13(floor(v_wpos * 90.0)));
		} else {
			int t = int(v_custom.b * 4.0 + 0.5);
			a = t == 0 ? vec3(0.06, 0.035, 0.02) : (t == 1 ? vec3(0.025, 0.025, 0.03)
				: (t == 2 ? vec3(0.42, 0.36, 0.25) : (t == 3 ? vec3(0.4, 0.27, 0.07) : vec3(0.5, 0.38, 0.17))));
		}
		a *= tint;
		if (!FRONT_FACING) {
			n = -n;
		}
	} else {
		a = tint;
		sh = 0.3;
	}
	if (foot_dark > 0.0) {
		a *= 1.0 - foot_dark * (1.0 - clamp((v_wpos.y - foot_y) / foot_h, 0.0, 1.0));
	}
	float ndl = dot(n, l);
	float diff = kind == 1 ? clamp(ndl * (1.0 - wrap) + wrap, 0.0, 1.0) : max(ndl, 0.0);
	vec3 lc = srgb(lamp_colour);
	vec3 col = a * (ambient + core_light * core_energy * diff + lc * lamps(v_wpos) * lamp_energy);
	if (lantern_energy > 0.0) {
		// The lanterns' light, read 0.3 m out from the surface (out of the hedge, onto its walk); a face takes
		// it as it turns to them, and less the further above or below the lantern's flame.
		vec2 q = (v_wpos.xz + n_geo.xz * 0.3 - lantern_rect.xy) * lantern_rect.zw;
		if (q.x >= 0.0 && q.y >= 0.0 && q.x <= 1.0 && q.y <= 1.0) {
			vec4 m = texture(lantern_map, q);
			vec2 way = m.rg * 2.0 - 1.0;
			float facing = abs(n.y) > 0.7 ? 0.5 : clamp(dot(n.xz, way) * 0.75 + 0.25, 0.0, 1.0);
			float dy = v_wpos.y - lantern_y;
			float g = pow(1.0 + dy * dy / 2.25, -1.5);
			col += a * lc * lantern_energy * 2.0 * m.b * m.b * facing * g;
		}
	}
	if (uplight > 0.0) {
		// Floodlit from the foot: warm, fading up; the undersides take the most.
		float up = exp(-max(v_wpos.y - foot_y, 0.0) / uplight_h);
		col += a * lc * uplight * up * (0.6 + 0.4 * clamp(-n.y * 0.5 + 0.5, 0.0, 1.0));
	}
	if (sh > 0.0) {
		vec3 h = normalize(l + v);
		col += core_light * core_energy * sh * pow(max(dot(n, h), 0.0), 24.0);
	}
	ALBEDO = mix(haze, col, exp(-dist / haze_distance));
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	ALBEDO = pow(max(ALBEDO, vec3(0.0)), vec3(1.0 / 2.2));
#endif
}
