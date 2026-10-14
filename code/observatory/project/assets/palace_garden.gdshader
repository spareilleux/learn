shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;

// The palace gardens of Trantor seen through the hall's two glazed bays (scripts/palace_gardens.gd):
// the terrace outside, the parterre below it, the trees, the water, the palace and the domed city
// round the grounds. As assets/upperside.gdshader, it lights itself: the galactic core (core_dir), a
// faint sky ambient and the garden's own lamps, so no light is added to the scene and the hall stays
// as it was. Distance fades into the haze over the horizon. Small details fade to their average
// before they are a few pixels wide, so that nothing far off shimmers as the view moves.
//   kind 0: built stone, with rows of lit windows (windows > 0) and floodlit from below (uplight),
//           tinted by COLOR
//   kind 1: the terrace's paving, square slabs
//   kind 2: the parterre: gravel walks and clipped box drawn in scrolls, the walks lamp-lit
//   kind 3: foliage, tinted per instance (COLOR), in clumps
//   kind 4: water, mirroring the sky and the lamps
//   kind 5: a lamp's globe, its own light

uniform int kind = 0;
uniform vec3 albedo : source_color = vec3(0.6, 0.57, 0.52);
uniform float sheen = 0.05;
uniform float windows = 0.0;      // the share of lit windows
uniform vec3 window_colour : source_color = vec3(1.0, 0.76, 0.46);
uniform float window_energy = 1.4;
uniform vec3 window_cell = vec3(4.0, 4.5, 4.0);   // metres between windows, and between floors
uniform float districts = 0.0;    // 1: windows lit by districts rather than evenly (the city)
uniform float uplight = 0.0;      // floodlights at the foot of a facade
uniform float base_y = -5.0;      // the ground the facade stands on
uniform vec3 core_dir = vec3(-0.468, 0.867, -0.170);
// Linear light values (see assets/upperside.gdshader).
uniform vec3 core_light = vec3(0.9, 0.8, 0.66);
uniform float core_energy = 0.35;
uniform vec3 ambient = vec3(0.07, 0.08, 0.11);
uniform vec3 lamp_colour : source_color = vec3(1.0, 0.72, 0.42);
uniform float lamp_energy = 1.5;
// The lamps: along the parterre's middle walk (x = +-walk_x, every lamp_step from lamp_z0 to lamp_z1),
// and along the terrace's edge (radius terrace_r, one every lamp_arc radians).
uniform float walk_x = 7.0;
uniform float lamp_step = 14.0;
uniform float lamp_z0 = 36.0;
uniform float lamp_z1 = 176.0;
uniform float lamp_y = -1.8;
uniform float terrace_r = 24.0;
uniform float lamp_arc = 0.1309;  // 7.5 degrees
uniform float terrace_y = 1.1;
uniform float terrace_reach = 3.5;  // metres: a terrace lamp's pool
// Stone in detail (kinds 0 and 1, when stone_detail > 0): a generated photograph of stone divided by its mean
// colour, stored halved (0.5: no change; artpass/gardens/NOTES.md), so that the material keeps its own
// albedo. It does not tile: each slab, and each block of the retaining wall, takes its own window of it,
// at random, and the joints hide where windows meet. Above wall_top (the balustrade), blocks 1.2 m long
// with no joints drawn.
uniform sampler2D detail_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float stone_detail = 0.0;
uniform vec2 ashlar = vec2(1.2, 0.5);   // the wall's blocks: length and course height, metres
uniform float wall_top = -0.35;
uniform vec3 haze = vec3(0.016, 0.02, 0.036);
uniform float haze_distance = 900.0;
uniform vec3 sky_low : source_color = vec3(0.05, 0.06, 0.11);  // the sky over the city's glow
uniform float time_scale = 1.0;
// The water mirrors the palace's painted card (assets/garden_card.gdshader) where a reflected ray meets
// it: the card stands in the plane z = palace_z, from x0 to x1 and y0 to y1 (palace_rect), the image's
// left at x1 (the card is turned round to face the hall). No card: palace_rect's width is 0.
uniform sampler2D palace_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 palace_rect = vec4(0.0);
uniform float palace_z = 430.0;
uniform float palace_energy = 1.0;

