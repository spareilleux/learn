shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Backlit stained glass for the oculus drum (scripts/observatory.gd, _build_windows): a ComfyUI
// panel seen through a round-headed lancet in a stone frame. The glass is lit from behind, so its
// colour is emission; the lead is dark in the panel itself. Brightness drifts slowly, as if clouds
// passed outside.

uniform sampler2D glass : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 frame_color : source_color = vec3(0.3, 0.33, 0.4);
uniform float energy = 2.0;
uniform float frame = 0.07;   // stone frame, in widths
uniform float aspect = 2.4;   // quad height / width
uniform float seed = 0.0;

void fragment() {
	// x across the window from its axis, y down from the top, both in widths.
	vec2 p = vec2(UV.x - 0.5, UV.y * aspect);
	float d_side = 0.5 - abs(p.x);
	float d_head = p.y < 0.5 ? 0.5 - length(p - vec2(0.0, 0.5)) : d_side;
	float d = min(min(d_side, d_head), aspect - p.y); // distance inside the outline
	if (d < 0.0) {
		discard;
	}
	float fw = fwidth(p.y);
	float in_glass = smoothstep(frame - fw, frame + fw, d);
	vec3 tex = texture(glass, UV).rgb;
	float drift = 0.9 + 0.1 * sin(TIME * 0.23 + seed * 6.28) * sin(TIME * 0.089 + seed * 2.1);
	ALBEDO = mix(frame_color, tex * 0.04, in_glass);
	ROUGHNESS = mix(0.8, 0.1, in_glass);
	SPECULAR = mix(0.3, 0.6, in_glass);
	EMISSION = in_glass * tex * energy * drift;
}
