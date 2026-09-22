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
    case "l14": Lesson14(); break;
    case "music": Music(); break;
    case "chat": Chat(); break;
    case "nets": WriteNets(args.Length > 1 ? args[1] : "out/nets"); break;
    default:
        Console.Error.WriteLine($"Unknown lesson '{lesson}'. Try l1 to l9, l14, or nets.");
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

// Lesson 14, on our own systems: the lock the Claude sessions of this repository take before a
// heavy or a GPU job, in the two shell shapes it has been written in.
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
