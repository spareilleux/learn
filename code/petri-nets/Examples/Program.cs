using System.Globalization;
using Examples;
using PetriNets;

// Each lesson of the Petri net course prints one block of text, compared with expected/ by check.sh.
// Usage: dotnet run --project Examples -- <lesson>
var lesson = args.Length > 0 ? args[0] : "l1";

switch (lesson)
{
    case "l1": Lesson1(); break;
    case "l2": Lesson2(); break;
    case "l3": Lesson3(); break;
    case "l4": Lesson4(); break;
    case "l5": Lesson5(); break;
    case "l6": Lesson6(); break;
    case "l7": Lesson7(); break;
    case "l8": Lesson8(); break;
    case "l9": Lesson9(); break;
    case "l10": Lesson10(); break;
    case "l11": Lesson11(args.Length > 1 ? args[1] : null); break;
    case "l12": Lesson12(args.Length > 1 ? args[1] : null); break;
    case "l13": Lesson13(args.Length > 1 ? args[1] : null); break;
    case "l14": Lesson14(); break;
    case "l15": Lesson15(); break;
    case "music": Music(); break;
    case "chat": Chat(); break;
    case "nets": WriteNets(args.Length > 1 ? args[1] : "out/nets"); break;
    case "tla": WriteTla(args.Length > 1 ? args[1] : "out/tla"); break;
    default:
        Console.Error.WriteLine($"Unknown lesson '{lesson}'. Try l1 to l15, nets, or tla.");
        return 2;
}

return 0;

// Lesson 1: places, transitions, the firing rule, and two firings that do not get in each other's way.
void Lesson1()
{
    var net = Nets.ProducerConsumer();
    Title("The net");
    Console.Write(Report.Net(net));

    Title("The same net as a diagram");
    Console.Write(Mermaid.Draw(net));

    Title("Enabled at the initial marking");
    Console.WriteLine(Enabled(net, net.InitialMarking));

    Title("One round trip: produce, deposit, take, consume");
    Console.Write(Report.Sequence(net, net.InitialMarking, "produce", "deposit", "take", "consume"));

    Title("Filling the buffer: the producer is stopped by the empty place free");
    var full = net.FireSequence(net.InitialMarking, "produce", "deposit", "produce", "deposit")[^1];
    Console.Write(Report.Sequence(net, net.InitialMarking, "produce", "deposit", "produce", "deposit"));
    Console.WriteLine($"enabled now: {Enabled(net, full)}");
    var producedAgain = net.Fire(full, net.TransitionIndex("produce"));
    Console.WriteLine($"after produce: {producedAgain} {producedAgain.ToString(net)}");
    Console.WriteLine($"enabled now: {Enabled(net, producedAgain)}");
    Console.WriteLine($"deposit enabled: {net.IsEnabled(producedAgain, net.TransitionIndex("deposit"))}"
                      + $"  (free holds {producedAgain[net.PlaceIndex("free")]} tokens)");

    Title("Concurrency: produce and take do not compete, and the order does not matter");
    var shared = net.FireSequence(net.InitialMarking, "produce", "deposit")[^1];
    Console.WriteLine($"from {shared} {shared.ToString(net)}");
    var left = net.FireSequence(shared, "produce", "take")[^1];
    var right = net.FireSequence(shared, "take", "produce")[^1];
    Console.WriteLine($"produce then take: {left}");
    Console.WriteLine($"take then produce: {right}");
    Console.WriteLine($"same marking: {left.Equals(right)}");

    Title("A state machine would need one state per combination");
    var graph = ReachabilityGraph.Build(net);
    Console.WriteLine($"markings of this net: {graph.States.Count}");
    Console.WriteLine($"tokens in the net: {string.Join(", ", graph.States.Select(m => m.TotalTokens).Distinct().Order())}");

    Title("Exercise 2: two threads and one lock, as a diagram");
    Console.Write(Mermaid.Draw(Nets.MutualExclusion()));
}

// Lesson 2: the matrices, the state equation, and a marking the equation accepts but the net cannot reach.
void Lesson2()
{
    var net = Nets.ProducerConsumer();
    Title("Pre, Post and the incidence matrix");
    Console.Write(Report.Matrices(net));

    Title("One firing as a column of C");
    var c = net.Incidence();
    for (var t = 0; t < net.Transitions.Count; t++)
    {
        var column = Enumerable.Range(0, net.Places.Count).Select(p => c[p, t]);
        Console.WriteLine($"{net.Transitions[t].Name,-10} {string.Join(" ", column.Select(v => v.ToString(CultureInfo.InvariantCulture).PadLeft(2)))}");
    }

    Title("The state equation on a real sequence");
    string[] sequence = ["produce", "deposit", "produce", "take"];
    var markings = net.FireSequence(net.InitialMarking, sequence);
    var counts = new int[net.Transitions.Count];
    foreach (var name in sequence) counts[net.TransitionIndex(name)]++;
    Console.WriteLine($"sequence  {string.Join(" ", sequence)}");
    Console.WriteLine($"x         ({string.Join(", ", counts)})   in the order {string.Join(" ", net.Transitions.Select(t => t.Name))}");
    Console.WriteLine($"M0        {net.InitialMarking}");
    Console.WriteLine($"M0 + C x  ({string.Join(", ", StateEquation.Apply(net, net.InitialMarking, counts))})");
    Console.WriteLine($"fired     {markings[^1]}");

    Title("The same x in a different order");
    var reordered = net.FireSequence(net.InitialMarking, "produce", "deposit", "take", "produce")[^1];
    Console.WriteLine($"produce deposit take produce -> {reordered}");
    Console.WriteLine($"same marking: {reordered.Equals(markings[^1])}");

    Title("An order that does not exist");
    Console.WriteLine("take produce deposit produce: take is not enabled at M0, and the equation does not care.");
    Console.WriteLine($"M0 + C x  ({string.Join(", ", StateEquation.Apply(net, net.InitialMarking, counts))})");

    Title("A net where the equation accepts what the net refuses");
    var handshake = Nets.Handshake();
    Console.Write(Report.Net(handshake));
    Console.Write(Mermaid.Draw(handshake));
    Console.Write(Report.Matrices(handshake));
    var graph = ReachabilityGraph.Build(handshake);
    Console.Write(Report.Graph(graph));
    var target = new Marking(0, 0, 1);
    var solution = StateEquation.Solve(handshake, target);
    Console.WriteLine($"target    {target}  {target.ToString(handshake)}");
    Console.WriteLine($"solution  x = ({string.Join(", ", solution ?? [])})   in the order {string.Join(" ", handshake.Transitions.Select(t => t.Name))}");
    Console.WriteLine($"reachable: {graph.States.Contains(target)}");
    Console.WriteLine("spurious markings up to 2 tokens: "
                      + string.Join(" ", StateEquation.SpuriousMarkings(handshake, 2).Select(m => m.ToString())));

    Title("Invariants read off the same matrix (lesson 5)");
    Console.Write(Report.InvariantReport(net));

    Title("Exercise 1: the incidence matrix of mutual exclusion");
    var mutex = Nets.MutualExclusion();
    Console.Write(Report.Matrix(mutex, mutex.Incidence(), "C = Post - Pre (change of marking per firing)"));
}

// Lesson 3: the reachability graph, its growth, and the coverability tree that survives an infinite one.
void Lesson3()
{
    var net = Nets.ProducerConsumer();
    Title("The reachability graph of the bounded producer and consumer");
    var graph = ReachabilityGraph.Build(net);
    Console.Write(Report.Graph(graph));

    Title("The same graph as a diagram");
    Console.Write(Mermaid.DrawGraph(graph));

    Title("Its coverability tree: bounded, so no omega appears");
    Console.Write(Report.Tree(CoverabilityTree.Build(net)));

    Title("Remove the place free and the graph becomes infinite");
    var unbounded = Nets.UnboundedProducer();
    Console.Write(Report.Net(unbounded));
    var prefix = ReachabilityGraph.Build(unbounded, limit: 50);
    Console.WriteLine($"stopped after {prefix.States.Count} states, complete: {prefix.IsComplete}");
    Console.WriteLine("largest number of tokens in full among them: "
                      + prefix.States.Max(m => m[unbounded.PlaceIndex("full")]));

    Title("The coverability tree finds the same net finite");
    Console.Write(Report.Tree(CoverabilityTree.Build(unbounded)));

    Title("What omega forgets");
    Console.WriteLine("The tree says full is unbounded. It cannot say whether full ever holds exactly 3 tokens");
    Console.WriteLine("while the consumer waits, because omega replaced the count.");

    Title("How fast the graph grows");
    Console.WriteLine("capacity  states  firings");
    for (var capacity = 1; capacity <= 8; capacity++)
    {
        var sized = ReachabilityGraph.Build(Nets.ProducerConsumer(capacity));
        Console.WriteLine($"{capacity,8}  {sized.States.Count,6}  {sized.Steps.Count,7}");
    }
    Console.WriteLine();
    Console.WriteLine("philosophers  states  firings");
    for (var count = 2; count <= 10; count++)
    {
        var philosophers = ReachabilityGraph.Build(Nets.Philosophers(count));
        Console.WriteLine($"{count,12}  {philosophers.States.Count,6}  {philosophers.Steps.Count,7}");
    }
    Console.WriteLine();
    Console.WriteLine("independent copies  states  firings");
    for (var copies = 1; copies <= 5; copies++)
    {
        var independent = ReachabilityGraph.Build(Nets.Independent(copies), limit: 400_000);
        Console.WriteLine($"{copies,18}  {independent.States.Count,6}  {independent.Steps.Count,7}");
    }

    Title("Exercise 4: a transition that reads a place and fills two others");
    Console.Write(Mermaid.Draw(Nets.EmitLoop()));
}

