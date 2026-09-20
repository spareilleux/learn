using System.Text;

namespace PetriNets;

/// <summary>
/// A colour set: the finite set of values a token of a place may carry. The type of the place,
/// in the sense a C# developer means by type (lesson 8).
/// </summary>
public sealed record ColourSet(string Name, IReadOnlyList<string> Values)
{
    /// <summary>The one-value colour set. A place of this colour is an ordinary P/T place.</summary>
    public static ColourSet Unit { get; } = new("UNIT", ["()"]);

    public bool IsUnit => Values.Count == 1 && Values[0] == "()";

    public int IndexOf(string value)
    {
        for (var i = 0; i < Values.Count; i++)
        {
            if (Values[i] == value) return i;
        }
        throw new KeyNotFoundException($"{value} is not a value of {Name}.");
    }

    public override string ToString() => $"colset {Name} = {{{string.Join(", ", Values)}}}";
}

/// <summary>
/// What an arc carries, as a function of the transition's variable. Only what lesson 8 needs:
/// the variable itself, a constant, and the successor in the colour set.
/// </summary>
public sealed record ArcExpression(string Text, Func<string, string> Evaluate)
{
    public static ArcExpression Variable(string name) => new(name, value => value);

    public static ArcExpression Constant(string value) => new(value, _ => value);

    public static ArcExpression Successor(ColourSet colours, string name) =>
        new($"{name}+1", value =>
        {
            var index = colours.IndexOf(value) + 1;
            return index < colours.Values.Count
                ? colours.Values[index]
                : throw new InvalidOperationException($"{value} has no successor in {colours.Name}; guard the transition.");
        });

    public override string ToString() => Text;
}

/// <summary>A guard: the condition a binding has to satisfy for the transition to fire at all.</summary>
public sealed record Guard(string Text, Func<string, bool> Holds)
{
    public static Guard None { get; } = new("", _ => true);
}

/// <summary>A place of a coloured net, with the colour set of the tokens it may hold.</summary>
public sealed record ColouredPlace(string Id, string Name, ColourSet Colours);

/// <summary>A transition of a coloured net: one variable, ranging over one colour set, with a guard.</summary>
public sealed record ColouredTransition(string Id, string Name, string Variable, ColourSet Binds, Guard Guard)
{
    public static ColouredTransition Plain(string id, string name) => new(id, name, "", ColourSet.Unit, Guard.None);
}

/// <summary>An arc of a coloured net, carrying one token of the colour its expression computes.</summary>
public sealed record ColouredArc(string Source, string Target, ArcExpression Expression);

/// <summary>How many tokens of each colour sit in each place of a coloured net.</summary>
public sealed class ColouredMarking
{
    private readonly int[][] _tokens;

    internal ColouredMarking(int[][] tokens) => _tokens = tokens;

    public int this[int place, int colour] => _tokens[place][colour];

    internal int[][] Copy() => [.. _tokens.Select(row => (int[])row.Clone())];

    /// <summary>The marking as "pending: 0  failed: 1", listing only the places that hold tokens.</summary>
    public string ToString(ColouredNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var parts = new List<string>();
        for (var p = 0; p < net.Places.Count; p++)
        {
            var colours = net.Places[p].Colours;
            for (var c = 0; c < colours.Values.Count; c++)
            {
                if (_tokens[p][c] == 0) continue;
                var value = colours.IsUnit ? "" : $": {colours.Values[c]}";
                var count = _tokens[p][c] == 1 ? "" : $" x{_tokens[p][c]}";
                parts.Add($"{net.Places[p].Name}{value}{count}");
            }
        }
        return parts.Count > 0 ? string.Join("  ", parts) : "(empty)";
    }
}

/// <summary>
/// A coloured net, in the sense of Jensen's coloured Petri nets reduced to what lesson 8 uses:
/// finite colour sets, one variable per transition, guards, and arc expressions. Every such net
/// unfolds into an ordinary P/T net with the same behaviour, which is what <see cref="Unfold"/>
/// builds and what every analysis of this course then runs on.
/// </summary>
public sealed class ColouredNet
{
    private readonly Dictionary<string, int> _placeIndex;
    private readonly Dictionary<string, int> _transitionIndex;

