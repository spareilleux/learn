"""Follow-up to rt_custom_compat.py, after the first run on the Observatory:
  - dFdx/dFdy, like fwidth: a small constant. The Observatory's uses (bump mapping from
    derivatives, a cotangent frame, a sky's pixel angle) then give no bump and a one-pixel-ish
    angle instead of failing to compile; none divides by them unguarded.
  - The merge push constants: Godot rounds a shader's push constant size up to 16 bytes, so the
    two new words need two words of padding (80 and 64 bytes).
    python rt_custom_compat2.py <godot source dir>"""
import sys

root = sys.argv[1].rstrip('/') + '/servers/rendering/renderer_rd/'
SH = root + 'shaders/raytracing/'
FC = root + 'forward_clustered/'


def edit(path, pairs):
    s = open(path, encoding='utf-8').read()
    for old, new in pairs:
        assert s.count(old) >= 1, (path, old[:80])
        s = s.replace(old, new)
    open(path, 'w', encoding='utf-8', newline='\n').write(s)


if '#define dFdx' in open(SH + 'raytracing_custom_globals_inc.glsl', encoding='utf-8').read():
    print('already')
    sys.exit(0)
edit(SH + 'raytracing_custom_globals_inc.glsl', [(
    '#define fwidth(x) (abs(x) * 0.0 + 1e-4)\n',
    '#define fwidth(x) (abs(x) * 0.0 + 1e-4)\n'
    '#define dFdx(x) (abs(x) * 0.0 + 1e-4)\n'
    '#define dFdy(x) (abs(x) * 0.0 + 1e-4)\n')])
edit(SH + 'multimesh_merge.glsl', [(
    "\tuint mm_custom_words; // offset of INSTANCE_CUSTOM in an instance's stride, 0xFFFFFFFF if none\n",
    "\tuint mm_custom_words; // offset of INSTANCE_CUSTOM in an instance's stride, 0xFFFFFFFF if none\n"
    "\tuint pad0; // push constants come in 16 bytes\n"
    "\tuint pad1;\n")])
edit(FC + 'render_raytracing.cpp', [
    ('\t\t\tuint32_t mm_color_words, mm_custom_words;\n\t\t} pc;\n',
     '\t\t\tuint32_t mm_color_words, mm_custom_words;\n\t\t\tuint32_t pad0 = 0, pad1 = 0; // 16-byte push constants\n\t\t} pc;\n'),
    ('\t\t\t\tuint32_t mm_color_words, mm_custom_words;\n\t\t\t} pc_ni;\n',
     '\t\t\t\tuint32_t mm_color_words, mm_custom_words;\n\t\t\t\tuint32_t pad0 = 0, pad1 = 0;\n\t\t\t} pc_ni;\n'),
])
print('patched')