// Lesson 4: boundedness, safeness, liveness, deadlock, reversibility, home states, persistence.
void Lesson4()
{
    foreach (var net in new[]
             {
                 Nets.ProducerConsumer(),
                 Nets.MutualExclusion(),
                 Nets.TwoLocks(),
                 Nets.StartOnce(),
                 Nets.Handshake(),
             })
    {
        Title($"{net.Name}");
        var graph = ReachabilityGraph.Build(net);
        Console.Write(Report.Properties(net, Behaviour.Analyse(graph)));
        Console.WriteLine();
    }

    Title("The unbounded net, seen by the coverability tree");
    var unbounded = Nets.UnboundedProducer();
    var tree = CoverabilityTree.Build(unbounded);
    Console.WriteLine($"bounded: {tree.IsBounded}");
    var bounds = tree.PlaceBounds();
    for (var p = 0; p < unbounded.Places.Count; p++)
        Console.WriteLine($"  bound of {unbounded.Places[p].Name}: {(bounds[p] is { } b ? b.ToString() : "unbounded")}");

    Title("How the two locks deadlock");
    var locks = Nets.TwoLocks();
    Console.Write(Mermaid.Draw(locks));
    var lockGraph = ReachabilityGraph.Build(locks);
    foreach (var dead in lockGraph.DeadStates)
    {
        var path = lockGraph.PathTo(dead) ?? [];
        Console.WriteLine($"M{dead} = {lockGraph.States[dead]}  {lockGraph.States[dead].ToString(locks)}");
        Console.WriteLine("  reached by: " + string.Join(", ", path.Select(t => locks.Transitions[t].Name)));
    }

    Title("The place invariants that make mutual exclusion a proof");
    Console.Write(Report.InvariantReport(Nets.MutualExclusion()));
}

// Lesson 5: place and transition invariants, and a bound proved without looking at a single marking.
void Lesson5()
{
    var net = Nets.ProducerConsumer();
    Title("What the producer and consumer never stops conserving");
    Console.Write(Report.InvariantReport(net));
    var rank = Invariants.Rank(net);
    Console.WriteLine($"places: {net.Places.Count}   rank of C: {rank}   "
                      + $"dimension of the solutions of y C = 0: {net.Places.Count - rank}");

    Title("The proof that the buffer cannot overflow");
    var full = net.PlaceIndex("full");
    var buffer = Invariants.Places(net).Single(i => i.Support.Contains(full));
    Console.WriteLine($"invariant     {Report.PlaceInvariant(net, buffer)}");
    Console.WriteLine("both counts are numbers of tokens, so free >= 0 and full >= 0");
    Console.WriteLine("therefore     full <= 2 at every reachable marking, and at every marking at all");
    Console.WriteLine("markings enumerated to get there: 0");
    var graph = ReachabilityGraph.Build(net);
    var holds = graph.States.All(m => Invariants.WeightedTokens(buffer, m) == Invariants.WeightedTokens(buffer, net.InitialMarking));
    Console.WriteLine($"checking it anyway on the graph of lesson 3: {graph.States.Count} markings, invariant holds in all: {holds}");
    Console.WriteLine($"largest value of full among them: {graph.States.Max(m => m[full])}");

    Title("The bound of every place, three ways");
    Console.Write(Report.Bounds(net));

    Title("The same table on the net with the brake removed");
    Console.Write(Report.InvariantReport(Nets.UnboundedProducer()));
    Console.Write(Report.Bounds(Nets.UnboundedProducer(), limit: 500));

    Title("An invariant cannot exclude what the state equation accepts");
    var handshake = Nets.Handshake();
    Console.Write(Report.InvariantReport(handshake));
    foreach (var spurious in StateEquation.SpuriousMarkings(handshake, 2))
    {
        var satisfied = Invariants.Places(handshake)
            .All(i => Invariants.WeightedTokens(i, spurious) == Invariants.WeightedTokens(i, handshake.InitialMarking));
        Console.WriteLine($"spurious marking {spurious}  {spurious.ToString(handshake)}  satisfies every place invariant: {satisfied}");
    }

    Title("What invariants do not see: the deadlock of two locks");
    var locks = Nets.TwoLocks();
    Console.Write(Report.InvariantReport(locks));
    var dead = ReachabilityGraph.Build(locks) is { } lockGraph && lockGraph.DeadStates.Count > 0
        ? lockGraph.States[lockGraph.DeadStates[0]]
        : null;
    Console.WriteLine($"dead marking {dead}  {dead?.ToString(locks)}");
    Console.WriteLine("every place invariant above holds there too: "
                      + Invariants.Places(locks).All(i =>
                            Invariants.WeightedTokens(i, dead!) == Invariants.WeightedTokens(i, locks.InitialMarking)));

    Title("Transition invariants: the firings that cancel out");
    foreach (var invariant in Invariants.Transitions(net))
    {
        Console.WriteLine($"x = {invariant}   {Report.TransitionInvariant(net, invariant)}");
        var after = net.FireSequence(net.InitialMarking, "produce", "deposit", "take", "consume")[^1];
        Console.WriteLine($"firing it once from M0 gives {after}, back to {net.InitialMarking}: {after.Equals(net.InitialMarking)}");
    }
    Console.WriteLine();
    Console.WriteLine("two locks has two of them, and a marking from which neither can be fired at all:");
    foreach (var invariant in Invariants.Transitions(locks))
        Console.WriteLine($"  x = {invariant}   {Report.TransitionInvariant(locks, invariant)}");
    Console.WriteLine($"  transitions enabled at the dead marking: {Enabled(locks, dead!)}");
    Console.WriteLine();
    Console.WriteLine("the handshake has none at all, and that is a statement about its runs:");
    Console.WriteLine($"  transition invariants of handshake: {Invariants.Transitions(handshake).Count}");
    Console.WriteLine($"  transition invariants of handshake-started: {Invariants.Transitions(Nets.HandshakeStarted()).Count}");
    Console.WriteLine("  a marking it can reach twice: "
                      + ReachabilityGraph.Build(Nets.HandshakeStarted(), limit: 500).HasCycle);
    Console.WriteLine("  a marking the producer and consumer can reach twice: "
                      + ReachabilityGraph.Build(net).HasCycle);

    Title("Exercise 2: the invariants of mutual exclusion and of the readers and writers");
    Console.Write(Report.InvariantReport(Nets.MutualExclusion()));
    Console.Write(Report.InvariantReport(Nets.ReadersWriters()));

    Title("Exercise 4: the invariants of the emit loop");
    Console.Write(Report.InvariantReport(Nets.EmitLoop()));
}

// Lesson 6: state machines, marked graphs, free-choice nets, and the siphons and traps behind them.
void Lesson6()
{
    Title("Where the nets of this course sit");
    Console.Write(Report.StructureTable(
    [
        Nets.ProducerConsumer(),
        Nets.UnboundedProducer(),
        Nets.Connection(),
        Nets.StartOnce(),
        Nets.Handshake(),
        Nets.MutualExclusion(),
        Nets.TwoLocks(),
        Nets.ReadersWriters(),
        Nets.Philosophers(3),
    ]));

    Title("A marked graph: the producer and consumer");
    var net = Nets.ProducerConsumer();
    Console.Write(Report.Structure(net));
    Console.Write(Report.Circuits(net));
    MarkedGraphVerdict(net);

    Title("A state machine that is live, and one that is not");
    foreach (var machine in new[] { Nets.Connection(), Nets.StartOnce() })
    {
        Console.Write(Report.Net(machine));
        Console.Write(Report.Structure(machine));
        StateMachineVerdict(machine);
        Console.WriteLine();
    }

    Title("Free choice, siphons and traps");
    foreach (var free in new[] { Nets.ProducerConsumer(), Nets.StartOnce(), Nets.Handshake() })
    {
        Console.Write(Report.Siphons(free));
        CommonerVerdict(free);
        Console.WriteLine();
    }

    Title("A liveness decided where no reachability graph exists");
    var started = Nets.HandshakeStarted();
    Console.Write(Report.Net(started));
    Console.Write(Report.Siphons(started));
    Console.WriteLine($"free choice: {Structure.Classify(started).IsFreeChoice}");
    Console.WriteLine($"every siphon contains a marked trap: {Structure.EverySiphonHasAMarkedTrap(started)}");
    Console.WriteLine("Commoner: live");
    var tree = CoverabilityTree.Build(started);
    Console.WriteLine($"the graph cannot say so: bounded: {tree.IsBounded}, "
                      + $"dead transitions: {(tree.DeadTransitions().Count == 0 ? "none" : "some")}");
    var prefix = ReachabilityGraph.Build(started, limit: 500);
    Console.WriteLine($"reachability graph stopped after {prefix.States.Count} markings, complete: {prefix.IsComplete}");

    Title("Every dead marking empties a siphon");
    var locks = Nets.TwoLocks();
    var graph = ReachabilityGraph.Build(locks);
    foreach (var state in graph.DeadStates)
    {
        var marking = graph.States[state];
        var empty = Structure.EmptyPlaces(marking);
        Console.WriteLine($"dead marking {marking}  {marking.ToString(locks)}");
        Console.WriteLine($"  places holding nothing: {Report.Set(locks, empty)}");
        Console.WriteLine($"  that set is a siphon: {Structure.IsSiphon(locks, empty)}");
        Console.WriteLine($"  largest trap inside it: {Report.Set(locks, Structure.MaximalTrapIn(locks, empty))}");
    }
    Console.Write(Report.Siphons(locks));
    Console.WriteLine($"free choice: {Structure.Classify(locks).IsFreeChoice}  "
                      + "(so Commoner does not apply, and only the one-way implication does)");

    Title("Where the classes stop: the place two transitions fight over");
    foreach (var shared in new[] { Nets.MutualExclusion(), Nets.TwoLocks(), Nets.Philosophers(3) })
    {
        var classes = Structure.Classify(shared);
        Console.WriteLine($"{shared.Name,-18} free choice: {classes.IsFreeChoice}, "
                          + $"extended: {classes.IsExtendedFreeChoice}, asymmetric: {classes.IsAsymmetricChoice}");
        foreach (var p in Enumerable.Range(0, shared.Places.Count))
        {
            var outputs = Structure.OutputTransitions(shared, p);
            if (outputs.Count < 2) continue;
            Console.WriteLine($"  {shared.Places[p].Name} feeds "
                              + string.Join(" and ", outputs.Select(t => shared.Transitions[t].Name))
                              + ", which do not read the same places");
        }
    }

    Title("Exercise 1: the same net with both threads taking x first");
    var ordered = Nets.TwoLocksOrdered();
    Console.Write(Report.Siphons(ordered));
    Console.WriteLine($"free choice: {Structure.Classify(ordered).IsFreeChoice}");
    Console.WriteLine($"deadlock-free by the graph: {Behaviour.Analyse(ordered).IsDeadlockFree}");
}

