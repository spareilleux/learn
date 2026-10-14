"""Custom ShaderMaterials in the fork's path tracer: make the Observatory's compile and render.

The fork translates a spatial shader's vertex() and fragment() into its closest-hit and any-hit
shaders. Five of the Observatory's materials failed to compile there, and fell out of the scene:
  - fwidth(): no screen-space derivatives in a ray tracing stage. Defined as a small constant
    footprint: filtered procedural patterns come out sharp, and DLSS-RR's accumulation over the
    jittered frames antialiases them.
  - POSITION: written by a vertex() that places geometry itself (the night sky). Declared and
    ignored: a hit is where the geometry is.
  - discard: not allowed in closest-hit. A material that discards now counts as alpha-clipped, so
    its instances are not forced opaque and get the custom any-hit, where discard becomes
    ignoreIntersectionEXT; in closest-hit it cannot be reached and becomes a no-op.
  - INSTANCE_CUSTOM, and a MultiMesh's per-instance COLOR: the merged MultiMesh BLAS replicated the
    mesh's vertex attributes but dropped the instance's colour and custom data, so every book came
    out the same. The merge dispatch now also writes each instance's colour and custom data (8
    floats) to a buffer that GeometryData points at, and the hit shaders read the instance's from
    the vertex index (vertices per instance in GeometryData's padding): COLOR = vertex colour x
    instance colour, as the rasterizer does.
    python rt_custom_compat.py <godot source dir>"""
import sys

root = sys.argv[1].rstrip('/') + '/servers/rendering/renderer_rd/'
SH = root + 'shaders/raytracing/'
FC = root + 'forward_clustered/'
MARK = 'instance_data_address_lo'


def edit(path, pairs):
    s = open(path, encoding='utf-8').read()
    for old, new in pairs:
        n = s.count(old)
        assert n >= 1, (path, old[:80])
        s = s.replace(old, new)
    open(path, 'w', encoding='utf-8', newline='\n').write(s)


if MARK in open(SH + 'raytracing_data_inc.glsl', encoding='utf-8').read():
    print('already')
    sys.exit(0)

# --- GeometryData: the per-instance data of a merged MultiMesh, in the padding ---
edit(SH + 'raytracing_data_inc.glsl', [(
    '\tuint _pad[5];\n};',
    '\t// Merged MultiMesh: address of the instances\' COLOR and INSTANCE_CUSTOM (8 floats each,\n'
    '\t// 0 = none), and the vertices per instance, to find a vertex\'s instance.\n'
    '\tuint instance_data_address_lo;\n'
    '\tuint instance_data_address_hi;\n'
    '\tuint instance_vertex_count;\n'
    '\tuint _pad[2];\n};')])
edit(FC + 'render_raytracing.h', [
    ('\tuint32_t _pad[5];\n};\nstatic_assert(sizeof(RT_GeometryData) == 128',
     '\t// Merged MultiMesh: address of the instances\' COLOR and INSTANCE_CUSTOM (8 floats each,\n'
     '\t// 0 = none), and the vertices per instance, to find a vertex\'s instance.\n'
     '\tuint32_t instance_data_address_lo;\n'
     '\tuint32_t instance_data_address_hi;\n'
     '\tuint32_t instance_vertex_count;\n'
     '\tuint32_t _pad[2];\n};\nstatic_assert(sizeof(RT_GeometryData) == 128'),
    ('\t// Replicated index buffer: uint32 N*I entries (invalid if non-indexed).\n\tRID replicated_idx_buffer;\n\tuint32_t idx_capacity = 0;\n',
     '\t// Replicated index buffer: uint32 N*I entries (invalid if non-indexed).\n\tRID replicated_idx_buffer;\n\tuint32_t idx_capacity = 0;\n\n'
     '\t// Per-instance COLOR and INSTANCE_CUSTOM, 8 floats per instance (white and zero if unused).\n'
     '\tRID merged_inst_buffer;\n\tuint32_t inst_capacity_bytes = 0;\n'),
])

