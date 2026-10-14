shader_type spatial;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
#else
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
#endif

// A jet of the fountain show (scripts/fountain_show.gd), drawn as a ribbon that faces the eye along the
// water's path. The mesh carries no place of its own: UV.y runs along the jet, 0 at the nozzle, UV.x across
// it; the instance is the nozzle (its frame, and in INSTANCE_CUSTOM what fountain_show.gdshaderinc reads).
//
// The water seen at an age of tau seconds left the nozzle at time - tau, with the speed and the lean the
// nozzle had then, and has fallen freely since: p = v(time - tau) tau - g tau² / 2. So a nozzle that sways
// throws a whip that lags behind it, and a valve that shuts leaves its last water rising alone, as real
// ones do. The water's marks (the spray texture) are read at the time it left, so that they ride with it.
// It is brightest where it is slowest and gathers (its crown), lit from under by the nozzle's light, whose
// colour is the light's now, not that of the water's own moment.
//
// Instance colour: r the jet's half width at the nozzle (m), g the longest flight drawn (in units of 8 s),
// b how fast it widens (m/s), a its strength.

#include "res://assets/fountain_show.gdshaderinc"

uniform float show_t = 0.0;
uniform float energy = 1.0;
// Compatibility has no tone curve over the frame, where Forward+ adds the light and curves the sum: each
// layer is curved by itself. Added as they were, jets one behind another burnt out white (shots/show/c1),
// and still did down the canal's axis at 0.4 of their light (c2). So there each layer is laid over what
// is behind it as far as it is bright (premultiplied alpha: its alpha is its brightest channel, times
// compat_cover): any number of them close on their own colour at its fullest, not on white.
uniform float compat_gain = 1.0;
uniform float compat_cover = 1.0;
uniform sampler2D spray_tex : filter_linear_mipmap, repeat_enable;
// 1 in the reflection's world (fountain_show.gd): the jets mirrored in the water's plane, at water_y.
uniform float mirror = 0.0;
uniform float water_y = -9.8;
// The nozzle's light on its water: full at the nozzle, down to `lit_far` of it lit_reach metres up.
uniform float lit_reach = 16.0;
uniform float lit_far = 0.35;
uniform float cap_speed = 4.0;   // m/s: the sideways lean given to water turning back on itself
uniform float near_fade_from = 0.6;
uniform float near_fade_to = 3.0;

varying vec3 v_wpos;
varying vec3 v_led;
varying float v_k;       // the water's amount and light there
varying float v_age;     // seconds since it left the nozzle
varying float v_left;    // when it left, seconds
varying float v_rnd;
varying float v_up;      // metres above the water
varying float v_life;    // its age over its whole flight: 0.5 at its highest, 1 back at the water

void vertex() {
	vec4 nozzle = INSTANCE_CUSTOM;
	vec4 par = COLOR;
	float tau = UV.y * par.g * 8.0;
	float left = show_t - tau;
	ShowJet j = show_jet(nozzle, left);
	vec3 vel = show_velocity(j);
	vec3 p = vel * tau;
	p.y -= 0.5 * SHOW_G * tau * tau;
	// The water a moment older, further along: the jet's way there as it stands now, in metres for a second
	// of water. It is the water's own speed while the nozzle holds still, and far more where the nozzle
	// changed fast: the same water drawn out over a longer way, and so thinner (taken for the water's
	// speed, a row whose jets dropped at once stood as flat blocks of light: shots/show/a3 head_t090).
	float tau2 = tau + 0.06;
	vec3 p2 = show_velocity(show_jet(nozzle, show_t - tau2)) * tau2;
	p2.y -= 0.5 * SHOW_G * tau2 * tau2;
	vec3 run = (p2 - p) / 0.06;
	mat3 frame = mat3(MODEL_MATRIX);
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 wp = origin + frame * p;
	vec3 along = frame * run;
	v_up = wp.y - water_y;
	if (mirror > 0.5) {
		wp.y = 2.0 * water_y - wp.y;
		along.y = -along.y;
	}
	// The ribbon lies across the water's way as the eye sees it. Where the water turns back on itself (the
	// top of a jet that rises straight, or one seen end-on) its way reverses within one segment and the
	// ribbon would twist flat, a bow tie (shots/show/a1); there its way is given a sideways lean, so that
	// it turns over half a second and the ribbon sweeps a round crown.
	vec3 view = INV_VIEW_MATRIX[3].xyz - wp;
	vec3 level = normalize(cross(vec3(0.0, 1.0, 0.0), view));
	float lean = cap_speed / (1.0 + along.y * along.y / 9.0);
	vec3 across = cross(along + level * (dot(along, level) < 0.0 ? -lean : lean), view);
	across = across / max(length(across), 1e-4);
	float width = par.r + par.b * tau;
	wp += across * (UV.x * 2.0 - 1.0) * width;
	VERTEX = (wp - origin) * frame;
	v_wpos = wp;
	// As much water in a metre of the jet as its way is short there, spread over its width; less light the
	// higher it is over its nozzle.
	float speed = max(length(run), 5.0);
	float lit = mix(lit_far, 1.0, exp(-max(p.y, 0.0) / lit_reach));
	v_k = par.a * j.valve * (14.0 / speed) * (par.r / width) * lit;
	v_led = show_jet(nozzle, show_t).led;
	v_age = tau;
	v_life = tau / max(2.0 * vel.y / SHOW_G, 0.3);
	v_left = left;
	v_rnd = nozzle.w;
}