    public ColouredNet(string name, IReadOnlyList<ColouredPlace> places, IReadOnlyList<ColouredTransition> transitions,
                       IReadOnlyList<ColouredArc> arcs, IReadOnlyList<(string Place, string Colour, int Count)> initialMarking)
    {
        ArgumentNullException.ThrowIfNull(places);
        ArgumentNullException.ThrowIfNull(transitions);
        ArgumentNullException.ThrowIfNull(arcs);
        ArgumentNullException.ThrowIfNull(initialMarking);

        Name = name;
        Places = [.. places];
        Transitions = [.. transitions];
        Arcs = [.. arcs];
        _placeIndex = Places.Select((p, i) => (p.Id, i)).ToDictionary(x => x.Id, x => x.i);
        _transitionIndex = Transitions.Select((t, i) => (t.Id, i)).ToDictionary(x => x.Id, x => x.i);

        var tokens = Places.Select(p => new int[p.Colours.Values.Count]).ToArray();
        foreach (var (place, colour, count) in initialMarking)
        {
            var p = PlaceIndex(place);
            tokens[p][Places[p].Colours.IndexOf(colour)] += count;
        }
        InitialMarking = new ColouredMarking(tokens);
    }

    public string Name { get; }
    public IReadOnlyList<ColouredPlace> Places { get; }
    public IReadOnlyList<ColouredTransition> Transitions { get; }
    public IReadOnlyList<ColouredArc> Arcs { get; }
    public ColouredMarking InitialMarking { get; }

    public int PlaceIndex(string id) => _placeIndex[id];

    public int TransitionIndex(string id) => _transitionIndex[id];

    /// <summary>The values the variable of <paramref name="transition"/> may take, once the guard has had its say.</summary>
    public IReadOnlyList<string> Bindings(int transition)
    {
        var t = Transitions[transition];
        return [.. t.Binds.Values.Where(t.Guard.Holds)];
    }

    /// <summary>True when the place holds one token of the right colour for every arc into the transition.</summary>
    public bool IsEnabled(ColouredMarking marking, int transition, string binding)
    {
        ArgumentNullException.ThrowIfNull(marking);
        var t = Transitions[transition];
        if (!t.Guard.Holds(binding)) return false;
        foreach (var (place, colour, count) in Demand(transition, binding))
        {
            if (marking[place, colour] < count) return false;
        }
        return true;
    }

    /// <summary>Fires the transition under one binding: the tokens it takes and gives carry the colours the arcs compute.</summary>
    public ColouredMarking Fire(ColouredMarking marking, int transition, string binding)
    {
        ArgumentNullException.ThrowIfNull(marking);
        if (!IsEnabled(marking, transition, binding))
            throw new InvalidOperationException($"{Transitions[transition].Name} is not enabled under {Variable(transition)} = {binding}.");
        var tokens = marking.Copy();
        foreach (var (place, colour, count) in Demand(transition, binding)) tokens[place][colour] -= count;
        foreach (var (place, colour, count) in Supply(transition, binding)) tokens[place][colour] += count;
        return new ColouredMarking(tokens);
    }

    /// <summary>Fires a sequence of (transition id, binding) pairs, returning every marking along the way.</summary>
    public IReadOnlyList<ColouredMarking> FireSequence(ColouredMarking start, params (string Transition, string Binding)[] steps)
    {
        ArgumentNullException.ThrowIfNull(steps);
        var markings = new List<ColouredMarking> { start };
        var current = start;
        foreach (var (transition, binding) in steps)
        {
            current = Fire(current, TransitionIndex(transition), binding);
            markings.Add(current);
        }
        return markings;
    }

    public string Variable(int transition) =>
        Transitions[transition].Binds.IsUnit ? "" : Transitions[transition].Variable;

