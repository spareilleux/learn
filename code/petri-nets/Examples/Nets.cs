using PetriNets;

namespace Examples;

/// <summary>
/// The nets the lessons use. Each one is built here once, written to nets/ as PNML by the
/// "nets" command, and read back from that PNML by check.sh, so the file a lesson shows and
/// the net a lesson analyses are the same object.
/// </summary>
public static class Nets
{
    /// <summary>
    /// Lesson 1: one producer, one consumer, and a buffer of two slots. The place "free" holds
    /// the slots that are still empty; it is the whole reason the buffer cannot overflow.
    /// </summary>
    public static PetriNet ProducerConsumer() => new(
        "producer-consumer",
        [
            new Place("ready", "ready"),
            new Place("produced", "produced"),
            new Place("free", "free"),
            new Place("full", "full"),
            new Place("waiting", "waiting"),
            new Place("taken", "taken"),
        ],
        [
            new Transition("produce", "produce"),
            new Transition("deposit", "deposit"),
            new Transition("take", "take"),
            new Transition("consume", "consume"),
        ],
        [
            new Arc("ready", "produce"),
            new Arc("produce", "produced"),
            new Arc("produced", "deposit"),
            new Arc("free", "deposit"),
            new Arc("deposit", "full"),
            new Arc("deposit", "ready"),
            new Arc("full", "take"),
            new Arc("waiting", "take"),
            new Arc("take", "taken"),
            new Arc("take", "free"),
            new Arc("taken", "consume"),
            new Arc("consume", "waiting"),
        ],
        new Marking(1, 0, 2, 0, 1, 0));

    /// <summary>
    /// The same net with the place "free" removed: the producer no longer waits for a slot.
    /// Nothing else changed, and the set of reachable markings is now infinite (lesson 3).
    /// </summary>
    public static PetriNet UnboundedProducer() => new(
        "unbounded-producer",
        [
            new Place("ready", "ready"),
            new Place("produced", "produced"),
            new Place("full", "full"),
            new Place("waiting", "waiting"),
            new Place("taken", "taken"),
        ],
        [
            new Transition("produce", "produce"),
            new Transition("deposit", "deposit"),
            new Transition("take", "take"),
            new Transition("consume", "consume"),
        ],
        [
            new Arc("ready", "produce"),
            new Arc("produce", "produced"),
            new Arc("produced", "deposit"),
            new Arc("deposit", "full"),
            new Arc("deposit", "ready"),
            new Arc("full", "take"),
            new Arc("waiting", "take"),
            new Arc("take", "taken"),
            new Arc("taken", "consume"),
            new Arc("consume", "waiting"),
        ],
        new Marking(1, 0, 0, 1, 0));

    /// <summary>
    /// Lesson 2: a request and a reply that keep handing the same token back to each other,
    /// and a counter of completed exchanges. Nothing is enabled at the initial marking, yet the
    /// state equation accepts "one exchange completed".
    /// </summary>
    public static PetriNet Handshake() => new(
        "handshake",
        [
            new Place("request", "request"),
            new Place("response", "response"),
            new Place("served", "served"),
        ],
        [
            new Transition("receive", "receive"),
            new Transition("reply", "reply"),
        ],
        [
            new Arc("request", "receive"),
            new Arc("receive", "response"),
            new Arc("receive", "served"),
            new Arc("response", "reply"),
            new Arc("reply", "request"),
        ],
        new Marking(0, 0, 0));

    /// <summary>
    /// Lesson 4: two threads and one lock. The token in "mutex" is the lock; the place invariant
    /// mutex + critical1 + critical2 = 1 is the proof that the two threads are never both inside.
    /// </summary>
    public static PetriNet MutualExclusion() => new(
        "mutual-exclusion",
        [
            new Place("idle1", "idle1"),
            new Place("critical1", "critical1"),
            new Place("idle2", "idle2"),
            new Place("critical2", "critical2"),
            new Place("mutex", "mutex"),
        ],
        [
            new Transition("enter1", "enter1"),
            new Transition("leave1", "leave1"),
            new Transition("enter2", "enter2"),
            new Transition("leave2", "leave2"),
        ],
        [
            new Arc("idle1", "enter1"),
            new Arc("mutex", "enter1"),
            new Arc("enter1", "critical1"),
            new Arc("critical1", "leave1"),
            new Arc("leave1", "idle1"),
            new Arc("leave1", "mutex"),
            new Arc("idle2", "enter2"),
            new Arc("mutex", "enter2"),
            new Arc("enter2", "critical2"),
            new Arc("critical2", "leave2"),
            new Arc("leave2", "idle2"),
            new Arc("leave2", "mutex"),
        ],
        new Marking(1, 0, 1, 0, 1));