# --- Hit shaders: read the instance's data ---
edit(SH + 'raytracing_hit_inc.glsl', [(
    '// ============================================================================\n// TBN FETCHING',
    '/// Merged MultiMesh: the instance\'s COLOR and INSTANCE_CUSTOM (white and zero elsewhere).\n'
    'void fetch_instance_data(in GeometryData geom, uint i0, out vec4 r_color, out vec4 r_custom) {\n'
    '\tr_color = vec4(1.0);\n'
    '\tr_custom = vec4(0.0);\n'
    '\tuint64_t addr = packUint2x32(uvec2(geom.instance_data_address_lo, geom.instance_data_address_hi));\n'
    '\tif (addr == 0ul || geom.instance_vertex_count == 0u) {\n'
    '\t\treturn;\n'
    '\t}\n'
    '\tFloatBuffer d = FloatBuffer(addr);\n'
    '\tuint b = (i0 / geom.instance_vertex_count) * 8u;\n'
    '\tr_color = vec4(d.v[b], d.v[b + 1u], d.v[b + 2u], d.v[b + 3u]);\n'
    '\tr_custom = vec4(d.v[b + 4u], d.v[b + 5u], d.v[b + 6u], d.v[b + 7u]);\n'
    '}\n\n'
    '// ============================================================================\n// TBN FETCHING')])
edit(SH + 'raytracing_closest_hit_common_inc.glsl', [
    ('\tvec4 color; // Vertex color (white if not present).\n',
     '\tvec4 color; // Vertex color (white if not present), times a MultiMesh instance\'s.\n'
     '\tvec4 instance_custom; // A MultiMesh instance\'s custom data (zero if none).\n'),
    ('\th.uv = attrs.uv;\n\th.color = attrs.color;\n',
     '\th.uv = attrs.uv;\n\th.color = attrs.color;\n'
     '\th.instance_custom = vec4(0.0);\n'
     '#ifdef RT_CUSTOM_HIT_GROUP\n'
     '\t{\n'
     '\t\tuint ii0, ii1, ii2;\n'
     '\t\tget_triangle_indices(geom, ii0, ii1, ii2);\n'
     '\t\tvec4 inst_color;\n'
     '\t\tfetch_instance_data(geom, ii0, inst_color, h.instance_custom);\n'
     '\t\th.color *= inst_color;\n'
     '\t}\n'
     '#endif\n'),
])
edit(SH + 'scene_raytracing_raygen.glsl', [
    ('\tvec4 rt_color = h.color;\n',
     '\tvec4 rt_color = h.color;\n\tvec4 rt_instance_custom = h.instance_custom;\n'),
    ('\tvec4 rt_color = fetch_color(geom, i0, i1, i2, bary);\n',
     '\tvec4 rt_color = fetch_color(geom, i0, i1, i2, bary);\n'
     '\tvec4 rt_instance_custom;\n'
     '\t{\n'
     '\t\tvec4 inst_color;\n'
     '\t\tfetch_instance_data(geom, i0, inst_color, rt_instance_custom);\n'
     '\t\trt_color *= inst_color;\n'
     '\t}\n'),
])
edit(SH + 'raytracing_custom_globals_inc.glsl', [(
    'vec2 alpha_texture_coordinate = vec2(0.0);\n',
    'vec2 alpha_texture_coordinate = vec2(0.0);\n'
    'vec4 instance_custom = vec4(0.0);\n'
    '// Written by a vertex() that places its geometry itself (a sky at infinity); a hit is where\n'
    '// the geometry is, so it is ignored.\n'
    'vec4 position = vec4(0.0);\n'
    '// No screen-space derivatives in a ray tracing stage: a small constant footprint, so filtered\n'
    '// procedural patterns come out sharp and the accumulation over jittered frames antialiases them.\n'
    '#define fwidth(x) (abs(x) * 0.0 + 1e-4)\n')])