    /// <summary>
    /// The unfolding: one P/T place per (place, colour) and one P/T transition per (transition, binding
    /// the guard accepts). The behaviour is unchanged — a coloured marking and its unfolded marking are
    /// the same vector — so colour folds the picture, not the state space.
    /// </summary>
    public PetriNet Unfold()
    {
        var places = new List<Place>();
        var marking = new List<int>();
        foreach (var place in Places)
        {
            foreach (var colour in place.Colours.Values)
            {
                places.Add(new Place(Join(place.Id, colour, place.Colours), Join(place.Name, colour, place.Colours)));
                marking.Add(InitialMarking[PlaceIndex(place.Id), place.Colours.IndexOf(colour)]);
            }
        }

        var transitions = new List<Transition>();
        var arcs = new List<Arc>();
        for (var t = 0; t < Transitions.Count; t++)
        {
            var transition = Transitions[t];
            foreach (var binding in Bindings(t))
            {
                var id = Join(transition.Id, binding, transition.Binds);
                transitions.Add(new Transition(id, Join(transition.Name, binding, transition.Binds)));
                foreach (var (place, colour, count) in Demand(t, binding))
                    arcs.Add(new Arc(ColouredPlaceId(place, colour), id, count));
                foreach (var (place, colour, count) in Supply(t, binding))
                    arcs.Add(new Arc(id, ColouredPlaceId(place, colour), count));
            }
        }

        return new PetriNet(Name, places, transitions, arcs, new Marking([.. marking]));
    }

    /// <summary>The declarations and the arcs of the net, the form lesson 8 prints.</summary>
    public string Describe()
    {
        var text = new StringBuilder();
        text.AppendLine($"coloured net {Name}");
        foreach (var colours in Places.Select(p => p.Colours).Distinct().Where(c => !c.IsUnit))
            text.AppendLine($"  {colours}");
        foreach (var place in Places)
            text.AppendLine($"  place       {place.Name} : {place.Colours.Name}");
        foreach (var transition in Transitions)
        {
            var variable = transition.Binds.IsUnit ? "" : $"  var {transition.Variable} : {transition.Binds.Name}";
            var guard = transition.Guard.Text.Length == 0 ? "" : $"  [{transition.Guard.Text}]";
            text.AppendLine($"  transition  {transition.Name}{variable}{guard}");
        }
        foreach (var arc in Arcs)
            text.AppendLine($"  arc         {Label(arc.Source)} -> {Label(arc.Target)}   {arc.Expression.Text}");
        text.AppendLine($"  M0          {InitialMarking.ToString(this)}");
        return text.ToString();
    }

    private string Label(string id) =>
        _placeIndex.TryGetValue(id, out var p) ? Places[p].Name : Transitions[_transitionIndex[id]].Name;

    private string ColouredPlaceId(int place, int colour) =>
        Join(Places[place].Id, Places[place].Colours.Values[colour], Places[place].Colours);

    private static string Join(string name, string value, ColourSet colours) =>
        colours.IsUnit ? name : $"{name}_{value}";

    /// <summary>The tokens the transition takes from each place under a binding, gathered by colour.</summary>
    private IEnumerable<(int Place, int Colour, int Count)> Demand(int transition, string binding) =>
        Gather(Arcs.Where(a => a.Target == Transitions[transition].Id), binding, a => a.Source);

    /// <summary>The tokens the transition gives to each place under a binding, gathered by colour.</summary>
    private IEnumerable<(int Place, int Colour, int Count)> Supply(int transition, string binding) =>
        Gather(Arcs.Where(a => a.Source == Transitions[transition].Id), binding, a => a.Target);

    private IEnumerable<(int Place, int Colour, int Count)> Gather(
        IEnumerable<ColouredArc> arcs, string binding, Func<ColouredArc, string> placeOf)
    {
        var counts = new Dictionary<(int, int), int>();
        foreach (var arc in arcs)
        {
            var place = PlaceIndex(placeOf(arc));
            var colour = Places[place].Colours.IndexOf(arc.Expression.Evaluate(binding));
            counts[(place, colour)] = counts.GetValueOrDefault((place, colour)) + 1;
        }
        return counts.OrderBy(pair => pair.Key.Item1).ThenBy(pair => pair.Key.Item2)
            .Select(pair => (pair.Key.Item1, pair.Key.Item2, pair.Value));
    }
}
