using System.Runtime;
using System.Runtime.CompilerServices;
using GA.Domain.Core.Theory.Atonal;
using static Advanced.Report;

namespace Advanced;

// Lesson 2: generations, the large and pinned object heaps, GC modes and what the runtime reports
public static class Lesson2
{
    public static void Run()
    {
        Modes();
        Generations();
        LargeObjects();
        Reachability();
        MemoryInfo();
        Budget();
        Exercises();
    }

    static void Exercises()
    {
        Title("Exercise solutions");
        Line($"1. new char[42,487] generation {GC.GetGeneration(new char[42_487])}, new char[42,488] generation {GC.GetGeneration(new char[42_488])}");
        var started = GC.TryStartNoGCRegion(1_000_000);
        var gen0 = GC.CollectionCount(0);
        var ring = new byte[16][];
        for (var i = 0; i < 1_000; i++)
        {
            ring[i & 15] = new byte[100];
        }
        Line($"2. TryStartNoGCRegion(1 MB) {started}, LatencyMode {GCSettings.LatencyMode}, gen0 collections for 1,000 arrays {GC.CollectionCount(0) - gen0}");
        GC.EndNoGCRegion();
        Line($"   after EndNoGCRegion: LatencyMode {GCSettings.LatencyMode}, {ring.Length} arrays kept");
        Line($"3. GC.GetGeneration(\"C major\") {GC.GetGeneration("C major")}, of new string('C', 7) {GC.GetGeneration(new string('C', 7))}, of typeof(PitchClass) {GC.GetGeneration(typeof(PitchClass))}");
    }

    // Also run alone by check.sh with DOTNET_gcServer=1, then with DOTNET_gcConcurrent=0
    public static void Modes()
    {
        Title("GC mode");
        Line($"GCSettings.IsServerGC: {GCSettings.IsServerGC}");
        Line($"GCSettings.LatencyMode: {GCSettings.LatencyMode}");
        Line($"GC.MaxGeneration: {GC.MaxGeneration}");
        var config = GC.GetConfigurationVariables();
        foreach (var key in new[] { "ServerGC", "ConcurrentGC", "LOHThreshold", "GCDynamicAdaptationMode" })
        {
            Line($"GC.GetConfigurationVariables()[\"{key}\"]: {(config.TryGetValue(key, out var value) ? value : "(absent)")}");
        }
        foreach (var key in new[] { "HeapCount", "GCGen0MaxBudget" })
        {
            Machine($"GC.GetConfigurationVariables()[\"{key}\"]: {(config.TryGetValue(key, out var value) ? value : "(absent)")}");
        }
        Machine($"Environment.ProcessorCount: {Environment.ProcessorCount}");
    }

    static void Generations()
    {
        Title("Generations: an object that survives a collection is promoted");
        var chord = new int[] { 0, 4, 7 };
        Line($"new int[3]           generation {GC.GetGeneration(chord)}");
        GC.Collect();
        Line($"after GC.Collect()   generation {GC.GetGeneration(chord)}");
        GC.Collect();
        Line($"after a second one   generation {GC.GetGeneration(chord)}");
        GC.Collect();
        Line($"after a third one    generation {GC.GetGeneration(chord)}");
        GC.Collect(0);
        var fresh = new int[3];
        Line($"GC.Collect(0) then new int[3]: generation {GC.GetGeneration(fresh)}");
        GC.KeepAlive(chord);
    }

    static void LargeObjects()
    {
        Title("Large object heap: 85,000 bytes and more, counted with the object header");
        foreach (var length in new[] { 84_975, 84_976, 1_000_000 })
        {
            var bytes = new byte[length];
            Line($"new byte[{length,9:N0}]  object size {Allocated(() => GC.KeepAlive(new byte[length])),9:N0}  generation {GC.GetGeneration(bytes)}");
        }
        var doubles = new double[10_622];
        Line($"new double[10,622]   object size {Allocated(() => GC.KeepAlive(new double[10_622])),9:N0}  generation {GC.GetGeneration(doubles)}");

        Title("Pinned object heap: GC.AllocateArray(pinned: true)");
        var pinned = GC.AllocateArray<byte>(1024, pinned: true);
        var ordinary = new byte[1024];
        Line($"pinned byte[1024]    generation {GC.GetGeneration(pinned)}");
        Line($"ordinary byte[1024]  generation {GC.GetGeneration(ordinary)}");
        var before = GC.GetGCMemoryInfo(GCKind.Any);
        GC.Collect();
        var info = GC.GetGCMemoryInfo(GCKind.Any);
        Line($"heaps in GCGenerationInfo: {info.GenerationInfo.Length} (gen0, gen1, gen2, LOH, POH)");
        Machine($"POH size after the collection: {info.GenerationInfo[4].SizeAfterBytes:N0} bytes, LOH {info.GenerationInfo[3].SizeAfterBytes:N0} bytes, before: POH {before.GenerationInfo[4].SizeAfterBytes:N0}");
        GC.KeepAlive(pinned);
    }

