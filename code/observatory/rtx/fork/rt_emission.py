"""Emission of a StandardMaterial3D in the fork's path tracer: it counted only with an emission
texture (MaterialData flag bit 1), so an emissive colour alone (the Observatory's lamp strips, gilt
glow, crystals, stars) emitted nothing. Now the colour times the energy always emits, times the
texture when there is one, as the rasterizer does with the default "add" operator and no texture.
    python rt_emission.py <godot source dir>"""
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


edit(root + 'shaders/raytracing/scene_raytracing_raygen.glsl',
     '\tvec3 emissive = vec3(0.0);\n'
     '\tif ((mat.flags & 2u) != 0u) {\n'
     '\t\temissive = sample_material_texture(mat.emission_texture_idx, uv, mat.flags).rgb * mat.emission_color * mat.emission_strength;\n'
     '\t\temissive *= scene_data_block.data.emissive_exposure_normalization;\n'
     '\t}\n',
     '\t// The emission colour times its energy (black unless set), times the texture if any.\n'
     '\tvec3 emissive = mat.emission_color * mat.emission_strength;\n'
     '\tif ((mat.flags & 2u) != 0u) {\n'
     '\t\temissive *= sample_material_texture(mat.emission_texture_idx, uv, mat.flags).rgb;\n'
     '\t}\n'
     '\temissive *= scene_data_block.data.emissive_exposure_normalization;\n')
edit(root + 'forward_clustered/scene_shader_raytracing.cpp',
     '\t\t\t\t\t"if ((rt_mat.flags & 2u) != 0u) {\\n"\n'
     '\t\t\t\t\t"    emission = sample_material_texture(rt_mat.emission_texture_idx, mat_uv, rt_mat.flags).rgb\\n"\n'
     '\t\t\t\t\t"             * rt_mat.emission_color * rt_mat.emission_strength;\\n"\n'
     '\t\t\t\t\t"}\\n";',
     '\t\t\t\t\t"emission = rt_mat.emission_color * rt_mat.emission_strength;\\n"\n'
     '\t\t\t\t\t"if ((rt_mat.flags & 2u) != 0u) {\\n"\n'
     '\t\t\t\t\t"    emission *= sample_material_texture(rt_mat.emission_texture_idx, mat_uv, rt_mat.flags).rgb;\\n"\n'
     '\t\t\t\t\t"}\\n";')
