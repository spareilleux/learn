shader_type spatial;
render_mode unshaded, fog_disabled, cull_back, blend_premul_alpha, depth_draw_never, shadows_disabled;

// A painted card in the palace gardens (scripts/palace_gardens.gd): an image generated with
// Z-Image-Turbo and cut out (artpass/gardens/NOTES.md), shown as painted, with its own light. Faded into
// the night's haze with distance.
// Blended premultiplied: where alpha is 0 the card can still add light. The city's strips keep the
// haze glowing over their skyline that way (sky_glow > 0): the image's colour there, less its black
// level, is added to the sky behind.

uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float energy = 1.0;
uniform float sky_glow = 0.0;
uniform float black = 0.03;                     // the image's sky, nearly black: added as nothing
uniform vec3 haze = vec3(0.016, 0.02, 0.036);   // linear, as palace_garden.gdshader's
uniform float haze_distance = 2500.0;

void fragment() {
	vec4 t = texture(tex, UV);
	vec3 c = t.rgb;
	float b = black;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There, a source_color texture arrives in sRGB, and the output is not converted: work in
	// linear, then back.
	c = pow(c, vec3(2.2));
	b = pow(b, 2.2);
#endif
	float fade = exp(-length(VERTEX) / haze_distance);
	vec3 body = mix(haze, c * energy, fade);
	vec3 glow = max(c - b, vec3(0.0)) * energy * sky_glow * fade * (1.0 - t.a);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// The framebuffer blends in sRGB there: premultiply after the conversion.
	body = pow(max(body, vec3(0.0)), vec3(1.0 / 2.2));
	glow = pow(max(glow, vec3(0.0)), vec3(1.0 / 2.2));
#endif
	ALBEDO = body * t.a + glow;
	ALPHA = t.a;
}
