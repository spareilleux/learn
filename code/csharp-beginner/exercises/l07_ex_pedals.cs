List<Effect> distortionFirst = [new Distortion(), new Delay(3)];
List<Effect> delayFirst = [new Delay(3), new Distortion()];

Console.WriteLine(Run(distortionFirst, "E2"));
Console.WriteLine(Run(delayFirst, "E2"));

string Run(List<Effect> pedalboard, string sound)
{
    List<string> names = [];
    foreach (Effect effect in pedalboard)
    {
        sound = effect.Apply(sound);
        names.Add(effect.Name);
    }
    return $"{string.Join(" -> ", names)}: {sound}";
}

abstract class Effect
{
    public string Name { get; }

    protected Effect(string name) => Name = name;

    public abstract string Apply(string sound);
}

sealed class Distortion : Effect
{
    public Distortion() : base("Distortion")
    {
    }

    public override string Apply(string sound) => $"distortion({sound})";
}

sealed class Delay : Effect
{
    private readonly int _repeats;

    public Delay(int repeats) : base("Delay") => _repeats = repeats;

    public override string Apply(string sound) => $"delay({sound}, {_repeats})";
}