// The parterre modelled (kind 2, parterre_kit 1; scripts/palace_gardens.gd _build_parterre_kit): its box and
// yews are meshes; here the ground under them, from generated tiles (artpass/foundation/gardens/tileable.py):
// the walks' gravel, crushed brick in each compartment's broderie, earth and flowers in its bed, the lawns
// beyond; darkened round the box by parterre_ao (parterre_export.py: per variant, plain then notched, 10 px a
// metre over the compartment and 1.5 m round it). The compartments as scripts/parterre_layout.gd places
// them: 52 x 28 m from 10 m off the axis, every 32 m from z 30; the second and third cut by the basin's walk,
// a disc of 20 m about (0, 92), the third mirrored.
uniform float parterre_kit = 0.0;
uniform sampler2D walk_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D brick_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D lawn_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D parterre_ao : hint_default_white, filter_linear_mipmap, repeat_disable;
uniform vec3 tile_span = vec3(1.6, 0.7, 2.4);       // metres a tile spans: walk, brick, lawn
uniform vec3 walk_tint = vec3(0.62, 0.66, 0.72);    // linear, times the tile: the gravel's albedo
uniform vec3 brick_tint = vec3(0.62);
uniform vec3 lawn_tint = vec3(0.8);
uniform vec2 bed = vec2(0.2, 1.75);                 // the bed's lines of box, in from the compartment's edge
// The basin's fountain lit from under the water (kind 4; make_basin.py): its middle at (x, z), six jets on a
// ring of radius z round it, the light's strength w (0: none).
uniform vec4 jet_light = vec4(0.0, 95.0, 8.0, 0.0);
// The ripples' tilt on the water outside the round basin (kind 4): at the basin's 0.08 the canal broke the
// palace's reflection into gold stripes (artpass/foundation/shots/basin/live-canal-before.png); the
// modelled basin sets it lower, the canal still enough to mirror the palace, the basin ruffled by its jets.
uniform float still_ruffle = 0.08;
// The fountain show's jets, mirrored in the water's plane and seen from the camera (kind 4;
// scripts/fountain_show.gd draws them into this, the size of the screen or less): added as their
// reflection, shaken by the ripples; show_mirror_k 0: none.
uniform sampler2D show_mirror : filter_linear, repeat_disable;
uniform float show_mirror_k = 0.0;

// A lamp's glass (kind 5) flickering by this share, each instance at its own pace, as a flame would.
uniform float flicker = 0.0;
// A lamp's globe (kind 5) never smaller than this angle across, in radians (0: as built): far off, a
// globe under a pixel would flicker as the view moves; it grows about its middle instead, so that the
// avenues' lamps stay points of light out to the woods, and stay their own size beside a rider.
uniform float min_angle = 0.0;

varying vec3 v_wpos;
varying vec3 v_origin;
varying vec3 v_wnorm;
varying vec3 v_local;
varying vec4 v_tint;

void vertex() {
	if (min_angle > 0.0) {
		// The mesh is a unit sphere scaled: its first axis's length is the globe's size.
		float size = max(length(MODEL_MATRIX[0].xyz), 1e-4);
		float d = length(MODEL_MATRIX[3].xyz - INV_VIEW_MATRIX[3].xyz);
		VERTEX *= max(1.0, d * min_angle / size);
	}
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_origin = MODEL_MATRIX[3].xyz;
	v_wnorm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	v_local = VERTEX;
	v_tint = COLOR;
}

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

// A lamp at q lighting p: falls off with distance, as a pool on the ground.
float pool(vec3 p, vec3 q, float reach) {
	vec3 d = p - q;
	return exp(-dot(d, d) / (reach * reach));
}

// The garden's own light at p: the two nearest walk lamps and the nearest terrace lamp.
float lamps(vec3 p) {
	float zl = clamp(lamp_z0 + lamp_step * floor((p.z - lamp_z0) / lamp_step + 0.5), lamp_z0, lamp_z1);
	float l = pool(p, vec3(walk_x, lamp_y, zl), 6.0) + pool(p, vec3(-walk_x, lamp_y, zl), 6.0);
	float a = atan(p.z, p.x);
	float al = lamp_arc * floor(a / lamp_arc + 0.5);
	l += pool(p, vec3(cos(al) * terrace_r, terrace_y, sin(al) * terrace_r), terrace_reach) * 0.8;
	return l;
}

