"""Unshaded custom ShaderMaterials in the fork's path tracer: render_mode unshaded was ignored, so
an unshaded surface's ALBEDO (its final colour on screen) was lit like paint and came out dark.
An unshaded surface now emits its ALBEDO and reflects nothing, which is what it shows in raster.
    python rt_unshaded.py <godot source dir>"""
import sys

root = sys.argv[1].rstrip('/') + '/servers/rendering/renderer_rd/forward_clustered/'


def edit(path, old, new):
    s = open(path, encoding='utf-8').read()
    if new in s:
        print('already', path)
        return
    assert s.count(old) == 1, (path, old[:80])
    open(path, 'w', encoding='utf-8', newline='\n').write(s.replace(old, new))
    print('patched', path)


edit(root + 'scene_shader_raytracing.h',
     '\t\tbool uses_alpha_clip = false; // Writes ALPHA_SCISSOR_THRESHOLD; needs per-HG any-hit\n',
     '\t\tbool uses_alpha_clip = false; // Writes ALPHA_SCISSOR_THRESHOLD; needs per-HG any-hit\n'
     '\t\tbool unshaded = false; // render_mode unshaded: ALBEDO is emitted, nothing is reflected\n')
cpp = root + 'scene_shader_raytracing.cpp'
edit(cpp,
     '\tactions.usage_flag_pointers["DISCARD"] = &detected_alpha_clip;\n',
     '\tactions.usage_flag_pointers["DISCARD"] = &detected_alpha_clip;\n'
     '\tbool detected_unshaded = false;\n'
     '\tactions.render_mode_flags["unshaded"] = &detected_unshaded;\n')
edit(cpp,
     '\tr_entry.uses_alpha_clip = detected_alpha_clip;\n',
     '\tr_entry.uses_alpha_clip = detected_alpha_clip;\n'
     '\tr_entry.unshaded = detected_unshaded;\n')
edit(cpp,
     '\t\tString fragment_code = entry.fragment_code;\n',
     '\t\tString fragment_code = entry.fragment_code;\n'
     '\t\tif (entry.unshaded && !fragment_code.is_empty()) {\n'
     '\t\t\t// What an unshaded surface shows is its ALBEDO: emit it, reflect nothing.\n'
     '\t\t\tfragment_code += "\\nemission += albedo;\\nalbedo = vec3(0.0);\\nmetallic = 0.0;\\nspecular = 0.0;\\nroughness = 1.0;\\n";\n'
     '\t\t}\n')
