shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled, skip_vertex_transform, fog_disabled;

// The particles of the frieze (scripts/fresco_frieze.gd), one per tessera of a panel
// (assets/fresco_panel.gdshader): idle, a faint gold dust drifting in front of the entablature; as
// reveal rises, each flies to its tessera on an arc out into the hall and back, taking on the
// tessera's colour, and goes out as the tessera lights; as reveal falls, the reverse. One MultiMesh
// per panel, every instance at the origin: the shader places each from its index and the panel's
// place on the hall's circle, so the CPU sets a uniform or two when something changes.

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 cell = vec4(0.0, 0.0, 0.5, 0.125);
uniform vec2 grid = vec2(128.0, 32.0);
uniform float reveal = 0.0;
uniform int stride = 1;              // one tessera in stride has a particle (a weak GPU)
uniform int drawn = 4096;            // the instances drawn: grid.x * grid.y / stride
uniform float idle_share = 0.25;     // the share of them in the idle dust
uniform float a0 = 0.0;              // the panel's centre, radians round the hall (x = cos, z = sin)
uniform float span = 0.287;          // its width, radians
uniform float radius = 12.26;
uniform vec2 ys = vec2(18.98, 19.86);  // its bottom and top
uniform float size = 0.035;          // metres across a particle
uniform float min_px = 1.3;
uniform float speed = 1.0;           // 0 for reduced motion
uniform float travel = 1.0;          // 0 for reduced motion: each particle lights where it belongs
uniform float idle = 0.3;            // the idle dust's brightness
uniform float energy = 1.0;
uniform bool linear_output = false;

varying vec3 v_col;
varying float v_a;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// The same as assets/fresco_panel.gdshader's: when the tessera lights, as reveal goes from 0 to 1.
float turn_of(vec2 t) {
	vec2 uv = (t + 0.5) / grid;
	return 0.27 + 0.55 * (0.6 * hash(t) + 0.4 * abs(uv.x * 2.0 - 1.0));
}

// u from left to right as seen from the hall, v from top to bottom; r from the hall's axis.
vec3 on_wall(float u, float v, float r) {
	float a = a0 + (u - 0.5) * span;
	return vec3(cos(a) * r, mix(ys.y, ys.x, v), sin(a) * r);
}

void vertex() {
	int id = INSTANCE_ID * stride;
	int cols = int(grid.x);
	vec2 t = vec2(float(id % cols), float(id / cols));
	vec2 uv = (t + 0.5) / grid;
	vec3 target = on_wall(uv.x, uv.y, radius - 0.01);
	float turn = turn_of(t);
	float h1 = hash(t + 11.0);
	float h2 = hash(t + 23.0);
	float h3 = hash(t + 37.0);
	float tt = TIME * speed;
	// While the panel is looked at, before it comes (scripts/fresco_frieze.gd: GATHER), its dust
	// draws in towards it and brightens.
	float lift = clamp(reveal / 0.22, 0.0, 1.0);
	// Idle: drifting slowly round the hall, in a band from a little above the panel to a little
	// below it and up to 3 m out from it, whatever its tessera.
	float du = fract(h2 + tt * (0.004 + 0.006 * h1));
	float dv = h3 * 1.6 - 0.3 + sin(tt * 0.3 + h1 * 6.2832) * 0.08;
	dv = mix(dv, uv.y, 0.4 * lift);
	vec3 drift = on_wall(du, dv, radius - 0.4 - 2.6 * fract(h3 * 7.13 + h1) * (1.0 - 0.6 * lift));
	// Faded at the ends of its band, where it wraps round.
	float ends = smoothstep(0.0, 0.08, du) * smoothstep(1.0, 0.92, du);
	drift.y += sin(tt * 0.5 + h2 * 6.2832) * 0.1;
	drift = mix(target, drift, travel);
	// The flight: from a quarter before the tessera's turn to just after it.
	float k = clamp((reveal - turn + 0.25) / 0.29, 0.0, 1.0);
	float e = k * k * (3.0 - 2.0 * k);
	vec3 p = mix(drift, target, e);
	vec3 inward = -normalize(vec3(target.x, 0.0, target.z));
	p += inward * sin(e * 3.14159) * 0.7 * travel;
	vec3 gold = vec3(1.0, 0.8, 0.45);
	if (linear_output) {
		gold = pow(gold, vec3(2.2));  // a constant written in sRGB; the atlas is read linear already
	}
	vec3 tessera = textureLod(atlas, cell.xy + uv * cell.zw, 1.0).rgb;
	v_col = mix(gold, tessera * 1.4, e);
	// In the idle dust or not yet, and gone once its tessera is lit.
	float share = (float(INSTANCE_ID) + 0.5) / float(max(drawn, 1));
	float present = clamp(1.0 - (share - idle_share) / 0.08, 0.0, 1.0);
	float after = 1.0 - clamp((reveal - turn) / 0.08, 0.0, 1.0);
	float flicker = 0.7 + 0.3 * sin(tt * (4.0 + 6.0 * h2) + h1 * 30.0);
	v_a = mix(idle * flicker * present * ends * (1.0 + 2.0 * lift), 1.0, e) * after;
	vec4 c = MODELVIEW_MATRIX * vec4(p, 1.0);
	float px = 2.0 * max(-c.z, 0.01) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	float w = max(size * mix(0.7, 1.0, e), min_px * px) * step(0.002, v_a);
	VERTEX = c.xyz + vec3(VERTEX.xy * w, 0.0);
}

void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float dot_ = exp(-d * d * 4.0) * (1.0 - smoothstep(0.75, 1.0, d));
	ALBEDO = v_col * energy;
	ALPHA = clamp(dot_ * v_a, 0.0, 1.0);
}
