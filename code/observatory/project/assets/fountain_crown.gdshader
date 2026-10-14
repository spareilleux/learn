shader_type spatial;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
#else
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
#endif

// The crown of a jet of the fountain show (scripts/fountain_show.gd): where its water stalls at its highest
// and breaks into spray, a soft round cloud that faces the eye. Its instance is the nozzle (as
// fountain_jet.gdshader's, whose instance colour it shares); the mesh gives only its corners (UV).
// The water at its highest now left the nozzle its rise ago, with what the show gave the nozzle then
// (fountain_show.gdshaderinc). Water that keeps moving across, an arch's, gathers no crown.

#include "res://assets/fountain_show.gdshaderinc"

uniform float show_t = 0.0;
uniform float energy = 1.0;
// Compatibility has no tone curve over the frame, where Forward+ adds the light and curves the sum: each
// layer is curved by itself. Added as they were, jets one behind another burnt out white (shots/show/c1),
// and still did down the canal's axis at 0.4 of their light (c2). So there each layer is laid over what
// is behind it as far as it is bright (premultiplied alpha: its alpha is its brightest channel, times
// compat_cover): any number of them close on their own colour at its fullest, not on white.
uniform float compat_gain = 1.0;
// A crown is mist, not a body of water: half laid over, half added. Fully laid over, a white one was
// grey smoke against the sky (shots/show/c4 ring_t078).
uniform float compat_cover = 0.5;
uniform sampler2D spray_tex : filter_linear_mipmap, repeat_enable;
// 1 in the reflection's world: mirrored in the water's plane, at water_y.
uniform float mirror = 0.0;
uniform float water_y = -9.8;
uniform float size = 3.2;        // the crown's radius, in widths of the jet there
uniform float lit_reach = 16.0;  // as fountain_jet.gdshader's
uniform float lit_far = 0.35;
uniform float time_scale = 1.0;

varying vec3 v_led;
varying float v_k;
varying float v_rnd;

void vertex() {
	vec4 nozzle = INSTANCE_CUSTOM;
	vec4 par = COLOR;
	// Its rise, found in two steps from the nozzle's now.
	float rise = show_velocity(show_jet(nozzle, show_t)).y / SHOW_G;
	rise = show_velocity(show_jet(nozzle, show_t - rise)).y / SHOW_G;
	ShowJet j = show_jet(nozzle, show_t - rise);
	vec3 vel = show_velocity(j);
	rise = vel.y / SHOW_G;
	vec3 p = vel * rise;
	p.y -= 0.5 * SHOW_G * rise * rise;
	mat3 frame = mat3(MODEL_MATRIX);
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 wp = origin + frame * p;
	if (mirror > 0.5) {
		wp.y = 2.0 * water_y - wp.y;
	}
	vec3 view = normalize(INV_VIEW_MATRIX[3].xyz - wp);
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), view));
	vec3 up = cross(view, right);
	float r = (par.r + par.b * rise) * size;
	wp += (right * (UV.x * 2.0 - 1.0) + up * (1.0 - UV.y * 2.0)) * r;
	VERTEX = (wp - origin) * frame;
	float stall = 1.0 - smoothstep(1.0, 5.0, length(vel.xz));
	float lit = mix(lit_far, 1.0, exp(-max(p.y, 0.0) / lit_reach));
	v_k = par.a * j.valve * stall * lit * smoothstep(0.5, 3.0, p.y);
	v_led = show_jet(nozzle, show_t).led;
	v_rnd = nozzle.w;
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
	// Thick in its middle, torn at its rim, churning slowly.
	float n = texture(spray_tex, UV * 0.55 + vec2(v_rnd, v_rnd * 3.0 - TIME * time_scale * 0.12)).r;
	float cloud = exp(-r * r * 3.2) * (0.45 + 0.9 * n) * (1.0 - smoothstep(0.55 + 0.35 * n, 1.0, r));
	float k = cloud * v_k * energy;
	vec3 c = pow(mix(v_led, vec3(1.0), 0.35 * cloud), vec3(2.2));
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
