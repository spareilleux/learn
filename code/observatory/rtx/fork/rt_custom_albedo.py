"""A ShaderMaterial with a colour uniform named "albedo" in the fork's path tracer: process_material()
took any material whose "albedo" parameter is a Color for a StandardMaterial3D, so such a shader never got
its own hit group and the rays saw a flat colour (render_raytracing.cpp, "Material properties"). In the
Observatory: assets/palace_garden.gdshader (the gardens' parterre without its scrolls, the paving, the
stone, the water without the palace in it), upperside.gdshader and wing_stone.gdshader (learn-08,
2026-10-12, artpass/dlss/NOTES.md, "Foundation path traced"). Now only a shader BaseMaterial3D generated
takes that path: its code declares "uniform float point_size" (scene/resources/material.cpp), which a
hand-written shader of this project does not.
    python rt_custom_albedo.py <godot source dir>"""
import sys

root = sys.argv[1].rstrip('/') + '/servers/rendering/renderer_rd/'


def edit(path, old, new):
    s = open(path, encoding='utf-8').read()
    if new in s:
        print('already', path)
        return
    assert s.count(old) == 1, (path, old[:80])
    open(path, 'w', encoding='utf-8', newline='\n').write(s.replace(old, new))
    print('patched', path)


edit(root + 'forward_clustered/render_raytracing.cpp',
     '\tVariant albedo_var = material_storage->material_get_param(p_material_rid, "albedo");\n'
     '\tif (albedo_var.get_type() == Variant::COLOR) {\n',
     '\tVariant albedo_var = material_storage->material_get_param(p_material_rid, "albedo");\n'
     '\t// A BaseMaterial3D\'s generated shader, not any shader with an "albedo" colour (rt_custom_albedo.py).\n'
     '\tconst bool rt_base_material = material_storage->material_get_shader_code_rt(p_material_rid).contains("uniform float point_size");\n'
     '\tif (albedo_var.get_type() == Variant::COLOR && rt_base_material) {\n')