// Lesson 7: mutual exclusion, semaphores, bounded channels, readers and writers, philosophers.
void Lesson7()
{
    Title("One lock, and the invariant that is the proof");
    var mutex = Nets.MutualExclusion();
    Console.Write(Report.InvariantReport(mutex));
    var mutexGraph = ReachabilityGraph.Build(mutex);
    Console.WriteLine($"markings where both threads are inside: "
                      + mutexGraph.States.Count(m => m[mutex.PlaceIndex("critical1")] > 0 && m[mutex.PlaceIndex("critical2")] > 0)
                      + $" out of {mutexGraph.States.Count}");

    Title("k permits instead of one: the counting semaphore");
    Console.WriteLine("threads  permits  states  greatest number inside at once  invariant");
    foreach (var permits in new[] { 1, 2, 3 })
    {
        var semaphore = Nets.CountingSemaphore(3, permits);
        var graph = ReachabilityGraph.Build(semaphore);
        var inside = Enumerable.Range(0, semaphore.Places.Count).Where(p => semaphore.Places[p].Name.StartsWith("inside")).ToList();
        var most = graph.States.Max(m => inside.Sum(p => m[p]));
        var invariant = Invariants.Places(semaphore).Single(i => i.Support.Contains(semaphore.PlaceIndex("permits")));
        Console.WriteLine($"{3,7}  {permits,7}  {graph.States.Count,6}  {most,29}  {Report.PlaceInvariant(semaphore, invariant)}");
    }

    Title("A bounded channel is the place free");
    Console.WriteLine("capacity  states  bound of full  invariant");
    foreach (var capacity in new[] { 1, 2, 3, 4 })
    {
        var channel = Nets.ProducerConsumer(capacity);
        var graph = ReachabilityGraph.Build(channel);
        var invariant = Invariants.Places(channel).Single(i => i.Support.Contains(channel.PlaceIndex("full")));
        Console.WriteLine($"{capacity,8}  {graph.States.Count,6}  {graph.PlaceBounds()[channel.PlaceIndex("full")],13}  "
                          + Report.PlaceInvariant(channel, invariant));
    }

    Title("Readers and writers, with one arc of weight 3");
    var rw = Nets.ReadersWriters();
    Console.Write(Report.Net(rw));
    Console.Write(Mermaid.Draw(rw));
    Console.Write(Report.InvariantReport(rw));
    var rwGraph = ReachabilityGraph.Build(rw);
    Console.Write(Report.Properties(rw, Behaviour.Analyse(rwGraph)));
    Console.WriteLine("markings with a writer and a reader at once: "
                      + rwGraph.States.Count(m => m[rw.PlaceIndex("writing")] > 0 && m[rw.PlaceIndex("reading")] > 0));
    Console.WriteLine("markings with two writers at once: "
                      + rwGraph.States.Count(m => m[rw.PlaceIndex("writing")] > 1));

    Title("Live and starved at the same time");
    var writer = rw.TransitionIndex("start_write");
    var cycle = rwGraph.CycleAvoiding(writer);
    Console.WriteLine($"start_write is live: {Behaviour.Analyse(rwGraph).TransitionLiveness[writer] == Liveness.Live}");
    if (cycle is { } loop)
    {
        Console.WriteLine("and yet the net can run for ever without ever firing it:");
        for (var i = 0; i < loop.States.Count; i++)
            Console.WriteLine($"  M{loop.States[i]} = {rwGraph.States[loop.States[i]]}  --{rw.Transitions[loop.Transitions[i]].Name}-->");
    }

    Title("The philosophers, with and without one fork at a time");
    Console.WriteLine("philosophers  both forks at once        one fork at a time       one of them reversed");
    Console.WriteLine("              states  deadlocks          states  deadlocks         states  deadlocks");
    for (var count = 2; count <= 6; count++)
    {
        var atomic = ReachabilityGraph.Build(Nets.Philosophers(count));
        var greedy = ReachabilityGraph.Build(Nets.PhilosophersOneFork(count));
        var ordered = ReachabilityGraph.Build(Nets.PhilosophersOneFork(count, ordered: true));
        Console.WriteLine($"{count,12}  {atomic.States.Count,6}  {atomic.DeadStates.Count,9}"
                          + $"          {greedy.States.Count,6}  {greedy.DeadStates.Count,9}"
                          + $"         {ordered.States.Count,6}  {ordered.DeadStates.Count,9}");
    }

    Title("The deadlock of five philosophers, and how to reach it");
    var hungry = Nets.PhilosophersOneFork(5);
    var hungryGraph = ReachabilityGraph.Build(hungry);
    var firstDead = hungryGraph.DeadStates[0];
    Console.WriteLine($"dead markings: {hungryGraph.DeadStates.Count} out of {hungryGraph.States.Count}");
    Console.WriteLine($"M{firstDead} = {hungryGraph.States[firstDead].ToString(hungry)}");
    Console.WriteLine("  reached by: " + string.Join(", ",
        (hungryGraph.PathTo(firstDead) ?? []).Select(t => hungry.Transitions[t].Name)));
    var deadMarking = hungryGraph.States[firstDead];
    var empty = Structure.EmptyPlaces(deadMarking);
    Console.WriteLine($"  places holding nothing: {empty.Count} of {hungry.Places.Count}, every fork among them");
    Console.WriteLine($"  that set is a siphon: {Structure.IsSiphon(hungry, empty)}");
    Console.WriteLine($"  largest trap inside it: {Report.Set(hungry, Structure.MaximalTrapIn(hungry, empty))}");
    Console.WriteLine();
    var three = Nets.PhilosophersOneFork(3);
    var siphons = Structure.SiphonsAndTraps(three);
    Console.WriteLine($"three philosophers, one fork at a time: {siphons.Count} minimal siphons, "
                      + $"{siphons.Count(s => !s.TrapIsMarked)} of them with no marked trap");
    foreach (var siphon in siphons.Where(s => !s.TrapIsMarked))
        Console.WriteLine($"  {Report.Set(three, siphon.Siphon)}");
    var ordered3 = Nets.PhilosophersOneFork(3, ordered: true);
    var orderedSiphons = Structure.SiphonsAndTraps(ordered3);
    Console.WriteLine($"with one of them reversed: {orderedSiphons.Count} minimal siphons, "
                      + $"{orderedSiphons.Count(s => !s.TrapIsMarked)} of them with no marked trap");

    Title("Exercise 2: the lock the first thread never gives back");
    var leaky = Nets.MutualExclusionLeaky();
    Console.Write(Report.Properties(leaky, Behaviour.Analyse(leaky)));
    Console.Write(Report.InvariantReport(leaky));
    Console.Write(Report.Siphons(leaky));
}

// Lesson 8: coloured nets, their unfolding, and what colour costs and saves.
void Lesson8()
{
    var retry = ColouredNets.Retry();
    Title("A retry policy, in colour");
    Console.Write(retry.Describe());

    Title("The same net as a diagram");
    Console.Write(Mermaid.DrawColoured(retry));

    Title("A token that carries the attempt it is on");
    var markings = retry.FireSequence(retry.InitialMarking,
        ("fail", "0"), ("retry", "0"), ("fail", "1"), ("retry", "1"), ("fail", "2"), ("giveup", "2"));
    string[] steps = ["", "fail(n=0)", "retry(n=0)", "fail(n=1)", "retry(n=1)", "fail(n=2)", "giveup(n=2)"];
    for (var i = 0; i < markings.Count; i++)
        Console.WriteLine($"{steps[i],-12}{markings[i].ToString(retry)}");

    Title("The same net without colour: its unfolding");
    var unfolded = retry.Unfold();
    Console.Write(Report.Net(unfolded));

    Title("What the unfolding costs");
    Console.WriteLine("attempts  coloured places  coloured transitions  unfolded places  unfolded transitions  markings");
    foreach (var attempts in new[] { 2, 3, 5, 10, 20 })
    {
        var net = ColouredNets.Retry(attempts);
        var plain = net.Unfold();
        var graph = ReachabilityGraph.Build(plain);
        Console.WriteLine($"{attempts,8}  {net.Places.Count,15}  {net.Transitions.Count,20}  "
                          + $"{plain.Places.Count,15}  {plain.Transitions.Count,20}  {graph.States.Count,8}");
    }

    Title("What the unfolding then says");
    var graph8 = ReachabilityGraph.Build(unfolded);
    Console.Write(Report.Graph(graph8));
    Console.Write(Report.Properties(unfolded, Behaviour.Analyse(graph8)));

    Title("The guard is what removes the bindings");
    for (var t = 0; t < retry.Transitions.Count; t++)
    {
        var transition = retry.Transitions[t];
        var guard = transition.Guard.Text.Length == 0 ? "(none)" : transition.Guard.Text;
        Console.WriteLine($"{transition.Name,-10} guard {guard,-8} bindings kept: "
                          + string.Join(" ", retry.Bindings(t).Select(b => $"{transition.Variable}={b}")));
    }

    Title("Exercise 3: a guard no binding satisfies deletes the transition");
    var once = ColouredNets.Retry(0);
    Console.WriteLine($"retry keeps {once.Bindings(once.TransitionIndex("retry")).Count} bindings when the limit is 0");
    Console.Write(Report.Net(once.Unfold()));
}

// Writes every net of the course as PNML, so the lessons can show the file and tools can read it.
void WriteNets(string directory)
{
    Directory.CreateDirectory(directory);
    foreach (var net in Nets.All)
    {
        var path = Path.Combine(directory, net.Name + ".pnml");
        Pnml.Save(net, path);
        Console.WriteLine($"wrote {net.Name}.pnml");
    }
}

// Every net as a TLA+ module, next to a copy of the hand-written firing rule the modules instantiate.
// `java -cp tla2tools.jar tlc2.TLC <module>.tla` then enumerates the same state space from the other side.
void WriteTla(string directory)
{
    Directory.CreateDirectory(directory);
    var rule = Path.Combine(AppContext.BaseDirectory, "tla", "PetriNet.tla");
    if (File.Exists(rule)) File.Copy(rule, Path.Combine(directory, "PetriNet.tla"), overwrite: true);
    foreach (var net in Nets.All)
    {
        var (cap, fromInvariants) = Tla.Cap(net);
        Tla.Write(net, directory);
        var note = fromInvariants ? "bounded by the invariants" : "truncated: no invariant bounds every place";
        Console.WriteLine($"wrote {Tla.ModuleName(net)}.tla   cap {cap}, {note}");
    }
}

