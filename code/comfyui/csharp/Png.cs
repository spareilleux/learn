using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;

namespace Learn.Comfy;

// A PNG file is an 8-byte signature followed by chunks: length, type, data, CRC-32.
// ComfyUI's SaveImage stores the workflow as text chunks next to the pixels.
public sealed record Chunk(string Type, byte[] Data);

public sealed record Pixels(int Width, int Height, int Channels, byte[] Data);

public static class Png
{
    static readonly byte[] Signature = [137, 80, 78, 71, 13, 10, 26, 10];

    public static List<Chunk> ReadChunks(string path)
    {
        using var reader = new BinaryReader(File.OpenRead(path));
        if (!reader.ReadBytes(8).AsSpan().SequenceEqual(Signature))
            throw new InvalidDataException($"{path} is not a PNG file");
        var chunks = new List<Chunk>();
        while (true)
        {
            int length = ReadBigEndian(reader);
            byte[] typeAndData = reader.ReadBytes(4 + length);
            uint crc = (uint)ReadBigEndian(reader);
            if (Crc32(typeAndData) != crc)
                throw new InvalidDataException("bad CRC");
            var chunk = new Chunk(Encoding.ASCII.GetString(typeAndData, 0, 4), typeAndData[4..]);
            chunks.Add(chunk);
            if (chunk.Type == "IEND") return chunks;
        }
    }

    // tEXt: keyword, a zero byte, then Latin-1 text.
    // iTXt: keyword, zero, compression flag, method, language tag, zero, translated keyword, zero, UTF-8 text.
    public static IEnumerable<(string Keyword, string Text)> TextChunks(IEnumerable<Chunk> chunks)
    {
        foreach (var chunk in chunks)
        {
            if (chunk.Type == "tEXt")
            {
                int zero = Array.IndexOf(chunk.Data, (byte)0);
                yield return (Encoding.Latin1.GetString(chunk.Data, 0, zero), Encoding.Latin1.GetString(chunk.Data, zero + 1, chunk.Data.Length - zero - 1));
            }
            else if (chunk.Type == "iTXt")
            {
                int zero = Array.IndexOf(chunk.Data, (byte)0);
                bool compressed = chunk.Data[zero + 1] == 1;
                int language = Array.IndexOf(chunk.Data, (byte)0, zero + 3);
                int translated = Array.IndexOf(chunk.Data, (byte)0, language + 1);
                byte[] text = chunk.Data[(translated + 1)..];
                if (compressed) text = Inflate(text);
                yield return (Encoding.Latin1.GetString(chunk.Data, 0, zero), Encoding.UTF8.GetString(text));
            }
        }
    }

    // Decodes 8-bit RGB or RGBA images without interlacing, which is what ComfyUI writes.
    public static Pixels ReadPixels(IReadOnlyList<Chunk> chunks)
    {
        byte[] header = chunks[0].Data;
        int width = ReadBigEndian(header, 0), height = ReadBigEndian(header, 4);
        byte bitDepth = header[8], colorType = header[9], interlace = header[12];
        if (bitDepth != 8 || colorType is not (2 or 6) || interlace != 0)
            throw new InvalidDataException($"unsupported PNG: bit depth {bitDepth}, color type {colorType}, interlace {interlace}");
        int channels = colorType == 2 ? 3 : 4;

        byte[] raw = Inflate(chunks.Where(c => c.Type == "IDAT").SelectMany(c => c.Data).ToArray());
        int stride = width * channels;
        var pixels = new byte[height * stride];
        for (int y = 0; y < height; y++)
        {
            int filter = raw[y * (stride + 1)];
            int src = y * (stride + 1) + 1, dst = y * stride;
            for (int x = 0; x < stride; x++)
            {
                int a = x >= channels ? pixels[dst + x - channels] : 0;
                int b = y > 0 ? pixels[dst + x - stride] : 0;
                int c = x >= channels && y > 0 ? pixels[dst + x - stride - channels] : 0;
                int predictor = filter switch
                {
                    0 => 0,
                    1 => a,
                    2 => b,
                    3 => (a + b) / 2,
                    4 => Paeth(a, b, c),
                    _ => throw new InvalidDataException($"unknown filter {filter}"),
                };
                pixels[dst + x] = (byte)(raw[src + x] + predictor);
            }
        }
        return new Pixels(width, height, channels, pixels);
    }

