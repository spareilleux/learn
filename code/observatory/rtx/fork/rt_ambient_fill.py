"""The Environment's ambient colour in the fork's path tracer, as light from the sky for the bounces: a
night scene lit in the rasterizer by an ambient colour (the Observatory's (0.32, 0.42, 0.62) x 0.45,
ambient_light_source = Color) came out black wherever no lamp reached, the gardens' ground and hedges,
since the path tracer ignores the ambient light (learn-08, 2026-10-12, the author's "c'est tres bizarre en
path reconstructions", artpass/dlss/NOTES.md, "Foundation path traced"). Now a ray that leaves the scene
after at least one bounce gets the sky plus that colour times its energy, when the Environment's ambient
source is Color: a uniform dome, as the rasterizer's ambient, but occluded by what the ray meets. A
camera ray that misses still sees the sky alone. Ambient source Sky or Background is already the sky.
    python rt_ambient_fill.py <godot source dir>"""
import sys

root = sys.argv[1].rstrip('/') + '/servers/rendering/renderer_rd/shaders/raytracing/'


def edit(path, old, new):
    s = open(path, encoding='utf-8').read()
    if new in s:
        print('already', path)
        return
    assert s.count(old) == 1, (path, old[:80])
    open(path, 'w', encoding='utf-8', newline='\n').write(s.replace(old, new))
    print('patched', path)


edit(root + 'scene_raytracing_raygen.glsl',
     '\tvec3 sky_color = radiance_octmap_sample(sky_uv, 0.0);\n'
     '\tsky_color *= scene_data_block.data.IBL_exposure_normalization;\n',
     '\tvec3 sky_color = radiance_octmap_sample(sky_uv, 0.0);\n'
     '\tsky_color *= scene_data_block.data.IBL_exposure_normalization;\n'
     '\t// The ambient colour as a dome for the bounces (rt_ambient_fill.py): ambient source Color only.\n'
     '\tif (get_total_bounces(ps.packed_bounces_flags) > 0u &&\n'
     '\t\t\tbool(scene_data_block.data.flags & SCENE_DATA_FLAGS_USE_AMBIENT_LIGHT) &&\n'
     '\t\t\t!bool(scene_data_block.data.flags & SCENE_DATA_FLAGS_USE_AMBIENT_CUBEMAP)) {\n'
     '\t\tsky_color += scene_data_block.data.ambient_light_color_energy.rgb;\n'
     '\t}\n')
