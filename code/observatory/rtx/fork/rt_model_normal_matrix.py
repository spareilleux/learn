"""MODEL_NORMAL_MATRIX in a custom shader's vertex() run by the fork's hit groups: the hit shader renames
it to model_normal_matrix (scene_shader_raytracing.cpp) but never declared it, so every material whose
vertex() reads it failed to compile ("'model_normal_matrix' : undeclared identifier") and vanished from
the rays. In the Observatory: the gardens' plants (assets/garden_plant.gdshader), and with the same line
palace_garden, upperside and wing_stone (learn-08, 2026-10-12, artpass/dlss/NOTES.md, "Foundation path
traced"). Declared beside read_model_matrix and set from it as the rasterizer does: the inverse transpose
of its 3x3 part.
    python rt_model_normal_matrix.py <godot source dir>"""
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


edit(root + 'raytracing_custom_globals_inc.glsl',
     'mat4 read_model_matrix = mat4(1.0);\n',
     'mat4 read_model_matrix = mat4(1.0);\n'
     'mat3 model_normal_matrix = mat3(1.0); // MODEL_NORMAL_MATRIX (rt_model_normal_matrix.py)\n')
edit(root + 'raytracing_custom_fragment_inc.glsl',
     'read_model_matrix = mat4(gl_ObjectToWorldEXT) * rt_inv_aabb_xform;\n',
     'read_model_matrix = mat4(gl_ObjectToWorldEXT) * rt_inv_aabb_xform;\n'
     'model_normal_matrix = transpose(inverse(mat3(read_model_matrix))); // rt_model_normal_matrix.py\n')
