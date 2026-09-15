using System.Buffers;
using System.Collections.Frozen;
using System.Numerics;
using System.Numerics.Tensors;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.Intrinsics;
using GA.Core.Numerics;
using GA.Domain.Core.Theory.Atonal;
using static Advanced.Report;

namespace Advanced;

// Lesson 4: what the benchmarks compare, checked for equal results; the timings are in Benchmarks/
public static class Lesson4
{
    public static void Run()
    {
        Jit();
        Search();
        Frozen();
        PitchClassSubtraction();
        Vectors();
        Exercises();
    }

    static void Exercises()
    {
        Title("Exercise solutions");
        string[] naturals = ["C", "D", "E", "F", "G", "A", "B"];
        Line($"1. the 7 natural notes: {naturals.ToFrozenDictionary(n => n, n => Array.IndexOf(naturals, n)).GetType().Name}");
        var agree = PitchClass.Items.All(l => PitchClass.Items.All(r => SubtractWithTable(l, r) == l - r));
        Line($"2. table of 144 PitchClass: agrees with GA {agree}, {Allocated(() => _ = SubtractWithTable(PitchClass.FromValue(4), PitchClass.FromValue(7)))} bytes");
        var chart = string.Concat(Enumerable.Repeat("C Am F G | ", 100)) + "F#m7b5";
        Line($"3. IndexOfAny('#', 'b') {chart.AsSpan().IndexOfAny('#', 'b')}, IndexOfAny(SearchValues) {chart.AsSpan().IndexOfAny(Accidentals)}");
    }

    // Exercise 2: every difference computed once, in a flat array indexed by left * 12 + right
    static readonly PitchClass[] DifferenceTable =
        [.. Enumerable.Range(0, 144).Select(i => PitchClass.FromValue((i / 12 - i % 12 + 12) % 12))];

    public static PitchClass SubtractWithTable(PitchClass left, PitchClass right) =>
        DifferenceTable[left.Value * 12 + right.Value];

    static void Jit()
    {
        Title("The JIT of this process");
        Line($"DOTNET_TieredCompilation={Environment.GetEnvironmentVariable("DOTNET_TieredCompilation") ?? "(unset)"}, DOTNET_TieredPGO={Environment.GetEnvironmentVariable("DOTNET_TieredPGO") ?? "(unset)"}");
        Line($"RuntimeFeature.IsDynamicCodeCompiled: {RuntimeFeature.IsDynamicCodeCompiled}");
        Machine($"JitInfo: {System.Runtime.JitInfo.GetCompiledMethodCount()} methods compiled, {System.Runtime.JitInfo.GetCompilationTime().TotalMilliseconds:F0} ms of JIT so far");
    }

    public static readonly string[] Symbols = ["C", "Cm", "C7", "Cmaj7", "Cm7", "Cm7b5", "Cdim7", "C#m", "Dbmaj7", "F#7#9", "Bb13", "Eb6/9", "Asus4", "G7b9"];

    static readonly SearchValues<char> Accidentals = SearchValues.Create("#b");
    static readonly SearchValues<string> Qualities = SearchValues.Create(["maj7", "m7b5", "dim7", "sus4"], StringComparison.Ordinal);

    public static int IndexOfAccidentalLoop(string symbol)
    {
        // The root letter is never an accidental: start at 1
        for (var i = 1; i < symbol.Length; i++)
        {
            if (symbol[i] is '#' or 'b') return i;
        }
        return -1;
    }

    public static int IndexOfAccidental(string symbol)
    {
        var i = symbol.AsSpan(1).IndexOfAny(Accidentals);
        return i < 0 ? -1 : i + 1;
    }

    static void Search()
    {
        Title("SearchValues: the same answers as a loop");
        var loop = Symbols.Select(IndexOfAccidentalLoop).ToArray();
        var searched = Symbols.Select(IndexOfAccidental).ToArray();
        Line($"first accidental: {string.Join(" ", searched)}; same as the loop: {loop.SequenceEqual(searched)}");
        Machine($"SearchValues.Create(\"#b\") is {Accidentals.GetType().Name}");
        Line($"quality found: {string.Join(" ", Symbols.Select(s => s.AsSpan().IndexOfAny(Qualities)))}");
        Machine($"SearchValues.Create([\"maj7\", ...]) is {Qualities.GetType().Name}");
    }

    public static readonly Dictionary<string, int[]> Formulas = new()
    {
        [""] = [0, 4, 7], ["m"] = [0, 3, 7], ["7"] = [0, 4, 7, 10], ["maj7"] = [0, 4, 7, 11], ["m7"] = [0, 3, 7, 10],
        ["m7b5"] = [0, 3, 6, 10], ["dim7"] = [0, 3, 6, 9], ["6"] = [0, 4, 7, 9], ["sus4"] = [0, 5, 7], ["9"] = [0, 4, 7, 10, 14],
    };

