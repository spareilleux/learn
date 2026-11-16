shader_type spatial;
#if defined(RT)
// NVIDIA's fork reads every shader a second time with RT defined, for its path tracer: there the plants are
// lit by its rays, the garden's lamps standing as lights (scripts/palace_gardens.gd set_rt_lit; the author,
// 2026-10-15: « On veut des arbres et jardins photorealistes »). Stock Godot and the web never define it.
render_mode fog_disabled, cull_disabled, depth_draw_opaque;
#else
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_opaque, shadows_disabled;
#endif

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
//           skin's tone. With `photo` on, a photographed person instead (artpass/gardens/people/: Z-Image-Turbo,
//           TRELLIS.2, rigged in Blender): its colours in tex, its walk's weights in UV2 (x: a leg's, + the
//           left; an arm's 2 + its weight, + the right; y: how far down the garment hangs), mask_tex R the
//           garment's share, dyed in COLOR.rgb over white_ref, and G its roughness
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
// The wind (the author, 2026-10-16: « Les haies [...] devraient bouger un peu au vent (De maniere realiste) »): gusts
// that travel downwind, with lulls between (gust()). Off (0) on the web.
uniform float gusty = 0.0;           // sprays: metres the gusts push them downwind, rasterized (the fork's rays see
                                     // no vertex() motion: only skinned and blend-shaped meshes are deformed there)
uniform float lumps = 0.0;           // kind 2: the clipped growth's clumps, their relief and hollows (0: flat)
uniform float leaf_wind = 0.0;       // kind 2: the gusts turning the leaves, in patches (0: still)
uniform vec2 wind_dir = vec2(0.8, 0.6);  // where the wind blows to, in x and z (the trees' sway's way)
uniform float wind_speed = 2.5;      // m/s the gusts travel at
// kind 2, off the web: the clipped growth's outer leaves, in layers over the surface (scripts/hedge_shells.gd
// builds them, each a copy of the surface pushed out along its normal, and sets px_angle each frame). A layer
// draws a scattering of leaves cut out of it, sparser outward; the surface beneath shades as the inside of the
// growth. In the fragment and in real geometry, so that the path tracer sees the leaves, their gaps, their
// shadows and the ragged outline. Drawn while a leaf spans 3.5 pixels or more, fading in to 6: under that, the
// path tracer paid for layers it could not resolve (artpass/gardens/hedges).
uniform float shell = 0.0;           // 1: this draws the layers, each vertex's colour's alpha its layer's height in
                                     // the growth (1 the outermost); 0: the surface
uniform float leaf_len = 0.0;        // metres a leaf is long (0: no layers over this surface)
uniform float leaf_form = 0.0;       // 0: a box's oval leaves, 1: a yew's narrow ones
uniform float px_angle = 0.0;        // radians a pixel spans at the screen's middle (0: no layers drawn)
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
uniform bool photo = false;          // kind 4: a photographed person (above)
uniform sampler2D mask_tex : hint_default_black, filter_linear_mipmap, repeat_disable;
uniform float white_ref = 0.85;      // the white garment's albedo, linear: dyed, it takes the person's colour
// kind 4, photo: the folds TRELLIS.2 baked from its dense surface (tangent space, glTF's +Y), by normal_strength,
// on the rasterizer's lighting only (neither the web nor the path tracer reads it); and the arms brought down by
// arm_lower from the A pose the photograph was taken in, about the shoulders' pivots at x = +shoulder_x.x (the right
// arm) and -shoulder_x.y (artpass/gardens/people/arm_pose.py; the author, 2026-10-15: « Les personnages sont
// mieux rendus sur les photos que dans la scène 3D »).
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform float normal_strength = 0.0;
uniform float arm_lower = 0.0;
uniform vec2 shoulder_x = vec2(0.12);
// kind 4, photographed: walked by its bones (scripts/garden_bones.gd: path traced, the rays see a skinned mesh
// move, never this vertex stage), not here; its garment dyed in `dye`, as it is not one of a MultiMesh's.
uniform bool skinned = false;
uniform vec4 dye = vec4(1.0);
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

// The wind's strength at p, 0 to 1: broad gusts some 15 m across travelling downwind, lulls between.
float gust(vec3 p, float t) {
	vec2 q = p.xz - wind_dir * wind_speed * t;
	float g = noise2(q * 0.07) * 0.65 + noise2(q * 0.19 + 7.3) * 0.35;
	return smoothstep(0.38, 0.82, g);
}

