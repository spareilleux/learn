using System.Runtime.InteropServices;

Console.WriteLine($"1000 cents + 20% VAT = {Native.AddVat(1000, 20)}");

double[] prices = [19.99, 5.0, 12.5];
Console.WriteLine($"sum computed in Rust: {Native.Sum(prices, (nuint)prices.Length):F2}");

// Rust allocated this string, so Rust must free it
nint label = Native.Label("book", 4250);
try
{
    Console.WriteLine(Marshal.PtrToStringUTF8(label));
}
finally
{
    Native.FreeString(label);
}

static partial class Native
{
    // Resolves to pricing_ffi.dll on Windows, libpricing_ffi.so on Linux, libpricing_ffi.dylib on macOS
    private const string Lib = "pricing_ffi";

    [LibraryImport(Lib, EntryPoint = "pricing_add_vat")]
    internal static partial ulong AddVat(ulong cents, uint percent);

    [LibraryImport(Lib, EntryPoint = "pricing_sum")]
    internal static partial double Sum([In] double[] prices, nuint len);

    [LibraryImport(Lib, EntryPoint = "pricing_label", StringMarshalling = StringMarshalling.Utf8)]
    internal static partial nint Label(string name, ulong cents);

    [LibraryImport(Lib, EntryPoint = "pricing_free_string")]
    internal static partial void FreeString(nint label);
}