    static void Frozen()
    {
        Title("FrozenDictionary: which implementation ToFrozenDictionary() picks");
        var frozen = Formulas.ToFrozenDictionary();
        Line($"{"10 chord suffixes (string keys)",-44} {frozen.GetType().Name}");
        Line($"{"same, StringComparer.OrdinalIgnoreCase",-44} {Formulas.ToFrozenDictionary(StringComparer.OrdinalIgnoreCase).GetType().Name}");
        Line($"{"12 pitch classes (int keys)",-44} {Enumerable.Range(0, 12).ToFrozenDictionary(i => i, i => i).GetType().Name}");
        Line($"{"12 PitchClass keys (record struct)",-44} {PitchClass.Items.ToFrozenDictionary(p => p, p => p.Value).GetType().Name}");
        Line($"{"GA: 144 (int, int) keys, PitchClass -",-44} {GaSubtractionTable().GetType().Name}");
        Line($"{"GA: ProgrammaticForteCatalog.ForteByPrimeFormId",-44} {ProgrammaticForteCatalog.ForteByPrimeFormId.GetType().Name} ({ProgrammaticForteCatalog.ForteByPrimeFormId.Count} keys)");
        var same = Formulas.All(p => frozen.TryGetValue(p.Key, out var f) && f == p.Value) && !frozen.ContainsKey("maj9");
        Line($"lookups agree with the Dictionary: {same}");
    }

    // GA's private cache behind PitchClass.operator -, read by reflection
    static object GaSubtractionTable()
    {
        var calculator = typeof(PitchClass).GetNestedType("FastPitchClassCalculator", BindingFlags.NonPublic)!;
        var lazy = calculator.GetField("_lazySubtractionDictionary", BindingFlags.NonPublic | BindingFlags.Static)!.GetValue(null)!;
        return lazy.GetType().GetProperty("Value")!.GetValue(lazy)!;
    }

    public static PitchClass Subtract(PitchClass left, PitchClass right) =>
        PitchClass.FromValue((left.Value - right.Value + 12) % 12);

    static void PitchClassSubtraction()
    {
        Title("GA PitchClass subtraction: FrozenDictionary lookup versus arithmetic");
        var pairs = 0;
        var equal = 0;
        foreach (var left in PitchClass.Items)
        {
            foreach (var right in PitchClass.Items)
            {
                pairs++;
                if (left - right == Subtract(left, right)) equal++;
            }
        }
        Line($"{equal} of {pairs} pairs agree; E - 1 = {PitchClass.FromValue(11) - PitchClass.FromValue(1)}, 1 - E = {PitchClass.FromValue(1) - PitchClass.FromValue(11)}");
        Line($"bytes allocated by one GA subtraction: {Allocated(() => _ = PitchClass.FromValue(4) - PitchClass.FromValue(7))}");
    }

    public static double DotScalar(ReadOnlySpan<double> a, ReadOnlySpan<double> b)
    {
        var sum = 0.0;
        for (var i = 0; i < a.Length; i++) sum += a[i] * b[i];
        return sum;
    }

    public static double[] Embedding(int length, int seed, bool integers)
    {
        var random = new Random(seed);
        return [.. Enumerable.Range(0, length).Select(_ => integers ? random.Next(-8, 9) : random.NextDouble() * 2 - 1)];
    }

    static void Vectors()
    {
        Title("Vectorized dot products: GA SimdOps.Dot, TensorPrimitives.Dot and a scalar loop");
        Machine($"Vector.IsHardwareAccelerated {Vector.IsHardwareAccelerated}, Vector<double>.Count {Vector<double>.Count}, Vector256 {Vector256.IsHardwareAccelerated}, Vector512 {Vector512.IsHardwareAccelerated}");
        foreach (var integers in new[] { true, false })
        {
            var a = Embedding(1027, 1, integers);
            var b = Embedding(1027, 2, integers);
            var scalar = DotScalar(a, b);
            var ga = SimdOps.Dot(a, b);
            var tensors = TensorPrimitives.Dot(a, b);
            var kind = integers ? "small integers" : "random doubles";
            Line($"{kind}: scalar {scalar:F6}, SimdOps {ga:F6}, TensorPrimitives {tensors:F6}; equal to 1e-9: {Math.Abs(scalar - ga) < 1e-9 && Math.Abs(scalar - tensors) < 1e-9}");
            Line($"{kind}: bit-identical to the scalar loop: {(integers ? (scalar == ga && scalar == tensors).ToString() : "(depends on the vector width)")}");
            if (!integers)
            {
                Machine($"random doubles: SimdOps - scalar = {ga - scalar:E2}, TensorPrimitives - scalar = {tensors - scalar:E2}");
            }
        }
        Line($"SimdOps.Dot allocates nothing itself: {Allocated(() => _ = SimdOps.Dot(s_a, s_b))} bytes");
    }

    static readonly double[] s_a = Embedding(1027, 1, false);
    static readonly double[] s_b = Embedding(1027, 2, false);
}