// Lesson 13: the same nets handed to TLC, and the three numbers a model checker prints for a state space.
void Lesson13(string? results)
{
    Console.WriteLine("Petri nets against other formalisms");
    Console.WriteLine();

    Console.WriteLine("The same net, written twice");
    Console.WriteLine();
    Console.WriteLine("  Nets.MutualExclusion() as a TLA+ module, generated by Examples/Tla.cs:");
    Console.WriteLine();
    foreach (var line in Tla.Module(Nets.MutualExclusion()).Replace("\r\n", "\n").TrimEnd('\n').Split('\n'))
        Console.WriteLine(line.Length == 0 ? "" : "    " + line);
    Console.WriteLine();
    Console.WriteLine("  The firing rule itself is not generated: tla/PetriNet.tla writes it once, by hand,");
    Console.WriteLine("  and every module instantiates it. A marking is a function from places to naturals,");
    Console.WriteLine("  so what TLC calls a state and what this course calls a marking are the same object.");
    Console.WriteLine();

    Console.WriteLine("What the model checker has to be told");
    Console.WriteLine();
    var truncated = Nets.All.Where(n => !Tla.Cap(n).FromInvariants).ToList();
    Console.WriteLine($"  {Nets.All.Count - truncated.Count} of {Nets.All.Count} nets carry a cap the place invariants produced.");
    Console.WriteLine($"  The other {truncated.Count} have no invariant covering every place, so the generated module caps them at {Tla.UnboundedCap}:");
    foreach (var net in truncated)
        Console.WriteLine($"    {net.Name}");
    Console.WriteLine();
    Console.WriteLine("  TLA+ has no notion of boundedness. Without a state constraint TLC enumerates until it");
    Console.WriteLine("  runs out of memory; with one it stops and says nothing is wrong. The coverability tree");
    Console.WriteLine("  of lesson 3 answers the question instead of avoiding it.");
    Console.WriteLine();

    Console.WriteLine("Three numbers for one state space");
    Console.WriteLine();
    Console.WriteLine($"  {"net",-26} {"markings",9} {"arcs",7} {"depth",6}   {"cap",4}");
    foreach (var net in Nets.All)
    {
        // The four capped nets have no finite graph to print; stopping at 5 000 says so without spending a minute
        // discovering it again, which is the same answer lesson 3 gives.
        var graph = ReachabilityGraph.Build(net, limit: 5_000);
        var (cap, fromInvariants) = Tla.Cap(net);
        var mark = fromInvariants ? " " : "*";
        Console.WriteLine(graph.IsComplete
            ? $"  {net.Name,-26} {graph.States.Count,9} {graph.Steps.Count,7} {Eccentricity(graph),6}   {cap,4}{mark}"
            : $"  {net.Name,-26} {"> 5000",9} {"",7} {"",6}   {cap,4}{mark}");
    }
    Console.WriteLine();
    Console.WriteLine("  * capped rather than bounded. Three of the four have no finite reachability graph, so");
    Console.WriteLine("    the cap is the only thing that makes TLC stop. The fourth, handshake, has exactly one");
    Console.WriteLine("    marking and is dead: a place invariant proves boundedness, it never disproves it.");
    Console.WriteLine();
    // TLC collects the successor states of a marking, this analyser collects its steps. The two counts differ
    // exactly when two transitions lead from one marking to the same one, which no net in this course does.
    var confluent = Nets.All
        .Where(n => Tla.Cap(n).FromInvariants)
        .Select(n => ReachabilityGraph.Build(n))
        .Sum(g => g.Steps.Count - g.Steps.Select(s => (s.From, s.To)).Distinct().Count());
    Console.WriteLine($"  Steps that share a source and a target across the {Nets.All.Count(n => Tla.Cap(n).FromInvariants)} bounded nets: {confluent}.");
    Console.WriteLine("  In order-sound, `ship` and `cancel` lead from one marking to the same one. A Petri net's");
    Console.WriteLine("  graph is labelled by transitions and TLA+'s is not, so that step should have gone missing");
    Console.WriteLine("  from TLC's count. It does not: TLC counts one state generated per disjunct it evaluates,");
    Console.WriteLine("  not per successor it keeps, which is why 'arcs + 1' survives the collision.");
    Console.WriteLine();

    Console.WriteLine("What a net says that a specification does not");
    Console.WriteLine();
    foreach (var (name, net) in new (string, PetriNet)[]
             {
                 ("mutual-exclusion", Nets.MutualExclusion()),
                 ("philosophers-one-fork-3", Nets.PhilosophersOneFork(3)),
                 ("readers-writers", Nets.ReadersWriters()),
             })
    {
        var siphons = Structure.MinimalSiphons(net);
        var traps = Structure.MinimalTraps(net);
        var invariants = Invariants.Places(net);
        Console.WriteLine($"  {name,-26} {invariants.Count,2} place invariants, {siphons.Count,2} minimal siphons, {traps.Count,2} minimal traps");
    }
    Console.WriteLine();
    Console.WriteLine("  None of these three numbers needs a reachable state. They are read off the arcs, which");
    Console.WriteLine("  is why lesson 7's deadlock verdict survives a net whose state space nobody can build.");
    Console.WriteLine();

    if (results is null)
    {
        Console.WriteLine("Against TLC");
        Console.WriteLine();
        Console.WriteLine("  Pass the directory of a TLC run to compare the two enumerations:");
        Console.WriteLine("    dotnet run --project Examples -c Release -- tla out/tla");
        Console.WriteLine("    java -cp tla2tools.jar tlc2.TLC -workers 1 -cleanup out/tla/mutual_exclusion.tla");
        Console.WriteLine("  tla2tools.jar is at https://github.com/tlaplus/tlaplus/releases (MIT), and is not vendored here.");
        return;
    }

    Console.WriteLine("Against TLC");
    Console.WriteLine();
    Console.WriteLine($"  {"net",-26} {"markings",9} {"distinct",9}  {"arcs+1",7} {"generated",10}  {"depth+1",8} {"TLC",4}");
    foreach (var net in Nets.All)
    {
        var path = Path.Combine(results, Tla.ModuleName(net) + ".out");
        if (!File.Exists(path)) continue;
        var text = File.ReadAllText(path);
        var (distinct, generated, depth) = TlcCounts(text);
        var graph = ReachabilityGraph.Build(net, limit: 5_000);
        if (!graph.IsComplete)
        {
            Console.WriteLine($"  {net.Name,-26} {"> 5000",9} {distinct,9}  {"",7} {generated,10}  {"",8} {depth,4}   truncated");
            continue;
        }
        var agree = graph.States.Count == distinct && graph.Steps.Count + 1 == generated && Eccentricity(graph) + 1 == depth;
        Console.WriteLine($"  {net.Name,-26} {graph.States.Count,9} {distinct,9}  {graph.Steps.Count + 1,7} {generated,10}  {Eccentricity(graph) + 1,8} {depth,4}   {(agree ? "agree" : "DIFFER")}");
    }
}

// The longest of the shortest paths from the initial marking, in one breadth-first pass. PathTo answers for one
// state and re-walks the graph each time, which is quadratic over a whole state space.
int Eccentricity(ReachabilityGraph graph)
{
    var distance = new int[graph.States.Count];
    Array.Fill(distance, -1);
    distance[0] = 0;
    var outgoing = graph.Steps.GroupBy(s => s.From).ToDictionary(g => g.Key, g => g.Select(s => s.To).ToArray());
    var queue = new Queue<int>();
    queue.Enqueue(0);
    var deepest = 0;
    while (queue.Count > 0)
    {
        var from = queue.Dequeue();
        if (!outgoing.TryGetValue(from, out var tos)) continue;
        foreach (var to in tos)
        {
            if (distance[to] >= 0) continue;
            distance[to] = distance[from] + 1;
            deepest = Math.Max(deepest, distance[to]);
            queue.Enqueue(to);
        }
    }
    return deepest;
}

(int Distinct, int Generated, int Depth) TlcCounts(string text)
{
    var counts = System.Text.RegularExpressions.Regex.Match(text, @"(\d+) states generated, (\d+) distinct states found");
    var depth = System.Text.RegularExpressions.Regex.Match(text, @"depth of the complete state graph search is (\d+)");
    return (counts.Success ? int.Parse(counts.Groups[2].Value, CultureInfo.InvariantCulture) : -1,
            counts.Success ? int.Parse(counts.Groups[1].Value, CultureInfo.InvariantCulture) : -1,
            depth.Success ? int.Parse(depth.Groups[1].Value, CultureInfo.InvariantCulture) : -1);
}