    /// <summary>
    /// Lesson 4: two threads that need both locks and take them in opposite orders.
    /// Thread A takes x then y, thread B takes y then x, and each releases both at the end.
    /// </summary>
    public static PetriNet TwoLocks() => new(
        "two-locks",
        [
            new Place("a_idle", "a_idle"),
            new Place("a_has_x", "a_has_x"),
            new Place("b_idle", "b_idle"),
            new Place("b_has_y", "b_has_y"),
            new Place("x", "x"),
            new Place("y", "y"),
        ],
        [
            new Transition("a_take_x", "a_take_x"),
            new Transition("a_take_y", "a_take_y"),
            new Transition("b_take_y", "b_take_y"),
            new Transition("b_take_x", "b_take_x"),
        ],
        [
            new Arc("a_idle", "a_take_x"),
            new Arc("x", "a_take_x"),
            new Arc("a_take_x", "a_has_x"),
            new Arc("a_has_x", "a_take_y"),
            new Arc("y", "a_take_y"),
            new Arc("a_take_y", "a_idle"),
            new Arc("a_take_y", "x"),
            new Arc("a_take_y", "y"),
            new Arc("b_idle", "b_take_y"),
            new Arc("y", "b_take_y"),
            new Arc("b_take_y", "b_has_y"),
            new Arc("b_has_y", "b_take_x"),
            new Arc("x", "b_take_x"),
            new Arc("b_take_x", "b_idle"),
            new Arc("b_take_x", "x"),
            new Arc("b_take_x", "y"),
        ],
        new Marking(1, 0, 1, 0, 1, 1));

    /// <summary>
    /// Lesson 4, exercise 2: the same two threads, with both of them taking x before y.
    /// One total order on the locks, and the deadlock is gone.
    /// </summary>
    public static PetriNet TwoLocksOrdered() => new(
        "two-locks-ordered",
        [
            new Place("a_idle", "a_idle"),
            new Place("a_has_x", "a_has_x"),
            new Place("b_idle", "b_idle"),
            new Place("b_has_x", "b_has_x"),
            new Place("x", "x"),
            new Place("y", "y"),
        ],
        [
            new Transition("a_take_x", "a_take_x"),
            new Transition("a_take_y", "a_take_y"),
            new Transition("b_take_x", "b_take_x"),
            new Transition("b_take_y", "b_take_y"),
        ],
        [
            new Arc("a_idle", "a_take_x"),
            new Arc("x", "a_take_x"),
            new Arc("a_take_x", "a_has_x"),
            new Arc("a_has_x", "a_take_y"),
            new Arc("y", "a_take_y"),
            new Arc("a_take_y", "a_idle"),
            new Arc("a_take_y", "x"),
            new Arc("a_take_y", "y"),
            new Arc("b_idle", "b_take_x"),
            new Arc("x", "b_take_x"),
            new Arc("b_take_x", "b_has_x"),
            new Arc("b_has_x", "b_take_y"),
            new Arc("y", "b_take_y"),
            new Arc("b_take_y", "b_idle"),
            new Arc("b_take_y", "x"),
            new Arc("b_take_y", "y"),
        ],
        new Marking(1, 0, 1, 0, 1, 1));

    /// <summary>
    /// Lesson 4: a service that starts once and then runs for ever. Nothing ever blocks, so the
    /// net has no deadlock, and yet "start" can never fire again: deadlock-free is not liveness.
    /// </summary>
    public static PetriNet StartOnce() => new(
        "start-once",
        [
            new Place("stopped", "stopped"),
            new Place("running", "running"),
            new Place("serving", "serving"),
        ],
        [
            new Transition("start", "start"),
            new Transition("accept", "accept"),
            new Transition("finish", "finish"),
        ],
        [
            new Arc("stopped", "start"),
            new Arc("start", "running"),
            new Arc("running", "accept"),
            new Arc("accept", "serving"),
            new Arc("serving", "finish"),
            new Arc("finish", "running"),
        ],
        new Marking(1, 0, 0));

