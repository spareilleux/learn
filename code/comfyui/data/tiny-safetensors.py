# Writes two small .safetensors files for check.sh, so that CI can test safetensors-info without a model:
#   tiny-lora.safetensors   two LoRA layers of rank 4 in kohya's naming, with their alpha, in bfloat16 and float32
#   tiny-quant.safetensors  one layer quantized ComfyUI's way: int8 weights, a scale, and a .comfy_quant JSON tensor
# usage: python tiny-safetensors.py <output folder>
import json, os, struct, sys

def write(path, tensors, metadata=None):
    # tensors: name -> (dtype, shape, raw bytes). The header maps each name to its byte range in the data.
    header, offset, data = {}, 0, b''
    if metadata:
        header['__metadata__'] = metadata
    for name, (dtype, shape, raw) in tensors.items():
        header[name] = {'dtype': dtype, 'shape': shape, 'data_offsets': [offset, offset + len(raw)]}
        offset += len(raw)
        data += raw
    text = json.dumps(header, separators=(',', ':')).encode()
    text += b' ' * (-len(text) % 8)  # the format pads the header to a multiple of 8 bytes
    with open(path, 'wb') as f:
        f.write(struct.pack('<Q', len(text)) + text + data)

def floats(count, fmt='<f'):
    return b''.join(struct.pack(fmt, (i % 7) / 10) for i in range(count))

def bfloat16(value):
    # 1 sign bit, 8 exponent bits, 7 mantissa bits: the top 16 bits of the float32 layout, rounded down.
    bits = struct.unpack('<I', struct.pack('<f', value))[0]
    return struct.pack('<H', (bits >> 16) & 0x8000 | (((bits >> 23) & 0xFF) << 7) | ((bits >> 16) & 0x7F))

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
write(os.path.join(out, 'tiny-lora.safetensors'), {
    'lora_unet_input_blocks_4_1_proj_in.alpha': ('BF16', [], bfloat16(4.0)),
    'lora_unet_input_blocks_4_1_proj_in.lora_down.weight': ('F32', [4, 16], floats(64)),
    'lora_unet_input_blocks_4_1_proj_in.lora_up.weight': ('F32', [16, 4], floats(64)),
    'lora_te1_text_model_encoder_layers_0_mlp_fc1.alpha': ('BF16', [], bfloat16(2.0)),
    'lora_te1_text_model_encoder_layers_0_mlp_fc1.lora_down.weight': ('F32', [4, 8], floats(32)),
    'lora_te1_text_model_encoder_layers_0_mlp_fc1.lora_up.weight': ('F32', [8, 4], floats(32)),
}, metadata={'ss_network_module': 'networks.lora', 'ss_network_dim': '4', 'ss_network_alpha': '4.0'})

quant = json.dumps({'format': 'int8_tensorwise'}).encode()
write(os.path.join(out, 'tiny-quant.safetensors'), {
    'layers.0.linear.weight': ('I8', [8, 8], bytes((i * 37) % 256 for i in range(64))),
    'layers.0.linear.weight_scale': ('F32', [], struct.pack('<f', 0.01)),
    'layers.0.linear.comfy_quant': ('U8', [len(quant)], quant),
    'layers.0.norm.weight': ('BF16', [8], b''.join(bfloat16(1.0) for _ in range(8))),
})
print('wrote tiny-lora.safetensors and tiny-quant.safetensors in', out)