    public static string PixelHash(Pixels pixels) =>
        Convert.ToHexStringLower(SHA256.HashData(pixels.Data))[..16];

    static int Paeth(int a, int b, int c)
    {
        int p = a + b - c, pa = Math.Abs(p - a), pb = Math.Abs(p - b), pc = Math.Abs(p - c);
        return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
    }

    internal static byte[] Inflate(byte[] data)
    {
        using var output = new MemoryStream();
        using (var zlib = new ZLibStream(new MemoryStream(data), CompressionMode.Decompress))
            zlib.CopyTo(output);
        return output.ToArray();
    }

    static int ReadBigEndian(BinaryReader reader) => ReadBigEndian(reader.ReadBytes(4), 0);

    static int ReadBigEndian(byte[] b, int i) => b[i] << 24 | b[i + 1] << 16 | b[i + 2] << 8 | b[i + 3];

    static readonly uint[] CrcTable = Enumerable.Range(0, 256).Select(n =>
    {
        uint c = (uint)n;
        for (int k = 0; k < 8; k++) c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
        return c;
    }).ToArray();

    static uint Crc32(byte[] bytes)
    {
        uint c = 0xFFFFFFFF;
        foreach (byte b in bytes) c = CrcTable[(c ^ b) & 0xFF] ^ (c >> 8);
        return c ^ 0xFFFFFFFF;
    }
}

public static class PngCommands
{
    public static int Info(string path)
    {
        var chunks = Png.ReadChunks(path);
        foreach (var group in chunks.GroupBy(c => c.Type))
        {
            // How well zlib compresses depends on the zlib Pillow was built with: on Linux, the same pixels
            // took 84 bytes where Windows and macOS took 88. The inflated size doesn't change.
            string size = group.Key == "IDAT"
                ? $"{Png.Inflate(group.SelectMany(c => c.Data).ToArray()).Length} bytes once inflated"
                : $"{group.Sum(c => c.Data.Length)} bytes";
            Console.WriteLine($"chunk {group.Key}: {group.Count()} x, {size}");
        }
        foreach (var (keyword, text) in Png.TextChunks(chunks))
        {
            string start = text.Length > 60 ? text[..60] + "..." : text;
            Console.WriteLine($"text {keyword}: {text.Length} characters: {start}");
        }
        var pixels = Png.ReadPixels(chunks);
        Console.WriteLine($"image: {pixels.Width} x {pixels.Height}, {pixels.Channels} channels, pixel SHA-256 {Png.PixelHash(pixels)}");
        return 0;
    }

    public static int Compare(string first, string second)
    {
        var a = Png.ReadPixels(Png.ReadChunks(first));
        var b = Png.ReadPixels(Png.ReadChunks(second));
        if (a.Width != b.Width || a.Height != b.Height || a.Channels != b.Channels)
        {
            Console.WriteLine($"different sizes: {a.Width} x {a.Height} and {b.Width} x {b.Height}");
            return 1;
        }
        int pixelCount = a.Width * a.Height, changed = 0, changedMoreThan8 = 0, max = 0;
        long sum = 0;
        for (int p = 0; p < pixelCount; p++)
        {
            int pixelMax = 0;
            for (int ch = 0; ch < a.Channels; ch++)
            {
                int d = Math.Abs(a.Data[p * a.Channels + ch] - b.Data[p * b.Channels + ch]);
                sum += d;
                pixelMax = Math.Max(pixelMax, d);
            }
            if (pixelMax > 0) changed++;
            if (pixelMax > 8) changedMoreThan8++;
            max = Math.Max(max, pixelMax);
        }
        Console.WriteLine($"identical pixels: {(changed == 0 ? "yes" : "no")}");
        Console.WriteLine($"largest difference: {max} of 255, mean {(double)sum / (pixelCount * a.Channels):F3}");
        Console.WriteLine($"pixels that differ: {100.0 * changed / pixelCount:F2} %, by more than 8: {100.0 * changedMoreThan8 / pixelCount:F2} %");
        return 0;
    }
}
