shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, fog_disabled, shadows_disabled;

// The beam of light from the Imperial Palace's spire into the night (scripts/palace_gardens.gd,
// artpass/foundation/palace/make_palace.py: a thin round shaft from the spire's tip to BEAM_TOP), added
// over what is behind it. Far off, the shaft would be under a pixel across and flicker as the view
// moves: it widens about its axis to min_angle across instead, dimmed as much, so that it carries the
// same light.

uniform vec3 colour = vec3(0.35, 0.8, 1.0);   // linear
uniform float energy = 4.0;
uniform vec2 axis = vec2(0.0, 76.0);          // the shaft's axis, in the mesh's x and z
uniform float radius = 0.35;
uniform float foot = 186.4;                   // the mesh's y at the spire's tip
uniform float fade_height = 520.0;            // fades out over this height above the foot
uniform float min_angle = 0.0025;             // radians across, at least
uniform vec3 haze = vec3(0.016, 0.02, 0.036);
uniform float haze_distance = 900.0;

varying float v_dim;
varying float v_along;
varying float v_fade;
varying vec3 v_wnorm;
varying vec3 v_wpos;

void vertex() {
	vec3 centre = vec3(axis.x, VERTEX.y, axis.y);
	vec3 wc = (MODEL_MATRIX * vec4(centre, 1.0)).xyz;
	float d = length(wc - INV_VIEW_MATRIX[3].xyz);
	float s = max(1.0, d * min_angle / (2.0 * radius));
	VERTEX.xz = axis + (VERTEX.xz - axis) * s;
	v_dim = 1.0 / s;
	v_along = clamp((VERTEX.y - foot) / fade_height, 0.0, 1.0);
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnorm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	v_fade = exp(-d / haze_distance);
}

void fragment() {
	vec3 v = normalize(INV_VIEW_MATRIX[3].xyz - v_wpos);
	// Soft sides: the shaft's middle, facing the eye, the brightest.
	float edge = pow(clamp(abs(dot(normalize(v_wnorm), v)), 0.0, 1.0), 1.5);
	float along = (1.0 - v_along) * (1.0 - v_along);
	vec3 col = colour * energy * along * edge * v_dim * mix(0.5, 1.0, v_fade);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	col = pow(max(col, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	ALBEDO = col;
}
