shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_opaque, shadows_disabled, skip_vertex_transform;

// Far trees in the palace gardens (scripts/palace_gardens.gd), each a card that turns about its own up axis
// to face the camera. Cut out at `cutoff`, so that thousands of them need no sorting; alpha rises with the
// mip level, or far trees would thin out to nothing as their mipmaps blur. Two ways:
//   views 1: painted trees (Z-Image-Turbo, artpass/gardens/NOTES.md), one per cell of the atlas, their foot
//            on its bottom edge; the instance's scale gives the card's width and height, INSTANCE_CUSTOM.x
//            its cell; lit as painted (energy).
//   views 8: the 3D trees' own views (artpass/gardens/blender/tree_kit.py, veg/prep_impostors.py): one
//            variant a row (INSTANCE_CUSTOM.x), view i seen from azimuth 2 pi i / 8 round the tree, the
//            two nearest the eye's azimuth in the tree's turned frame blended. The instance is the tree's
//            turn and uniform scale, as its near mesh's (assets/garden_plant.gdshader): the card is the
//            views' frame, span square across the cell's aspect, its foot foot_v up the cell. Lit as the
//            near trees, by the views' normals (ntex: x right, y up, z towards the eye).
// Each tree sways in the wind, the top more than the foot, at its own phase (INSTANCE_CUSTOM.y). With
// near_r, a tree nearer than that is its near mesh's to draw: out to near_r - band it is not here, and
// across the band the two share its pixels by the same dither.

uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D ntex : hint_default_white, filter_linear_mipmap, repeat_disable;
uniform vec2 grid = vec2(4.0, 1.0);         // cells across and down
uniform vec2 tex_size = vec2(1024.0, 1024.0);
uniform float energy = 0.6;
uniform float sway = 0.3;                   // metres at the top, at its widest
uniform float gust = 1.0;
uniform float cutoff = 0.5;
uniform vec3 haze = vec3(0.016, 0.02, 0.036);   // linear, as palace_garden.gdshader's
uniform float haze_distance = 2500.0;
uniform int views = 1;
uniform float span = 15.0;
uniform float aspect = 1.0;
uniform float foot_v = 0.0198;
uniform float near_r = 0.0;
uniform float band = 8.0;
uniform vec3 tint = vec3(1.0);
uniform float wrap = 0.35;
uniform float uplight = 0.0;
uniform float uplight_h = 6.0;
uniform float foot_y = -10.0;
uniform vec3 core_dir = vec3(-0.468, 0.867, -0.170);
uniform vec3 core_light = vec3(0.9, 0.8, 0.66);
uniform float core_energy = 0.35;
uniform vec3 ambient = vec3(0.07, 0.08, 0.11);
uniform vec3 lamp_colour : source_color = vec3(1.0, 0.72, 0.42);

varying float v_dist;
varying float v_odist;
varying vec3 v_wpos;
varying vec3 v_side;
varying vec3 v_fwd;
varying vec2 v_uv1;
varying float v_blend;

