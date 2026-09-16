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
    case "nets": WriteNets(args.Length > 1 ? args[1] : "out/nets"); break;
    default:
        Console.Error.WriteLine($"Unknown lesson '{lesson}'. Try l1, l2, l3, l4 or nets.");
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

string Enabled(PetriNet net, Marking marking) =>
    string.Join(" ", net.EnabledTransitions(marking).Select(t => net.Transitions[t].Name)) is { Length: > 0 } names
        ? names
        : "(nothing)";

void Title(string title)
{
    Console.WriteLine();
    Console.WriteLine("== " + title + " ==");
}