edit(SH + 'raytracing_custom_fragment_inc.glsl', [(
    'color_interp = rt_color;\n',
    'color_interp = rt_color;\ninstance_custom = rt_instance_custom;\n')])

# --- The merge dispatch writes the instances' colour and custom data ---
edit(SH + 'multimesh_merge.glsl', [
    ('#ifdef MODE_INDEXED\nlayout(set = 0, binding = 4)',
     '// Per instance: COLOR (4 floats) then INSTANCE_CUSTOM (4 floats).\n'
     'layout(set = 0, binding = 5) restrict writeonly buffer DstInstBuf {\n\tfloat v[];\n}\ndst_inst;\n\n'
     '#ifdef MODE_INDEXED\nlayout(set = 0, binding = 4)'),
    ('\tuint attr_stride_words; // attribute stride in uint words (0 = mesh has no attribs)\n}\npush;',
     '\tuint attr_stride_words; // attribute stride in uint words (0 = mesh has no attribs)\n'
     '\tuint mm_color_words; // offset of COLOR in an instance\'s stride, 0xFFFFFFFF if none\n'
     '\tuint mm_custom_words; // offset of INSTANCE_CUSTOM in an instance\'s stride, 0xFFFFFFFF if none\n'
     '}\npush;'),
    ('\tuint total_v = push.vertex_count * push.instance_count;\n',
     '\tuint total_v = push.vertex_count * push.instance_count;\n\n'
     '\t// --- Per-instance section: COLOR and INSTANCE_CUSTOM ---\n'
     '\tif (idx < push.instance_count) {\n'
     '\t\tuint ib = (push.mm_offset + idx) * push.mm_stride;\n'
     '\t\tvec4 col = vec4(1.0);\n'
     '\t\tvec4 cus = vec4(0.0);\n'
     '\t\tif (push.mm_color_words != 0xFFFFFFFFu) {\n'
     '\t\t\tuint o = ib + push.mm_color_words;\n'
     '\t\t\tcol = vec4(mm_buf.v[o], mm_buf.v[o + 1u], mm_buf.v[o + 2u], mm_buf.v[o + 3u]);\n'
     '\t\t}\n'
     '\t\tif (push.mm_custom_words != 0xFFFFFFFFu) {\n'
     '\t\t\tuint o = ib + push.mm_custom_words;\n'
     '\t\t\tcus = vec4(mm_buf.v[o], mm_buf.v[o + 1u], mm_buf.v[o + 2u], mm_buf.v[o + 3u]);\n'
     '\t\t}\n'
     '\t\tfor (uint k = 0u; k < 4u; k++) {\n'
     '\t\t\tdst_inst.v[idx * 8u + k] = col[k];\n'
     '\t\t\tdst_inst.v[idx * 8u + 4u + k] = cus[k];\n'
     '\t\t}\n'
     '\t}\n'),
])

free_e = ('\t\t\tif (e->replicated_idx_buffer.is_valid()) {\n'
          '\t\t\t\trd->free_rid(e->replicated_idx_buffer);\n'
          '\t\t\t\te->replicated_idx_buffer = RID();\n'
          '\t\t\t}\n')
free_old = ('\t\t\tif (old->replicated_idx_buffer.is_valid()) {\n'
            '\t\t\t\trd_local->free_rid(old->replicated_idx_buffer);\n'
            '\t\t\t}\n')