// Lesson 15: where the analyser stops, measured rather than asserted — and what the extension that
// would lift one limit costs in decidability.
void Lesson15()
{
    Console.WriteLine("Limits, measured");
    Console.WriteLine();

    Console.WriteLine("How fast the state space grows");
    Console.WriteLine();
    Console.WriteLine($"  {"family",-24} {"n",3} {"markings",10} {"arcs",11} {"arcs/marking",13}");
    foreach (var (family, build, sizes) in new (string, Func<int, PetriNet>, int[])[]
             {
                 ("philosophers", Nets.Philosophers, [2, 3, 4, 5, 6, 7]),
                 ("philosophers-one-fork", n => Nets.PhilosophersOneFork(n), [2, 3, 4, 5, 6]),
                 ("kanban", Nets.Kanban, [1, 2, 3]),
             })
    {
        foreach (var n in sizes)
        {
            var graph = ReachabilityGraph.Build(build(n), limit: 2_000_000);
            if (!graph.IsComplete)
            {
                Console.WriteLine($"  {family,-24} {n,3} {"> 2000000",10}");
                break;
            }
            var ratio = (double)graph.Steps.Count / graph.States.Count;
            Console.WriteLine($"  {family,-24} {n,3} {graph.States.Count,10} {graph.Steps.Count,11} {ratio,13:F1}");
        }
    }
    Console.WriteLine();
    Console.WriteLine("  Lesson 12 measured the wall at 1.216 G arcs on an 8 GiB heap. What this table adds is");
    Console.WriteLine("  the shape of the approach: the number of arcs per marking climbs with n, so each extra");
    Console.WriteLine("  component costs more than the markings it adds.");
    Console.WriteLine();

    Console.WriteLine("What the structure costs by comparison");
    Console.WriteLine();
    Console.WriteLine($"  {"net",-24} {"places",7} {"invariants",11} {"siphons",8} {"traps",7}");
    foreach (var n in new[] { 3, 4, 5 })
    {
        var net = Nets.Philosophers(n);
        var siphons = net.Places.Count <= 20 ? Structure.MinimalSiphons(net).Count.ToString(CultureInfo.InvariantCulture) : "> 20 places";
        var traps = net.Places.Count <= 20 ? Structure.MinimalTraps(net).Count.ToString(CultureInfo.InvariantCulture) : "> 20 places";
        Console.WriteLine($"  {net.Name,-24} {net.Places.Count,7} {Invariants.Places(net).Count,11} {siphons,8} {traps,7}");
    }
    Console.WriteLine();
    Console.WriteLine("  The invariants are a matrix computation and keep answering. The siphons are the brute");
    Console.WriteLine("  force of lesson 7, capped at twenty places, and that cap is this analyser's, not the");
    Console.WriteLine("  theory's: the question is NP-hard, and a constraint solver would push it further.");
    Console.WriteLine();

    Console.WriteLine("The extension that lifts the limit, and what it costs");
    Console.WriteLine();
    var self = InhibitorNets.SelfInhibited();
    var (selfStates, _, selfComplete) = self.Reachable();
    var tree = CoverabilityTree.Build(self.Net);
    Console.WriteLine("  self-inhibited: one place, one transition, one inhibitor arc.");
    Console.WriteLine($"    as an ordinary net, the coverability tree says bounded = {tree.IsBounded}, p <= {Describe(tree.PlaceBounds()[0])}");
    Console.WriteLine($"    with the inhibitor arc, the reachable set is {selfStates.Count} markings, p <= {self.PlaceBounds()[0]}, complete = {selfComplete}");
    Console.WriteLine();
    Console.WriteLine("  Karp and Miller accelerate on the argument that a sequence reaching a strictly greater");
    Console.WriteLine("  marking can be repeated. An inhibitor arc breaks it: the token that appeared is exactly");
    Console.WriteLine("  what now blocks the transition that produced it. The tree is not slow here, it is wrong.");
    Console.WriteLine();
    Console.WriteLine($"  {"flush(n)",-12} {"with the zero test",20} {"without it",14}");
    foreach (var n in new[] { 1, 2, 4, 8 })
    {
        var flush = InhibitorNets.Flush(n);
        var (states, _, _) = flush.Reachable();
        var plain = ReachabilityGraph.Build(flush.Net);
        Console.WriteLine($"  {"flush-" + n.ToString(CultureInfo.InvariantCulture),-12} {states.Count,20} {plain.States.Count,14}");
    }
    Console.WriteLine();
    Console.WriteLine("  `finish` is blocked while `a` holds a token, so it fires once, after the last `move`.");
    Console.WriteLine("  Drop the inhibitor arc and it fires at any point: 2(n+1) markings instead of n+2, and a");
    Console.WriteLine("  model that no longer says what it was written to say.");
    Console.WriteLine();
    Console.WriteLine("  That zero test is what makes two places into the counters of a two-counter machine.");
    Console.WriteLine("  Boundedness, reachability and liveness are all undecidable for these nets, which is why");
    Console.WriteLine("  InhibitorNet has a reachable-set builder with a limit and no coverability counterpart.");
}

static string Describe(int? bound) => bound?.ToString(CultureInfo.InvariantCulture) ?? "omega";

// Lesson 6: the liveness and safeness of a marked graph, read off its circuits, then checked on the graph.
void MarkedGraphVerdict(PetriNet net)
{
    var circuits = Structure.Circuits(net);
    var live = circuits.All(c => c.Tokens(net.InitialMarking) >= 1);
    var safe = Enumerable.Range(0, net.Places.Count)
        .All(p => circuits.Any(c => c.Places.Contains(p) && c.Tokens(net.InitialMarking) == 1));
    var graph = ReachabilityGraph.Build(net);
    var properties = Behaviour.Analyse(graph);
    Console.WriteLine($"marked graph theorem  live: {live}   safe: {safe}   markings enumerated: 0");
    Console.WriteLine($"reachability graph    live: {properties.IsLive}   safe: {properties.IsSafe}   "
                      + $"markings enumerated: {graph.States.Count}");
}

// Lesson 6: a state machine is live when it is strongly connected and holds a token, and safe when it holds one.
void StateMachineVerdict(PetriNet net)
{
    var classes = Structure.Classify(net);
    var tokens = net.InitialMarking.TotalTokens ?? 0;
    var graph = ReachabilityGraph.Build(net);
    var properties = Behaviour.Analyse(graph);
    Console.WriteLine($"state machine theorem  strongly connected: {classes.IsStronglyConnected}   tokens at M0: {tokens}");
    Console.WriteLine($"                       live: {classes.IsStronglyConnected && tokens >= 1}   safe: {tokens <= 1}");
    Console.WriteLine($"reachability graph     live: {properties.IsLive}   safe: {properties.IsSafe}   "
                      + $"markings enumerated: {graph.States.Count}");
}

// Lesson 9: rates turn the reachability graph into a Markov chain, and the chain answers
// "how often" and "how long" - the two questions the untimed net refuses.
void Lesson9()
{
    const int capacity = 5;
    const double arrival = 3.0;
    const double service = 4.0;

    var queue = Nets.Queue(capacity);
    var graph = ReachabilityGraph.Build(queue);
    Title($"A queue with one server and room for {capacity}");
    Console.Write(Report.Net(queue));
    Console.WriteLine($"reachable markings: {graph.States.Count}");

    Title("The same structure, now with a rate on each transition");
    var timing = new Timing(new Dictionary<string, double>
    {
        ["arrive"] = arrival,
        ["serve"] = service,
    });
    Console.WriteLine($"arrive: {Stochastic.Format(arrival)} per unit of time");
    Console.WriteLine($"serve:  {Stochastic.Format(service)} per unit of time");
    Console.WriteLine($"load:   {Stochastic.Format(arrival / service)}");

    var steady = Stochastic.Solve(graph, timing);

    Title("Stationary distribution, computed twice");
    var formula = Stochastic.QueueFormula(arrival, service, capacity);
    Console.WriteLine("jobs   from the net   from the formula");
    var worst = 0.0;
    for (var k = 0; k <= capacity; k++)
    {
        var fromNet = steady.ProbabilityOf("jobs", k);
        worst = Math.Max(worst, Math.Abs(fromNet - formula[k]));
        Console.WriteLine($"{k,-7}{Stochastic.Format(fromNet),-14}{Stochastic.Format(formula[k])}");
    }
    // The gap is around 1e-16 and its digits differ between machines, so the check prints a
    // verdict against a threshold instead of a number that would never match three times.
    Console.WriteLine($"every state agrees within 1e-12: {(worst < 1e-12 ? "ok" : "DIFFERENT")}");

    Title("What the chain is worth asking");
    var mean = steady.MeanTokens("jobs");
    var thrArrive = steady.Throughput("arrive");
    var thrServe = steady.Throughput("serve");
    var lost = steady.ProbabilityOf("room", 0);
    Console.WriteLine($"mean jobs in the system:   {Stochastic.Format(mean)}");
    Console.WriteLine($"accepted arrivals:         {Stochastic.Format(thrArrive)} per unit of time");
    Console.WriteLine($"completions:               {Stochastic.Format(thrServe)} per unit of time");
    Console.WriteLine($"arrivals turned away:      {Stochastic.Format(lost)} of the time");
    Console.WriteLine($"server busy:               {Stochastic.Format(1 - steady.ProbabilityOf("jobs", 0))} of the time");

    Title("Little's law, as an independent check");
    var wait = mean / thrArrive;
    Console.WriteLine($"mean time in the system:   {Stochastic.Format(wait)}");
    Console.WriteLine($"arrivals times that time:  {Stochastic.Format(thrArrive * wait)}");
    Console.WriteLine($"mean jobs (above):         {Stochastic.Format(mean)}");
    Console.WriteLine($"in and out balance: {(Math.Abs(thrArrive - thrServe) < 1e-12 ? "ok" : "DIFFERENT")}");

    Title("Raising the load to 1 spreads the queue evenly");
    var even = Stochastic.Solve(graph, new Timing(new Dictionary<string, double>
    {
        ["arrive"] = 4.0,
        ["serve"] = 4.0,
    }));
    Console.WriteLine("jobs   probability");
    for (var k = 0; k <= capacity; k++)
        Console.WriteLine($"{k,-7}{Stochastic.Format(even.ProbabilityOf("jobs", k))}");

    Title("A choice that takes no time: immediate transitions");
    var servers = Nets.TwoServers();
    var serverGraph = ReachabilityGraph.Build(servers);
    Console.Write(Report.Net(servers));
    var gspn = new Timing(
        rates: new Dictionary<string, double> { ["done-fast"] = 2.0, ["done-slow"] = 1.0 },
        weights: new Dictionary<string, double> { ["to-fast"] = 7.0, ["to-slow"] = 3.0 });
    var split = Stochastic.Solve(serverGraph, gspn);
    Console.WriteLine($"reachable markings: {serverGraph.States.Count}, of which tangible: {split.Tangible.Count}");
    Console.WriteLine($"the job waits (vanishing state): {Stochastic.Format(split.ProbabilityOf("waiting", 1))} of the time");
    Console.WriteLine($"at the fast server: {Stochastic.Format(split.ProbabilityOf("at-fast", 1))}");
    Console.WriteLine($"at the slow server: {Stochastic.Format(split.ProbabilityOf("at-slow", 1))}");

    Title("The same two numbers by hand");
    // Seven jobs in ten go to a server that takes 1/2 a unit of time, three in ten to one that
    // takes 1; the time spent at each is the share divided by the rate, then normalised.
    var fast = 0.7 / 2.0;
    var slow = 0.3 / 1.0;
    Console.WriteLine($"at the fast server: {Stochastic.Format(fast / (fast + slow))}");
    Console.WriteLine($"at the slow server: {Stochastic.Format(slow / (fast + slow))}");
}

