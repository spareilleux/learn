using System.IO.Compression;
using System.Text;

namespace Learn.Comfy;

// Writing PNG files: the inputs of lesson 5 are made by this tool, not drawn in an image editor.
public static class PngWriter
{
    public static void Write(string path, Pixels pixels)
    {
        using var file = File.Create(path);
        file.Write([137, 80, 78, 71, 13, 10, 26, 10]);

        var header = new byte[13];
        WriteBigEndian(header, 0, pixels.Width);
        WriteBigEndian(header, 4, pixels.Height);
        header[8] = 8;                                  // bits per channel
        header[9] = (byte)(pixels.Channels == 4 ? 6 : 2); // 6 = RGBA, 2 = RGB
        WriteChunk(file, "IHDR", header);

        // Each row starts with its filter type; 0 means the bytes are stored as they are.
        int stride = pixels.Width * pixels.Channels;
        using var raw = new MemoryStream();
        using (var zlib = new ZLibStream(raw, CompressionLevel.Optimal, leaveOpen: true))
            for (int y = 0; y < pixels.Height; y++)
            {
                zlib.WriteByte(0);
                zlib.Write(pixels.Data, y * stride, stride);
            }
        WriteChunk(file, "IDAT", raw.ToArray());
        WriteChunk(file, "IEND", []);
    }

    static void WriteChunk(Stream file, string type, byte[] data)
    {
        var length = new byte[4];
        WriteBigEndian(length, 0, data.Length);
        file.Write(length);
        byte[] typeAndData = [.. Encoding.ASCII.GetBytes(type), .. data];
        file.Write(typeAndData);
        var crc = new byte[4];
        WriteBigEndian(crc, 0, (int)Png.Crc32(typeAndData));
        file.Write(crc);
    }

    static void WriteBigEndian(byte[] b, int i, int value)
    {
        b[i] = (byte)(value >> 24); b[i + 1] = (byte)(value >> 16); b[i + 2] = (byte)(value >> 8); b[i + 3] = (byte)value;
    }
}

public static class ImageCommands
{
    // make-image <width> <height> <out.png>: a test pattern that needs no model, for CI.
    // Red grows to the right, green grows downwards, blue is a checkerboard of 8-pixel squares.
    public static int Make(int width, int height, string output)
    {
        var data = new byte[width * height * 3];
        for (int y = 0; y < height; y++)
            for (int x = 0; x < width; x++)
            {
                int p = (y * width + x) * 3;
                data[p] = (byte)(255 * x / Math.Max(1, width - 1));
                data[p + 1] = (byte)(255 * y / Math.Max(1, height - 1));
                data[p + 2] = (byte)(((x / 8) + (y / 8)) % 2 == 0 ? 40 : 200);
            }
        var pixels = new Pixels(width, height, 3, data);
        PngWriter.Write(output, pixels);
        Console.WriteLine($"{output}: {width} x {height}, 3 channels, pixel SHA-256 {Png.PixelHash(pixels)}");
        return 0;
    }

    // cut <in.png> <out.png> <cx> <cy> <rx> <ry> [feather]: copies an image with an alpha channel that is
    // transparent inside an ellipse. LoadImage turns transparency into its mask: mask = 1 - alpha.
    // With a feather width in pixels, alpha rises from 0 to 255 across that band outside the ellipse.
    public static int Cut(string input, string output, double cx, double cy, double rx, double ry, double feather)
    {
        var source = Png.ReadPixels(Png.ReadChunks(input));
        if (source.BitDepth != 8) throw new InvalidDataException("cut reads 8-bit images only");
        var data = new byte[source.Width * source.Height * 4];
        int transparent = 0;
        for (int y = 0; y < source.Height; y++)
            for (int x = 0; x < source.Width; x++)
            {
                int s = (y * source.Width + x) * source.Channels, d = (y * source.Width + x) * 4;
                for (int ch = 0; ch < 3; ch++) data[d + ch] = source.Data[s + ch];
                // The distance outside the ellipse, roughly in pixels along the smaller radius.
                double r = Math.Sqrt(Math.Pow((x + 0.5 - cx) / rx, 2) + Math.Pow((y + 0.5 - cy) / ry, 2));
                double outside = (r - 1) * Math.Min(rx, ry);
                double alpha = outside <= 0 ? 0 : feather <= 0 ? 1 : Math.Min(1, outside / feather);
                data[d + 3] = (byte)Math.Round(255 * alpha);
                if (data[d + 3] == 0) transparent++;
            }
        var pixels = new Pixels(source.Width, source.Height, 4, data);
        PngWriter.Write(output, pixels);
        Console.WriteLine($"{output}: {source.Width} x {source.Height}, {transparent} transparent pixels, pixel SHA-256 {Png.PixelHash(pixels)}");
        return 0;
    }
}
