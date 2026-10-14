shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled, skip_vertex_transform, fog_disabled;

// Seldon's recording (scripts/seldon_recording.gd): the statue's own vertices as points of light. One
// MultiMesh of small quads, every instance at the origin; each takes its place on the figure from
// the targets texture (one vertex per texel, in the figure's units: 1 is its height with its base),
// and all motion is computed here from its index, so the CPU does nothing per frame.
//   form     0 dust swirling low round the figure's feet .. 1 the figure; each point arrives in turn,
//            from the feet up, a bright band climbing with them
//   scatter  0 .. 1 the figure lifting away as dust, fading
// The statue's own square base (under base_cut) is left out.

uniform sampler2D targets : filter_nearest;
uniform int columns = 256;
uniform int count = 0;
uniform int stride = 1;              // every stride-th point, on a weak GPU (scripts/quality.gd)
uniform float base_cut = 0.065;
uniform float form = 0.0;
uniform float scatter = 0.0;
uniform float size = 0.012;          // metres across a point
uniform float min_px = 1.4;          // and never under this many pixels, so far points still read
uniform float speed = 1.0;           // 0 for reduced motion: no swirl, no shimmer
uniform float travel = 1.0;          // 0 for reduced motion: each point lights where it belongs
uniform vec3 tint : source_color = vec3(0.5, 0.82, 1.0);
uniform vec3 band_tint : source_color = vec3(0.95, 0.98, 1.0);
uniform float energy = 1.0;
uniform bool linear_output = false;

varying vec3 v_col;
varying float v_a;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	int id = INSTANCE_ID * stride;
	vec3 tgt = texelFetch(targets, ivec2(id % columns, id / columns), 0).rgb;
	float fid = float(id);
	float h1 = hash(fid * 0.1371 + 1.0);
	float h2 = hash(fid * 0.7193 + 2.0);
	float h3 = hash(fid * 0.3117 + 3.0);
	float t = TIME * speed;
	float alive = (id < count && tgt.y >= base_cut) ? 1.0 : 0.0;
	// Dust: a slow swirl in a ring round the feet.
	float ang = h1 * 6.2831853 + t * (0.25 + 0.2 * h2);
	float rad = 0.16 + 0.22 * sqrt(h2);
	vec3 dust = mix(tgt, vec3(cos(ang) * rad, base_cut + h3 * 0.12, sin(ang) * rad), travel);
	// Each point's arrival: from the feet up, a little scattered.
	float delay = clamp((tgt.y - base_cut) / (1.0 - base_cut), 0.0, 1.0) * 0.7 + h1 * 0.15;
	float k = clamp((form - delay) / 0.15, 0.0, 1.0);
	k = k * k * (3.0 - 2.0 * k);
	// On the way, it spirals in round the figure's axis.
	vec3 p = mix(dust, tgt, k);
	float swirl = (1.0 - k) * k * 2.2 * travel;
	p.xz = mat2(vec2(cos(swirl), sin(swirl)), vec2(-sin(swirl), cos(swirl))) * p.xz;
	// Formed, a faint shimmer.
	p += vec3(sin(t * 2.3 + fid), sin(t * 1.7 + fid * 1.3), sin(t * 2.9 + fid * 0.7)) * 0.0012 * k;
	// Scattered: lifting and spreading as dust.
	float s = clamp(scatter * 1.4 - h2 * 0.4, 0.0, 1.0);
	p += vec3(cos(ang) * (0.15 + 0.3 * h3), 0.25 + 0.5 * h1, sin(ang) * (0.15 + 0.3 * h3)) * s * travel;
	// The band climbing with the arrivals: where points of middling delay are half there.
	float front = base_cut + (1.0 - base_cut) * (form - 0.15) / 0.7;
	float e = (tgt.y - front) * 18.0;
	float band = exp(-e * e) * (1.0 - step(1.0, form));
	v_col = mix(tint, band_tint, clamp(band + 0.15 * h3, 0.0, 1.0));
	float flicker = 0.82 + 0.18 * sin(t * (9.0 + 9.0 * h3) + fid);
	v_a = alive * (0.18 + 0.82 * k + band) * (1.0 - s) * flicker;
	vec4 c = MODELVIEW_MATRIX * vec4(p, 1.0);
	float px = 2.0 * max(-c.z, 0.01) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	float w = max(size, min_px * px) * alive;
	VERTEX = c.xyz + vec3(VERTEX.xy * w, 0.0);
}

void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float dot_ = exp(-d * d * 4.0) * (1.0 - smoothstep(0.75, 1.0, d));
	vec3 col = v_col * energy;
	if (linear_output) {
		col = pow(col, vec3(2.2));
	}
	ALBEDO = col;
	ALPHA = clamp(dot_ * v_a, 0.0, 1.0);
}