// As garden_plant.gdshader's.
float dither(vec2 px) {
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	vec3 to_eye = eye - origin;
	v_odist = length(to_eye);
	float phase = INSTANCE_CUSTOM.y * 6.2831853;
	float s = sin(TIME * 0.7 + phase) * 0.7 + sin(TIME * 1.9 + phase * 2.3) * 0.3;
	float top = clamp(VERTEX.y, 0.0, 1.0);
	vec3 world;
	if (views <= 1) {
		vec3 up = MODEL_MATRIX[1].xyz;
		float h = length(up);
		up /= h;
		float w = length(MODEL_MATRIX[0].xyz);
		vec3 side = cross(up, to_eye);
		side = dot(side, side) > 1e-8 ? normalize(side) : MODEL_MATRIX[0].xyz / w;
		world = origin + side * (VERTEX.x * w + s * sway * gust * top * top) + up * (VERTEX.y * h);
		NORMAL = normalize((VIEW_MATRIX * vec4(to_eye, 0.0)).xyz);
		vec2 cell = vec2(mod(INSTANCE_CUSTOM.x, grid.x), floor(INSTANCE_CUSTOM.x / grid.x));
		UV = (cell + UV) / grid;
		v_blend = 0.0;
		v_uv1 = UV;
	} else {
		float k = length(MODEL_MATRIX[1].xyz);
		vec3 up = vec3(0.0, 1.0, 0.0);
		vec3 flat_eye = vec3(to_eye.x, 0.0, to_eye.z);
		vec3 fwd = dot(flat_eye, flat_eye) > 1e-8 ? normalize(flat_eye) : vec3(0.0, 0.0, 1.0);
		vec3 side = cross(up, fwd);
		// The eye's azimuth in the tree's frame: from its +Z towards its +X, as the views were taken.
		float az = atan(dot(to_eye, MODEL_MATRIX[0].xyz), dot(to_eye, MODEL_MATRIX[2].xyz));
		float f = fract(az / 6.2831853) * grid.x;
		float i0 = floor(f);
		v_blend = f - i0;
		float i1 = mod(i0 + 1.0, grid.x);
		float row = INSTANCE_CUSTOM.x;
		float h = span * k;
		world = origin + side * (VERTEX.x * h * aspect + s * sway * gust * top * top) + up * ((VERTEX.y - foot_v) * h);
		NORMAL = normalize((VIEW_MATRIX * vec4(fwd, 0.0)).xyz);
		v_uv1 = (vec2(i1, row) + UV) / grid;
		UV = (vec2(i0, row) + UV) / grid;
		v_side = side;
		v_fwd = fwd;
		if (near_r > 0.0 && v_odist < near_r - band) {
			// Its near mesh draws it here.
			world = origin;
		}
	}
	v_wpos = world;
	v_dist = length(world - eye);
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
}

void fragment() {
	vec4 t = texture(tex, UV);
	if (views > 1) {
		if (near_r > 0.0) {
			float f = clamp((near_r - v_odist) / band, 0.0, 1.0);
			if (dither(FRAGCOORD.xy) < f) {
				discard;
			}
		}
		t = mix(t, texture(tex, v_uv1), v_blend);
	}
	vec2 px = UV * tex_size;
	vec2 dx = dFdx(px);
	vec2 dy = dFdy(px);
	float mip = max(0.0, 0.5 * log2(max(dot(dx, dx), dot(dy, dy))));
	vec3 c = t.rgb;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There, a source_color texture arrives in sRGB and the output is not converted: work in linear,
	// then back.
	c = pow(c, vec3(2.2));
#endif
	float fade = exp(-v_dist / haze_distance);
	vec3 col;
	if (views > 1) {
		vec3 nv = mix(texture(ntex, UV).rgb, texture(ntex, v_uv1).rgb, v_blend) * 2.0 - 1.0;
		vec3 n = normalize(v_side * nv.x + vec3(0.0, 1.0, 0.0) * nv.y + v_fwd * nv.z);
		vec3 a = c * tint * COLOR.rgb;
		float diff = clamp(dot(n, normalize(core_dir)) * (1.0 - wrap) + wrap, 0.0, 1.0);
		vec3 lc = lamp_colour;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		lc = pow(lc, vec3(2.2));
#endif
		col = a * (ambient + core_light * core_energy * diff);
		if (uplight > 0.0) {
			float up = exp(-max(v_wpos.y - foot_y, 0.0) / uplight_h);
			col += a * lc * uplight * up * (0.6 + 0.4 * clamp(-n.y * 0.5 + 0.5, 0.0, 1.0));
		}
		col = mix(haze, col, fade);
	} else {
		col = mix(haze, c * energy * COLOR.rgb, fade);
	}
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	col = pow(max(col, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	ALBEDO = col;
	ALPHA = t.a * (1.0 + 0.25 * mip);
	ALPHA_SCISSOR_THRESHOLD = cutoff;
}
