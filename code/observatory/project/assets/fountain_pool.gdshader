shader_type spatial;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
#else
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
#endif

// What a jet of the fountain show does to the water (scripts/fountain_show.gd): a flat quad just over it,
// its instance the nozzle (as fountain_jet.gdshader's, whose instance colour it shares: r the jet's half
// width, b how fast it widens).
//   landing 0: the light under the nozzle, on the water round it: the nozzle's light now
//     (fountain_show.gdshaderinc), as strong as its valve is open;
//   landing 1: the foam where its water comes back down: where what left one flight ago lands now, as
//     wide as the jet has grown, churned (the spray's texture, running outwards), lit by the same light.

#include "res://assets/fountain_show.gdshaderinc"

uniform float show_t = 0.0;
uniform float energy = 1.0;
// Compatibility has no tone curve over the frame, where Forward+ adds the light and curves the sum: each
// layer is curved by itself. Added as they were, jets one behind another burnt out white (shots/show/c1),
// and still did down the canal's axis at 0.4 of their light (c2). So there each layer is laid over what
// is behind it as far as it is bright (premultiplied alpha: its alpha is its brightest channel, times
// compat_cover): any number of them close on their own colour at its fullest, not on white.
// Less of it here than of the jets: laid over the water at its full light, the foam under the vault
// was torn white paper (shots/show/c3 ring_t042).
uniform float compat_gain = 0.5;
uniform float compat_cover = 1.0;
uniform float landing = 0.0;
uniform float radius = 9.0;      // the pool's, in jet widths
uniform float foam_radius = 2.6; // the foam's, in widths of the jet where it lands
uniform sampler2D spray_tex : filter_linear_mipmap, repeat_enable;
uniform float time_scale = 1.0;

varying vec3 v_led;
varying float v_k;
varying float v_rnd;

void vertex() {
	ShowJet j = show_jet(INSTANCE_CUSTOM, show_t);
	v_led = j.led;
	v_rnd = INSTANCE_CUSTOM.w;
	if (landing > 0.5) {
		// The water landing now left a flight ago: its own flight, found in two steps from the nozzle's
		// flight now.
		float flight = 2.0 * show_velocity(j).y / SHOW_G;
		ShowJet old = show_jet(INSTANCE_CUSTOM, show_t - flight);
		flight = 2.0 * show_velocity(old).y / SHOW_G;
		old = show_jet(INSTANCE_CUSTOM, show_t - flight);
		// More foam the further the water fell.
		v_k = old.valve * COLOR.a * clamp(old.h / 12.0, 0.0, 1.4);
		VERTEX.xz = VERTEX.xz * (COLOR.r + COLOR.b * flight) * foam_radius + vec2(old.reach_in, old.reach_along);
	} else {
		// A jet that rises 10 m lights its pool fully.
		v_k = j.valve * COLOR.a * clamp(j.h / 10.0, 0.15, 1.0);
		VERTEX.xz *= COLOR.r * radius;
	}
}

#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
vec3 aces(vec3 x) {
	x *= 1.8 * 0.95;
	vec3 y = (x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081);
	return max(y, vec3(0.0)) / 0.78107;
}
#endif

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	float t = TIME * time_scale;
	float k;
	vec3 c = v_led;
	if (landing > 0.5) {
		// Churned water: lumps of foam running out from the middle, thick there, torn at the rim.
		float a = atan(d.y, d.x) / 6.2831853;
		float n = texture(spray_tex, vec2(a * 2.0 + v_rnd, r * 0.9 - t * 0.8 + v_rnd * 7.0)).r;
		float n2 = texture(spray_tex, d * 0.9 + vec2(v_rnd * 3.0, t * 0.15)).r;
		float foam = smoothstep(0.2 + 0.7 * r, 0.85 + 0.7 * r, n * 0.6 + n2 * 0.6);
		k = foam * (1.0 - smoothstep(0.75, 1.0, r)) * v_k * energy;
		c = mix(c, vec3(1.0), 0.3);
	} else {
		// Bright at the nozzle, gone at the quad's edge; rings running out.
		float glow = exp(-r * r * 5.0) + 0.25 * exp(-r * r * 1.6);
		float rings = 0.75 + 0.25 * sin(r * 26.0 - t * 5.0 + v_rnd * 6.2831853);
		k = glow * rings * (1.0 - smoothstep(0.8, 1.0, r)) * v_k * energy;
	}
	c = pow(c, vec3(2.2));
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 lin = c * k * compat_gain;
	lin = mix(vec3(dot(lin, vec3(0.2126, 0.7152, 0.0722))), lin, 0.75);
	vec3 shown = clamp(pow(aces(lin), vec3(1.0 / 2.2)), vec3(0.0), vec3(1.0));
	ALBEDO = shown;
	ALPHA = max(shown.r, max(shown.g, shown.b)) * compat_cover;
#else
	ALBEDO = c * k;
#endif
}