// Lesson 10: a workflow net is a net with one way in and one way out, and soundness is the
// property a business process is supposed to have. Both are decided here twice: once on the
// three conditions themselves, and once through the short-circuit of van der Aalst's theorem.
void Lesson10()
{
    var sound = Nets.OrderSound();
    Title("An order, as a workflow net");
    Console.Write(Report.Net(sound));

    Title("What makes it a workflow net");
    var endpoints = Workflow.Endpoints(sound, out var whyNot);
    Console.WriteLine($"source: {sound.Places[endpoints!.Value.Source].Name}");
    Console.WriteLine($"sink:   {sound.Places[endpoints.Value.Sink].Name}");
    Console.WriteLine($"why not: {whyNot ?? "(it is one)"}");
    Console.WriteLine($"short-circuited net adds: {Workflow.ShortCircuit(sound).Transitions[^1].Name}");

    Title("Soundness, condition by condition");
    PrintCheck(Workflow.Check(sound));

    Title("An AND split joined by an XOR: the case ends while a branch is still running");
    var andXor = Nets.OrderAndXor();
    PrintCheck(Workflow.Check(andXor));

    Title("An XOR split joined by an AND: the case stops one step short");
    var xorAnd = Nets.OrderXorAnd();
    PrintCheck(Workflow.Check(xorAnd));

    Title("A rework loop: sound, and able to run for ever without finishing");
    var rework = Nets.OrderRework();
    PrintCheck(Workflow.Check(rework));
    var graph = ReachabilityGraph.Build(rework);
    var cycle = graph.CycleAvoiding(rework.TransitionIndex("approve"));
    Console.WriteLine(cycle is null
        ? "no cycle avoids approve"
        : $"a cycle that never approves: {string.Join(" ", cycle.Value.Transitions.Select(x => rework.Transitions[x].Name))}");

    Title("The same four verdicts through the short circuit");
    // Van der Aalst 1997: a workflow net is sound exactly when the net short-circuited from the
    // sink back to the source is live and bounded. Two routes, one answer, no shared code.
    Console.WriteLine("net              sound?  live?  bounded?  live and bounded?  agree?");
    foreach (var net in new[] { sound, andXor, xorAnd, rework })
    {
        var direct = Workflow.Check(net).IsSound;
        var (live, bounded) = Workflow.ShortCircuitVerdict(net);
        var theorem = live && bounded;
        Console.WriteLine($"{net.Name,-17}{YesNo(direct),-8}{YesNo(live),-7}{YesNo(bounded),-10}{YesNo(theorem),-19}{YesNo(direct == theorem)}");
    }

    Title("What the short circuit is doing");
    // The theorem is not a coincidence: t-star turns "the case can always finish" into "every
    // transition can always fire again", which is liveness, and "nothing is left behind" into
    // boundedness of a net that now loops for ever.
    var shorted = Workflow.ShortCircuit(andXor);
    var properties = Behaviour.Analyse(shorted);
    Console.WriteLine($"{shorted.Name}: bound {properties.Bound?.ToString(CultureInfo.InvariantCulture) ?? "unbounded"}");
    for (var i = 0; i < shorted.Transitions.Count; i++)
        Console.WriteLine($"  {shorted.Transitions[i].Name,-16}{properties.TransitionLiveness[i]}");
}

void PrintCheck(WorkflowCheck check)
{
    Console.WriteLine($"net: {check.Net}");
    if (!check.IsWorkflowNet)
    {
        Console.WriteLine($"  not a workflow net: {check.WhyNotAWorkflowNet}");
        return;
    }
    Console.WriteLine($"  reachable markings:  {check.States}");
    Console.WriteLine($"  option to complete:  {YesNo(check.OptionToComplete)}");
    if (!check.FinalReachable)
        Console.WriteLine("    the final marking is never reached, from anywhere");
    else if (check.Stuck.Count > 0)
        Console.WriteLine($"    stuck at: {Markings(check.Stuck)}");
    Console.WriteLine($"  proper completion:   {YesNo(check.ProperCompletion)}");
    if (check.Improper.Count > 0)
        Console.WriteLine($"    finishes with something left: {Markings(check.Improper)}");
    Console.WriteLine($"  no dead transitions: {YesNo(check.DeadTransitions.Count == 0)}");
    if (check.DeadTransitions.Count > 0)
        Console.WriteLine($"    never enabled: {string.Join(", ", check.DeadTransitions)}");
    Console.WriteLine($"  sound: {YesNo(check.IsSound)}");
}

string YesNo(bool value) => value ? "yes" : "no";

// Three markings are enough to show the shape of a counter-example; the rest is noise in a lesson.
string Markings(IReadOnlyList<Marking> markings) =>
    string.Join("; ", markings.Take(3).Select(m => m.ToString()))
    + (markings.Count > 3 ? $"; and {markings.Count - 3} more" : "");

// Lesson 11: PNML is the one thing every Petri net tool agrees on. This lesson checks that claim
// in both directions - what we write can be read back unchanged, and what another tool wrote can
// be read at all. Pass a directory to run the second half against files this repository does not
// carry; check.sh runs it without one, so the comparison stays offline.
void Lesson11(string? foreign)
{
    Title("What the writer emits");
    var queue = Nets.Queue(2);
    Console.Write(Pnml.Write(queue));

    Title("Every net of the course, written and read back");
    // Interoperability begins at home: if the writer and the reader disagree, no other tool matters.
    var mismatch = 0;
    foreach (var net in Nets.All)
    {
        var xml = Pnml.Write(net);
        var back = Pnml.Parse(xml);
        var same = Pnml.Write(back) == xml
                   && ReachabilityGraph.Build(back).States.Count == ReachabilityGraph.Build(net).States.Count;
        if (!same)
        {
            Console.WriteLine($"  DIFFERENT: {net.Name}");
            mismatch++;
        }
    }
    Console.WriteLine($"{Nets.All.Count} nets written, parsed and written again");
    Console.WriteLine($"identical text and identical reachability graph: {(mismatch == 0 ? "all of them" : $"{mismatch} differ")}");

    Title("What a round trip drops");
    // PNML carries more than the analyser models. Reading a file and writing it back is lossless
    // for the net and lossy for everything a drawing tool put around it.
    Console.WriteLine("kept:    place and transition ids and names, arc weights, the initial marking");
    Console.WriteLine("dropped: <graphics> positions and offsets, <toolspecific> blocks, page structure");
    Console.WriteLine("refused: any <net type> that is not the P/T net type");

    if (foreign is null)
    {
        Title("Reading another tool");
        Console.WriteLine("no directory given; see the lesson for a run against the ePNK examples");
        return;
    }

    Title("Reading another tool");
    foreach (var path in Directory.GetFiles(foreign, "*.pnml").OrderBy(x => x, StringComparer.Ordinal))
    {
        var file = Path.GetFileName(path);
        try
        {
            var net = Pnml.Load(path);
            Console.WriteLine($"{file,-38}read: {net.Places.Count} places, {net.Transitions.Count} transitions, \"{net.Name}\"");
        }
        catch (Exception e)
        {
            Console.WriteLine($"{file,-38}refused: {Short(e.Message)}");
        }
    }
}

// The grammar URIs share a 41-character prefix that says nothing; the last segment is the answer.
string Short(string message) => message.Replace("http://www.pnml.org/version-2009/grammar/", "");

// Lesson 14, on our own systems: the lock the Claude sessions of this repository take before a
// heavy or a GPU job, in the two shell shapes it has been written in.
// Lesson 12: industrial nets. The course's own Kanban against the Model Checking Contest's answer,
// what four invariants say that two and a half million markings also say, and where enumeration stops.
// Pass a directory of MCC instances to compare against them directly; pass "big" for the five-card run.
void Lesson12(string? mode)
{
    var directory = mode is not null && mode != "big" ? mode : null;

    Title("A net from the shop floor");
    var kanban = Nets.Kanban(1);
    Console.Write(Report.Net(kanban));

    Title("What enumerating it costs");
    // No timings here: this block is compared line by line by check.sh, and a stopwatch never
    // prints the same thing twice. The lesson quotes the seconds from a dated run instead.
    Console.WriteLine($"{"cards",-8}{"markings",-16}{"arcs",-16}arcs per marking");
    foreach (var cards in (int[])[1, 2, 3])
    {
        var graph = ReachabilityGraph.Build(Nets.Kanban(cards), 1_000_000);
        Console.WriteLine($"{cards,-8}{graph.States.Count,-16}{graph.Steps.Count,-16}"
                          + $"{(double)graph.Steps.Count / graph.States.Count:F1}");
    }
    var five = Mcc.Published.Single(i => i.Instance == "Kanban-PT-00005");
    Console.WriteLine($"{5,-8}{five.Markings,-16}{five.Arcs,-16}{(double)five.Arcs / five.Markings:F1}"
                      + "   published by the contest, not run here");

    Title("Four invariants, and no graph at all");
    // Lesson 5 on an industrial net: the bound holds for every number of cards, and costs a matrix.
    Console.Write(Report.InvariantReport(Nets.Kanban(3)));

    Title("The same bounds, paid for twice");
    // Report.Bounds would add a third column from the coverability tree of lesson 3. It is left out
    // here: on this net the tree does not come back in any time worth waiting for, which is its own
    // lesson about industrial nets and is measured in the journal.
    var two = Nets.Kanban(2);
    var fromInvariants = Invariants.PlaceBounds(two);
    var enumerated = ReachabilityGraph.Build(two, 1_000_000);
    var fromGraph = enumerated.PlaceBounds();
    Console.WriteLine($"{"place",-12}{"invariants",-14}reachability graph");
    for (var p = 0; p < two.Places.Count; p++)
        Console.WriteLine($"{two.Places[p].Name,-12}{(fromInvariants[p]?.ToString() ?? "not covered"),-14}{fromGraph[p]?.ToString() ?? "unbounded"}");
    Console.WriteLine($"markings enumerated: 0 for the invariants, {enumerated.States.Count} for the graph");

    Title("What kind of net a factory turns out to be");
    Console.Write(Report.Structure(Nets.Kanban(1)));
    Console.Write(Report.Properties(kanban, Behaviour.Analyse(kanban)));

    Title("The contest's models, by industry");
    Console.WriteLine(Mcc.Source);
    Console.WriteLine($"{"instance",-32}{"markings",-12}{"arcs",-14}what it models");
    foreach (var group in Mcc.Published.GroupBy(i => i.Domain))
    {
        Console.WriteLine($"-- {group.Key}");
        foreach (var i in group)
            Console.WriteLine($"{i.Instance,-32}{i.Markings,-12}{i.Arcs,-14}{i.What}");
    }

    Title("Just above the line");
    Console.WriteLine($"{"instance",-24}{"markings",-14}{"arcs",-16}best time in the contest");
    foreach (var (instance, markings, arcs, best) in Mcc.OutOfReach)
        Console.WriteLine($"{instance,-24}{markings,-14}{arcs,-16}{best}");

    if (mode == "big")
    {
        Title("Five cards");
        var net = Nets.Kanban(5);
        var watch = System.Diagnostics.Stopwatch.StartNew();
        var graph = ReachabilityGraph.Build(net, 10_000_000);
        watch.Stop();
        Console.WriteLine($"{graph.States.Count} markings, {graph.Steps.Count} arcs, {watch.Elapsed.TotalSeconds:F1}s");
        Console.WriteLine($"contest:  {five.Markings} markings, {five.Arcs} arcs");
        Console.WriteLine($"agree: {(graph.States.Count == five.Markings && graph.Steps.Count == five.Arcs ? "yes" : "NO")}");
    }

    if (directory is null)
    {
        Title("Against the contest's own files");
        Console.WriteLine("no directory given; see the lesson for a run against the contest's models");
        return;
    }

    Title("Against the contest's own files");
    var published = Mcc.Published.ToDictionary(i => i.Instance);
    var refused = 0;
    var skipped = 0;
    Console.WriteLine($"{"instance",-32}{"markings",-12}{"arcs",-14}{"seconds",-10}agrees");
    foreach (var path in Directory.GetFiles(directory, "*.pnml", SearchOption.AllDirectories)
                                  .OrderBy(x => x, StringComparer.Ordinal))
    {
        PetriNet net;
        // Every model ships twice: once as a P/T net and once as the coloured net it was drawn as.
        // The coloured half is refused on its type, exactly as in lesson 11, and only counted here.
        try { net = Pnml.Load(path); }
        catch { refused++; continue; }
        if (!published.TryGetValue(net.Name, out var answer)) { skipped++; continue; }
        var watch = System.Diagnostics.Stopwatch.StartNew();
        var graph = ReachabilityGraph.Build(net, 10_000_000);
        watch.Stop();
        var bounds = TokenBounds(net, graph);
        var agrees = graph.IsComplete && graph.States.Count == answer.Markings && graph.Steps.Count == answer.Arcs
                     && bounds.PerPlace == answer.MaxPerPlace && bounds.Total == answer.MaxTotal;
        Console.WriteLine($"{net.Name,-32}{graph.States.Count,-12}{graph.Steps.Count,-14}"
                          + $"{watch.Elapsed.TotalSeconds,-10:F2}{(agrees ? "yes" : "NO")}");
    }
    Console.WriteLine($"{refused} files refused on their net type: the same models as coloured nets");
    Console.WriteLine($"{skipped} P/T files skipped: the contest rounds their answer, so there is nothing to compare");
}

