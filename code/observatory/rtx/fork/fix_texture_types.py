"""Two placeholder textures of the wrong type, which NVIDIA's fork (e1157bf) turns into failures: it
added a check to RenderingDevice::uniform_set_create that a texture's type match the shader's
uniform, so the uniform set is not created and SDFGI's integration and the sky's fog-only pass are
dispatched without it every frame (on the Observatory, 9 failed dispatches a frame, its bounce light
missing). Both are upstream Godot 4.6.3 code the fork did not touch:
  - gi.cpp defines USE_OCTMAP_ARRAY for SDFGI's integrate shader, which tests
    USE_RADIANCE_OCTMAP_ARRAY (as fog.cpp and the forward renderers define it): the shader always
    declares a texture2D, and a sky stored as a 2D array is bound to it.
  - sky.cpp's fog-only set binds a black cubemap where sky.glsl declares texture2D radiance.
    python fix_texture_types.py <godot source dir>"""
import sys

G = sys.argv[1].rstrip('/')


def patch(rel, old, new):
    p = f'{G}/{rel}'
    s = open(p, encoding='utf-8').read()
    if new in s:
        print('already', rel)
        return
    assert s.count(old) == 1, (rel, old)
    open(p, 'w', encoding='utf-8', newline='\n').write(s.replace(old, new))
    print('patched', rel)


patch('servers/rendering/renderer_rd/environment/gi.cpp',
      '\t\t\tdefines += "\\n#define USE_OCTMAP_ARRAY\\n";',
      '\t\t\tdefines += "\\n#define USE_RADIANCE_OCTMAP_ARRAY\\n"; // The name sdfgi_integrate.glsl tests (was USE_OCTMAP_ARRAY).')
patch('servers/rendering/renderer_rd/environment/sky.cpp',
      '\t\t\tu.append_id(texture_storage->texture_rd_get_default(RendererRD::TextureStorage::DEFAULT_RD_TEXTURE_CUBEMAP_BLACK));\n'
      '\t\t\tuniforms.push_back(u);\n\t\t}\n\t\t{\n\t\t\tRD::Uniform u;\n\t\t\tu.uniform_type = RD::UNIFORM_TYPE_TEXTURE;\n\t\t\tu.binding = 1;',
      '\t\t\t// sky.glsl declares texture2D radiance (was a black cubemap).\n'
      '\t\t\tu.append_id(texture_storage->texture_rd_get_default(RendererRD::TextureStorage::DEFAULT_RD_TEXTURE_BLACK));\n'
      '\t\t\tuniforms.push_back(u);\n\t\t}\n\t\t{\n\t\t\tRD::Uniform u;\n\t\t\tu.uniform_type = RD::UNIFORM_TYPE_TEXTURE;\n\t\t\tu.binding = 1;')