    /// <summary>
    /// Lesson 3, exercise 4: a transition that gives its input token back and produces elsewhere.
    /// The arc pair between "ready" and "emit" is a self-loop, so the incidence matrix has a zero
    /// there while the firing rule still needs the token (lesson 2). Two places grow without limit.
    /// </summary>
    public static PetriNet EmitLoop() => new(
        "emit-loop",
        [
            new Place("ready", "ready"),
            new Place("log", "log"),
            new Place("queue", "queue"),
        ],
        [new Transition("emit", "emit")],
        [
            new Arc("ready", "emit"),
            new Arc("emit", "ready"),
            new Arc("emit", "log"),
            new Arc("emit", "queue"),
        ],
        new Marking(1, 0, 0));

    /// <summary>
    /// The producer/consumer net with a buffer of <paramref name="capacity"/> slots, used in
    /// lesson 3 to watch the reachability graph grow with the size of the buffer.
    /// </summary>
    public static PetriNet ProducerConsumer(int capacity)
    {
        var net = ProducerConsumer();
        var marking = net.InitialMarking.ToArray();
        marking[net.PlaceIndex("free")] = capacity;
        return new PetriNet($"producer-consumer-{capacity}", net.Places, net.Transitions, net.Arcs, new Marking(marking));
    }

    /// <summary>
    /// The dining philosophers, with each philosopher taking both forks in one transition.
    /// Used in lesson 3 for the size of the reachability graph, and studied in lesson 7.
    /// </summary>
    public static PetriNet Philosophers(int count)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(count, 2);
        var places = new List<Place>();
        var transitions = new List<Transition>();
        var arcs = new List<Arc>();
        var marking = new List<int>();

        for (var i = 1; i <= count; i++)
        {
            places.Add(new Place($"thinking{i}", $"thinking{i}"));
            marking.Add(1);
            places.Add(new Place($"eating{i}", $"eating{i}"));
            marking.Add(0);
            places.Add(new Place($"fork{i}", $"fork{i}"));
            marking.Add(1);
        }

        for (var i = 1; i <= count; i++)
        {
            var right = i % count + 1;
            transitions.Add(new Transition($"take{i}", $"take{i}"));
            transitions.Add(new Transition($"put{i}", $"put{i}"));
            arcs.Add(new Arc($"thinking{i}", $"take{i}"));
            arcs.Add(new Arc($"fork{i}", $"take{i}"));
            arcs.Add(new Arc($"fork{right}", $"take{i}"));
            arcs.Add(new Arc($"take{i}", $"eating{i}"));
            arcs.Add(new Arc($"eating{i}", $"put{i}"));
            arcs.Add(new Arc($"put{i}", $"thinking{i}"));
            arcs.Add(new Arc($"put{i}", $"fork{i}"));
            arcs.Add(new Arc($"put{i}", $"fork{right}"));
        }

        return new PetriNet($"philosophers-{count}", places, transitions, arcs, new Marking([.. marking]));
    }

    /// <summary>
    /// <paramref name="copies"/> producer/consumer nets side by side, sharing nothing. Lesson 3 uses
    /// them to show that independent components multiply the number of markings instead of adding to it.
    /// </summary>
    public static PetriNet Independent(int copies)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(copies, 1);
        var one = ProducerConsumer();
        var places = new List<Place>();
        var transitions = new List<Transition>();
        var arcs = new List<Arc>();
        var marking = new List<int>();

        for (var i = 1; i <= copies; i++)
        {
            places.AddRange(one.Places.Select(p => new Place($"{p.Id}{i}", $"{p.Name}{i}")));
            transitions.AddRange(one.Transitions.Select(t => new Transition($"{t.Id}{i}", $"{t.Name}{i}")));
            arcs.AddRange(one.Arcs.Select(a => new Arc($"{a.Source}{i}", $"{a.Target}{i}", a.Weight)));
            marking.AddRange(one.InitialMarking.ToArray());
        }

        return new PetriNet($"independent-{copies}", places, transitions, arcs, new Marking([.. marking]));
    }

    /// <summary>Every net of the course, in the order the lessons meet them.</summary>
    public static IReadOnlyList<PetriNet> All =>
    [
        ProducerConsumer(),
        UnboundedProducer(),
        Handshake(),
        MutualExclusion(),
        TwoLocks(),
        TwoLocksOrdered(),
        StartOnce(),
        EmitLoop(),
    ];
}