// The contest's StateSpace examination asks for two more numbers than the graph's size: the most
// tokens one place ever holds, and the most a whole marking ever holds.
(int PerPlace, int Total) TokenBounds(PetriNet net, ReachabilityGraph graph)
{
    var perPlace = 0;
    var total = 0;
    foreach (var marking in graph.States)
    {
        var sum = 0;
        for (var p = 0; p < net.Places.Count; p++)
        {
            perPlace = Math.Max(perPlace, marking[p]);
            sum += marking[p];
        }
        total = Math.Max(total, sum);
    }
    return (perPlace, total);
}

void Lesson14()
{
    var guarded = Nets.LaneLock();
    var unguarded = Nets.LaneLock(2, guarded: false);

    Title("The lock as the rule states it: remove the directory only if the owner file is yours");
    Console.Write(Report.Net(guarded));
    Console.Write(Report.InvariantReport(guarded));
    Verdict(guarded);

    Title("The same lock written mkdir \"$lock\" && work ; rm -r \"$lock\"");
    Console.WriteLine("The ';' does not look at what mkdir did, so a lane that lost the race");
    Console.WriteLine("still runs rm -r, on a directory the winner created.");
    Console.Write(Report.Net(unguarded));
    Console.Write(Report.InvariantReport(unguarded));
    Verdict(unguarded);

    Title("How the two shapes scale with the number of lanes");
    Console.WriteLine("lanes  markings  two holders at once  shortest way there");
    foreach (var lanes in (int[])[2, 3, 4, 5])
    {
        foreach (var guard in (bool[])[true, false])
        {
            var net = Nets.LaneLock(lanes, guard);
            var graph = ReachabilityGraph.Build(net);
            var bad = SharedHolders(graph);
            var path = bad.Count > 0 ? string.Join(" ", ShortestFiring(graph, bad[0])) : "-";
            Console.WriteLine($"{lanes,5}  {graph.States.Count,8}  "
                              + $"{(bad.Count > 0 ? $"yes, {bad.Count} markings" : "no"),-19}  {path}"
                              + $"   ({(guard ? "guarded" : "unguarded")})");
        }
    }

    Title("One bounded C# pipeline, with success, failure and cancellation made explicit");
    var pipeline = Nets.PipelineLifecycle();
    var pipelineGraph = ReachabilityGraph.Build(pipeline);
    var terminalNames = new[] { "succeeded", "failed", "cancelled" };
    var terminalPlaces = terminalNames.Select(pipeline.PlaceIndex).ToArray();
    var nonTerminalDead = pipelineGraph.DeadStates
        .Where(state => terminalPlaces.Sum(place => pipelineGraph.States[state][place]) != 1)
        .ToArray();
    Console.WriteLine($"markings: {pipelineGraph.States.Count}   graph complete: {pipelineGraph.IsComplete}");
    Console.WriteLine($"dead markings: {pipelineGraph.DeadStates.Count}   non-terminal dead markings: {nonTerminalDead.Length}");
    Console.WriteLine("queue capacity invariant free + queued = 1: "
                      + pipelineGraph.States.All(marking =>
                          marking[pipeline.PlaceIndex("free")] + marking[pipeline.PlaceIndex("queued")] == 1));
    foreach (var sequence in new[]
             {
                 new[] { "write", "read", "consume", "settle_success" },
                 new[] { "producer_fail", "settle_producer_failure" },
                 new[] { "write", "read", "consumer_fail" },
                 new[] { "cancel" },
             })
    {
        var final = pipeline.FireSequence(pipeline.InitialMarking, sequence)[^1];
        var terminal = terminalNames.Single(name => final[pipeline.PlaceIndex(name)] == 1);
        Console.WriteLine($"{string.Join(" -> ", sequence),-58} {terminal}");
    }
}

// The markings where more than one lane believes it holds the lock: the property the lock exists for.
IReadOnlyList<int> SharedHolders(ReachabilityGraph graph)
{
    var held = Enumerable.Range(0, graph.Net.Places.Count)
        .Where(p => graph.Net.Places[p].Name.StartsWith("held", StringComparison.Ordinal))
        .ToArray();
    return [.. Enumerable.Range(0, graph.States.Count)
        .Where(s => held.Sum(p => graph.States[s][p]) > 1)];
}

// The shortest firing sequence from the initial marking to a state, by a breadth-first walk of
// the steps. The graph is already built breadth first, so this only recovers the path itself.
IReadOnlyList<string> ShortestFiring(ReachabilityGraph graph, int target)
{
    var from = new int[graph.States.Count];
    var via = new int[graph.States.Count];
    Array.Fill(from, -1);
    var queue = new Queue<int>();
    queue.Enqueue(0);
    var seen = new HashSet<int> { 0 };
    var successors = graph.Steps.GroupBy(s => s.From).ToDictionary(g => g.Key, g => g.ToList());
    while (queue.Count > 0)
    {
        var state = queue.Dequeue();
        if (state == target) break;
        if (!successors.TryGetValue(state, out var steps)) continue;
        foreach (var step in steps.Where(step => seen.Add(step.To)))
        {
            from[step.To] = state;
            via[step.To] = step.Transition;
            queue.Enqueue(step.To);
        }
    }
    var names = new List<string>();
    for (var s = target; s != 0 && from[s] >= 0; s = from[s]) names.Add(graph.Net.Transitions[via[s]].Name);
    names.Reverse();
    return names;
}

// What the net says about a lock: is it bounded, can it wedge, and can two lanes hold it at once.
void Verdict(PetriNet net)
{
    var graph = ReachabilityGraph.Build(net);
    var properties = Behaviour.Analyse(graph);
    Console.WriteLine($"markings: {graph.States.Count}   safe: {properties.IsSafe}   "
                      + $"deadlock-free: {properties.IsDeadlockFree}   live: {properties.IsLive}   "
                      + $"reversible: {properties.IsReversible}");
    var bad = SharedHolders(graph);
    if (bad.Count == 0)
    {
        Console.WriteLine("two lanes holding the lock at once: no marking out of "
                          + $"{graph.States.Count} reaches that.");
        return;
    }
    Console.WriteLine($"two lanes holding the lock at once: {bad.Count} markings out of {graph.States.Count}.");
    var first = graph.States[bad[0]];
    Console.WriteLine($"the shortest way there, from {net.InitialMarking.ToString(net)}:");
    foreach (var transition in ShortestFiring(graph, bad[0])) Console.WriteLine($"  {transition}");
    Console.WriteLine($"leaves {first}  {first.ToString(net)}");
}