// The parterre's box, drawn in scrolls: 1 on the hedge, 0 on the gravel. Mirrored on the middle walk
// and repeated every 24 m down the garden.
float broderie(vec2 p) {
	vec2 q = vec2(abs(p.x), p.y);
	if (q.x < walk_x + 3.0 || q.x > 66.0 || p.y < 30.0 || p.y > 158.0) {
		return 0.0;
	}
	vec2 c = vec2(q.x - 10.0, mod(p.y - 30.0, 32.0)) ;  // one compartment, 56 x 32 m, 4 m walks round it
	if (c.x > 52.0 || c.y > 28.0) {
		return 0.0;
	}
	vec2 u = c - vec2(26.0, 14.0);
	float hedge = 0.0;
	// The compartment's edging.
	vec2 e = abs(u) - vec2(25.0, 13.0);
	hedge = max(hedge, 1.0 - smoothstep(0.35, 0.6, abs(max(e.x, e.y))));
	// Two scrolls in it, mirrored: rings of box round an empty eye.
	vec2 s = vec2(abs(u.x) - 12.0, u.y);
	float r = length(s);
	float ang = atan(s.y, s.x);
	float spiral = abs(fract((r - ang * 1.6) / 4.0) - 0.5) * 4.0;
	hedge = max(hedge, (1.0 - smoothstep(0.35, 0.6, spiral)) * step(1.5, r) * (1.0 - step(10.5, r)));
	// A lozenge in the middle.
	float lz = abs(u.x) * 0.5 + abs(u.y);
	hedge = max(hedge, 1.0 - smoothstep(0.35, 0.6, abs(lz - 5.0)));
	return hedge;
}

vec3 to_linear(vec3 c) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There, a source_color texture arrives in sRGB.
	return pow(max(c, vec3(0.0)), vec3(2.2));
#else
	return c;
#endif
}

// A ground tile at p (metres), span metres across: two readings of it, the second turned and larger, mixed
// by a slow noise, and a slow change of brightness, so that no grid shows from the terrace.
vec3 ground_tile(sampler2D t, vec2 p, float span) {
	vec2 u = p / span;
	vec2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p / (span * 1.37) + 0.37;
	float k = smoothstep(0.3, 0.7, noise2(p / (span * 3.1)));
	vec3 c = mix(to_linear(texture(t, u).rgb), to_linear(texture(t, r).rgb), k);
	return c * (0.85 + 0.3 * noise2(p / (span * 5.3) + 7.1));
}

// The parterre's ground at p (x, z) with the kit; m_px: metres a pixel spans there. Every texture is read
// whatever the place, outside any branch, so that their mipmaps' derivatives hold at the compartments' edges.
vec3 parterre_ground(vec2 p, float m_px) {
	vec3 walk = ground_tile(walk_tex, p, tile_span.x) * walk_tint;
	vec3 brick = ground_tile(brick_tex, p, tile_span.y) * brick_tint;
	float ci = floor((p.y - 28.0) / 32.0);
	vec2 q = vec2(abs(p.x) - 36.0, p.y - (44.0 + 32.0 * ci));
	bool notched = ci == 1.0 || ci == 2.0;
	q.y *= ci == 2.0 ? -1.0 : 1.0;
	vec2 uv = vec2((q.x + 27.5) / 55.0, ((15.5 - q.y) / 31.0 + (notched ? 1.0 : 0.0)) * 0.5);
	float occ = texture(parterre_ao, clamp(uv, 0.0, 1.0)).r;
	if (ci < 0.0 || ci > 3.0 || abs(q.x) > 27.5 || abs(q.y) > 15.5) {
		return walk;
	}
	// How far in from the compartment's edge, or from the basin's walk.
	float e = min(26.0 - abs(q.x), 14.0 - abs(q.y));
	if (notched) {
		e = min(e, length(q - vec2(-36.0, 16.0)) - 20.0);
	}
	float w = 0.5 * m_px + 0.02;
	// The bed: earth, under its mound of flowers (make_parterre.py); flowers drawn here read as confetti
	// (live-03).
	vec3 bed_col = vec3(0.04, 0.028, 0.02) * (0.8 + 0.4 * noise2(p * 6.0));
	vec3 col = mix(walk, bed_col, smoothstep(bed.x - w, bed.x + w, e));
	col = mix(col, brick, smoothstep(bed.y - w, bed.y + w, e));
	// The ground darkened round the box and the yews.
	return col * occ;
}

