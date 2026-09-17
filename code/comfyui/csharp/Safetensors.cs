using System.Text;
using System.Text.Json.Nodes;

namespace Learn.Comfy;

// A .safetensors file is an 8-byte little-endian header length, a JSON header, then the tensor bytes.
// The header gives each tensor's dtype, shape and byte range, so a tool can describe a model without loading it.
public static class Safetensors
{
    public static int Info(string path)
    {
        using var file = File.OpenRead(path);
        using var reader = new BinaryReader(file);
        long headerLength = reader.ReadInt64();
        var header = JsonNode.Parse(Encoding.UTF8.GetString(reader.ReadBytes(checked((int)headerLength))))!.AsObject();
        long dataStart = 8 + headerLength;
        var metadata = header["__metadata__"]?.AsObject();
        var tensors = header.Where(t => t.Key != "__metadata__").ToList();
        long dataLength = tensors.Max(t => t.Value!["data_offsets"]![1]!.GetValue<long>());
        bool hasData = file.Length >= dataStart + dataLength;

        Console.WriteLine($"{Path.GetFileName(path)}: header {headerLength} bytes, {tensors.Count} tensors, "
            + (hasData ? $"{Size(dataLength)} of tensor data" : "header only, no tensor data in this file"));
        foreach (var group in tensors.GroupBy(t => t.Value!["dtype"]!.GetValue<string>()).OrderByDescending(g => g.Sum(Bytes)))
            Console.WriteLine($"  {group.Key,-8} {group.Count(),5} tensors, {Size(group.Sum(Bytes)),9}");

        // LoRA files: each adapted layer has a down matrix (rank x inputs) and an up matrix (outputs x rank).
        var down = tensors.Where(t => t.Key.EndsWith(".lora_down.weight") || t.Key.EndsWith(".lora_A.weight")).ToList();
        if (down.Count > 0)
        {
            var ranks = down.Select(t => t.Value!["shape"]![0]!.GetValue<long>()).Distinct().Order();
            int unet = down.Count(t => t.Key.StartsWith("lora_unet") || t.Key.StartsWith("unet."));
            Console.WriteLine($"LoRA: {down.Count} adapted layers ({unet} in the UNet, {down.Count - unet} in the text encoders), rank {string.Join(", ", ranks)}");
            var alphas = tensors.Where(t => t.Key.EndsWith(".alpha")).ToList();
            if (alphas.Count > 0 && hasData)
            {
                var values = alphas.Select(t => ReadScalar(file, dataStart, t.Value!)).Distinct().Order();
                Console.WriteLine($"  alpha: {string.Join(", ", values)} (the weight change is scaled by alpha / rank)");
            }
            else if (alphas.Count > 0)
                Console.WriteLine($"  alpha: {alphas.Count} scalar tensors, not in this file");
        }

        // Quantized files: ComfyUI reads the format of each layer from _quantization_metadata in the header,
        // or from a small uint8 tensor named <layer>.comfy_quant that holds a JSON object.
        if (metadata?["_quantization_metadata"] is JsonNode quant)
        {
            var layers = JsonNode.Parse(quant.GetValue<string>())!["layers"]!.AsObject();
            var formats = layers.GroupBy(l => l.Value!["format"]!.GetValue<string>()).Select(g => $"{g.Count()} {g.Key}");
            Console.WriteLine($"quantized layers (_quantization_metadata): {string.Join(", ", formats)}");
        }
        var comfyQuant = tensors.Where(t => t.Key.EndsWith(".comfy_quant")).ToList();
        if (comfyQuant.Count > 0)
        {
            if (hasData)
            {
                var formats = comfyQuant.Select(t => ReadText(file, dataStart, t.Value!)).GroupBy(s => s).Select(g => $"{g.Count()} x {g.Key}");
                Console.WriteLine($"quantized layers (.comfy_quant): {comfyQuant.Count}");
                foreach (string format in formats) Console.WriteLine($"  {format}");
            }
            else
                Console.WriteLine($"quantized layers (.comfy_quant): {comfyQuant.Count}, their JSON is not in this file");
        }

        if (metadata is not null)
            foreach (string key in new[] { "ss_sd_model_name", "ss_base_model_version", "ss_network_module", "ss_network_dim", "ss_network_alpha", "modelspec.architecture", "modelspec.title" })
                if (metadata[key] is JsonNode value)
                    Console.WriteLine($"metadata {key}: {value}");
        return 0;
    }

    static string Size(long bytes) => bytes >= 100_000_000 ? $"{bytes / 1e9:F2} GB" : bytes >= 100_000 ? $"{bytes / 1e6:F1} MB" : $"{bytes} bytes";

    static long Bytes(KeyValuePair<string, JsonNode?> tensor) =>
        tensor.Value!["data_offsets"]![1]!.GetValue<long>() - tensor.Value["data_offsets"]![0]!.GetValue<long>();

    static byte[] ReadBytes(FileStream file, long dataStart, JsonNode tensor)
    {
        long from = tensor["data_offsets"]![0]!.GetValue<long>(), to = tensor["data_offsets"]![1]!.GetValue<long>();
        var bytes = new byte[to - from];
        file.Seek(dataStart + from, SeekOrigin.Begin);
        file.ReadExactly(bytes);
        return bytes;
    }

    static double ReadScalar(FileStream file, long dataStart, JsonNode tensor)
    {
        byte[] b = ReadBytes(file, dataStart, tensor);
        return tensor["dtype"]!.GetValue<string>() switch
        {
            "F32" => BitConverter.ToSingle(b),
            "F16" => (double)BitConverter.ToHalf(b),
            "BF16" => BFloat16(BitConverter.ToUInt16(b)),
            "F64" => BitConverter.ToDouble(b),
            string other => throw new InvalidDataException($"unexpected alpha dtype {other}"),
        };
    }

    // bfloat16: 1 sign bit, 8 exponent bits like a float32, 7 mantissa bits.
    static double BFloat16(ushort bits)
    {
        int sign = bits >> 15, exponent = (bits >> 7) & 0xFF, mantissa = bits & 0x7F;
        double value = exponent == 0 ? mantissa / 128.0 * Math.Pow(2, -126) : (1 + mantissa / 128.0) * Math.Pow(2, exponent - 127);
        return sign == 1 ? -value : value;
    }

    static string ReadText(FileStream file, long dataStart, JsonNode tensor) =>
        Encoding.UTF8.GetString(ReadBytes(file, dataStart, tensor));
}