// Lesson 14, on Guitar Alchemist: voice leading as a net, where a marking is a chord.
void Music()
{
    int[] cMajorTriad = [0, 4, 7];
    int[] cMajorKey = [0, 2, 4, 5, 7, 9, 11];

    Title("A chord is a marking: C major triad, three voices over twelve pitch classes");
    var steps = Nets.VoiceLeading(cMajorTriad, 1);
    Console.WriteLine($"M0 = {steps.InitialMarking}  =  {Nets.Chord(steps.InitialMarking)}");
    Console.WriteLine($"places: {steps.Places.Count}   transitions: {steps.Transitions.Count} "
                      + "(one per ordered pair of pitch classes one semitone apart)");
    Console.Write(Report.InvariantReport(steps));
    Console.WriteLine("The place invariant is the conservation of voices: no move creates or drops one,");
    Console.WriteLine("so every reachable marking is a three-note chord, and nothing else can be.");
    Console.WriteLine("The transition invariants are the closed voice leadings: the chromatic scale");
    Console.WriteLine("all the way round in either direction, and every move followed by its undo.");

    Title("Widening the moves to a tone breaks the transition invariants, not the place one");
    var free = Nets.VoiceLeading(cMajorTriad);
    Console.WriteLine($"places: {free.Places.Count}   transitions: {free.Transitions.Count}"
                      + "   rank of C: " + Invariants.Rank(free));
    foreach (var invariant in Invariants.Places(free))
        Console.WriteLine($"place invariant   {Report.PlaceInvariant(free, invariant)}");
    Console.WriteLine($"transition invariants: the solutions of C x = 0 form a cone of dimension "
                      + $"{free.Transitions.Count - Invariants.Rank(free)} in {free.Transitions.Count} "
                      + "unknowns, and Farkas' elimination does not finish on it.");
    Console.WriteLine("Place invariants stay cheap because they live in one dimension per place.");

    Title("Every chord a smooth voice leading can reach, and how far away it is");
    var freeGraph = ReachabilityGraph.Build(free);
    var freeDepth = Depths(freeGraph);
    Console.WriteLine($"reachable chords: {freeGraph.States.Count}   "
                      + $"largest number of moves needed: {freeDepth.Max()}");
    foreach (var d in Enumerable.Range(0, freeDepth.Max() + 1))
        Console.WriteLine($"  at {d} move(s): {freeDepth.Count(x => x == d)} chords");

    Title("The same net inside a key, with a budget of one foreign note");
    var keyed = Nets.VoiceLeading(cMajorTriad, key: cMajorKey, budget: 1);
    foreach (var invariant in Invariants.Places(keyed))
        Console.WriteLine($"place invariant   {Report.PlaceInvariant(keyed, invariant)}");
    Console.WriteLine("The invariant carrying 'chromatic' is the budget: it says, with no search at all,");
    Console.WriteLine("that at most one voice sits outside C major in any chord this net can reach.");
    var keyedGraph = ReachabilityGraph.Build(keyed);
    var outside = Enumerable.Range(0, 12).Where(pc => !cMajorKey.Contains(pc)).ToArray();
    var worst = keyedGraph.States.Max(m => outside.Sum(pc => m[pc]));
    Console.WriteLine($"reachable chords: {keyedGraph.States.Count}  "
                      + $"(against {freeGraph.States.Count} with no key)");
    Console.WriteLine($"most foreign notes found in any of them, by enumeration: {worst}");

    Title("Shortest voice leading from C major to F major, read off the graph");
    foreach (var (name, target) in (( string, int[])[])[("F major", [5, 9, 0]), ("G major", [7, 11, 2]),
                                                        ("A minor", [9, 0, 4]), ("Db major", [1, 5, 8])])
    {
        var marking = Marked(target);
        var state = IndexOf(freeGraph, marking);
        var path = state >= 0 ? ShortestFiring(freeGraph, state) : [];
        Console.WriteLine($"{name,-10} {Nets.Chord(marking),-10} "
                          + (state < 0 ? "unreachable"
                             : $"{path.Count} move(s): {string.Join(" ", path.Select(Pretty))}"));
    }

    Title("The same four targets when the key allows only one foreign note");
    foreach (var (name, target) in ((string, int[])[])[("F major", [5, 9, 0]), ("G major", [7, 11, 2]),
                                                       ("A minor", [9, 0, 4]), ("Db major", [1, 5, 8])])
    {
        var foreign = target.Count(pc => !cMajorKey.Contains(pc));
        var marking = foreign <= 1 ? Marked(target, cMajorKey, 1) : null;
        var state = marking is null ? -1 : IndexOf(keyedGraph, marking);
        Console.WriteLine($"{name,-10} {Nets.Chord(Marked(target)),-10} "
                          + (marking is null
                             ? $"outside the budget: {foreign} foreign notes, the invariant allows 1"
                             : state < 0 ? "inside the budget, but no smooth path reaches it"
                             : $"{ShortestFiring(keyedGraph, state).Count} move(s)"));
    }

    Marking Marked(int[] chord, int[]? key = null, int budget = 0)
    {
        var tokens = new int[key is null ? 12 : 13];
        foreach (var pc in chord) tokens[pc]++;
        if (key is not null) tokens[12] = budget - chord.Count(pc => !key.Contains(pc));
        return new Marking(tokens);
    }

    static string Pretty(string transition) => transition.Replace("s", "#", StringComparison.Ordinal)
                                                         .Replace("_", "→", StringComparison.Ordinal);
}

// Lesson 14, on Guitar Alchemist: two concurrent chat turns through the orchestrator.
void Chat()
{
    foreach (var streaming in (bool[])[false, true])
    {
        var net = Nets.ChatTurn(streaming);
        Title(streaming
            ? "The streaming path, AnswerStreamingAsync: OnRequestReceived and nothing else"
            : "The buffered path, ProductionOrchestrator.AnswerAsync: every hook runs");
        var graph = ReachabilityGraph.Build(net);
        Console.WriteLine($"markings: {graph.States.Count}   "
                          + $"dead markings: {graph.DeadStates.Count}, all of them turns that ended: "
                          + $"{Stuck(graph, "done", "rejected").Count == 0}");
        foreach (var invariant in Invariants.Places(net))
            Console.WriteLine($"place invariant   {Report.PlaceInvariant(net, invariant)}");

        // The question: can a turn finish without its OnResponseSent hook having run?
        var done = net.PlaceIndex("done1");
        var notified = net.PlaceIndex("notified1");
        var silent = graph.States.Where(m => m[done] > 0 && m[notified] == 0).ToList();
        Console.WriteLine(silent.Count == 0
            ? $"turn 1 finished with its OnResponseSent hook never run: no marking out of {graph.States.Count}."
            : $"turn 1 finished with its OnResponseSent hook never run: {silent.Count} markings "
              + $"out of {graph.States.Count}, that is every way the turn can end.");
    }

    Title("Does the gate refusing instead of waiting change anything?");
    Console.WriteLine("ChatIntake.cs:37 calls TryEnterAsync, which answers Busy rather than queueing.");
    Console.WriteLine("The comparison is the same pipeline with the refusal replaced by a wait.");
    Console.WriteLine("turns  refuses (as written)        wait instead");
    foreach (var turns in (int[])[2, 3, 4])
    {
        var line = new List<string>();
        foreach (var waits in (bool[])[false, true])
        {
            var net = Nets.ChatTurn(waits: waits, turns: turns);
            var graph = ReachabilityGraph.Build(net);
            line.Add($"{graph.States.Count,5} markings, {Stuck(graph, "done", "rejected").Count} stuck");
        }
        Console.WriteLine($"{turns,5}  {string.Join("   ", line)}");
    }
    Console.WriteLine();
    Console.WriteLine("The gate and the initialisation lock are always taken in that one order,");
    Console.WriteLine("so neither version can wedge: there is no second order to cycle against.");

    Title("The F# session pool: one gate, two sessions, and an exception path with no finally");
    var pool = Nets.SessionPool();
    foreach (var invariant in Invariants.Places(pool))
        Console.WriteLine($"place invariant   {Report.PlaceInvariant(pool, invariant)}");
    Console.WriteLine();
    Console.WriteLine("\"wedged\" is the bug: dead markings the pool can never leave. The last column is");
    Console.WriteLine("not one — the evaluation ends at :140, so a second caller through the gate at");
    Console.WriteLine(":144 runs in its own session, which :13-20 allows. It is here for the contrast.");
    Console.WriteLine();
    Console.WriteLine("leak  early gate  markings  wedged  two sessions in flight (allowed)");
    foreach (var leaks in (bool[])[true, false])
    {
        foreach (var early in (bool[])[true, false])
        {
            var net = Nets.SessionPool(leaks: leaks, earlyGateRelease: early);
            var graph = ReachabilityGraph.Build(net);
            var busy = Enumerable.Range(0, net.Places.Count)
                .Where(p => net.Places[p].Name.StartsWith("has_session", StringComparison.Ordinal)
                            || net.Places[p].Name.StartsWith("releasing", StringComparison.Ordinal))
                .ToArray();
            var shared = graph.States.Count(m => busy.Sum(p => m[p]) > 1);
            Console.WriteLine($"{(leaks ? "yes" : "no "),-5} {(early ? "yes" : "no "),-10} "
                              + $"{graph.States.Count,8}  {graph.DeadStates.Count,6}  {shared}");
        }
    }

    var leaking = Nets.SessionPool();
    var leakGraph = ReachabilityGraph.Build(leaking);
    var deadState = leakGraph.DeadStates.FirstOrDefault(-1);
    if (deadState >= 0)
    {
        Console.WriteLine();
        Console.WriteLine("The shortest way to a pool that can never serve anyone again:");
        foreach (var transition in ShortestFiring(leakGraph, deadState))
            Console.WriteLine($"  {transition}");
        var dead = leakGraph.States[deadState];
        Console.WriteLine($"leaves {dead.ToString(leaking)}");
        Console.WriteLine("Both callers are inside the gate waiting for a session, and the pool is empty:");
        Console.WriteLine("acquireSession blocks synchronously on the channel, holding the gate.");
    }
}

// A dead marking is only a deadlock when somebody is still in flight. A workflow net that has
// finished is dead too, and that is the whole point of it, so the ends have to be named.
IReadOnlyList<int> Stuck(ReachabilityGraph graph, params string[] endings)
{
    var net = graph.Net;
    var parties = net.Places.Select(p => p.Name)
        .Where(n => endings.Any(e => n.StartsWith(e, StringComparison.Ordinal)))
        .Select(n => n[endings.First(e => n.StartsWith(e, StringComparison.Ordinal)).Length..])
        .Distinct()
        .ToList();
    return [.. graph.DeadStates.Where(s =>
        parties.Any(party => endings.Sum(e =>
            net.Places.Select(p => p.Name).Contains(e + party)
                ? graph.States[s][net.PlaceIndex(e + party)]
                : 0) == 0))];
}

// The number of firings between the initial marking and each state, the graph being breadth first.
int[] Depths(ReachabilityGraph graph)
{
    var depth = new int[graph.States.Count];
    Array.Fill(depth, -1);
    depth[0] = 0;
    foreach (var step in graph.Steps.OrderBy(s => s.From))
        if (depth[step.To] < 0 && depth[step.From] >= 0) depth[step.To] = depth[step.From] + 1;
    return depth;
}

int IndexOf(ReachabilityGraph graph, Marking marking)
{
    for (var s = 0; s < graph.States.Count; s++)
        if (graph.States[s].Equals(marking)) return s;
    return -1;
}

// Lesson 6: Commoner's condition on a free-choice net, next to what the graph says.
void CommonerVerdict(PetriNet net)
{
    var free = Structure.Classify(net).IsFreeChoice;
    var condition = Structure.EverySiphonHasAMarkedTrap(net);
    var properties = Behaviour.Analyse(net);
    Console.WriteLine($"free choice: {free}   every siphon contains a marked trap: {condition}");
    Console.WriteLine($"Commoner therefore says live: {(free ? condition.ToString() : "(the theorem does not apply)")}");
    Console.WriteLine($"the reachability graph says live: {properties.IsLive}");
}

string Enabled(PetriNet net, Marking marking) =>
    string.Join(" ", net.EnabledTransitions(marking).Select(t => net.Transitions[t].Name)) is { Length: > 0 } names
        ? names
        : "(nothing)";

void Title(string title)
{
    Console.WriteLine();
    Console.WriteLine("== " + title + " ==");
}