// A clipped hedge's clumps on a face's plane, 0 to 1: some 25 cm across, and 10 cm within them.
float clumps(vec2 u) {
	return noise2(u * 4.0) * 0.6 + noise2(u * 9.5 + 3.7) * 0.4;
}

// A clipped hedge as it reads from afar (the author, 2026-10-16, after the telescope's close view: « la vue de loin
// est pas terrible »), times its colour: box planted close grows into one line of plants, each a little yellower
// or bluer, lighter or darker than the next; and the top, clipped, puts out paler young shoots. `outer`: how far
// out in the growth (1 at its surface).
vec3 growth_tint(vec3 p, vec3 n0, float outer) {
	float plant = noise2(p.xz * 2.6 + p.y * 1.3) * 0.65 + noise2(p.zx * 6.1 + 4.2) * 0.35;
	vec3 c = mix(vec3(0.82, 0.92, 1.0), vec3(1.12, 1.08, 0.78), plant);
	float top = smoothstep(0.55, 0.9, n0.y) * outer;
	float shoots = smoothstep(0.35, 0.8, noise2(p.xz * 9.0 + 1.7) * 0.6 + noise2(p.xz * 17.0) * 0.4);
	return mix(c, c * vec3(1.45, 1.6, 0.95), top * shoots * 0.7);
}

// One scattering of leaves on a face's plane (u, metres): a leaf in each cell with the chance p, turned and
// placed at random in it, shaken about its stalk by gw (the gust, and a tremor that never quite stops). Returns 0 off a leaf, else its rank (1 to 2:
// the highest lies on top); `shade` its brightness across its fold, `tilt` its normal's lean in u's axes, `mid`
// its middle (for its colour).
float leaf_on(vec2 u, float seed, float p, float gw, out float shade, out vec2 tilt, out vec2 mid) {
	// 0.7 of a leaf's length: a leaf placed anywhere in the middle half of its cell still lies within the four
	// cells searched round u.
	float cell = leaf_len * 0.7;
	float width = mix(0.55, 0.3, leaf_form);
	vec2 q = u / cell;
	vec2 c0 = floor(q - 0.5);
	float rank = 0.0;
	shade = 1.0;
	tilt = vec2(0.0);
	mid = u;
	for (int j = 0; j < 4; j++) {
		vec2 c = c0 + vec2(float(j & 1), float(j >> 1));
		vec2 key = c + seed * 17.13;
		float h = hash12(key);
		if (h >= p) {
			continue;
		}
		float h2 = hash12(key + 3.7);
		float h3 = hash12(key + 7.1);
		float th = hash12(key + 11.3) * 6.2832;
		float sh = gw * sin(TIME * (6.0 + 3.0 * h2) + h3 * 6.2832);
		th += sh * 0.45;
		vec2 ax = vec2(cos(th), sin(th));
		vec2 ctr = (c + 0.25 + 0.5 * vec2(h2, h3)) * cell + ax * sh * 0.025 * leaf_len;
		vec2 d = u - ctr;
		float s = dot(d, ax) / (leaf_len * 0.5);
		float t = dot(d, vec2(-ax.y, ax.x)) / (leaf_len * 0.5 * width * (1.0 - 0.3 * max(s, 0.0)));
		float top = 1.0 + hash12(key + 5.9);
		if (s * s + t * t < 1.0 && top > rank) {
			rank = top;
			shade = mix(0.7, 1.2, hash12(key + 9.4)) * (0.88 + 0.12 * t) * (abs(t) < 0.1 ? 0.88 : 1.0);
			tilt = (vec2(hash12(key + 13.7), hash12(key + 15.1)) - 0.5) * 0.9 + vec2(-ax.y, ax.x) * t * 0.35;
			mid = ctr;
		}
	}
	return rank;
}

