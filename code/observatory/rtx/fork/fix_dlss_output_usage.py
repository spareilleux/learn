"""DLSS output one frame late. NVIDIA's fork (e1157bf) runs DLSS as a render-graph callback
(DLSSEffect::upscale, driver_callback_add) and declares every texture it touches as sampled,
including the output that DLSS writes. The graph therefore sees no write to that texture, so it
does not order the tonemap's read of it after the callback: the screen showed the previous
frame's DLSS output. Measured 2026-10-06 with ga-godot probes/moonring/motion_probe.gd: under
camera motion every DLSS setting matched the reference one frame back, while FSR2, fed the same
motion vectors, matched the current frame. Upstream's MetalFX callbacks declare their
destination CALLBACK_RESOURCE_USAGE_STORAGE_IMAGE_READ_WRITE (metal_fx.mm).
The output is now declared read-write, which the graph lays out as VK_IMAGE_LAYOUT_GENERAL, and
it is tagged to Streamline in that layout (D3D12: UNORDERED_ACCESS) instead of shader-read-only.
    python fix_dlss_output_usage.py <godot source dir>"""
import sys

G = sys.argv[1].rstrip('/')
F = 'servers/rendering/renderer_rd/effects/dlss.cpp'


def patch(rel, old, new):
    p = f'{G}/{rel}'
    s = open(p, encoding='utf-8').read()
    if new in s:
        print('already', rel)
        return
    assert s.count(old) == 1, (rel, old)
    open(p, 'w', encoding='utf-8', newline='\n').write(s.replace(old, new))
    print('patched', rel)


patch(F,
      'static constexpr uint64_t DLSS_D3D12_RESOURCE_STATE_NON_PIXEL_SR = 0x40;\n',
      'static constexpr uint64_t DLSS_D3D12_RESOURCE_STATE_NON_PIXEL_SR = 0x40;\n'
      'static constexpr uint64_t DLSS_VK_IMAGE_LAYOUT_GENERAL = 1; // The layout of a read-write storage image.\n'
      'static constexpr uint64_t DLSS_D3D12_RESOURCE_STATE_UNORDERED_ACCESS = 0x8;\n')
patch(F,
      '\tfor (int i = 0; i < num_resources; i++) {\n'
      '\t\tres[i].usage = RD::CALLBACK_RESOURCE_USAGE_TEXTURE_SAMPLE;\n'
      '\t}\n',
      '\tfor (int i = 0; i < num_resources; i++) {\n'
      '\t\tres[i].usage = RD::CALLBACK_RESOURCE_USAGE_TEXTURE_SAMPLE;\n'
      '\t}\n'
      '\t// DLSS writes its output. Declared as sampled, the graph let the tonemap read it before DLSS ran.\n'
      '\tres[1].usage = RD::CALLBACK_RESOURCE_USAGE_STORAGE_IMAGE_READ_WRITE;\n')
patch(F,
      '\t\tif (context->is_d3d12) {\n'
      '\t\t\ttexture_state = DLSS_D3D12_RESOURCE_STATE_NON_PIXEL_SR;\n'
      '\t\t}\n',
      '\t\tif (context->is_d3d12) {\n'
      '\t\t\ttexture_state = DLSS_D3D12_RESOURCE_STATE_NON_PIXEL_SR;\n'
      '\t\t}\n'
      '\t\tif (bufferType == sl::kBufferTypeScalingOutputColor) {\n'
      '\t\t\t// The graph hands the output over as a read-write storage image (see upscale()).\n'
      '\t\t\ttexture_state = context->is_d3d12 ? DLSS_D3D12_RESOURCE_STATE_UNORDERED_ACCESS : DLSS_VK_IMAGE_LAYOUT_GENERAL;\n'
      '\t\t}\n')
