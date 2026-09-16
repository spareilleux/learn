using GA.Domain.Core.Theory.Atonal;
using static Advanced.Report;

namespace Advanced;

// Appendix 1: three optimisations in Guitar Alchemist, each checked against GA's own answer for
// every one of the 4096 pitch-class sets. The timings are in Benchmarks/GaBenchmarks.cs; this
// program is the part CI runs, and it is what makes the benchmark worth reading — a faster
// version that returns a different answer is not an optimisation.
public static class Appendix1
{
    static PitchClassSet Set(int id) => PitchClassSet.FromId(PitchClassSetId.FromValue(id));

    static void Row(string label, object? first, object? second = null) =>
        Line($"{label,-28} {first,-18} {second}".TrimEnd());

    public static void Run()
    {
        Title("Exhaustive check: all 4096 twelve-bit pitch-class sets");
        Row("member", "agree", "verdict");

        int clusterFree = 0, clusterAgree = 0, icvAgree = 0, firstIcv = -1;
        for (var id = 0; id < 4096; id++)
        {
            var ga = PitchClassSetId.FromValue(id);
            if (ga.IsClusterFree) clusterFree++;
            if (ga.IsClusterFree == GaFast.IsClusterFree(id)) clusterAgree++;
            if (Set(id).IntervalClassVector.Id.Value == GaFast.IntervalClassVectorIds[id]) icvAgree++;
            else if (firstIcv < 0) firstIcv = id;
        }

        int keyAgree = 0, firstKey = -1;
        for (var id = 0; id < 4096; id++)
        {
            var set = Set(id);
            if (set.ClosestDiatonicKey.ToString() == GaFast.ClosestDiatonicKey(set).ToString()) keyAgree++;
            else if (firstKey < 0) firstKey = id;
        }

        Row("IsClusterFree", $"{clusterAgree}/4096", clusterAgree == 4096 ? "identical" : "differs");
        Row("IntervalClassVector.Id", $"{icvAgree}/4096", icvAgree == 4096 ? "identical" : $"differs first at {firstIcv}");
        Row("ClosestDiatonicKey", $"{keyAgree}/4096", keyAgree == 4096 ? "identical" : $"differs first at {firstKey}");
        Line($"sets with no chromatic cluster: {clusterFree} of 4096");

        Title("The defect the fast version has to keep, not fix");
        Row("chromatic aggregate", "id", "decoded");
        var aggregate = Set(4095);
        Row("GA", aggregate.IntervalClassVector.Id.Value, aggregate.IntervalClassVector.ToString());
        Row("the fast version", GaFast.IntervalClassVectorIds[4095], new IntervalClassVectorId(GaFast.IntervalClassVectorIds[4095]).ToString());
        Line("The true vector is <12 12 12 12 12 6>, and 12 does not fit a base-12 digit: it carries.");
        Line("Packing it correctly would change 4095's id, and with it every Forte number in");
        Line("ProgrammaticForteCatalog, which orders each cardinality by this id. So it is kept.");

        Title("Forte numbering is unchanged");
        var agree = SetClass.Items.Count(setClass =>
            setClass.IntervalClassVector.Id.Value == GaFast.IntervalClassVectorIds[setClass.PrimeForm.Id.Value]);
        Row("set classes", SetClass.Items.Count, $"{agree} vector ids identical");
        Row("distinct Forte numbers", SetClass.Items.Select(sc => ForteCatalog.GetForteNumber(sc.PrimeForm)).Distinct().Count());

        Title("What one call costs");
        var one = Set(2741);
        Machine($"GA   IntervalClassVector.Id.Value  {Allocated(() => _ = one.IntervalClassVector.Id.Value),8:N0} bytes");
        Machine($"fast IntervalClassVectorIds[id]    {Allocated(() => _ = GaFast.IntervalClassVectorIds[2741]),8:N0} bytes");
        Machine($"GA   IsClusterFree                 {Allocated(() => _ = one.Id.IsClusterFree),8:N0} bytes");
        Machine($"fast IsClusterFree                 {Allocated(() => _ = GaFast.IsClusterFree(2741)),8:N0} bytes");
        Machine($"GA   ClosestDiatonicKey            {Allocated(() => _ = one.ClosestDiatonicKey),8:N0} bytes");
        Machine($"fast ClosestDiatonicKey            {Allocated(() => _ = GaFast.ClosestDiatonicKey(one)),8:N0} bytes");

        Title("A few sets, so the tables above are readable");
        Row("set", "interval-class vector", "closest key, cluster-free");
        foreach (var (name, id) in new[] { ("major scale", 2741), ("C major triad", 145), ("whole tone", 1365), ("chromatic aggregate", 4095) })
        {
            var set = Set(id);
            Row(name, $"{id}: {set.IntervalClassVector}", $"{set.ClosestDiatonicKey}, {GaFast.IsClusterFree(id)}");
        }
    }
}
