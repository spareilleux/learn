"""The path tracer's lights: 256, not 64. render_raytracing.cpp keeps the 64 positional lights of the best
score (energy x range^2 / distance^2, behind the camera a twentieth) and drops the rest. The Observatory's
hall has 148 lights from its start view: one reading lamp per shelf unit (energy 0.7, range 5.5), the fill
lights, the wing's and the gardens' lamps. The shelf units across the hall lost their lamps, and their
books went black where the rasterizer lit them (artpass/publish/rtx/NOTES.md, 2026-10-14).
The cost per hit does not grow with the count: raytracing_lights_inc.glsl draws 16 candidates at random
among all the lights (RT_LIGHT_RESERVOIR_SIZE) and keeps one in range. The shaders read the lights from an
unsized storage buffer (RTLightData rt_lights[]), whose size is RT_LIGHTS_MAX x 80 bytes."""
root = r"C:\tmp\godot-nvidia-dlss\godot"
p = root + r"\servers\rendering\renderer_rd\forward_clustered\render_raytracing.h"
s = open(p, encoding="utf-8", newline="").read()
old_max, new_max = "\tRT_LIGHTS_MAX = 64,", "\tRT_LIGHTS_MAX = 256, // raise_rt_lights.py: 64 dropped most of the Observatory's shelf lamps"
old_fr, new_fr = "\tRT_LIGHTS_FRUSTUM_BUDGET = 48,", "\tRT_LIGHTS_FRUSTUM_BUDGET = 192,"
if new_max in s:
    print("already:", p)
else:
    assert s.count(old_max) == 1 and s.count(old_fr) == 1, (s.count(old_max), s.count(old_fr))
    s = s.replace(old_max, new_max).replace(old_fr, new_fr)
    open(p, "w", encoding="utf-8", newline="").write(s)
    print("patched:", p)
