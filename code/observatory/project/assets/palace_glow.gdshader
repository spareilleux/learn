shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// Light that is only light, added over what is behind it (scripts/palace_gardens.gd): the fountains'
// jets, the city's glow over the horizon, and the light falling through the bays' coloured fanlights
// into the hall. Mesh UV.y runs from 0 at the top to 1 at the foot; the colour fades out towards the
// edges and, by `fade_top` and `fade_foot`, towards either end.
//   mode 0: a soft sheet or shaft; mode 1: a jet of water, broken into drops that rise and fall;
//   mode 2: the maze's lanterns' light on its walk, read from the lantern map (palace_gardens.gd
//   _lantern_map: B is the root of the light's strength, stopped by the hedges)
//   mode 3: water turned round an axis, a jet or a veil falling from a vasque (artpass/foundation/gardens/
//   make_basin.py): UV.x round it, UV.y along the flow, 0 at the nozzle, 1 at its end (make_basin.py
//   writes v the other way; glTF flips it); threads of drops running with the flow, brighter where it
//   is seen edge-on (more water along the line of sight), lit warm from the light under the water at
//   its nozzle (foot_colour, foot_glow)

uniform int mode = 0;
uniform sampler2D lantern_map : filter_linear, repeat_disable;
uniform vec4 lantern_rect = vec4(0.0, 0.0, 1.0, 1.0);  // the map's corner (x, z) and 1 / its size
uniform vec3 colour : source_color = vec3(0.6, 0.8, 1.0);
uniform float energy = 0.3;
uniform float fade_top = 0.15;
uniform float fade_foot = 0.3;
uniform float edge = 0.35;        // the share of the width over which the sides fade
uniform float time_scale = 1.0;
// Near the eye a shaft would fill the screen: it fades out between these distances.
uniform float near_fade_from = 0.5;
uniform float near_fade_to = 2.5;
uniform vec3 foot_colour : source_color = vec3(1.0, 0.78, 0.45);
uniform float foot_glow = 0.0;
// mode 3: threads of water round the axis (a whole number, so that they meet where UV.x wraps), and the
// even film between them.
uniform float lanes = 64.0;
uniform float mist = 0.05;
// mode 3: a rising jet's column, solid water from its nozzle to where it begins to break up, nozzle_to
// along the flow from its end (1 - UV.y): this much film there, fading to `mist` beyond.
uniform float nozzle_film = 0.0;
uniform float nozzle_to = 0.5;

varying vec3 v_wpos;
varying vec3 v_tint;
varying vec3 v_n;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_tint = COLOR.rgb;  // a mesh's vertex colour tints it: white without one
	v_n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
// Godot's fit of ACES (main.tscn: tonemap_mode 3, exposure 0.95), less its colour matrices. Forward+
// applies it to the whole frame; Compatibility applies none, and the curve's toe is what keeps a faint
// glow faint: the city's glow, converted without it, veiled the windows in pink
// (artpass/bays/rays2-compat).
vec3 aces(vec3 x) {
	x *= 1.8 * 0.95;
	vec3 y = (x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081);
	return max(y, vec3(0.0)) / 0.78107;  // white (1.0) to 1
}
#endif

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 c = colour;
	float k = smoothstep(0.0, fade_top, UV.y) * (1.0 - smoothstep(1.0 - fade_foot, 1.0, UV.y));
	k *= 1.0 - smoothstep(0.5 - edge * 0.5, 0.5, abs(UV.x - 0.5));
	if (mode == 2) {
		// Round about each post, falling off much as the ground under a lantern 1 m up does
		// (1 at the post's foot, about a third at 1 m, a tenth at 2 m), dark behind a hedge.
		float b = texture(lantern_map, clamp((v_wpos.xz - lantern_rect.xy) * lantern_rect.zw, 0.0, 1.0)).b;
		k = b * b;
	}
	if (mode == 1) {
		// Drops rising up the jet: streaks that move, brighter at the jet's core.
		float t = TIME * time_scale;
		float lane = floor(UV.x * 9.0);
		float s = fract(UV.y * 6.0 + t * (1.6 + hash12(vec2(lane, 3.0))) + hash12(vec2(lane, 7.0)));
		k *= 0.45 + 0.55 * smoothstep(0.5, 0.95, s);
	}
	if (mode == 3) {
		// A thread of water in each lane round the axis, a third of the lane wide and off its middle by its
		// own amount, drops running down it, over a faint film; brighter seen edge-on, where the line of
		// sight crosses more water. Lanes under a pixel give their average, so that nothing far off
		// shimmers. Streaks as wide as their lanes, over a film at 0.35, read as a bell of frosted glass
		// in a quilt (artpass/foundation/shots/basin/live-basin-oblique.png).
		float t = TIME * time_scale;
		// From 1 at the nozzle to 0 at the flow's end. Read the other way, the jets were solid at their
		// crowns, a lampshade each, and their drops ran back up (shots/basin/live-basin-oblique3).
		float y = 1.0 - UV.y;
		float u = UV.x * lanes;
		float lane = floor(u);
		float h1 = hash12(vec2(lane, 3.0));
		float h2 = hash12(vec2(lane, 7.0));
		float h3 = hash12(vec2(lane, 11.0));
		float du = fwidth(u);
		float off = abs(fract(u) - 0.5 - (h3 - 0.5) * 0.5);
		float thread = 1.0 - smoothstep(0.16, 0.16 + du, off);
		float s = fract(UV.y * (5.0 + 4.0 * h1) - t * (1.0 + 0.8 * h1) + h2);
		float fine = thread * (0.25 + 0.75 * smoothstep(0.3, 0.9, s)) * (0.5 + 0.5 * h2);
		float w = mix(0.13, fine, 1.0 - smoothstep(0.3, 0.8, du));
		vec3 v = normalize(INV_VIEW_MATRIX[3].xyz - v_wpos);
		float side = 1.0 - abs(dot(normalize(v_n), v));
		// Round it, no sides to fade: only its two ends.
		k = smoothstep(0.0, fade_top, y) * (1.0 - smoothstep(1.0 - fade_foot, 1.0, y));
		// The column is solid water, as bright face-on as edge-on.
		float column = smoothstep(nozzle_to, nozzle_to + 0.25, y) * step(0.001, nozzle_film);
		k *= (mix(mist, nozzle_film, column) + w) * mix(0.12 + 0.88 * side * side * side, 1.0, column);
		c = mix(c, foot_colour, foot_glow * smoothstep(0.25, 1.0, y));
	}
	float d = length(v_wpos - INV_VIEW_MATRIX[3].xyz);
	k *= smoothstep(near_fade_from, near_fade_to, d);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There the colour uniform arrives as set, in sRGB, and what is drawn is added in sRGB: the light
	// is worked out in linear, tone-mapped and converted, as Forward+ does on output. Added as it
	// was, a pool at 0.12 was a third as bright as under Forward+ and barely there
	// (artpass/bays/rays-compat).
	// A quarter less saturated, as ACES's matrices leave it under Forward+: the shaft seen through came
	// out orange here against Forward+'s pale amber (artpass/bays/region.py on rays2-fwd, rays5-compat).
	c = pow(c, vec3(2.2));
	vec3 lin = c * v_tint * energy * k;
	lin = mix(vec3(dot(lin, vec3(0.2126, 0.7152, 0.0722))), lin, 0.75);
	ALBEDO = pow(aces(lin), vec3(1.0 / 2.2));
#else
	ALBEDO = c * v_tint * energy * k;
#endif
}