void fragment() {
	vec3 n = normalize(v_wnorm);
	if (!FRONT_FACING) {
		n = -n;
	}
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	vec3 to_eye = eye - v_wpos;
	float dist = length(to_eye);
	vec3 v = to_eye / max(dist, 1e-4);
	vec3 l = normalize(core_dir);
	float m_px = max(length(dFdx(v_wpos)), length(dFdy(v_wpos))) + 1e-5;

	vec3 a = albedo;
	vec3 wc = window_colour;
	vec3 lc = lamp_colour;
	vec3 sl = sky_low;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There, the uniform colours arrive as they were set, in sRGB (assets/upperside.gdshader).
	a = pow(a, vec3(2.2));
	wc = pow(wc, vec3(2.2));
	lc = pow(lc, vec3(2.2));
	sl = pow(sl, vec3(2.2));
#endif
	float sh = sheen;
	float lamp_k = 1.0;
	vec3 glow = vec3(0.0);
	if (kind == 0) {
		// Stone and bronze boxes of several colours share one MultiMesh, each tinted (linear, white
		// without a colour).
		a *= v_tint.rgb;
		if (stone_detail > 0.0) {
			// On top faces, blocks laid flat; on the others, round the hall (along the circle) and up.
			vec3 an = abs(n);
			bool top = an.y > 0.7;
			vec2 s = top ? v_wpos.xz : vec2(atan(v_wpos.z, v_wpos.x) * length(v_wpos.xz), v_wpos.y);
			bool wall = !top && v_wpos.y < wall_top;
			vec2 size = top ? vec2(1.2) : (wall ? ashlar : vec2(1.2, 2.0));
			vec2 b = vec2(s.x, wall ? s.y : s.y - wall_top) / size;
			if (wall) {
				b.x += 0.5 * mod(floor(b.y), 2.0);  // courses staggered by half a block
			}
			vec2 cell = floor(b);
			vec2 win = size / 2.4;
			vec2 uv = fract(b) * win + vec2(hash12(cell + 3.1), hash12(cell + 7.7)) * (1.0 - win);
			a *= mix(vec3(1.0), textureGrad(detail_tex, uv, dFdx(b) * win, dFdy(b) * win).rgb * 2.0, stone_detail);
			if (wall) {
				vec2 f = abs(fract(b) - 0.5);
				vec2 w = (0.006 + 0.5 * m_px) / size;
				float joint = max(smoothstep(0.5 - w.x, 0.5, f.x), smoothstep(0.5 - w.y, 0.5, f.y)) * (1.0 - smoothstep(0.05, 0.12, m_px));
				a *= 1.0 - 0.5 * joint;
			}
		}
	} else if (kind == 1) {
		// Slabs 1.2 m square, joints darker, each slab a little different.
		vec2 q = v_wpos.xz / 1.2;
		vec2 f = abs(fract(q) - 0.5);
		float w = 0.03 + m_px / 1.2;
		float joint = smoothstep(0.5 - w, 0.5, max(f.x, f.y)) * (1.0 - smoothstep(0.06, 0.15, m_px));
		a *= (0.9 + 0.2 * hash12(floor(q))) * (1.0 - 0.4 * joint);
		if (stone_detail > 0.0) {
			// Each slab its own window, a little under half the image across.
			vec2 cell = floor(q);
			vec2 uv = fract(q) * 0.45 + vec2(hash12(cell + 3.1), hash12(cell + 7.7)) * 0.55;
			a *= mix(vec3(1.0), textureGrad(detail_tex, uv, dFdx(q) * 0.45, dFdy(q) * 0.45).rgb * 2.0, stone_detail);
		}
	} else if (kind == 2 && parterre_kit > 0.0) {
		a = parterre_ground(v_wpos.xz, m_px);
		// The lawns either side of the parterre, and the grass beyond.
		float lawn = smoothstep(66.0, 67.0, abs(v_wpos.x));
		a = mix(a, ground_tile(lawn_tex, v_wpos.xz, tile_span.z) * lawn_tint, lawn);
	} else if (kind == 2) {
		vec3 gravel = a * (0.92 + 0.16 * noise2(v_wpos.xz * 2.0));
		vec3 box = vec3(0.035, 0.07, 0.03);  // linear, as every constant here
		// Far off, the scrolls' average: a tone between box and gravel.
		float detail = 1.0 - smoothstep(0.15, 0.45, m_px);
		float b = broderie(v_wpos.xz);
		float avg = (abs(v_wpos.x) > walk_x + 3.0 && abs(v_wpos.x) < 66.0 && v_wpos.z > 30.0 && v_wpos.z < 158.0) ? 0.3 : 0.0;
		a = mix(gravel, box, mix(avg, b, detail));
		// The lawns either side of the parterre, and the grass beyond.
		vec3 grass = vec3(0.05, 0.085, 0.04);
		float lawn = smoothstep(66.0, 67.0, abs(v_wpos.x));
		a = mix(a, grass * (0.85 + 0.3 * noise2(v_wpos.xz * 0.3)), lawn);
	} else if (kind == 3) {
		// Leaves in clumps: brighter where a clump faces the light, darker in the hollows.
		// Instance colours reach the shader as they were set, under either renderer: linear here.
		vec3 tint = v_tint.rgb;
		float clump = noise2(v_wpos.xz * 1.3 + v_wpos.y * 0.9) * 0.6 + noise2(v_wpos.xz * 4.1 - v_wpos.y * 2.3) * 0.4;
		float detail = 1.0 - smoothstep(0.08, 0.3, m_px);
		a = tint * mix(1.0, 0.6 + 0.8 * clump, detail);
		// Close to, leaves in small clusters: a near crown read as a flat ball (artpass/bays/v6-fwd).
		float leaf = noise2(v_wpos.xz * 9.0 + v_wpos.y * 7.0) * noise2(v_wpos.zx * 13.0 - v_wpos.y * 11.0);
		float fine = 1.0 - smoothstep(0.015, 0.05, m_px);
		a *= mix(1.0, 0.45 + 1.6 * leaf, fine);
		// Inside the crown, the light does not reach: darker low and towards the trunk.
		a *= mix(0.55, 1.0, clamp(v_local.y + 0.5, 0.0, 1.0));
		// Oranges on the orange trees, whose instance colour has alpha 0: a few small fruit among the
		// leaves, up close only.
		// Round: a ball 9 cm across in one 14 cm cell in ten, cut by the crown's surface.
		vec3 fc = v_wpos * 7.0;
		float ball = 1.0 - smoothstep(0.26, 0.34, length(fract(fc) - 0.5));
		float fruit = (1.0 - v_tint.a) * fine * step(0.9, hash13(floor(fc))) * ball * step(-0.25, v_local.y);
		a = mix(a, vec3(0.75, 0.22, 0.02), fruit);
		sh = 0.0;
	} else if (kind == 4) {
		// The sky's low glow and the lamps, mirrored, broken by ripples.
		vec2 rip = vec2(noise2(v_wpos.xz * 0.7 + TIME * 0.3 * time_scale), noise2(v_wpos.zx * 0.9 - TIME * 0.25 * time_scale)) - 0.5;
		float ruffle = mix(still_ruffle, 0.08, 1.0 - smoothstep(13.0, 14.5, length(v_wpos.xz - jet_light.xy)));
		vec3 nn = normalize(vec3(rip.x * ruffle, 1.0, rip.y * ruffle));
		vec3 r = reflect(-v, nn);
		float fres = 0.02 + 0.98 * pow(1.0 - clamp(dot(nn, v), 0.0, 1.0), 5.0);
		vec3 sky = mix(sl * 1.6, sl * 0.4, clamp(r.y * 3.0, 0.0, 1.0));
		vec3 col;
		if (palace_rect.y > palace_rect.x) {
			// The palace, where the reflected ray meets its card; sampled everywhere (derivatives need
			// it), kept only inside.
			float t = (palace_z - v_wpos.z) / max(r.z, 1e-3);
			vec3 p = v_wpos + r * t;
			vec2 uv = vec2((palace_rect.y - p.x) / (palace_rect.y - palace_rect.x), (palace_rect.w - p.y) / (palace_rect.w - palace_rect.z));
			float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0) * step(1e-3, r.z);
			vec4 pt = texture(palace_tex, clamp(uv, 0.0, 1.0));
			vec3 pc = pt.rgb;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
			pc = pow(pc, vec3(2.2));
#endif
			col = mix(sky * 2.0, pc * palace_energy, pt.a * inside) * fres + a * 0.15;
		} else {
			// The palace's lit windows, a warm band in the water below them.
			float band = (1.0 - smoothstep(0.0, 0.08, abs(r.y - 0.03))) * smoothstep(0.0, 0.2, r.z);
			col = sky * fres * 2.0 + wc * band * 0.25 * fres * 4.0 + a * 0.15;
		}
		col += lc * lamps(v_wpos) * lamp_energy * 0.25;
		if (jet_light.w > 0.0) {
			// Pools of warm light round the fountain's foot and round each jet's, broken by the ripples.
			vec2 d0 = v_wpos.xz - jet_light.xy;
			float r = length(d0);
			float aj = 1.0471976 * floor(atan(d0.y, d0.x) / 1.0471976 + 0.5);
			vec2 dj = v_wpos.xz - (jet_light.xy + jet_light.z * vec2(cos(aj), sin(aj)));
			float g = exp(-max(r - 3.2, 0.0) * max(r - 3.2, 0.0) / 6.0) * 0.8 + exp(-dot(dj, dj) / 1.5);
			col += lc * jet_light.w * g * (0.7 + 0.6 * rip.x);
		}
		if (show_mirror_k > 0.0) {
			// The show's jets in the water, drawn out towards the eye by finer ripples than the palace's, which
			// move them less the further off they are. Shaken by the large ripples alone, 0.9 / dist of the
			// screen, the water by the walk was marbled paper (shots/show/a2 side_t018).
			vec2 fine = vec2(noise2(v_wpos.xz * 3.1 + TIME * 0.6 * time_scale), noise2(v_wpos.zx * 2.3 - TIME * 0.5 * time_scale)) - 0.5;
			vec3 jets = texture(show_mirror, SCREEN_UV + (fine * vec2(0.25, 0.7) + rip * 0.1) / max(dist, 6.0)).rgb;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
			jets = pow(jets, vec3(2.2));
#endif
			col += jets * show_mirror_k * (0.1 + 0.9 * fres);
		}
		float fade = exp(-dist / haze_distance);
		ALBEDO = mix(haze, col, fade);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		ALBEDO = pow(max(ALBEDO, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	} else if (kind == 5) {
		float fl = 1.0;
		if (flicker > 0.0) {
			float ph = hash12(floor(v_origin.xz * 4.0)) * 40.0;
			fl += flicker * (sin(TIME * 7.0 + ph) * 0.6 + sin(TIME * 17.0 + ph * 1.7) * 0.4);
		}
		ALBEDO = lc * lamp_energy * 3.0 * fl;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		ALBEDO = pow(max(ALBEDO, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	}
	if (kind != 4 && kind != 5) {
		vec3 col = a * (ambient + core_light * core_energy * max(dot(n, l), 0.0) + lc * lamps(v_wpos) * lamp_energy * lamp_k);
		vec3 h = normalize(l + v);
		col += core_light * core_energy * sh * pow(max(dot(n, h), 0.0), 32.0);
		if (uplight > 0.0) {
			// Floodlit from its foot: warm, fading up the facade.
			float up = exp(-max(v_wpos.y - base_y, 0.0) / 14.0);
			col += a * lc * uplight * up * (1.0 - smoothstep(0.7, 0.95, abs(n.y)));
		}
		if (windows > 0.0) {
			// Rows of windows on the facades, most of them lit; far off, their average glow.
			vec3 cell = floor(v_wpos / window_cell);
			vec3 f = fract(v_wpos / window_cell);
			float side = 1.0 - smoothstep(0.55, 0.8, abs(n.y));
			float share = windows;
			if (districts > 0.0) {
				// By districts of 5 x 5 cells: some dark, most dim, a few bright.
				float d = hash13(floor(v_wpos / (window_cell * 5.0)) + 17.0);
				share = windows * mix(1.0, smoothstep(0.35, 0.95, d) * 2.2, districts);
			}
			float lit = step(1.0 - share, hash13(cell));
			bool x_across = abs(n.x) > abs(n.z);
			float across = x_across ? f.z : f.x;
			// Each pane's edges blurred over a pixel, so that panes a few pixels wide neither shimmer nor
			// vanish; the average once a floor is under three pixels. An average from further in made the
			// city's domes far off read as pale hills (artpass/bays/v4-fwd).
			float wy = m_px / window_cell.y;
			float hx = 0.5 * m_px / (x_across ? window_cell.z : window_cell.x);
			float hy = 0.5 * wy;
			float pane = (smoothstep(0.25 - hy, 0.25 + hy, f.y) - smoothstep(0.75 - hy, 0.75 + hy, f.y))
				* (smoothstep(0.3 - hx, 0.3 + hx, across) - smoothstep(0.7 - hx, 0.7 + hx, across));
			float near = 1.0 - smoothstep(0.3, 0.5, wy);
			glow = wc * window_energy * side * mix(share * 0.2, lit * pane, near);
		}
		float fade = exp(-dist / haze_distance);
		ALBEDO = mix(haze, col, fade) + glow * mix(0.3, 1.0, fade);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		ALBEDO = pow(max(ALBEDO, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	}
}
