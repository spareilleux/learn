// A dependency between two IX steps (scripts/hologram_ix.gd): a ribbon that always faces the viewer,
// at least 1.2 pixels wide so it never breaks into dashes far off, with pulses running from the
// upstream step to the downstream one while data flows. UV.x runs along it, UV.y across;
// NORMAL carries its direction.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled, skip_vertex_transform;

uniform vec3 tint : source_color = vec3(0.4, 1.0, 0.78);
uniform float width = 0.012;  // metres, half the ribbon
uniform float appear = 0.0;
uniform float flow = 0.0;     // 0..1: how far the data has travelled along it
uniform float done = 0.0;     // 1 once the downstream step has run

varying float v_across;

void vertex() {
	vec3 p = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 t = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 side = normalize(cross(t, p));
	float px = 2.0 * max(-p.z, 0.01) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	v_across = UV.y * 2.0 - 1.0;
	VERTEX = p + side * v_across * max(width, 1.2 * px);
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	float core = pow(max(1.0 - abs(v_across), 0.0), 1.6);
	float base = 0.22 + 0.5 * done;
	// The travelled part glows; a few pulses ride the front while it moves.
	float behind = step(UV.x, flow);
	// Three short pulses along the ribbon, riding towards the downstream step.
	float pulse = smoothstep(0.42, 0.5, abs(fract(UV.x * 3.0 - TIME * 1.6) - 0.5)) * behind * (1.0 - done);
	float front = (1.0 - smoothstep(0.0, 0.08, abs(UV.x - flow))) * step(0.001, flow) * (1.0 - done);
	ALBEDO = tint * core * appear * (base * mix(0.5, 1.0, behind) + pulse * 0.8 + front * 2.0);
}
