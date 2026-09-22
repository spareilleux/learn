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
    /// Lesson 9: a queue with one server and room for <paramref name="capacity"/> jobs. The place
    /// "room" holds the free slots, so arrivals stop when it is empty - the same trick as the
    /// buffer of lesson 1. With an exponential rate on each transition this net is exactly an
    /// M/M/1/K queue, whose stationary distribution has a closed form to compare against.
    /// </summary>
    public static PetriNet Queue(int capacity) => new(
        $"queue-{capacity}",
        [
            new Place("room", "room"),
            new Place("jobs", "jobs"),
        ],
        [
            new Transition("arrive", "arrive"),
            new Transition("serve", "serve"),
        ],
        [
            new Arc("room", "arrive"),
            new Arc("arrive", "jobs"),
            new Arc("jobs", "serve"),
            new Arc("serve", "room"),
        ],
        new Marking([capacity, 0]));

    /// <summary>
    /// Lesson 9: one job, two servers, and a choice that takes no time. "to-fast" and "to-slow"
    /// are immediate transitions: they fire the instant a job is waiting, and their weights split
    /// the traffic. The state where the job waits is therefore vanishing - no time passes in it.
    /// </summary>
    public static PetriNet TwoServers() => new(
        "two-servers",
        [
            new Place("waiting", "waiting"),
            new Place("at-fast", "at-fast"),
            new Place("at-slow", "at-slow"),
        ],
        [
            new Transition("to-fast", "to-fast"),
            new Transition("to-slow", "to-slow"),
            new Transition("done-fast", "done-fast"),
            new Transition("done-slow", "done-slow"),
        ],
        [
            new Arc("waiting", "to-fast"),
            new Arc("to-fast", "at-fast"),
            new Arc("waiting", "to-slow"),
            new Arc("to-slow", "at-slow"),
            new Arc("at-fast", "done-fast"),
            new Arc("done-fast", "waiting"),
            new Arc("at-slow", "done-slow"),
            new Arc("done-slow", "waiting"),
        ],
        new Marking([1, 0, 0]));

    /// <summary>
    /// Lesson 10: an order handled by a workflow net. One token enters at "in", the registration
    /// splits the case into a credit check and a stock check that run at the same time (an AND
    /// split), and the two are joined by a choice between shipping and cancelling (an XOR split
    /// on the joined state). It is the shape almost every BPMN diagram has, and it is sound.
    /// </summary>
    public static PetriNet OrderSound() => new(
        "order-sound",
        [
            new Place("in", "in"),
            new Place("credit", "credit"),
            new Place("stock", "stock"),
            new Place("credit-done", "credit-done"),
            new Place("stock-done", "stock-done"),
            new Place("out", "out"),
        ],
        [
            new Transition("register", "register"),
            new Transition("check-credit", "check-credit"),
            new Transition("check-stock", "check-stock"),
            new Transition("ship", "ship"),
            new Transition("cancel", "cancel"),
        ],
        [
            new Arc("in", "register"),
            new Arc("register", "credit"),
            new Arc("register", "stock"),
            new Arc("credit", "check-credit"),
            new Arc("check-credit", "credit-done"),
            new Arc("stock", "check-stock"),
            new Arc("check-stock", "stock-done"),
            new Arc("credit-done", "ship"),
            new Arc("stock-done", "ship"),
            new Arc("ship", "out"),
            new Arc("credit-done", "cancel"),
            new Arc("stock-done", "cancel"),
            new Arc("cancel", "out"),
        ],
        new Marking(1, 0, 0, 0, 0, 0));

    /// <summary>
    /// Lesson 10: the same order, with the AND split joined by an XOR. Either branch alone ends
    /// the case, so the other one is still running when the case is declared finished. This is the
    /// commonest modelling error in BPMN, and the net names it: proper completion fails.
    /// </summary>
    public static PetriNet OrderAndXor() => new(
        "order-and-xor",
        [
            new Place("in", "in"),
            new Place("credit", "credit"),
            new Place("stock", "stock"),
            new Place("credit-done", "credit-done"),
            new Place("stock-done", "stock-done"),
            new Place("out", "out"),
        ],
        [
            new Transition("register", "register"),
            new Transition("check-credit", "check-credit"),
            new Transition("check-stock", "check-stock"),
            new Transition("finish-credit", "finish-credit"),
            new Transition("finish-stock", "finish-stock"),
        ],
        [
            new Arc("in", "register"),
            new Arc("register", "credit"),
            new Arc("register", "stock"),
            new Arc("credit", "check-credit"),
            new Arc("check-credit", "credit-done"),
            new Arc("stock", "check-stock"),
            new Arc("check-stock", "stock-done"),
            new Arc("credit-done", "finish-credit"),
            new Arc("finish-credit", "out"),
            new Arc("stock-done", "finish-stock"),
            new Arc("finish-stock", "out"),
        ],
        new Marking(1, 0, 0, 0, 0, 0));

    /// <summary>
    /// Lesson 10: the mirror error. The registration chooses one branch (an XOR split) and the
    /// shipment waits for both (an AND join), so the case stops for ever one step short of the
    /// sink. Option to complete fails, and "ship" is a dead transition.
    /// </summary>
    public static PetriNet OrderXorAnd() => new(
        "order-xor-and",
        [
            new Place("in", "in"),
            new Place("credit", "credit"),
            new Place("stock", "stock"),
            new Place("credit-done", "credit-done"),
            new Place("stock-done", "stock-done"),
            new Place("out", "out"),
        ],
        [
            new Transition("register-credit", "register-credit"),
            new Transition("register-stock", "register-stock"),
            new Transition("check-credit", "check-credit"),
            new Transition("check-stock", "check-stock"),
            new Transition("ship", "ship"),
        ],
        [
            new Arc("in", "register-credit"),
            new Arc("register-credit", "credit"),
            new Arc("in", "register-stock"),
            new Arc("register-stock", "stock"),
            new Arc("credit", "check-credit"),
            new Arc("check-credit", "credit-done"),
            new Arc("stock", "check-stock"),
            new Arc("check-stock", "stock-done"),
            new Arc("credit-done", "ship"),
            new Arc("stock-done", "ship"),
            new Arc("ship", "out"),
        ],
        new Marking(1, 0, 0, 0, 0, 0));

    /// <summary>
    /// Lesson 10: a review that can send the case back for rework, for ever. The net is sound —
    /// from every reachable marking the case can still finish — and it has an infinite run in
    /// which it never does. Soundness is "always possible", exactly as liveness was in lesson 4.
    /// </summary>
    public static PetriNet OrderRework() => new(
        "order-rework",
        [
            new Place("in", "in"),
            new Place("drafted", "drafted"),
            new Place("reviewed", "reviewed"),
            new Place("out", "out"),
        ],
        [
            new Transition("draft", "draft"),
            new Transition("review", "review"),
            new Transition("rework", "rework"),
            new Transition("approve", "approve"),
        ],
        [
            new Arc("in", "draft"),
            new Arc("draft", "drafted"),
            new Arc("drafted", "review"),
            new Arc("review", "reviewed"),
            new Arc("reviewed", "rework"),
            new Arc("rework", "drafted"),
            new Arc("reviewed", "approve"),
            new Arc("approve", "out"),
        ],
        new Marking(1, 0, 0, 0));

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

    /// <summary>
    /// Lesson 7, exercise 2: the mutual exclusion net with "leave1" removed — a lock the first
    /// thread takes and never releases. Not part of <see cref="All"/>: it exists to be broken.
    /// </summary>
    public static PetriNet MutualExclusionLeaky()
    {
        var net = MutualExclusion();
        return new PetriNet(
            "mutual-exclusion-leaky",
            net.Places,
            [.. net.Transitions.Where(t => t.Id != "leave1")],
            [.. net.Arcs.Where(a => a.Source != "leave1" && a.Target != "leave1")],
            net.InitialMarking);
    }

    /// <summary>
    /// Lesson 6: a connection that opens, is established or fails, and closes. Every transition has
    /// exactly one input and one output place, so this is a state machine; it is strongly connected
    /// and holds one token, which is the whole hypothesis of the liveness theorem for that class.
    /// </summary>
    public static PetriNet Connection() => new(
        "connection",
        [
            new Place("disconnected", "disconnected"),
            new Place("connecting", "connecting"),
            new Place("connected", "connected"),
        ],
        [
            new Transition("open", "open"),
            new Transition("established", "established"),
            new Transition("failed", "failed"),
            new Transition("close", "close"),
        ],
        [
            new Arc("disconnected", "open"),
            new Arc("open", "connecting"),
            new Arc("connecting", "established"),
            new Arc("established", "connected"),
            new Arc("connecting", "failed"),
            new Arc("failed", "disconnected"),
            new Arc("connected", "close"),
            new Arc("close", "disconnected"),
        ],
        new Marking(1, 0, 0));

    /// <summary>
    /// Lesson 6: the handshake of lesson 2 with the first request already in place. The structure is
    /// unchanged and the net is now live — and unbounded, since "served" counts the exchanges for ever.
    /// Its liveness is decided by Commoner's condition, on a net whose reachability graph does not exist.
    /// </summary>
    public static PetriNet HandshakeStarted()
    {
        var net = Handshake();
        return new PetriNet("handshake-started", net.Places, net.Transitions, net.Arcs, new Marking(1, 0, 0));
    }

    /// <summary>
    /// Lesson 7: readers and writers. The place "access" holds one permit per reader; a reader takes
    /// one, a writer takes all of them at once through an arc of weight 3. That weighted arc is
    /// exactly the difference between <c>SemaphoreSlim.Wait()</c> and a reader/writer lock.
    /// </summary>
    public static PetriNet ReadersWriters(int readers = 3) => new(
        readers == 3 ? "readers-writers" : $"readers-writers-{readers}",
        [
            new Place("idle", "idle"),
            new Place("reading", "reading"),
            new Place("writing", "writing"),
            new Place("access", "access"),
        ],
        [
            new Transition("start_read", "start_read"),
            new Transition("stop_read", "stop_read"),
            new Transition("start_write", "start_write"),
            new Transition("stop_write", "stop_write"),
        ],
        [
            new Arc("idle", "start_read"),
            new Arc("access", "start_read"),
            new Arc("start_read", "reading"),
            new Arc("reading", "stop_read"),
            new Arc("stop_read", "idle"),
            new Arc("stop_read", "access"),
            new Arc("idle", "start_write"),
            new Arc("access", "start_write", readers),
            new Arc("start_write", "writing"),
            new Arc("writing", "stop_write"),
            new Arc("stop_write", "idle"),
            new Arc("stop_write", "access", readers),
        ],
        new Marking(readers, 0, 0, readers));

    /// <summary>
    /// Lesson 7: a counting semaphore. <paramref name="permits"/> tokens in "permits" and
    /// <paramref name="threads"/> threads competing for them, which is <c>new SemaphoreSlim(k)</c>
    /// with the mutual exclusion net as the case k = 1.
    /// </summary>
    public static PetriNet CountingSemaphore(int threads = 3, int permits = 2)
    {
        var places = new List<Place> { new("permits", "permits") };
        var marking = new List<int> { permits };
        var transitions = new List<Transition>();
        var arcs = new List<Arc>();
        for (var i = 1; i <= threads; i++)
        {
            places.Add(new Place($"idle{i}", $"idle{i}"));
            marking.Add(1);
            places.Add(new Place($"inside{i}", $"inside{i}"));
            marking.Add(0);
            transitions.Add(new Transition($"acquire{i}", $"acquire{i}"));
            transitions.Add(new Transition($"release{i}", $"release{i}"));
            arcs.Add(new Arc($"idle{i}", $"acquire{i}"));
            arcs.Add(new Arc("permits", $"acquire{i}"));
            arcs.Add(new Arc($"acquire{i}", $"inside{i}"));
            arcs.Add(new Arc($"inside{i}", $"release{i}"));
            arcs.Add(new Arc($"release{i}", $"idle{i}"));
            arcs.Add(new Arc($"release{i}", "permits"));
        }
        var name = threads == 3 && permits == 2 ? "counting-semaphore" : $"counting-semaphore-{threads}-{permits}";
        return new PetriNet(name, places, transitions, arcs, new Marking([.. marking]));
    }

    /// <summary>
    /// Lesson 7: the dining philosophers again, this time taking one fork at a time. Philosopher
    /// <paramref name="count"/> reverses the order when <paramref name="ordered"/> is true, which is
    /// the total order on locks of lesson 4 applied to a ring.
    /// </summary>
    public static PetriNet PhilosophersOneFork(int count, bool ordered = false)
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
            places.Add(new Place($"holding{i}", $"holding{i}"));
            marking.Add(0);
            places.Add(new Place($"eating{i}", $"eating{i}"));
            marking.Add(0);
            places.Add(new Place($"fork{i}", $"fork{i}"));
            marking.Add(1);
        }

        for (var i = 1; i <= count; i++)
        {
            var right = i % count + 1;
            // Everybody takes their left fork first, except the last one when the order is imposed.
            var (first, second) = ordered && i == count ? (right, i) : (i, right);
            transitions.Add(new Transition($"take_first{i}", $"take_first{i}"));
            transitions.Add(new Transition($"take_second{i}", $"take_second{i}"));
            transitions.Add(new Transition($"put{i}", $"put{i}"));
            arcs.Add(new Arc($"thinking{i}", $"take_first{i}"));
            arcs.Add(new Arc($"fork{first}", $"take_first{i}"));
            arcs.Add(new Arc($"take_first{i}", $"holding{i}"));
            arcs.Add(new Arc($"holding{i}", $"take_second{i}"));
            arcs.Add(new Arc($"fork{second}", $"take_second{i}"));
            arcs.Add(new Arc($"take_second{i}", $"eating{i}"));
            arcs.Add(new Arc($"eating{i}", $"put{i}"));
            arcs.Add(new Arc($"put{i}", $"thinking{i}"));
            arcs.Add(new Arc($"put{i}", $"fork{i}"));
            arcs.Add(new Arc($"put{i}", $"fork{right}"));
        }

        var name = ordered ? $"philosophers-ordered-{count}" : $"philosophers-one-fork-{count}";
        return new PetriNet(name, places, transitions, arcs, new Marking([.. marking]));
    }

    /// <summary>
    /// Lesson 14, on our own system: the lock several Claude sessions of this repository take
    /// before running a heavy or a GPU job. The lock is a directory, taken with <c>mkdir</c>,
    /// which succeeds for exactly one caller; a lane that loses writes its name in an
    /// <c>owner</c> file and removes the directory when it is done.
    ///
    /// The lock is modelled by the complementary pair <c>free</c> / <c>taken</c> rather than one
    /// place, because a lane that fails to take it has to *test* that it is held, and an ordinary
    /// place/transition net has no inhibitor arc: the test becomes a self-loop on <c>taken</c>.
    ///
    /// <paramref name="guarded"/> is the whole question. The shell shape
    /// <c>mkdir "$lock" &amp;&amp; work ; rm -r "$lock"</c> releases the lock whatever the
    /// <c>mkdir</c> did, because <c>;</c> does not care: that is <c>guarded: false</c>, where
    /// <c>clean_hit</c> removes a directory another lane created. The rule this repository
    /// actually runs checks the owner file first, so a lane that never took the lock never
    /// removes it: that is <c>guarded: true</c>, where <c>clean</c> touches neither place.
    /// </summary>
    public static PetriNet LaneLock(int lanes = 2, bool guarded = true)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(lanes, 2);
        var places = new List<Place> { new("free", "free"), new("taken", "taken") };
        var marking = new List<int> { 1, 0 };
        var transitions = new List<Transition>();
        var arcs = new List<Arc>();

        for (var i = 1; i <= lanes; i++)
        {
            places.Add(new Place($"idle{i}", $"idle{i}"));
            marking.Add(1);
            places.Add(new Place($"held{i}", $"held{i}"));
            marking.Add(0);
            places.Add(new Place($"failed{i}", $"failed{i}"));
            marking.Add(0);
        }

        for (var i = 1; i <= lanes; i++)
        {
            // mkdir succeeded: the lane holds the lock and the directory now exists.
            transitions.Add(new Transition($"take{i}", $"take{i}"));
            arcs.Add(new Arc($"idle{i}", $"take{i}"));
            arcs.Add(new Arc("free", $"take{i}"));
            arcs.Add(new Arc($"take{i}", $"held{i}"));
            arcs.Add(new Arc($"take{i}", "taken"));

            // mkdir failed: the directory exists, and the lane only read that fact.
            transitions.Add(new Transition($"fail{i}", $"fail{i}"));
            arcs.Add(new Arc($"idle{i}", $"fail{i}"));
            arcs.Add(new Arc("taken", $"fail{i}"));
            arcs.Add(new Arc($"fail{i}", $"failed{i}"));
            arcs.Add(new Arc($"fail{i}", "taken"));

            // The holder finishes and removes its own directory.
            transitions.Add(new Transition($"release{i}", $"release{i}"));
            arcs.Add(new Arc($"held{i}", $"release{i}"));
            arcs.Add(new Arc("taken", $"release{i}"));
            arcs.Add(new Arc($"release{i}", $"idle{i}"));
            arcs.Add(new Arc($"release{i}", "free"));

            if (guarded)
            {
                // The owner check fails, so the loser goes home without touching the lock.
                transitions.Add(new Transition($"clean{i}", $"clean{i}"));
                arcs.Add(new Arc($"failed{i}", $"clean{i}"));
                arcs.Add(new Arc($"clean{i}", $"idle{i}"));
            }
            else
            {
                // rm -r runs anyway. It either removes the directory the holder is still using,
                // or finds nothing there because the holder released first.
                transitions.Add(new Transition($"clean_hit{i}", $"clean_hit{i}"));
                arcs.Add(new Arc($"failed{i}", $"clean_hit{i}"));
                arcs.Add(new Arc("taken", $"clean_hit{i}"));
                arcs.Add(new Arc($"clean_hit{i}", $"idle{i}"));
                arcs.Add(new Arc($"clean_hit{i}", "free"));

                transitions.Add(new Transition($"clean_miss{i}", $"clean_miss{i}"));
                arcs.Add(new Arc($"failed{i}", $"clean_miss{i}"));
                arcs.Add(new Arc("free", $"clean_miss{i}"));
                arcs.Add(new Arc($"clean_miss{i}", $"idle{i}"));
                arcs.Add(new Arc($"clean_miss{i}", "free"));
            }
        }

        var name = (guarded ? "lane-lock-guarded" : "lane-lock-unguarded") + (lanes == 2 ? "" : $"-{lanes}");
        return new PetriNet(name, places, transitions, arcs, new Marking([.. marking]));
    }

    /// <summary>
    /// Lesson 14, on Guitar Alchemist: one chat turn through the orchestrator, at commit
    /// a826864. A turn is admitted only if the intake gate is free — <c>TryEnterAsync</c> in
    /// ChatIntake.cs:37 refuses instead of waiting, so a refused turn leaves at once — and the
    /// gate is held until the very end, ChatIntake.cs:51, which is why the embedding
    /// initialisation lock of SemanticRouter is taken *inside* it.
    ///
    /// The place "notified" is marked only by the OnResponseSent hook. Whether a marking exists
    /// with the turn finished and "notified" still empty is the whole question:
    /// ProductionOrchestrator.cs:487 runs that hook on the buffered path, and
    /// AnswerStreamingAsync (:154-302) does not.
    ///
    /// <paramref name="waits"/> replaces the refusal by a wait, which is the version this is
    /// compared against: it is the same pipeline with one behaviour changed.
    /// </summary>
    public static PetriNet ChatTurn(bool streaming = false, bool waits = false, int turns = 2)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(turns, 1);
        var places = new List<Place>
        {
            new("gate_free", "gate_free"),
            new("gate_held", "gate_held"),
            new("init_free", "init_free"),
            new("init_held", "init_held"),
        };
        var marking = new List<int> { 1, 0, 1, 0 };
        var transitions = new List<Transition>();
        var arcs = new List<Arc>();

        void Step(string name, params string[] io)
        {
            transitions.Add(new Transition(name, name));
            foreach (var place in io)
                arcs.Add(place.StartsWith('-') ? new Arc(place[1..], name) : new Arc(name, place));
        }

        for (var i = 1; i <= turns; i++)
        {
            foreach (var stage in (string[])["request", "admitted", "routed", "executed", "sent", "notified", "done", "rejected"])
            {
                places.Add(new Place($"{stage}{i}", $"{stage}{i}"));
                marking.Add(stage == "request" ? 1 : 0);
            }

            // ChatIntake.cs:37. Without "waits", a turn that finds the gate held is answered Busy
            // at once; with it, the turn simply stays in "request" until the gate frees up.
            Step($"admit{i}", $"-request{i}", "-gate_free", $"admitted{i}", "gate_held");
            if (!waits) Step($"refuse{i}", $"-request{i}", "-gate_held", $"rejected{i}", "gate_held");

            // SemanticRouter.EnsureEmbeddingsInitializedAsync: a second lock, taken while the
            // gate is still held, and always in that order.
            Step($"take_init{i}", $"-admitted{i}", "-init_free", $"routed{i}", "init_held");
            Step($"drop_init{i}", $"-routed{i}", "-init_held", $"executed{i}", "init_free");

            if (streaming)
            {
                // AnswerStreamingAsync runs OnRequestReceived only: no OnBeforeSkill,
                // OnAfterSkill or OnResponseSent, so nothing ever marks "notified".
                Step($"finish{i}", $"-executed{i}", "-gate_held", $"done{i}", "gate_free");
            }
            else
            {
                // ProductionOrchestrator.cs:487. The hook both moves the turn on and drops a
                // token in "notified", which nothing ever consumes: it is a witness that the
                // hook ran, still readable once the turn is over.
                Step($"on_response_sent{i}", $"-executed{i}", $"sent{i}", $"notified{i}");
                Step($"finish{i}", $"-sent{i}", "-gate_held", $"done{i}", "gate_free");
            }
        }

        var name = $"chat-turn{(streaming ? "-streaming" : "")}{(waits ? "-waiting" : "")}"
                   + (turns == 2 ? "" : $"-{turns}");
        return new PetriNet(name, places, transitions, arcs, new Marking([.. marking]));
    }

    /// <summary>
    /// Lesson 14, on Guitar Alchemist: the F# interactive session pool, GaFsiSessionPool.fs at
    /// commit a826864. Callers take the gate (one permit, :133) and then a session from a pool
    /// of two (:134), always in that order — so there is no cycle to deadlock on. The net is
    /// about the two other things the code does.
    ///
    /// <paramref name="leaks"/> is the exception path :159-162, which releases the gate and
    /// never returns the session to the pool. There is no try/finally around the acquisition.
    ///
    /// <paramref name="earlyGateRelease"/> is the success path :140-150, which releases the gate
    /// at :144 and the session only at :146. It leaves a window where a second caller is through
    /// the gate while the first still holds a session, and the net finds it — but that window is
    /// harmless here, and the net is what shows why: the evaluation itself finished at :140 and
    /// its output was read at :143, so nothing is running concurrently inside a session. The
    /// header at :13-20 serialises *evaluations* and explicitly allows several sessions to exist.
    /// The parameter is kept because the contrast is what makes the leak legible.
    /// </summary>
    public static PetriNet SessionPool(
        int callers = 2, int poolSize = 2, bool leaks = true, bool earlyGateRelease = true)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(callers, 1);
        ArgumentOutOfRangeException.ThrowIfLessThan(poolSize, 1);
        var places = new List<Place> { new("gate", "gate"), new("pool", "pool") };
        var marking = new List<int> { 1, poolSize };
        var transitions = new List<Transition>();
        var arcs = new List<Arc>();

        void Step(string name, params string[] io)
        {
            transitions.Add(new Transition(name, name));
            foreach (var place in io)
                arcs.Add(place.StartsWith('-') ? new Arc(place[1..], name) : new Arc(name, place));
        }

        for (var i = 1; i <= callers; i++)
        {
            foreach (var stage in (string[])["outside", "in_gate", "has_session", "releasing"])
            {
                places.Add(new Place($"{stage}{i}", $"{stage}{i}"));
                marking.Add(stage == "outside" ? 1 : 0);
            }

            Step($"enter{i}", $"-outside{i}", "-gate", $"in_gate{i}");
            Step($"acquire{i}", $"-in_gate{i}", "-pool", $"has_session{i}");

            if (earlyGateRelease)
            {
                Step($"release_gate{i}", $"-has_session{i}", $"releasing{i}", "gate");
                Step($"release_session{i}", $"-releasing{i}", $"outside{i}", "pool");
            }
            else
            {
                Step($"finish{i}", $"-has_session{i}", $"outside{i}", "gate", "pool");
            }

            // The "with ex" path: the gate comes back, the session does not.
            if (leaks) Step($"leak{i}", $"-has_session{i}", $"outside{i}", "gate");
        }

        var name = "session-pool"
                   + (leaks ? "" : "-nofinallyfix")
                   + (earlyGateRelease ? "" : "-ordered")
                   + (callers == 2 && poolSize == 2 ? "" : $"-{callers}x{poolSize}");
        return new PetriNet(name, places, transitions, arcs, new Marking([.. marking]));
    }

    /// <summary>The twelve pitch classes, named with sharps, as the places of <see cref="VoiceLeading"/>.</summary>
    public static readonly string[] PitchClasses =
        ["C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"];

    /// <summary>
    /// Lesson 14, on Guitar Alchemist: voice leading as a net. One place per pitch class, one
    /// token per voice, so a marking *is* a chord as a multiset of pitch classes — the same
    /// object GA's chord-to-set conversion produces. A transition moves one voice from one pitch
    /// class to another, by at most <paramref name="maxStep"/> semitones.
    ///
    /// Two invariants fall out of the structure rather than out of a search. The tokens are never
    /// created or destroyed, so the number of voices is conserved. And when a
    /// <paramref name="key"/> is given, the extra place "chromatic" is a budget: a voice moving
    /// onto a pitch class outside the key spends one, a voice coming back returns it, so
    /// chromatic + (voices outside the key) is constant. That bounds the foreign notes at
    /// <paramref name="budget"/> for every reachable chord, without enumerating any of them.
    /// </summary>
    public static PetriNet VoiceLeading(
        IReadOnlyList<int> chord, int maxStep = 2, IReadOnlyList<int>? key = null, int budget = 1)
    {
        ArgumentNullException.ThrowIfNull(chord);
        ArgumentOutOfRangeException.ThrowIfLessThan(maxStep, 1);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(maxStep, 5);

        var inKey = key is null ? null : new HashSet<int>(key);
        var places = new List<Place>();
        var marking = new int[inKey is null ? 12 : 13];
        for (var pc = 0; pc < 12; pc++) places.Add(new Place(PitchClasses[pc], PitchClasses[pc]));
        foreach (var pc in chord) marking[pc]++;
        if (inKey is not null)
        {
            places.Add(new Place("chromatic", "chromatic"));
            marking[12] = budget - chord.Count(pc => !inKey.Contains(pc));
            ArgumentOutOfRangeException.ThrowIfNegative(marking[12], nameof(budget));
        }

        var transitions = new List<Transition>();
        var arcs = new List<Arc>();
        for (var from = 0; from < 12; from++)
        {
            for (var step = -maxStep; step <= maxStep; step++)
            {
                if (step == 0) continue;
                var to = (from + step + 12) % 12;
                var id = $"{PitchClasses[from]}_{PitchClasses[to]}";
                transitions.Add(new Transition(id, id));
                arcs.Add(new Arc(PitchClasses[from], id));
                arcs.Add(new Arc(id, PitchClasses[to]));
                if (inKey is null) continue;
                // Leaving the key spends a unit of the budget; coming back returns it.
                if (inKey.Contains(from) && !inKey.Contains(to)) arcs.Add(new Arc("chromatic", id));
                if (!inKey.Contains(from) && inKey.Contains(to)) arcs.Add(new Arc(id, "chromatic"));
            }
        }

        var name = "voice-leading-" + string.Join("", chord.Select(pc => PitchClasses[pc]))
                   + $"-step{maxStep}" + (inKey is null ? "" : $"-key{budget}");
        return new PetriNet(name, places, transitions, arcs, new Marking(marking));
    }

    /// <summary>A marking of <see cref="VoiceLeading"/> read back as a chord, low pitch class first.</summary>
    public static string Chord(Marking marking)
    {
        ArgumentNullException.ThrowIfNull(marking);
        var notes = new List<string>();
        for (var pc = 0; pc < 12; pc++)
            for (var n = 0; n < marking[pc]; n++) notes.Add(PitchClasses[pc].Replace("s", "#", StringComparison.Ordinal));
        return string.Join(" ", notes);
    }

    /// <summary>
    /// A finite, single-item bounded pipeline used to connect the Petri-net course to the
    /// Channel, Dataflow and Rx lifecycle experiments in Advanced C#. Success, failure and
    /// cancellation are intentional terminal markings; any other dead marking is a defect.
    /// </summary>
    public static PetriNet PipelineLifecycle() => new(
        "pipeline-lifecycle",
        [
            new Place("work", "work"),
            new Place("producer", "producer"),
            new Place("free", "free"),
            new Place("queued", "queued"),
            new Place("consumer", "consumer"),
            new Place("processing", "processing"),
            new Place("produced", "produced"),
            new Place("consumed", "consumed"),
            new Place("producer_faulted", "producer faulted"),
            new Place("succeeded", "succeeded"),
            new Place("failed", "failed"),
            new Place("cancelled", "cancelled"),
        ],
        [
            new Transition("write", "write"),
            new Transition("producer_fail", "producer fails"),
            new Transition("read", "read"),
            new Transition("consume", "consume"),
            new Transition("consumer_fail", "consumer fails"),
            new Transition("settle_success", "settle success"),
            new Transition("settle_producer_failure", "settle producer failure"),
            new Transition("cancel", "cancel"),
        ],
        [
            new Arc("work", "write"),
            new Arc("producer", "write"),
            new Arc("free", "write"),
            new Arc("write", "queued"),
            new Arc("write", "produced"),

            new Arc("work", "producer_fail"),
            new Arc("producer", "producer_fail"),
            new Arc("producer_fail", "producer_faulted"),

            new Arc("queued", "read"),
            new Arc("consumer", "read"),
            new Arc("read", "processing"),
            new Arc("read", "free"),

            new Arc("processing", "consume"),
            new Arc("consume", "consumed"),

            new Arc("processing", "consumer_fail"),
            new Arc("produced", "consumer_fail"),
            new Arc("consumer_fail", "failed"),

            new Arc("produced", "settle_success"),
            new Arc("consumed", "settle_success"),
            new Arc("settle_success", "succeeded"),

            new Arc("producer_faulted", "settle_producer_failure"),
            new Arc("consumer", "settle_producer_failure"),
            new Arc("settle_producer_failure", "failed"),

            new Arc("work", "cancel"),
            new Arc("producer", "cancel"),
            new Arc("consumer", "cancel"),
            new Arc("cancel", "cancelled"),
        ],
        new Marking(1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0));

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
        Connection(),
        HandshakeStarted(),
        ReadersWriters(),
        CountingSemaphore(),
        PhilosophersOneFork(3),
        PhilosophersOneFork(3, ordered: true),
        LaneLock(),
        LaneLock(2, guarded: false),
        PipelineLifecycle(),
        Queue(5),
        TwoServers(),
        OrderSound(),
        OrderAndXor(),
        OrderXorAnd(),
        OrderRework(),
        ColouredNets.Retry().Unfold(),
    ];
}
