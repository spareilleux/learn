namespace Examples;

/// <summary>What a Model Checking Contest instance is, and the answer the contest publishes for it.</summary>
/// <param name="Domain">The industry the model comes from, as lesson 12 groups them.</param>
/// <param name="Instance">The contest's own instance name, as it appears in its result files.</param>
/// <param name="What">What the net models, in one phrase.</param>
/// <param name="Markings">Reachable markings.</param>
/// <param name="Arcs">Arcs of the reachability graph.</param>
/// <param name="MaxPerPlace">The most tokens any single place ever holds.</param>
/// <param name="MaxTotal">The most tokens a marking ever holds, over all places.</param>
public sealed record MccInstance(
    string Domain, string Instance, string What, long Markings, long Arcs, int MaxPerPlace, int MaxTotal);

/// <summary>
/// The answers the <a href="https://mcc.lip6.fr/">Model Checking Contest</a> publishes for its
/// StateSpace examination, for the P/T instances whose four numbers are available in full. They
/// come from the 2026 edition's `raw-result-analysis.csv`, whose `estimated result` column holds
/// the value a majority of the entered tools agree on, weighted by each tool's measured confidence
/// rate. That column is rounded to five significant digits above a million, so for the two large
/// instances the digits here are the ones tedd, TY and the 2025 gold medal each printed, in
/// agreement, in the `results` column of `GlobalSummary.csv`.
///
/// These are the external oracle of lesson 12: every other lesson of this course checks the
/// analyser against itself, and this one checks it against numbers computed by other people's
/// tools, on other people's nets.
/// </summary>
public static class Mcc
{
    public const string Source = "Model Checking Contest 2026, StateSpace examination, raw-result-analysis.csv";

    public static IReadOnlyList<MccInstance> Published =>
    [
        new("manufacturing", "FMS-PT-00002", "a flexible manufacturing system, three part types", 3_444, 16_311, 3, 12),
        new("manufacturing", "Kanban-PT-00005", "four kanban cells, work released against a free card", 2_546_432, 24_460_016, 5, 20),
        new("manufacturing", "SwimmingPool-PT-01", "a swimming pool where bags and baskets are the resources", 89_621, 450_003, 20, 45),
        new("manufacturing", "ResAllocation-PT-R003C003", "processes taking shared resources in a fixed order", 92, 257, 1, 9),
        new("manufacturing", "ResAllocation-PT-R010C002", "the same, ten resources and two processes", 6_144, 20_480, 1, 20),

        new("protocols", "TokenRing-PT-005", "a token ring, the token being the right to speak", 166, 365, 1, 6),
        new("protocols", "TokenRing-PT-010", "the same ring with ten stations", 58_905, 294_050, 1, 11),
        new("protocols", "Raft-PT-02", "the leader election of the Raft consensus algorithm", 7_381, 55_824, 1, 6),
        new("protocols", "DrinkVendingMachine-PT-02", "a vending machine and two customers", 1_024, 7_680, 1, 12),
        new("protocols", "BridgeAndVehicles-PT-V04P05N02", "a one-lane bridge with vehicles on both sides", 2_874, 7_160, 5, 17),
        new("protocols", "Railroad-PT-005", "trains and a controller over a shared crossing", 1_838, 7_699, 1, 16),
        new("protocols", "CircularTrains-PT-012", "twelve trains on a circular track, one section each", 195, 496, 2, 12),

        new("hardware and shared memory", "SharedMemory-PT-000005", "processors contending for one memory bus", 1_863, 10_395, 1, 11),
        new("hardware and shared memory", "Dekker-PT-010", "Dekker's mutual exclusion, ten processes", 6_144, 171_530, 1, 20),
        new("hardware and shared memory", "Peterson-PT-2", "Peterson's mutual exclusion", 20_754, 62_262, 1, 8),
        new("hardware and shared memory", "DatabaseWithMutex-PT-02", "database sites replicating under a mutex", 153, 312, 1, 6),

        new("biochemistry", "ERK-PT-000001", "the ERK signalling pathway, one molecule of each species", 13, 30, 1, 5),
        new("biochemistry", "ERK-PT-000010", "the same pathway, ten molecules of each", 47_047, 372_372, 10, 50),
        new("biochemistry", "Angiogenesis-PT-01", "the signalling that makes blood vessels grow", 110, 288, 1, 8),
        new("biochemistry", "CircadianClock-PT-000001", "the gene circuit of a circadian clock", 128, 624, 1, 7),

        new("security", "QuasiCertifProtocol-PT-02", "a certification protocol for electronic documents", 1_029, 3_084, 1, 20),
    ];

    /// <summary>
    /// The instances just above what an explicit reachability graph can hold, with the best time
    /// any contest tool needed for them. The contrast is the point: a decision diagram answers in
    /// seconds what enumerating markings cannot answer at all.
    /// </summary>
    public static IReadOnlyList<(string Instance, long Markings, long Arcs, string Best)> OutOfReach =>
    [
        ("FMS-PT-00005", 2_895_018, 23_527_185, "tedd, 5.3 s, 2117 MB"),
        ("Kanban-PT-00005", 2_546_432, 24_460_016, "tedd, 2.1 s, 1400 MB"),
        ("Peterson-PT-3", 3_407_946, 13_631_784, "tedd, 6.3 s, 3062 MB"),
        ("Dekker-PT-020", 11_534_336, 1_216_348_180, "tedd, 2.3 s, 1209 MB"),
        ("Angiogenesis-PT-05", 42_734_935, 486_873_657, "tedd, 5.1 s, 3162 MB"),
    ];
}
