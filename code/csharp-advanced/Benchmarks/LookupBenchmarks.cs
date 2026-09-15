using System.Buffers;
using System.Collections.Frozen;
using Advanced;
using BenchmarkDotNet.Attributes;
using GA.Domain.Core.Theory.Atonal;

namespace Benchmarks;

// Lesson 4: GA's PitchClass subtraction, a FrozenDictionary lookup, against the arithmetic it caches
[MemoryDiagnoser]
public class PitchClassBenchmarks
{
    private static readonly PitchClass[] All = [.. PitchClass.Items];

    [Benchmark(Baseline = true)]
    public int GaOperatorMinus()
    {
        var sum = 0;
        foreach (var left in All)
        {
            foreach (var right in All)
            {
                sum += (left - right).Value;
            }
        }
        return sum;
    }

    [Benchmark]
    public int Arithmetic()
    {
        var sum = 0;
        foreach (var left in All)
        {
            foreach (var right in All)
            {
                sum += Lesson4.Subtract(left, right).Value;
            }
        }
        return sum;
    }

    [Benchmark]
    public int LookupTable()
    {
        var sum = 0;
        foreach (var left in All)
        {
            foreach (var right in All)
            {
                sum += Lesson4.SubtractWithTable(left, right).Value;
            }
        }
        return sum;
    }
}

// Lesson 4: Dictionary against FrozenDictionary on chord suffixes, two of which are missing
[MemoryDiagnoser]
public class DictionaryBenchmarks
{
    private static readonly Dictionary<string, int[]> Dictionary = Lesson4.Formulas;
    private static readonly FrozenDictionary<string, int[]> Frozen = Lesson4.Formulas.ToFrozenDictionary();
    private static readonly string[] Suffixes = ["", "m", "7", "maj7", "m7", "m7b5", "dim7", "6", "sus4", "9", "maj9", "add9"];

    [Benchmark(Baseline = true)]
    public int DictionaryTryGetValue()
    {
        var notes = 0;
        foreach (var suffix in Suffixes)
        {
            if (Dictionary.TryGetValue(suffix, out var formula)) notes += formula.Length;
        }
        return notes;
    }

    [Benchmark]
    public int FrozenDictionaryTryGetValue()
    {
        var notes = 0;
        foreach (var suffix in Suffixes)
        {
            if (Frozen.TryGetValue(suffix, out var formula)) notes += formula.Length;
        }
        return notes;
    }
}

// Lesson 4: a hand-written loop against SearchValues, on short chord symbols and on a long chord chart
[MemoryDiagnoser]
public class SearchBenchmarks
{
    private static readonly SearchValues<char> Accidentals = SearchValues.Create("#b");
    private static readonly string Chart = string.Concat(Enumerable.Repeat("C Am F G | C Am Dm G7 | ", 400)) + "F#m7b5";

    [Benchmark(Baseline = true)]
    public int SymbolsLoop()
    {
        var sum = 0;
        foreach (var symbol in Lesson4.Symbols) sum += Lesson4.IndexOfAccidentalLoop(symbol);
        return sum;
    }

    [Benchmark]
    public int SymbolsSearchValues()
    {
        var sum = 0;
        foreach (var symbol in Lesson4.Symbols) sum += Lesson4.IndexOfAccidental(symbol);
        return sum;
    }

    [Benchmark]
    public int ChartLoop()
    {
        for (var i = 0; i < Chart.Length; i++)
        {
            if (Chart[i] is '#' or 'b') return i;
        }
        return -1;
    }

    [Benchmark]
    public int ChartSearchValues() => Chart.AsSpan().IndexOfAny(Accidentals);

    [Benchmark]
    public int ChartIndexOfAnyTwoChars() => Chart.AsSpan().IndexOfAny('#', 'b');
}
