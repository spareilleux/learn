// The gold frame round the inscription on Seldon's pedestal (scripts/seldon_recording.gd): a faint
// outline once the viewer is near, tracing itself clockwise from the top while they look at the
// name; traced all round, Seldon's recording plays. Flat on the die's face; UV across the plate.
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 gold : source_color = vec3(1.0, 0.8, 0.45);
uniform vec2 size = vec2(0.9, 0.42);  // metres
uniform float near = 0.0;  // 0..1: shown as the viewer comes within reach
uniform float fill = 0.0;  // 0..1: gaze held

void fragment() {
	vec2 p = (UV - 0.5) * size;  // metres from the plate's centre, y down
	vec2 q = abs(p) - (size * 0.5 - 0.025);
	float d = abs(max(q.x, q.y));
	// A line 5 mm across, never thinner than about a pixel and a half: further off it widens and
	// dims, so it neither shimmers nor brightens with distance.
	float px = fwidth(d);
	float half_w = max(0.0025, px * 0.75);
	float line = (1.0 - smoothstep(half_w, half_w + px, d)) * 0.0025 / half_w;
	float a = fract(atan(p.x, -p.y) / 6.28318 + 1.0);  // 0 at the top, clockwise
	float traced = line * step(a, fill) * 1.6;
	ALBEDO = gold * (line * 0.3 * near + traced);
}