#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
// As assets/palace_glow.gdshader: Godot's fit of ACES (main.tscn: tonemap_mode 3, exposure 0.95), which
// Forward+ applies to the frame and Compatibility does not.
vec3 aces(vec3 x) {
	x *= 1.8 * 0.95;
	vec3 y = (x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081);
	return max(y, vec3(0.0)) / 0.78107;
}
#endif

void fragment() {
	float x = UV.x * 2.0 - 1.0;
	// A round column's depth of water along the line of sight, thinning to nothing at its edges: with the
	// plain half circle a jet seen close was a flat band with hard sides (shots/show/a2 side_t018).
	float column = pow(max(1.0 - x * x, 0.0), 1.5);
	// Whole at the nozzle, broken into drops within a second; long in the air and falling, a veil of fine
	// drops.
	float broken = smoothstep(0.1, 1.0, v_age);
	float veil = smoothstep(0.55, 0.85, v_life) * smoothstep(1.0, 2.5, v_age);
	// The water's marks, riding with it: read at the time it left (3.5, 9 and 30 a second: whole numbers of
	// tiles over the show's loop, so that nothing jumps where it starts again). At 0.9 and 2.7 they were
	// streaks 10 m long, strands of glass (shots/show/a1). The finest shows only from close by: further
	// off, the texture's smaller levels even it out.
	float n1 = texture(spray_tex, vec2(UV.x * 0.5 + v_rnd, v_left * 3.5 + v_rnd * 13.0)).r;
	float n2 = texture(spray_tex, vec2(UV.x * 1.6 + v_rnd * 3.0 + 0.37, v_left * 9.0 + v_rnd * 5.0)).r;
	float n3 = texture(spray_tex, vec2(UV.x * 5.0 + v_rnd * 7.0 + 0.71, v_left * 30.0 + v_rnd * 3.0)).r;
	float n = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
	// The column, eaten away from its edges as it breaks up, into lumps and threads; then the veil, even.
	float lumps = clamp(column * 1.3 - broken * 0.9 * (1.0 - n), 0.0, 1.0);
	lumps *= mix(0.8 + 0.2 * n3, 0.5 + 1.2 * smoothstep(0.35, 0.8, n), broken);
	float a = mix(lumps, column * (0.3 + 0.25 * n2), veil);
	// Drops that catch the light.
	float glint = smoothstep(0.86, 0.97, n2 * 0.6 + n3 * 0.4) * a * broken;
	float k = (a + glint * 1.5) * v_k * energy;
	// Gone under the water (its mirror has no water to hide it), and near the eye.
	k *= smoothstep(-0.15, 0.25, v_up);
	k *= smoothstep(near_fade_from, near_fade_to, length(v_wpos - INV_VIEW_MATRIX[3].xyz));
	// The light's colour, whiter where the water is thick.
	vec3 c = pow(mix(v_led, vec3(1.0), clamp(0.3 * a + 0.6 * glint, 0.0, 1.0)), vec3(2.2));
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
