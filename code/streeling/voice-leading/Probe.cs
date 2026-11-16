using System.Text.Json;
using GA.Domain.Services.Atonal;

// Standalone characterization, not the GA test assembly or a replacement engine.
var json = new JsonSerializerOptions { PropertyNameCaseInsensitive = true, WriteIndented = true, PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
var expected = JsonSerializer.Deserialize<Expectations>(File.ReadAllText(args.Single()), json)
    ?? throw new InvalidDataException("Missing expectations");
var checks = new List<Check>();
void Check(string id, bool pass, object? wanted = null, object? actual = null) => checks.Add(new(id, pass, wanted, actual));
var requiredCases = new[] { "ordered_absolute", "ordered_octave", "permuted_absolute", "permuted_octave", "register_absolute", "register_octave", "upstream_seven", "registered_counterexample", "normalized_counterexample_only", "ambiguous_plan", "ranking_near", "upstream_transposition", "empty" };
Check("fixed_case_inventory", expected.Cases.Select(c => c.Id).SequenceEqual(requiredCases), requiredCases, expected.Cases.Select(c => c.Id));
var results = new List<CaseResult>();
foreach (var c in expected.Cases)
{
    if (c.A.Length != c.B.Length || c.A.Length > 7 || c.A.Concat(c.B).Any(x => !double.IsFinite(x) || x != Math.Truncate(x)))
        throw new InvalidDataException("Oracle scope is equal-cardinality finite integer teaching cases with at most seven voices");
    var space = new VoiceLeadingSpace(c.A.Length, c.O, c.P, c.T, c.I);
    var native = space.Distance(c.A, c.B);
    var oracle = ExhaustiveOracle(c);
    Check(c.Id + "_native", native == c.ExpectedNative, c.ExpectedNative, native);
    Check(c.Id + "_oracle", oracle.Cost == c.ExpectedOracle, c.ExpectedOracle, oracle.Cost);
    if (c.ExpectedPermutations is not null)
        Check(c.Id + "_permutation_count", oracle.PermutationsEvaluated == c.ExpectedPermutations, c.ExpectedPermutations, oracle.PermutationsEvaluated);
    // Retain witnesses only where the lesson uses them; all assignments are still enumerated.
    var witnesses = c.Id is "ambiguous_plan" or "registered_counterexample" ? oracle.Witnesses : [];
    results.Add(new(c.Id, c.A, c.B, c.O, c.P, c.T, c.I, native, oracle.Cost, oracle.PermutationsEvaluated, oracle.Witnesses.Count, witnesses));
}
var counter = results.Single(r => r.Id == "registered_counterexample");
var counterExpected = expected.Cases.Single(c => c.Id == counter.Id);
Check("oracle_zero_known_case", counter.OracleCost == 0, 0, counter.OracleCost);
Check("counterexample_oracle_witness", counter.Witnesses.Any(w => w.Assignment.SequenceEqual(counterExpected.ExpectedOracleWitness!)), counterExpected.ExpectedOracleWitness, counter.Witnesses);
// Characterize exactly the three source candidate assignments for the declared example.
double[][] cyclicAssignments = [[60,65,75], [65,75,60], [75,60,65]];
var cyclicCosts = cyclicAssignments.Select(b => PairCosts(counter.A, b, true).Sum()).ToArray();
Check("counterexample_cyclic_costs", cyclicCosts.SequenceEqual(counterExpected.ExpectedCyclicCosts!), counterExpected.ExpectedCyclicCosts, cyclicCosts);
Check("counterexample_source_matches_cyclic_minimum", counter.NativeCost == cyclicCosts.Min(), cyclicCosts.Min(), counter.NativeCost);
var originalEquivalence = counter.NativeCost == counter.OracleCost;
Check("original_equivalence_failure_reproduced", originalEquivalence == expected.ExpectedOriginalEquivalenceSatisfied && !originalEquivalence, false, originalEquivalence);
var normalized = results.Single(r => r.Id == "normalized_counterexample_only");
var normalizationMatches = normalized.A.SequenceEqual(counter.A.Select(Mod12)) && normalized.B.SequenceEqual(counter.B.Select(Mod12));
Check("normalization_is_exactly_this_example", normalizationMatches, true, normalizationMatches);
var ambiguous = results.Single(r => r.Id == "ambiguous_plan");
var expectedWitnesses = expected.Cases.Single(c => c.Id == ambiguous.Id).ExpectedWitnesses!;
Check("ambiguous_two_minimum_assignments", ambiguous.MinimumAssignmentCount == 2 && expectedWitnesses.Length == 2 && expectedWitnesses.All(w => ambiguous.Witnesses.Any(got => got.Assignment.SequenceEqual(w.Assignment) && got.Motions.SequenceEqual(w.Motions))), expectedWitnesses, ambiguous.Witnesses);
var register = results.Single(r => r.Id == "register_absolute");
var absoluteCommonNotes = register.A.Intersect(register.B).Count();
var commonPitchClasses = register.A.Select(Mod12).Intersect(register.B.Select(Mod12)).Count();
Check("teaching_absolute_common_notes", absoluteCommonNotes == expected.ExpectedAbsoluteCommonNotes, expected.ExpectedAbsoluteCommonNotes, absoluteCommonNotes);
Check("teaching_common_pitch_classes", commonPitchClasses == expected.ExpectedCommonPitchClasses, expected.ExpectedCommonPitchClasses, commonPitchClasses);
var near = results.Single(r => r.Id == "ranking_near");
var nativeRanking = new[] { (Name: "targetSame", Cost: counter.NativeCost), (Name: "targetNear", Cost: near.NativeCost) }.OrderBy(x => x.Cost).Select(x => x.Name).ToArray();
var oracleRanking = new[] { (Name: "targetSame", Cost: counter.OracleCost), (Name: "targetNear", Cost: near.OracleCost) }.OrderBy(x => x.Cost).Select(x => x.Name).ToArray();
Check("constructed_native_ranking", nativeRanking.SequenceEqual(expected.ExpectedNativeRanking), expected.ExpectedNativeRanking, nativeRanking);
Check("constructed_oracle_ranking", oracleRanking.SequenceEqual(expected.ExpectedOracleRanking), expected.ExpectedOracleRanking, oracleRanking);
string? mismatchException = null;
try { _ = new VoiceLeadingSpace(1, true, true, false, false).Distance([60], [60,64]); }
catch (ArgumentException e) { mismatchException = e.GetType().Name; }
Check("mismatched_cardinality_exception", mismatchException == expected.ExpectedMismatchedCardinalityException, expected.ExpectedMismatchedCardinalityException, mismatchException);
var passed = checks.All(c => c.Pass);
Console.WriteLine(JsonSerializer.Serialize(new
{
    probe_completed = true,
    characterization_pass = passed,
    original_expected_equivalence_satisfied = originalEquivalence,
    scope = "Unchanged pinned GA class compiled in standalone .NET 10 assembly with compile-only PublicAPI metadata stand-in; finite integer equal-cardinality cases <=7 voices. Not GA full assembly/full suite, a production fix, physical voice continuity, upstream KNN, or UI execution.",
    sourcePin = expected.SourcePin,
    cases = results,
    counterexampleCyclicAssignments = cyclicAssignments,
    counterexampleCyclicCosts = cyclicCosts,
    commonNoteTeachingCounts = new { absoluteCommonNotes, commonPitchClasses, isGaCommonTonesOutput = false },
    constructedRanking = new { nativeRanking, oracleRanking, isUpstreamKnnOrUiRun = false },
    normalizedCounterexample = new { scope = "Workaround for this example only; no general fix or physical voice continuity claim", nativeCost = normalized.NativeCost },
    checks
}, json));
return passed ? 0 : 1;

static double Mod12(double x) => ((x % 12) + 12) % 12;

static double[] PairCosts(double[] a, double[] b, bool octave)
{
    var costs = new double[a.Length];
    for (var i = 0; i < a.Length; i++)
    {
        var delta = Math.Abs(a[i] - b[i]);
        costs[i] = octave ? Math.Min(Mod12(delta), 12 - Mod12(delta)) : delta;
    }
    return costs;
}

// Independent exhaustive indexed permutations. No sorting, rotations, cyclic search,
// or calls to the vendored implementation. Repeated pitches retain distinct indices.
static OracleResult ExhaustiveOracle(Case c)
{
    var minimum = double.PositiveInfinity;
    long count = 0;
    var witnesses = new List<Witness>();
    foreach (var sign in c.I ? new[] { 1, -1 } : new[] { 1 })
    for (var shift = 0; shift < (c.T ? 12 : 1); shift++)
    {
        var transformed = c.B.Select(x => sign * x + shift).ToArray();
        var assignment = new double[c.A.Length];
        var used = new bool[c.A.Length];
        void Visit(int depth)
        {
            if (depth == assignment.Length)
            {
                count++;
                var costs = PairCosts(c.A, assignment, c.O);
                var total = costs.Sum();
                if (total < minimum) { minimum = total; witnesses.Clear(); }
                if (total == minimum) witnesses.Add(new([.. assignment], assignment.Select((x, i) => x - c.A[i]).ToArray(), costs));
                return;
            }
            for (var index = 0; index < transformed.Length; index++)
            {
                if (used[index] || (!c.P && index != depth)) continue;
                used[index] = true;
                assignment[depth] = transformed[index];
                Visit(depth + 1);
                used[index] = false;
            }
        }
        Visit(0);
    }
    return new(minimum, count, witnesses);
}

internal sealed record Check(string Id, bool Pass, object? Expected, object? Actual);
internal sealed record Witness(double[] Assignment, double[] Motions, double[] VoiceCosts);
internal sealed record OracleResult(double Cost, long PermutationsEvaluated, List<Witness> Witnesses);
internal sealed record CaseResult(string Id, double[] A, double[] B, bool O, bool P, bool T, bool I, double NativeCost, double OracleCost, long PermutationsEvaluated, int MinimumAssignmentCount, List<Witness> Witnesses);
internal sealed class Case
{
    public string Id { get; init; } = "";
    public double[] A { get; init; } = [];
    public double[] B { get; init; } = [];
    public bool O { get; init; }
    public bool P { get; init; }
    public bool T { get; init; }
    public bool I { get; init; }
    public double ExpectedNative { get; init; }
    public double ExpectedOracle { get; init; }
    public long? ExpectedPermutations { get; init; }
    public double[]? ExpectedCyclicCosts { get; init; }
    public double[]? ExpectedOracleWitness { get; init; }
    public Witness[]? ExpectedWitnesses { get; init; }
}
internal sealed class Expectations
{
    public string SourcePin { get; init; } = "";
    public Case[] Cases { get; init; } = [];
    public int ExpectedAbsoluteCommonNotes { get; init; }
    public int ExpectedCommonPitchClasses { get; init; }
    public bool ExpectedOriginalEquivalenceSatisfied { get; init; }
    public string[] ExpectedNativeRanking { get; init; } = [];
    public string[] ExpectedOracleRanking { get; init; } = [];
    public string ExpectedMismatchedCardinalityException { get; init; } = "";
}