// Flowers in bloom, in two scatterings of cells (16 and 11 cm, the second turned 30 degrees), so that no grid
// shows; each its own size (6 to 11 cm), its own petals (five, six, or for the palest a daisy's thirteen round a
// yellow heart) and its own shade of the bed's colour `col`, `dens` of the cells holding one. Returns the share
// of a bloom at wp (0 to 1); `petal` its colour, `shade` the shadow round it, `dn` the dome's lean in b1, b2.
float bloom(vec3 wp, vec3 n0, vec3 col, float dens, out vec3 petal, out float shade, out vec2 dn, out vec3 b1,
		out vec3 b2) {
	b1 = normalize(cross(n0, abs(n0.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
	b2 = cross(n0, b1);
	float grey = dot(col, vec3(0.3333));
	float pale = step(0.55, grey) * step(length(col - vec3(grey)), 0.15);
	float best = 0.0;
	shade = 0.0;
	petal = col;
	dn = vec2(0.0);
	for (int layer = 0; layer < 2; layer++) {
		float cs = layer == 0 ? 0.16 : 0.11;
		vec3 q = wp / cs;
		if (layer == 1) {
			q.xz = vec2(0.866 * q.x - 0.5 * q.z, 0.5 * q.x + 0.866 * q.z) + 17.3;
		}
		if (flower_plane > 0.0) {
			q.y = 0.5;
		}
		vec3 fc = floor(q);
		vec3 key = fc + float(layer) * 31.7;
		vec3 c = fc + 0.3 + 0.4 * vec3(hash13(key + 1.7), hash13(key + 5.3), hash13(key + 9.1));
		if (flower_plane > 0.0) {
			c.y = q.y;
		}
		vec3 d = (q - c) * cs;
		float r = length(d);
		float on = step(1.0 - dens * (layer == 0 ? 0.7 : 0.45), hash13(key));
		float sz = mix(0.03, 0.055, hash13(key + 2.9)) * (layer == 0 ? 1.0 : 0.8);
		float hp = hash13(key + 4.4);
		float np = (pale > 0.5 && hp < 0.7) ? 13.0 : (hp < 0.5 ? 5.0 : 6.0);
		float th = atan(dot(d, b2), dot(d, b1)) + 6.2832 * hash13(key + 3.1);
		float lobe = abs(cos(np * th * 0.5));
		float edge = np > 10.0 ? sz * (0.55 + 0.45 * pow(lobe, 0.35)) : sz * (0.84 + 0.16 * lobe);
		float bl = on * (1.0 - smoothstep(edge - 0.004, edge, r));
		shade = max(shade, on * (1.0 - smoothstep(edge, edge + 0.016, r)));
		if (bl > best) {
			best = bl;
			float rr = r / sz;
			vec3 base = mix(col, vec3(0.95), 0.15 * hash13(key + 8.8)) * mix(0.8, 1.15, hash13(key + 6.6));
			vec3 heart = np > 10.0 ? vec3(0.85, 0.6, 0.08) : base * 0.35;
			float hr = np > 10.0 ? 0.3 : 0.2;
			petal = mix(heart, base * mix(0.75, 1.15, smoothstep(hr, 1.0, rr)), smoothstep(hr - 0.06, hr + 0.04, rr));
			petal *= np > 10.0 ? 0.85 + 0.15 * cos(np * th) : 0.85 + 0.2 * sin(rr * 7.0 - th * 2.0);
			dn = vec2(dot(d, b1), dot(d, b2)) / sz;
		}
	}
	return best;
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
	} else if (kind == 4 && !skinned) {
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
		// The modelled figures mark each limb whole in UV; a photographed one weighs each vertex in UV2, so that
		// a sleeve bends where it leaves the body rather than tearing from it.
		float mark = photo ? UV2.x : UV.x;
		float hang = photo ? UV2.y : UV.y;
		if (mark != 0.0) {
			// Forward is -z: a positive turn about x brings a hanging limb forward.
			// An arm is marked 2 (a leg's top and an arm's inside overlap in x); a leg by its stride, 1 or 0.6,
			// + the left.
			bool arm = abs(mark) > 1.5;
			float wgt = photo ? clamp(arm ? abs(mark) - 2.0 : abs(mark), 0.0, 1.0) : 1.0;
			float stride = photo ? INSTANCE_CUSTOM.a : abs(mark);
			vec3 v0 = VERTEX;
			vec3 n0 = NORMAL;
			float py = arm ? shoulder_y : hip_y;
			float ang;
			float shorten = 1.0;
			if (arm) {
				if (photo && arm_lower > 0.0) {
					// Down towards the body, in its plane, before the swing.
					vec2 pv = vec2(mark > 0.0 ? shoulder_x.x : -shoulder_x.y, shoulder_y);
					float al = -sign(mark) * arm_lower;
					float ca = cos(al);
					float sa = sin(al);
					vec2 d = VERTEX.xy - pv;
					VERTEX.xy = pv + vec2(d.x * ca - d.y * sa, d.x * sa + d.y * ca);
					NORMAL.xy = vec2(NORMAL.x * ca - NORMAL.y * sa, NORMAL.x * sa + NORMAL.y * ca);
				}
				// Against the leg on its side: the right arm forward as the left foot comes down.
				ang = sign(mark) * 0.42 * a * cos(ph * 6.2831853);
			} else {
				float u = fract(ph + (mark > 0.0 ? 0.0 : 0.5));
				float x = reach * (1.0 - 4.0 * u);
				if (u >= 0.5) {
					float t = (u - 0.5) * 2.0;
					x = reach * (2.0 * (0.5 - 0.5 * cos(3.14159265 * t)) - 1.0);
					shorten = 1.0 - sin(3.14159265 * t) * 0.07 * a * stride / leg;
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
			VERTEX = mix(v0, VERTEX, wgt);
			NORMAL = normalize(mix(n0, NORMAL, wgt));
		}
		// The hem swings after the legs; the body comes down over the supporting foot and leans onto it.
		VERTEX.z -= hang * 0.07 * s * a;
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
			float g = gusty > 0.0 ? gust((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, TIME) : 0.0;
			off += NORMAL * flutter * (1.0 + 2.5 * g) * sin(TIME * 4.3 + dot(VERTEX, vec3(3.1, 2.3, 1.7)) + ph);
			// The sprays fringing a hedge: pushed downwind as a gust passes, wavering, back in the lulls.
			off += vec3(wind_dir.x, 0.0, wind_dir.y) * gusty * g
				* (0.7 + 0.3 * sin(TIME * 2.7 + ph * 3.0 + dot(VERTEX.xz, vec2(1.3, 0.9))));
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
	float rough = 0.9;
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
		// Along the three axes, each weighted by how squarely the face meets it.
		vec3 n0 = n;
		vec3 w = pow(abs(n), vec3(4.0));
		w /= w.x + w.y + w.z;
		// Clipped hedges vary in patches, some greener, some darker.
		float patchy = noise2(v_wpos.xz * 0.3 + v_wpos.y * 0.21) * 0.7 + noise2(v_wpos.zx * 1.1 - v_wpos.y * 0.7) * 0.3;
		// How far the outer leaves' layers are drawn here: from 3.5 pixels a leaf, in full from 6.
		float near_k = 0.0;
		if (px_angle > 0.0 && leaf_len > 0.0) {
			near_k = smoothstep(3.5, 6.0, leaf_len / max(dist * px_angle, 1e-7));
		}
		float dens = flowers * mix(0.45, 1.2, noise2(v_wpos.xz * 0.55 + 3.0));
		if (shell > 0.0) {
			// A layer of the outer leaves (scripts/hedge_shells.gd): a scattering of leaves, sparser outward,
			// each trembling on its stalk, and shaken as a gust passes, the outer ones the most; nothing between them.
			if (near_k <= 0.0) {
				discard;
			}
			float lh = v_col.a;  // the layer's height in the growth
			float gw = gust(v_wpos, TIME) * leaf_wind * (0.4 + 0.6 * lh);
			bool drawn = false;
			if (flowers > 0.0) {
				// A flower stands out of the growth: the outermost layer draws it, the ones within leave it room.
				vec3 petal;
				float fshade;
				vec2 dn;
				vec3 b1;
				vec3 b2;
				float best = bloom(v_wpos, n0, v_col.rgb, dens, petal, fshade, dn, b1, b2);
				if (best > 0.5) {
					if (lh < 0.99) {
						discard;
					}
					a = petal;
					n = normalize(n0 + (b1 * dn.x + b2 * dn.y) * 0.8);
					drawn = true;
				}
			}
			if (!drawn) {
				// The leaves on each plane the face meets squarely enough, a plane's fading in as it takes over,
				// so that a curved face shows no seam; fewer as the layer thins out of sight (near_k).
				float rank = 0.0;
				float shade = 1.0;
				vec2 tilt = vec2(0.0);
				vec2 mid = vec2(0.0);
				int axis = 1;
				for (int ax = 0; ax < 3; ax++) {
					float wa = ax == 0 ? w.x : (ax == 1 ? w.y : w.z);
					if (wa < 0.1) {
						continue;
					}
					vec2 u = ax == 0 ? v_wpos.zy : (ax == 1 ? v_wpos.xz : v_wpos.xy);
					float sd;
					vec2 tl;
					vec2 md;
					float p = (1.1 - 0.65 * lh) * smoothstep(0.1, 0.3, wa) * near_k;
					float r = leaf_on(u, lh * 7.0 + float(ax) * 3.1, p, gw + 0.12 * leaf_wind * lh, sd, tl, md);
					if (r > rank) {
						rank = r;
						shade = sd;
						tilt = tl;
						mid = md;
						axis = ax;
					}
				}
				if (rank <= 0.0) {
					discard;
				}
				vec3 t1 = axis == 0 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
				vec3 t2 = axis == 1 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
				// Its colour the tile's round its middle, blurred, and lighter than that average of leaves and the
				// dark between them; deeper in, darker.
				a = srgb(textureLod(tex, mid / tile, 2.0).rgb) * 1.35 * tint * (0.85 + 0.3 * patchy) * shade;
				a *= flowers > 0.0 ? vec3(1.0) : v_col.rgb * growth_tint(v_wpos, n0, lh);
#if defined(RT)
				a *= mix(0.8, 1.0, lh);
#else
				a *= mix(0.55, 1.0, lh);
#endif
				// A gust turns some over: their paler backs.
				if (hash12(floor(mid * 997.0)) < gw * 0.45) {
					a *= vec3(1.3, 1.36, 1.2);
				}
				n = normalize(n0 + t1 * tilt.x + t2 * tilt.y);
			}
		} else {
			// The surface: the tile on the three axes, the normal map's tilt carried onto each axis's face (a
			// whiteout blend).
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
			a *= tint * (0.85 + 0.3 * patchy);
			if (lumps > 0.0) {
				// Clipped growth in clumps, on each face's own plane: their slope tilts the normal and their
				// hollows are darker, so that a hedge is not a print of leaves on a box (the author, at the
				// telescope: « Les haies ont l'air du papier peint »).
				vec3 grad = vec3(0.0);
				float hl = 0.0;
				for (int ax = 0; ax < 3; ax++) {
					float wa = ax == 0 ? w.x : (ax == 1 ? w.y : w.z);
					if (wa < 0.02) {
						continue;
					}
					vec2 u = ax == 0 ? v_wpos.zy : (ax == 1 ? v_wpos.xz : v_wpos.xy);
					float h0 = clumps(u);
					float hu = (clumps(u + vec2(0.03, 0.0)) - h0) / 0.03;
					float hv = (clumps(u + vec2(0.0, 0.03)) - h0) / 0.03;
					grad += (ax == 0 ? vec3(0.0, hv, hu) : (ax == 1 ? vec3(hu, 0.0, hv) : vec3(hu, hv, 0.0))) * wa;
					hl += h0 * wa;
				}
				n = normalize(n - grad * 0.04 * lumps);
				a *= mix(1.0 - 0.4 * lumps, 1.0, smoothstep(0.2, 0.75, hl));
				if (flowers <= 0.0) {
					a *= growth_tint(v_wpos, n0, 1.0);
				}
				// At a glancing look the eye meets the leaves' tips rather than the shade between them: the growth
				// lightens towards its outline, as velvet does, where a smooth tube darkens.
				float graze = 1.0 - clamp(dot(n0, v), 0.0, 1.0);
				a *= 1.0 + 0.45 * lumps * graze * graze;
			}
			if (leaf_wind > 0.0) {
				// As a gust crosses, the leaves it lifts show their paler backs, in small patches that come and go,
				// and their light flickers; in the lulls the hedge is still. In the fragment, so that the rays see
				// it.
				float gw = gust(v_wpos, TIME) * leaf_wind;
				vec2 fq = v_wpos.xz * 4.0 + v_wpos.y * vec2(2.3, -1.7);
				float turned = smoothstep(0.55, 0.9, noise2(fq + TIME * vec2(1.9, 1.3))) * gw;
				a = mix(a, a * vec3(1.3, 1.36, 1.2), turned * 0.7);
				vec3 jitter = vec3(noise2(fq * 1.7 - TIME * 2.3), noise2(fq * 1.3 + 5.0 + TIME * 1.7),
					noise2(fq * 1.7 + 11.0 + TIME * 2.1)) - 0.5;
				n = normalize(n + jitter * 0.5 * gw);
			}
			if (flowers > 0.0) {
				// Flowers in bloom (bloom()), the beds fuller in some places than others, and each flower a low dome
				// that takes the light on one side (the author, 2026-10-15: « le parterre de fleurs fait trop
				// tapisserie »). Under a few pixels, their average.
				float m_px = max(length(dFdx(v_wpos)), length(dFdy(v_wpos)));
				float detail = 1.0 - smoothstep(0.02, 0.06, m_px);
				vec3 petal;
				float shade;
				vec2 dn;
				vec3 b1;
				vec3 b2;
				float best = bloom(v_wpos, n0, v_col.rgb, dens, petal, shade, dn, b1, b2);
				shade *= 1.0 - best;
				a = mix(mix(a, v_col.rgb, dens * 0.42), mix(a * (1.0 - 0.45 * shade), petal, best), detail);
				// A bloom is smooth, the leaves' normal map not on it, and domed: its normal leans out to its rim.
				n = normalize(mix(n, normalize(n0 + (b1 * dn.x + b2 * dn.y) * 0.8), best * detail));
			} else {
				a *= v_col.rgb;
			}
			// Under the outer leaves' layers, the inside of the growth.
#if defined(RT)
			a *= mix(1.0, 0.65, near_k);
#else
			a *= mix(1.0, 0.45, near_k);
#endif
		}
	} else if (kind == 4) {
		if (photo) {
			vec3 t = srgb(texture(tex, UV).rgb);
			vec2 mk = texture(mask_tex, UV).rg;
			a = mix(t, t * (skinned ? dye.rgb : v_col.rgb) / white_ref, mk.r);
			rough = clamp(mk.g, 0.35, 1.0);
			sh = 0.05;
#if !defined(RT) && CURRENT_RENDERER != RENDERER_COMPATIBILITY
			if (normal_strength > 0.0) {
				vec2 nm = (texture(normal_tex, UV).rg * 2.0 - 1.0) * normal_strength;
				vec3 tw = (INV_VIEW_MATRIX * vec4(TANGENT, 0.0)).xyz;
				vec3 bw = (INV_VIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz;
				n = normalize(tw * nm.x + bw * nm.y + n * sqrt(max(1.0 - dot(nm, nm), 0.0)));
			}
#endif
		} else if (part == 0) {
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
	float fade = exp(-dist / haze_distance);
#if defined(RT)
	// What the surface is made of, for the path tracer to light: its colour, its normal (in view space, as
	// the rasterizer's NORMAL), how rough, the haze over it as painted. The rays flip a back face's normal,
	// so the flips above for bark and figures come undone, and a leaf keeps its crown's normal on either
	// side of its card, as the rasterizer draws it.
	if (!FRONT_FACING && (kind == 0 || kind == 1 || kind == 4)) {
		n = -n;
	}
	ALBEDO = min(a, vec3(0.9)) * fade;
	EMISSION = haze * (1.0 - fade);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ROUGHNESS = kind == 1 ? 0.55 : (kind == 3 ? 0.4 : (kind == 4 && photo ? rough : (kind == 4 && part == 0 ? 0.5 : (kind == 2 ? (shell > 0.0 ? 0.55 : (lumps > 0.0 ? 0.6 : 0.75)) : 0.9))));
	SPECULAR = kind == 0 ? 0.3 : 0.5;
	// Light through a leaf (the fork's rt_foliage.py): yellower than what it reflects, as a lime's leaf held up
	// to a lamp.
	BACKLIGHT = kind == 1 ? a * vec3(0.75, 0.9, 0.45) : vec3(0.0);
#else
	float ndl = dot(n, l);
	float diff = kind == 1 ? clamp(ndl * (1.0 - wrap) + wrap, 0.0, 1.0) : max(ndl, 0.0);
	vec3 lc = srgb(lamp_colour);
	// A photographed person takes the sky's light more from above than from below, so that its shape reads in it.
	vec3 amb = kind == 4 && photo ? ambient * (0.55 + 0.45 * n.y) : ambient;
	vec3 col = a * (amb + core_light * core_energy * diff + lc * lamps(v_wpos) * lamp_energy);
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
	ALBEDO = mix(haze, col, fade);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	ALBEDO = pow(max(ALBEDO, vec3(0.0)), vec3(1.0 / 2.2));
#endif
#endif
}
