using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using GA.Domain.Core.Theory.Atonal;
using Snippets;
using static Advanced.Report;

namespace Advanced;

// Lesson 1: value and reference types, boxing, ref/in, Span<T> and stackalloc
public static class Lesson1
{
    struct Point(int x, int y)
    {
        public int X = x;
        public int Y = y;
    }

    struct Padded(byte flag, long ticks)
    {
        public byte Flag = flag;
        public long Ticks = ticks;
    }

    sealed class Node(int value)
    {
        public int Value = value;
    }

    public static void Run()
    {
        Title("Inline size (Unsafe.SizeOf) and heap size of one allocation, in bytes");
        Line($"{"type",-26} {"inline",6} {"heap",6}  what the heap bytes are");
        Size<int>("int", () => (object)42, "a boxed int");
        Size<long>("long", () => (object)42L, "a boxed long");
        Size<decimal>("decimal", () => (object)42m, "a boxed decimal");
        Size<Guid>("Guid", () => (object)Guid.Empty, "a boxed Guid");
        Size<Point>("Point (2 ints)", () => (object)new Point(1, 2), "a boxed Point");
        Size<Padded>("Padded (byte, long)", () => (object)new Padded(1, 2), "a boxed Padded");
        Size<(byte, long)>("(byte, long)", () => (object)(1, 2L), "a boxed tuple");
        Size<object>("object", () => new object(), "new object()");
        Size<Node>("Node (class, 1 int)", () => new Node(1), "new Node(1)");
        Size<string>("string", () => new string('a', 5), "a 5-char string");
        Size<int[]>("int[]", () => new int[0], "an empty int[]");
        Size<int[]>("int[]", () => new int[10], "an int[10]");
        Size<PitchClass>("GA PitchClass", () => (object)PitchClass.FromValue(3), "a boxed PitchClass");
        Size<PitchClassSetId>("GA PitchClassSetId", () => (object)new PitchClassSetId(2741), "a boxed PitchClassSetId");

        BoxingTable();

        Title("in and ref: a method called on an in parameter runs on a copy");
        var counter = new Counter();
        Line($"ByIn returns {DefensiveCopy.ByIn(in counter)}, counter.Value is now {counter.Value}");
        Line($"ByRef returns {DefensiveCopy.ByRef(ref counter)}, counter.Value is now {counter.Value}");

        Title("ref locals: one dictionary lookup per update (CollectionsMarshal)");
        var byCardinality = new Dictionary<int, int>();
        foreach (var id in PitchClassSetId.Items)
        {
            ref var count = ref CollectionsMarshal.GetValueRefOrAddDefault(byCardinality, id.Cardinality, out _);
            count++;
        }
        Line($"sets by number of notes: {string.Join(" ", byCardinality.OrderBy(p => p.Key).Select(p => p.Value))}");

        Title("Parsing a voicing: string.Split versus spans");
        const string voicing = "x 3 2 0 1 0";
        Line($"split: {SumWithSplit(voicing)} frets, {Allocated(() => SumWithSplit(voicing))} bytes");
        Line($"spans: {SumWithSpans(voicing)} frets, {Allocated(() => SumWithSpans(voicing))} bytes");

        Title("GA: ItemsSpan of two value objects");
        Line($"PitchClass.ItemsSpan: {PitchClass.ItemsSpan.Length} items, {Allocated(() => _ = PitchClass.ItemsSpan.Length)} bytes");
        Line($"PitchClassSetId.ItemsSpan: {PitchClassSetId.ItemsSpan.Length} items, {Allocated(() => _ = PitchClassSetId.ItemsSpan.Length)} bytes");
        Line($"PitchClassSetId.Items is {PitchClassSetId.Items.GetType().Name}");

        Title("Exercise solutions");
        Line($"1. (bool, int, bool) {Unsafe.SizeOf<(bool, int, bool)>()} bytes, SequentialFlags {Unsafe.SizeOf<SequentialFlags>()}, AutoFlags {Unsafe.SizeOf<AutoFlags>()}");
        Line($"3. cached ItemsSpan: {CachedIds.ItemsSpan.Length} items, {Allocated(() => _ = CachedIds.ItemsSpan.Length)} bytes, same ids {CachedIds.ItemsSpan.SequenceEqual(PitchClassSetId.ItemsSpan)}");
    }

    struct SequentialFlags(bool muted, int fret, bool barre)
    {
        public bool Muted = muted;
        public int Fret = fret;
        public bool Barre = barre;
    }

    [StructLayout(LayoutKind.Auto)]
    struct AutoFlags(bool muted, int fret, bool barre)
    {
        public bool Muted = muted;
        public int Fret = fret;
        public bool Barre = barre;
    }

    // Exercise 3: PitchClassSetId.ItemsSpan without a copy per call
    static class CachedIds
    {
        private static readonly PitchClassSetId[] Items = [.. PitchClassSetId.Items];

        public static ReadOnlySpan<PitchClassSetId> ItemsSpan => Items;
    }

    // Also run alone by check.sh with DOTNET_TieredCompilation=0, where every method is compiled fully optimized at once
    public static void BoxingTable()
    {
        var tiered = Environment.GetEnvironmentVariable("DOTNET_TieredCompilation") != "0";
        Title($"Boxing: bytes allocated by the second call ({(tiered ? "tiered JIT, first tier" : "DOTNET_TieredCompilation=0")})");
        var pc = PitchClass.FromValue(3);
        Row("Boxing.ToObjectAndBack(42)", () => Boxing.ToObjectAndBack(42));
        Row("Escape.BoxAndHash(42)", () => Escape.BoxAndHash(42));
        Row("Boxing.ThroughInterface(pc, pc)", () => Boxing.ThroughInterface(pc, pc));
        Row("Boxing.ThroughConstraint(pc, pc)", () => Boxing.ThroughConstraint(pc, pc));
        Row("Boxing.Format(12345)", () => Boxing.Format(12345));
        Row("Boxing.Interpolate(12345)", () => Boxing.Interpolate(12345));

        static void Row(string call, Action action) => Line($"{call,-36} {Allocated(action),6}");
    }

    static void Size<T>(string name, Func<object> allocate, string what)
    {
        object? kept = null;
        var heap = Allocated(() => kept = allocate());
        GC.KeepAlive(kept);
        Line($"{name,-26} {Unsafe.SizeOf<T>(),6} {heap,6}  {what}");
    }

    public static int SumWithSplit(string voicing)
    {
        var sum = 0;
        foreach (var part in voicing.Split(' '))
        {
            if (part != "x")
            {
                sum += int.Parse(part);
            }
        }
        return sum;
    }

    public static int SumWithSpans(string voicing)
    {
        Span<int> frets = stackalloc int[6];
        var count = 0;
        var text = voicing.AsSpan();
        foreach (var range in text.Split(' '))
        {
            var part = text[range];
            frets[count++] = part is "x" ? -1 : int.Parse(part);
        }
        var sum = 0;
        foreach (var fret in frets[..count])
        {
            if (fret > 0) sum += fret;
        }
        return sum;
    }
}
