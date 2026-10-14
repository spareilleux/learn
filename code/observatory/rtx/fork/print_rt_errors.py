"""Diagnostic: the fork's ray tracing pipeline builder (scene_shader_raytracing.cpp) dumps a material's
hit shader that fails to compile but drops glslang's message. Print it.
    python print_rt_errors.py <godot source dir>"""
import re
import sys

p = sys.argv[1].rstrip('/') + '/servers/rendering/renderer_rd/forward_clustered/scene_shader_raytracing.cpp'
s = open(p, encoding='utf-8').read()
if 'RT hit shader compile error' in s:
    print('already')
    sys.exit(0)
n = 0


def add(m):
    global n
    n += 1
    return (f'{m.group(1)}ERR_PRINT(vformat("RT hit shader compile error (%s): %s", {m.group(3)}, error));\n'
            f'{m.group(1)}{m.group(2)}')


s = re.sub(r'(\t+)(_dump_failed_shader\([^,]+, (vformat\("hg%d_v%x_[a-z_]+", i, p_task->rt_flags\))\);)', add, s)
assert n == 3, n
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched', n)
