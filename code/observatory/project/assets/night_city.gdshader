shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled, cull_back;

// Trantor at night round the palace grounds (scripts/night_city.gd; the author, 2026-10-12: "un panorama
// nocturne de Trantor, bleu-cyan, avec des tours et de grandes structures circulaires"). Everything here
// lights itself, as the gardens do: dark shells, their windows lit storey by storey, cyan lines along a
// few roofs and round the great rings, traffic running round the raised ones, a lit mist low among the
// towers, and the air's blue haze with distance. It adds no light to the scene and casts nothing.
//   shape 0: a box (a unit cube scaled by its instance or node);
//   shape 1: something round: a unit cylinder scaled, or a ring modelled in metres (ring_r > 0), its
//            windows round it, its edges lined in cyan;
//   shape 3: a penthouse (lit 1): glass lit from within, mullions, its floors; or the slab over it (lit 0),
//            its edge a line of light (scripts/night_city.gd _roof);
//   shape 4: a pool on a roof: lit water, glass sides; one reaching out past its roof glows underneath too;
//   shape 5: light itself: the landmarks' bands and edges, in `rim` (or warm), at rim_energy;
//   shape 2: the ground under the city, seen from above: its lights at night from `aerial`, a map of the
//            whole city drawn offline (artpass/foundation/city: districts and boulevards from ix, refined
//            with ComfyUI); without it, streets of lights in 60 m blocks.
// `instanced`: a MultiMesh's INSTANCE_CUSTOM gives each tower (seed, share of windows lit, share of them
// warm, 1 for a cyan line round its roof); otherwise the uniforms do.
// Windows smaller than about two pixels are drawn as their average, so that a far facade does not crawl
// as the view moves (artpass/motion/NOTES.md). All colours are linear: Compatibility converts no
// source_color, and gets the tone curve Forward+ applies to the frame (as palace_glow.gdshader).

uniform int shape = 0;
uniform bool instanced = false;
uniform vec3 body = vec3(0.005, 0.009, 0.018);
uniform vec3 window_cool = vec3(0.42, 0.78, 1.0);
uniform vec3 window_warm = vec3(1.0, 0.62, 0.28);
uniform vec2 cell = vec2(6.0, 6.5);          // m: a window's bay and storey
uniform vec2 pane = vec2(0.36, 0.3);         // of the cell, glazed
uniform float lit = 0.3;
uniform float warm = 0.1;
uniform float window_energy = 2.4;
uniform float seed = 0.0;
uniform float rim_on = 1.0;
uniform vec3 rim = vec3(0.10, 0.78, 1.0);
uniform float rim_energy = 2.0;
uniform float rim_width = 1.2;               // m
uniform vec2 ring_r = vec2(0.0, 0.0);        // a ring's inner and outer radii (m); 0: a unit cylinder
uniform vec2 band = vec2(-1e6, 1e6);         // a ring's wall, foot and top (m, in the mesh)
uniform float traffic = 0.0;                 // a raised ring: lights running round its top
uniform vec3 haze = vec3(0.006, 0.026, 0.075);
uniform float haze_distance = 4600.0;
uniform vec3 mist = vec3(0.018, 0.085, 0.22);
uniform float mist_height = 70.0;            // m over the city's ground
uniform float mist_energy = 0.2;
uniform float ground_y = -12.0;
uniform float energy = 1.0;
// shape 2: the rings of light round the great structures, (x, z, radius, width) each.
uniform vec4 rings[8];
uniform int ring_count = 0;
uniform sampler2D aerial : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool has_aerial = false;
uniform float plan_extent = 3200.0;          // m: `aerial` covers x and z in [-plan_extent, plan_extent]
uniform float aerial_energy = 1.0;
// Facades from photographs made with ComfyUI (artpass/foundation/city/make_facades.py): an atlas of 4 x 2
// tiles, each a kind of building at night, tileable. A tower takes one by its seed; its walls slide each
// tile-high band along, and light each band more or less, so that no two towers and no two bands match.
uniform sampler2D facades : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_facades = false;
uniform int facade_style = -1;               // -1: from the seed; 0 to 7, that tile
uniform float facade_tile = 42.0;            // m of wall a tile covers
uniform bool round_mesh = false;
uniform bool use_uv = false;                 // shape 0: the mesh's UV is its wall in metres (the landmarks)             // shapes 3: the mesh is the unit cylinder, not the cube

