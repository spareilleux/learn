shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// White statuary marble for the Hari Seldon statue (scripts/seldon_statue.gd). The art pass's
// marble is a dark stone (mean 0.25): it lends only its veins, where it is darker than its mean.
// Triplanar in the figure's own frame (1 unit = the figure's height), so the mesh needs no UVs.

uniform sampler2D marble : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float marble_tile = 0.45;
uniform vec3 stone : source_color = vec3(0.86, 0.84, 0.8);
uniform vec3 vein : source_color = vec3(0.5, 0.52, 0.56);
uniform float vein_strength = 0.75;
uniform float roughness = 0.34;

varying vec3 v_opos;
varying vec3 v_onorm;

void vertex() {
	v_opos = VERTEX;
	v_onorm = NORMAL;
}

void fragment() {
	vec3 on = normalize(v_onorm);
	vec3 w = pow(abs(on), vec3(4.0));
	w /= w.x + w.y + w.z;
	vec3 q = v_opos / marble_tile;
	vec3 lum = vec3(1.0 / 3.0);
	float m = dot(texture(marble, q.zy).rgb, lum) * w.x + dot(texture(marble, q.xz).rgb, lum) * w.y
		+ dot(texture(marble, q.xy).rgb, lum) * w.z;
	float v = clamp((0.24 - m) / 0.12, 0.0, 1.0) * vein_strength;
	ALBEDO = mix(stone, vein, v);
	ROUGHNESS = roughness;
}