cpp = FC + 'render_raytracing.cpp'
s = open(cpp, encoding='utf-8').read()
assert s.count(free_e) == 2 and s.count(free_old) == 1
open(cpp, 'w', encoding='utf-8', newline='\n').write(s)
edit(cpp, [
    (free_e, free_e + '\t\t\tif (e->merged_inst_buffer.is_valid()) {\n'
                      '\t\t\t\trd->free_rid(e->merged_inst_buffer);\n'
                      '\t\t\t\te->merged_inst_buffer = RID();\n'
                      '\t\t\t}\n'),
    (free_old, free_old + '\t\t\tif (old->merged_inst_buffer.is_valid()) {\n'
                          '\t\t\t\trd_local->free_rid(old->merged_inst_buffer);\n'
                          '\t\t\t}\n'),
    ('\t// --- Grow / allocate replicated index buffer ---\n',
     '\t// --- Grow / allocate the per-instance data buffer: COLOR and INSTANCE_CUSTOM, 8 floats each ---\n'
     '\tuint32_t merged_inst_bytes = MAX(p_mm_count, 1u) * 32;\n'
     '\tif (!entry.merged_inst_buffer.is_valid() || entry.inst_capacity_bytes < merged_inst_bytes) {\n'
     '\t\tif (entry.merged_inst_buffer.is_valid()) {\n'
     '\t\t\trd->free_rid(entry.merged_inst_buffer);\n'
     '\t\t\tentry.merged_inst_buffer = RID();\n'
     '\t\t}\n'
     '\t\tentry.inst_capacity_bytes = merged_inst_bytes;\n'
     '\t\tentry.merged_inst_buffer = rd->storage_buffer_create(merged_inst_bytes, {}, 0, gpu_buf_flags);\n'
     '\t\tERR_FAIL_COND_V(!entry.merged_inst_buffer.is_valid(), false);\n'
     '\t\trd->set_resource_name(entry.merged_inst_buffer, "RT MM merged inst [" + itos(cache_key) + "]");\n'
     '\t}\n\n'
     '\t// --- Grow / allocate replicated index buffer ---\n'),
    ('\t\t\tif (indexed) {\n\t\t\t\tpush_buf(4, entry.replicated_idx_buffer);\n\t\t\t}\n',
     '\t\t\tif (indexed) {\n\t\t\t\tpush_buf(4, entry.replicated_idx_buffer);\n\t\t\t}\n'
     '\t\t\tpush_buf(5, entry.merged_inst_buffer);\n'),
    ('\t\t\tuint32_t has_tbn;\n\t\t\tuint32_t attr_stride_words;\n\t\t} pc;\n',
     '\t\t\tuint32_t has_tbn;\n\t\t\tuint32_t attr_stride_words;\n'
     '\t\t\tuint32_t mm_color_words, mm_custom_words;\n\t\t} pc;\n'),
    ('\t\tpc.attr_stride_words = has_attr ? (attrib_stride / 4) : 0u;\n',
     '\t\tpc.attr_stride_words = has_attr ? (attrib_stride / 4) : 0u;\n'
     '\t\t// The instance stride: a 3x4 transform, then COLOR, then INSTANCE_CUSTOM, each if used.\n'
     '\t\tconst bool mm_colors = mesh_storage->multimesh_uses_colors(p_mm_rid);\n'
     '\t\tconst bool mm_custom = mesh_storage->multimesh_uses_custom_data(p_mm_rid);\n'
     '\t\tpc.mm_color_words = mm_colors ? 12u : 0xFFFFFFFFu;\n'
     '\t\tpc.mm_custom_words = mm_custom ? (mm_colors ? 16u : 12u) : 0xFFFFFFFFu;\n'),
    ('\t\t\t\tuint32_t has_tbn;\n\t\t\t\tuint32_t attr_stride_words;\n\t\t\t} pc_ni;\n',
     '\t\t\t\tuint32_t has_tbn;\n\t\t\t\tuint32_t attr_stride_words;\n'
     '\t\t\t\tuint32_t mm_color_words, mm_custom_words;\n\t\t\t} pc_ni;\n'),
    ('\t\t\tpc_ni.attr_stride_words = pc.attr_stride_words;\n',
     '\t\t\tpc_ni.attr_stride_words = pc.attr_stride_words;\n'
     '\t\t\tpc_ni.mm_color_words = pc.mm_color_words;\n'
     '\t\t\tpc_ni.mm_custom_words = pc.mm_custom_words;\n'),
    ('\t// Point attribute address at fully replicated attribute buffer.\n',
     '\t// The instances\' COLOR and INSTANCE_CUSTOM, found from a vertex index.\n'
     '\tif (entry.merged_inst_buffer.is_valid()) {\n'
     '\t\tuint64_t inst_addr = rd->buffer_get_device_address(entry.merged_inst_buffer);\n'
     '\t\tgeom.instance_data_address_lo = uint32_t(inst_addr);\n'
     '\t\tgeom.instance_data_address_hi = uint32_t(inst_addr >> 32);\n'
     '\t\tgeom.instance_vertex_count = vertex_count;\n'
     '\t}\n\n'
     '\t// Point attribute address at fully replicated attribute buffer.\n'),
    ('\t\tif (e->replicated_idx_buffer.is_valid()) {\n'
     '\t\t\trd->raytracing_list_add_buffer_dependency(p_list, e->replicated_idx_buffer, /*p_writable=*/false);\n'
     '\t\t}\n',
     '\t\tif (e->replicated_idx_buffer.is_valid()) {\n'
     '\t\t\trd->raytracing_list_add_buffer_dependency(p_list, e->replicated_idx_buffer, /*p_writable=*/false);\n'
     '\t\t}\n'
     '\t\tif (e->merged_inst_buffer.is_valid()) {\n'
     '\t\t\trd->raytracing_list_add_buffer_dependency(p_list, e->merged_inst_buffer, /*p_writable=*/false);\n'
     '\t\t}\n'),
])