varying vec3 v_local;
varying vec3 v_size;
varying vec3 v_n;
varying vec3 v_world;
varying vec4 v_custom;
varying vec2 v_uv;

void vertex() {
	v_size = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	v_local = VERTEX * v_size;
	v_n = NORMAL;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_custom = INSTANCE_CUSTOM;
	v_uv = UV;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// The integral of a pulse train (on over the middle w of each period), for a box filter.
float pulse_int(float x, float w) {
	return floor(x) * w + clamp(fract(x) - (1.0 - w) * 0.5, 0.0, w);
}

// The share of [x - fw/2, x + fw/2] inside the pulses: 0 or 1 when sharp, w when blurred.
float pulse(float x, float w, float fw) {
	fw = max(fw, 1e-4);
	return (pulse_int(x + fw * 0.5, w) - pulse_int(x - fw * 0.5, w)) / fw;
}

#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
// Godot's fit of ACES (main.tscn: tonemap_mode 3, exposure 0.95), as palace_glow.gdshader.
vec3 aces(vec3 x) {
	x *= 1.8 * 0.95;
	vec3 y = (x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081);
	return max(y, vec3(0.0)) / 0.78107;
}
#endif

// A facade's windows at (u, v) metres, v up from the city's ground: lit by storeys and by chance, each lit
// one cool or warm, brighter or dimmer.
vec3 windows(vec2 uv, float s, float share, float warm_share) {
	vec2 g = uv / cell;
	vec2 id = floor(g);
	vec2 fw = fwidth(g);
	float h = hash12(id + vec2(s * 97.0, s * 13.0));
	// Whole storeys go dark together, as offices do at night.
	float storey = hash12(vec2(id.y, s * 61.0));
	float on = step(h, share * (storey < 0.3 ? 0.12 : 1.35));
	float mask = pulse(g.x, pane.x, fw.x) * pulse(g.y, pane.y, fw.y);
	vec3 tint = mix(window_cool, window_warm, step(hash12(id.yx + vec2(s * 29.0, 4.0)), warm_share));
	tint *= 0.5 + hash12(id + vec2(17.0, s * 5.0));
	float blur = smoothstep(0.45, 1.0, max(fw.x, fw.y));
	vec3 avg = mix(window_cool, window_warm, warm_share) * share * pane.x * pane.y;
	return mix(tint * on * mask, avg, blur);
}

// A wall's lit facade at (u, v) metres from the atlas, `face` telling a box's four walls apart.
vec3 facade(vec2 uv, float s, float share, float warm_share, float face) {
	int k = facade_style >= 0 ? facade_style : int(floor(hash12(vec2(s * 41.0, 2.0)) * 7.999));
	vec2 t = uv / (facade_tile * (0.85 + 0.35 * hash12(vec2(s * 5.0, 7.0))));
	float row = floor(t.y);
	t.x += hash12(vec2(row, s * 13.0 + face)) * 3.0;
	vec2 tile = vec2(float(k % 4), float(k / 4));
	vec2 scale = vec2(0.25, 0.5);
	// Inset a little from the tile's edges, and the derivatives of the unbroken coordinate, so that
	// neither the atlas's neighbours nor the wrap draw seams.
	vec2 a = (tile + 0.004 + fract(t) * 0.992) * scale;
	vec3 c = textureGrad(facades, a, dFdx(t) * scale, dFdy(t) * scale).rgb;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	c = pow(c, vec3(2.2));  // source_color is not linearised there
#endif
	float lvl = hash12(vec2(row * 3.1 + face, s * 7.0));
	c *= share / 0.22 * (0.3 + 1.2 * lvl * lvl);
	// Trantor's light is cool; a warm tower keeps its own.
	bool warm_tower = hash12(vec2(s * 3.0, 9.0)) < warm_share * 2.0;
	return warm_tower ? c * vec3(1.1, 0.95, 0.8) : c * vec3(0.7, 0.9, 1.25);
}

// A line of light `width` metres wide where d (metres from an edge) is 0, never under a pixel, its
// light spread when it is.
float edge_line(float d, float width) {
	float fw = fwidth(d);
	float w = max(width, fw * 1.2);
	return (1.0 - smoothstep(w * 0.5, w * 0.5 + fw, abs(d))) * min(1.0, width / w + 0.3);
}

void fragment() {
	vec3 n = normalize(v_n);
	vec3 c = body;
	float s = instanced ? v_custom.x : seed;
	float share = instanced ? v_custom.y : lit;
	float warm_share = instanced ? v_custom.z : warm;
	float edge = instanced ? v_custom.w : rim_on;
	if (shape == 5) {
		c += mix(rim, window_warm, warm) * rim_energy;
	} else if (shape == 3) {
		vec3 lc = mix(vec3(1.0, 0.86, 0.66), vec3(1.0, 0.6, 0.3), warm_share);
		float r = length(v_local.xz);
		float d = round_mesh ? v_size.x - r : min(v_size.x * 0.5 - abs(v_local.x), v_size.z * 0.5 - abs(v_local.z));
		if (share > 0.5 && abs(n.y) < 0.5) {
			// Floor-to-ceiling glass, every bay lit a little differently, the floors' slabs dark lines.
			float u = round_mesh ? atan(v_local.z, v_local.x) * r : (abs(n.x) > 0.5 ? v_local.z : v_local.x);
			float y = v_local.y + v_size.y * 0.5;
			float fu = u / 2.4;
			float fy = y / 4.2;
			float glass = (1.0 - pulse(fu, 0.1, fwidth(fu))) * (1.0 - pulse(fy, 0.14, fwidth(fy)));
			float bay = 0.55 + 0.8 * hash12(vec2(floor(fu), s * 31.0 + floor(fy)));
			c += lc * 2.4 * glass * mix(bay, 0.95, smoothstep(0.3, 1.0, max(fwidth(fu), fwidth(fy))));
			c += rim * edge_line(y - 0.2, 0.3) * 1.6;
		} else if (share < 0.5) {
			// The slab: its thin sides a line of light all round, its top edged in cyan, its underside
			// lit by the glass below.
			if (abs(n.y) < 0.5) {
				c += mix(rim, lc, 0.45) * 2.6;
			} else if (n.y < -0.5) {
				c += lc * 0.35;
			} else {
				c += rim * edge_line(d - 0.35, 0.35) * 2.2;
			}
		}
	} else if (shape == 4) {
		vec3 deep = vec3(0.02, 0.3, 0.4);
		vec3 bright = vec3(0.3, 0.95, 1.0);
		if (n.y > 0.5) {
			// Lit water, bands of light wandering over it; the coping lit round it.
			vec2 q = v_world.xz * 0.8;
			float k = sin(q.x + 1.7 * sin(q.y * 0.7 + TIME * 0.6)) * sin(q.y * 1.1 + 1.3 * sin(q.x * 0.5 - TIME * 0.5));
			float caus = mix(pow(abs(k), 4.0), 0.12, smoothstep(0.2, 1.0, fwidth(q.x)));
			c += mix(deep, bright, 0.3 + 0.7 * caus) * 1.5;
			float dd = min(v_size.x * 0.5 - abs(v_local.x), v_size.z * 0.5 - abs(v_local.z));
			c += vec3(1.0, 0.95, 0.85) * edge_line(dd - 0.25, 0.3) * 1.2;
		} else if (n.y < -0.5) {
			// Seen from below, a pool reaching out on glass glows; one on its roof is not seen.
			c += mix(deep, bright, 0.5) * 1.3 * edge;
		} else {
			c += mix(deep, bright, 0.45) * 1.4;
		}
	} else if (shape == 2 && has_aerial) {
		// From above: the city's map at night; the great rings round the structures in cyan.
		vec2 p = v_world.xz;
		vec3 t = texture(aerial, (p + plan_extent) / (2.0 * plan_extent)).rgb;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		t = pow(t, vec3(2.2));  // source_color is not linearised there
#endif
		c += t * aerial_energy;
		for (int i = 0; i < ring_count; i++) {
			vec4 r = rings[i];
			c += rim * edge_line(length(p - r.xy) - r.z, r.w) * 1.4;
		}
	} else if (shape == 2) {
		// From above: blocks 60 m across, their streets lit, their roofs dotted with lights; the great
		// rings round the structures in cyan.
		vec2 p = v_world.xz;
		vec2 g = p / 60.0;
		vec2 fw = fwidth(g);
		float street = 1.0 - pulse(g.x, 0.82, fw.x) * pulse(g.y, 0.82, fw.y);
		vec2 q = p / 9.0;
		vec2 qw = fwidth(q);
		float dots = pulse(q.x, 0.3, qw.x) * pulse(q.y, 0.3, qw.y) * step(hash12(floor(q) + 3.0), 0.3);
		dots = mix(dots, 0.027, smoothstep(0.35, 0.9, max(qw.x, qw.y)));
		c += window_cool * street * 0.12;
		c += mix(window_cool, window_warm, 0.35) * dots * (1.0 - street) * 0.7;
		for (int i = 0; i < ring_count; i++) {
			vec4 r = rings[i];
			c += rim * edge_line(length(p - r.xy) - r.z, r.w) * 1.4;
		}
	} else if (abs(n.y) < 0.5) {
		// A wall: windows across it, from the city's ground up.
		vec2 uv;
		float top;
		float r = length(v_local.xz);
		if (shape == 0) {
			uv.x = abs(n.x) > 0.5 ? v_local.z : v_local.x;
			top = v_size.y * 0.5 - v_local.y;
		} else {
			uv.x = atan(v_local.z, v_local.x) * r;
			top = ring_r.y > 0.0 ? min(band.y - v_local.y, v_local.y - band.x) : v_size.y * 0.5 - v_local.y;
		}
		uv.y = v_world.y - ground_y;
		if (use_uv) {
			uv = v_uv;
		}
		if (use_facades) {
			float face = shape == 0 && !use_uv ? (abs(n.x) > 0.5 ? 1.0 + step(0.0, n.x) : 3.0 + step(0.0, n.z)) : 0.0;
			c += facade(uv, s, share, warm_share, face) * window_energy;
		} else {
			c += windows(uv, s, share, warm_share) * window_energy;
		}
		// A cyan line under the roof, or round a ring's wall at its foot and top.
		c += rim * edge_line(top - rim_width * 0.5, rim_width) * rim_energy * edge;
		if (traffic > 0.0 && ring_r.y > 0.0 && r > ring_r.y - 1.0) {
			// Traffic round a raised ring, in two lanes, white one way and amber the other.
			float lane = step(0.0, v_local.y);
			float along = atan(v_local.z, v_local.x) * r / 22.0 + TIME * (lane > 0.5 ? 1.1 : -0.9);
			float f = fract(along);
			float car = smoothstep(0.0, 0.08, f) * (1.0 - smoothstep(0.12, 0.3, f)) * step(hash12(vec2(floor(along), lane)), 0.55);
			float fa = fwidth(along);
			car = mix(car, 0.12, smoothstep(0.25, 0.8, fa));
			float row = 1.0 - smoothstep(0.6, 1.2, abs(abs(v_local.y) - band.y * 0.45));
			c += mix(vec3(1.0, 0.95, 0.9), window_warm, lane) * car * row * traffic;
		}
	} else if (n.y > 0.5) {
		// A roof, dark, lined in cyan at its edges.
		float d;
		float r = length(v_local.xz);
		if (shape == 0) {
			vec2 h = v_size.xz * 0.5 - abs(v_local.xz);
			d = min(h.x, h.y);
		} else {
			d = (ring_r.y > 0.0 ? ring_r.y : v_size.x) - r;
			if (ring_r.x > 0.0) {
				d = min(d, r - ring_r.x);
			}
		}
		c += rim * edge_line(d - rim_width, rim_width) * rim_energy * edge;
	} else if (shape == 1) {
		// A ring's underside, lit from below by the city.
		c += mist * 0.35;
	}
	// The mist low among the towers, lit by the streets.
	c += mist * exp(-max(v_world.y - ground_y, 0.0) / mist_height) * mist_energy;
	// The air's blue haze with distance.
	float fade = exp(-length(VERTEX) / haze_distance);
	c = mix(haze, c, fade);
	c *= energy;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	ALBEDO = pow(aces(c), vec3(1.0 / 2.2));
#else
	ALBEDO = c;
#endif
}
