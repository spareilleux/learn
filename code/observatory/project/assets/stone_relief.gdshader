shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Dressed stone for the colonnade, arches, entablature, drum and ceiling (scripts/observatory.gd,
// _stone). Colour: the art pass's ComfyUI marble. Surface: a ComfyUI tooled-limestone height.
// Joints are procedural, in the mesh's own frame, so every pier and arch is coursed alike:
//   pattern 0  none (single blocks: plinths, capitals)
//   pattern 1  ashlar on a box: bed joints along y, head joints along the face (piers)
//   pattern 2  polar in the xz plane: joints by angle and by radius (arch voussoirs; the ceiling's
//              underside becomes coffers when coffer_depth > 0)
//   pattern 3  cylinder: bed joints along y, head joints by angle (entablature, drum)
// Relief is bump-mapped from screen-space derivatives, so the procedural meshes need no UVs.

uniform sampler2D marble : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(0.5, 0.55, 0.64);
uniform float marble_tile = 2.5;
uniform sampler2D relief : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float relief_tile = 0.6;
uniform float relief_depth = 0.0012;
uniform int pattern = 0;
uniform float course = 0.62;      // metres between bed joints (1, 3) or ring joints (2)
uniform float block = 0.9;        // metres between head joints (1)
uniform float sectors = 64.0;     // head joints per full turn (2, 3)
uniform float joint_width = 0.005;
uniform float joint_depth = 0.008;
uniform float coffer_depth = 0.0; // pattern 2, underside only
uniform float coffer_rib = 0.14;
uniform float radial_offset = 0.0; // pattern 2: radius where the first ring of cells starts
uniform vec3 rosette : source_color = vec3(0.83, 0.64, 0.3);
uniform float roughness = 0.78;

varying vec3 v_opos;
varying vec3 v_onorm;

float hash12(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

void vertex() {
	v_opos = VERTEX;
	v_onorm = NORMAL;
}

void fragment() {
	vec3 p = v_opos;
	vec3 on = normalize(v_onorm);
	vec3 w = pow(abs(on), vec3(4.0));
	w /= w.x + w.y + w.z;
	vec3 fw3 = fwidth(p);
	float fw = max(fw3.x, max(fw3.y, fw3.z));

	// Triplanar marble and relief, sampled in uniform control flow.
	vec3 mq = p / marble_tile;
	vec3 col = (texture(marble, mq.zy).rgb * w.x + texture(marble, mq.xz).rgb * w.y + texture(marble, mq.xy).rgb * w.z) * tint;
	vec3 rq = p / relief_tile;
	float rel = texture(relief, rq.zy).r * w.x + texture(relief, rq.xz).r * w.y + texture(relief, rq.xy).r * w.z;

	// Joint grid: u across the joints' spacing "block", v across "course", both in metres.
	vec2 cell = vec2(block, course);
	vec2 uv = vec2(0.0);
	float use_head = 1.0;
	float use_bed = 1.0;
	float ang = atan(p.z, p.x);
	float rad = length(p.xz);
	if (pattern == 1) {
		uv = vec2(abs(on.x) > abs(on.z) ? p.z : p.x, p.y);
		use_head = step(abs(on.y), 0.5);
		use_bed = use_head;
	} else if (pattern == 2) {
		cell = vec2(1.0, course);
		uv = vec2(ang / TAU * sectors, rad - radial_offset);
		use_bed = step(0.5, abs(on.y));
	} else if (pattern == 3) {
		cell = vec2(1.0, course);
		uv = vec2(ang / TAU * sectors, p.y);
		use_head = step(abs(on.y), 0.5);
		use_bed = use_head;
	}
	float row = floor(uv.y / cell.y);
	uv.x += (pattern == 1 || pattern == 3) ? 0.5 * cell.x * mod(row, 2.0) : 0.0; // running bond
	vec2 id = floor(uv / cell);
	vec2 f = uv / cell - id;
	// Distance to the cell's edges in metres; the angular axis is converted at this radius.
	float metres_u = (pattern == 1) ? cell.x : TAU * max(rad, 0.01) / sectors;
	vec2 d = vec2(min(f.x, 1.0 - f.x) * metres_u, min(f.y, 1.0 - f.y) * cell.y);
	float dj = min(mix(1e3, d.x, use_head), mix(1e3, d.y, use_bed));
	float has_joints = step(0.5, float(pattern));
	float joint = has_joints * (1.0 - smoothstep(joint_width - fw, joint_width + fw, dj));
	float joint_lod = 1.0 - smoothstep(0.004, 0.02, fw);
	// Stones are dressed slightly proud of their joints: a bevel over the last 2 cm.
	float bevel = has_joints * (1.0 - smoothstep(joint_width, joint_width + 0.02, dj));

	// Per-stone variation in tone and a little in the surface.
	float v = hash12(id + float(pattern) * 17.0);
	col *= 0.86 + 0.26 * v;

	float height = (rel - 0.5) * relief_depth * 2.0 - joint_depth * (0.35 * bevel + 0.65 * joint) * joint_lod;
	col *= 1.0 - 0.55 * joint;
	float rough = mix(roughness, 0.95, joint);

	// Coffers: recessed panels inside ribs on the underside, a gilt rosette in each.
	if (pattern == 2 && coffer_depth > 0.0) {
		float under = step(0.5, -on.y);
		float rib = 1.0 - smoothstep(coffer_rib, coffer_rib + 0.05, min(d.x, d.y));
		float recess = under * (1.0 - rib);
		// Coffers read from the floor, 20 m below: their relief fades much later than the joints'.
		height -= recess * coffer_depth * (1.0 - smoothstep(0.06, 0.25, fw));
		// Shade deepens towards the ribs: the coffer's own ambient occlusion.
		float ao = smoothstep(coffer_rib, coffer_rib + 0.35, min(d.x, d.y));
		col *= mix(1.0 + 0.3 * under, 0.45 + 0.35 * ao, recess);
		vec2 c = vec2((f.x - 0.5) * metres_u, (f.y - 0.5) * cell.y);
		float rr = length(c);
		float ros = under * (1.0 - smoothstep(0.05, 0.05 + fw * 1.5, rr)) * (0.6 + 0.4 * step(0.025, rr));
		col = mix(col, rosette, ros);
		rough = mix(rough, 0.35, ros);
		METALLIC = ros;
		EMISSION = rosette * ros * 0.05;
	}

	// Bump (Mikkelsen 2010) with the tilt clamped, so edges between faces do not sparkle.
	vec3 n = normalize(NORMAL);
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	float dhx = dFdx(height);
	float dhy = dFdy(height);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2) / max(abs(det), 1e-12);
	float gl = length(grad);
	grad *= min(gl, 1.0) / max(gl, 1e-6);
	NORMAL = normalize(n - grad);
	ALBEDO = col;
	ROUGHNESS = rough;
	AO = 1.0 - 0.6 * joint;
}