    static void Reachability()
    {
        Title("Reachability: a weak reference does not keep an object alive");
        var (weak, strong) = MakeReferences();
        GC.Collect();
        Line($"only weakly reachable:  IsAlive {weak.IsAlive}");
        Line($"still referenced:       IsAlive {strong.TryGetTarget(out var target)} ({target?.Length} notes)");

        Title("Finalizers: a finalizable object is freed one collection later");
        Finalizable.Finalized = 0;
        var (shortWeak, longWeak) = MakeFinalizable();
        GC.Collect();
        GC.WaitForPendingFinalizers();
        Line($"after 1 collection:  finalized {Finalizable.Finalized}, short weak IsAlive {shortWeak.IsAlive}, long weak IsAlive {longWeak.IsAlive}");
        GC.Collect();
        Line($"after 2 collections: finalized {Finalizable.Finalized}, short weak IsAlive {shortWeak.IsAlive}, long weak IsAlive {longWeak.IsAlive}");
        Line($"bytes of new Finalizable(): {Allocated(() => GC.KeepAlive(new Finalizable()))}, of new object(): {Allocated(() => GC.KeepAlive(new object()))}");
        GC.Collect();
        GC.WaitForPendingFinalizers();
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    static (WeakReference, WeakReference<int[]>) MakeReferences()
    {
        var kept = new[] { 0, 3, 7, 10 };
        s_kept = kept;
        return (new WeakReference(new[] { 0, 4, 7 }), new WeakReference<int[]>(kept));
    }

    static int[]? s_kept;

    [MethodImpl(MethodImplOptions.NoInlining)]
    static (WeakReference, WeakReference) MakeFinalizable()
    {
        var finalizable = new Finalizable();
        return (new WeakReference(finalizable), new WeakReference(finalizable, trackResurrection: true));
    }

    sealed class Finalizable
    {
        public static int Finalized;

        ~Finalizable() => Interlocked.Increment(ref Finalized);
    }

    static void MemoryInfo()
    {
        Title("GC.GetGCMemoryInfo after an induced, blocking, compacting collection");
        GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true);
        var info = GC.GetGCMemoryInfo(GCKind.Any);
        Line($"Generation {info.Generation}, Compacted {info.Compacted}, Concurrent {info.Concurrent}");
        Machine($"Index {info.Index}, PauseDurations[0] {info.PauseDurations[0].TotalMilliseconds:F3} ms, PauseTimePercentage {info.PauseTimePercentage}%");
        Machine($"HeapSizeBytes {info.HeapSizeBytes:N0}, FragmentedBytes {info.FragmentedBytes:N0}, TotalCommittedBytes {info.TotalCommittedBytes:N0}");
        Machine($"TotalAvailableMemoryBytes {info.TotalAvailableMemoryBytes:N0}, HighMemoryLoadThresholdBytes {info.HighMemoryLoadThresholdBytes:N0}");
        for (var gen = 0; gen < info.GenerationInfo.Length; gen++)
        {
            var g = info.GenerationInfo[gen];
            Machine($"  {new[] { "gen0", "gen1", "gen2", "LOH", "POH" }[gen]}: before {g.SizeBeforeBytes:N0}, after {g.SizeAfterBytes:N0}");
        }
    }

    static void Budget()
    {
        Title("Allocation budget: many short-lived objects, few collections");
        var gen0 = GC.CollectionCount(0);
        var gen1 = GC.CollectionCount(1);
        var gen2 = GC.CollectionCount(2);
        var before = GC.GetAllocatedBytesForCurrentThread();
        // Each chord escapes into the ring, so that the JIT cannot put it on the stack
        var ring = new int[16][];
        for (var i = 0; i < 1_000_000; i++)
        {
            var id = new PitchClassSetId(i & 0xFFF);
            ring[i & 15] = new int[] { id.Value, id.Cardinality };
        }
        var allocated = GC.GetAllocatedBytesForCurrentThread() - before;
        Line($"allocated {allocated:N0} bytes for 1,000,000 arrays of 2 ints, {ring.Length} still referenced");
        Machine($"collections: gen0 {GC.CollectionCount(0) - gen0}, gen1 {GC.CollectionCount(1) - gen1}, gen2 {GC.CollectionCount(2) - gen2}");
    }
}
