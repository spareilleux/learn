shader_type spatial;
render_mode unshaded, fog_disabled, cull_back, depth_draw_never, blend_mix;

// The glass of the lift's kiosk on the roof (scripts/lift.gd): nearly clear seen straight on, a
// faint sea-green; towards grazing, a reflection of the sky and of the galactic core's light.
// Unshaded, as the rest of Upperside is (assets/upperside.gdshader): it adds no light.

uniform vec3 tint : source_color = vec3(0.5, 0.68, 0.64);
uniform vec3 sky : source_color = vec3(0.34, 0.46, 0.55);
uniform float clear = 0.07;   // the alpha seen straight on
uniform float edge = 0.5;     // the alpha at grazing

void fragment() {
	float f = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 4.0);
	// Colours in, colour out, no light in between: each renderer keeps them in one space (Forward+
	// linear, Compatibility sRGB), so no conversion is needed.
	ALBEDO = mix(tint * 0.18, sky, f);
	ALPHA = mix(clear, edge, f);
}
