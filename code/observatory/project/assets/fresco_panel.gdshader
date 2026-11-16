shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque, fog_disabled;

// One panel of the particle frieze (scripts/fresco_frieze.gd): its mosaic, from its cell of the atlas,
// shown tessera by tessera as reveal rises. Each tessera's turn comes from the same hash as its
// particle's in assets/fresco_dust.gdshader, so a tessera lights as its particle lands, the centre a
// little before the ends. Gold tesserae glint as the viewer moves. Cut out, not blended: where the
// mosaic has not come yet, the entablature shows.

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 cell = vec4(0.0, 0.0, 0.5, 0.125);  // the panel's rectangle in the atlas
uniform vec2 grid = vec2(128.0, 32.0);           // tesserae that arrive one by one
uniform float reveal = 0.0;
uniform float glint = 1.0;
uniform float brightness = 1.0;
uniform bool linear_output = false;  // Forward+: the glows below are written in sRGB
// The moving fresco (artpass/frescovideo/): the panel's clip, one texel per tessera, cells of 128 x 32
// in assets/fresco_motion.png. Its first frame is colour; the others are their change from it, halved
// and offset by 128 (make_motion_atlas.py), so read raw, not as colour. A tessera takes the clip's
// change: added to the still where it is small, so the still's detail stays; the clip's own colour
// where it is large. The changes were measured in sRGB, so they are applied there.
uniform sampler2D motion_atlas : filter_linear, repeat_disable;
uniform vec2 motion_cells = vec2(8.0, 26.0);  // cells across and down the motion atlas
uniform float motion_base = 0.0;              // the panel's first frame's cell
uniform float motion_frames = 13.0;
uniform float motion_frame = 0.0;             // where the clip is, between frames
uniform float motion_mix = 0.0;               // 0: the still alone

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// When a tessera comes, as reveal goes from 0 to 1: 0.27 to 0.82.
float turn_of(vec2 t) {
	vec2 uv = (t + 0.5) / grid;
	return 0.27 + 0.55 * (0.6 * hash(t) + 0.4 * abs(uv.x * 2.0 - 1.0));
}

// A tessera's texel in frame f of the clip; tc is the tessera's centre within the panel, 0 to 1.
vec3 motion_at(float f, vec2 tc) {
	float idx = motion_base + f;
	vec2 mc = vec2(mod(idx, motion_cells.x), floor(idx / motion_cells.x));
	return textureLod(motion_atlas, (mc + tc) / motion_cells, 0.0).rgb;
}

// A tessera's change from the clip's first frame at frame f, in sRGB, -1 to 1.
vec3 motion_change(float f, vec2 tc) {
	if (f < 0.5) {
		return vec3(0.0);
	}
	return (motion_at(f, tc) * 255.0 - 128.0) * (2.0 / 255.0);
}

void fragment() {
	vec2 t = min(floor(UV * grid), grid - 1.0);
	float turn = turn_of(t);
	float k = clamp((reveal - turn) / 0.08, 0.0, 1.0);
	vec3 c = texture(atlas, cell.xy + clamp(UV, vec2(0.002), vec2(0.998)) * cell.zw).rgb;
	if (motion_mix > 0.0) {
		// Read between tessera centres, kept half a texel inside the panel's cell: a flat colour per
		// tessera looked coarse up close against the still's finer drawn tesserae.
		vec2 tc = clamp(UV, 0.5 / grid, 1.0 - 0.5 / grid);
		float f0 = floor(motion_frame);
		float f1 = min(f0 + 1.0, motion_frames - 1.0);
		vec3 dm = mix(motion_change(f0, tc), motion_change(f1, tc), motion_frame - f0);
		vec3 first = motion_at(0.0, tc);
		float w = smoothstep(0.08, 0.25, length(dm));
		vec3 cs = linear_output ? pow(c, vec3(1.0 / 2.2)) : c;
		// Where the clip's colour takes over, the still's own grain within the tessera stays (its grout
		// and glass), as the still's brightness over the tessera's: a flat colour looked coarse up close.
		const vec3 LUMA = vec3(0.299, 0.587, 0.114);
		float grain = clamp(dot(cs, LUMA) / max(dot(first, LUMA), 0.05), 0.6, 1.6);
		vec3 ms = mix(clamp(cs + dm, 0.0, 1.0), clamp((first + dm) * grain, 0.0, 1.0), w);
		c = mix(c, linear_output ? pow(ms, vec3(2.2)) : ms, motion_mix);
	}
	// Gold leaf: warm and bright. A tessera of it catches the light now and then, as the eye moves.
	float gold = smoothstep(0.08, 0.3, c.r - c.b) * smoothstep(0.35, 0.7, c.r);
	float tw = hash(t + 7.0);
	float facing = dot(VIEW, NORMAL);
	float g = pow(max(0.0, sin(tw * 40.0 + facing * 24.0 + TIME * 0.5)), 30.0) * gold * glint;
	vec3 glow = vec3(1.0, 0.86, 0.55);
	if (linear_output) {
		glow = pow(glow, vec3(2.2));
	}
	vec3 col = c * brightness + glow * g * 1.4;
	// A tessera just arrived still glows from its flight.
	col += glow * (1.0 - k) * step(0.001, k) * 0.9;
	ALBEDO = col;
	ALPHA = step(0.001, k);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