# --- discard: alpha-clipped for routing; ignoreIntersectionEXT in any-hit, a no-op in closest-hit ---
edit(FC + 'scene_shader_raytracing.cpp', [
    ('\tactions.usage_flag_pointers["ALPHA_HASH_SCALE"] = &detected_alpha_clip;\n\n\tHashMap<StringName, ShaderLanguage::ShaderNode::Uniform> uniform_sink;',
     '\tactions.usage_flag_pointers["ALPHA_HASH_SCALE"] = &detected_alpha_clip;\n'
     '\t// A fragment() that discards needs the any-hit, where discard ignores the intersection.\n'
     '\tactions.usage_flag_pointers["DISCARD"] = &detected_alpha_clip;\n\n'
     '\tHashMap<StringName, ShaderLanguage::ShaderNode::Uniform> uniform_sink;'),
    ('\t\t\tString s = ctx.ch_template;\n'
     '\t\t\ts = s.replace("/* RT_CUSTOM_FRAGMENT_GLOBALS */", entry.fragment_globals);\n'
     '\t\t\ts = s.replace("/* RT_CUSTOM_FRAGMENT_CODE */", fragment_code);\n',
     '\t\t\tString s = ctx.ch_template;\n'
     '\t\t\ts = s.replace("/* RT_CUSTOM_FRAGMENT_GLOBALS */", entry.fragment_globals);\n'
     '\t\t\t// No discard in closest-hit; the any-hit already ignored a discarded hit.\n'
     '\t\t\ts = s.replace("/* RT_CUSTOM_FRAGMENT_CODE */", fragment_code.replace("discard;", "{}"));\n'),
    ('\t\t\tString s = ctx.ah_template;\n'
     '\t\t\ts = s.replace("/* RT_CUSTOM_FRAGMENT_GLOBALS */", entry.fragment_globals);\n'
     '\t\t\ts = s.replace("/* RT_CUSTOM_FRAGMENT_CODE */", fragment_code);\n',
     '\t\t\tString s = ctx.ah_template;\n'
     '\t\t\ts = s.replace("/* RT_CUSTOM_FRAGMENT_GLOBALS */", entry.fragment_globals);\n'
     '\t\t\ts = s.replace("/* RT_CUSTOM_FRAGMENT_CODE */", fragment_code.replace("discard;", "ignoreIntersectionEXT;"));\n'),
])
print('patched')
