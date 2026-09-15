// compare/l01_typed_keys.cs
// C# has no literal types: a string can't carry its payload's type, so a typed key object does
var hub = new Hub();
hub.On(HubEvents.NavigateToPlanet, data => Console.WriteLine($"navigate to {data.Target}"));
hub.On(HubEvents.Connected, data => Console.WriteLine($"{data.Connections} clients connected"));
hub.Receive("NavigateToPlanet", new NavigateToPlanet("saturn"));
hub.Receive("Connected", new Connected(2));

record NavigateToPlanet(string Target);
record Connected(int Connections);

// The key: a name for the wire, and a type parameter for the compiler
sealed record HubEvent<T>(string Name);

static class HubEvents
{
    public static readonly HubEvent<NavigateToPlanet> NavigateToPlanet = new("NavigateToPlanet");
    public static readonly HubEvent<Connected> Connected = new("Connected");
}

class Hub
{
    private readonly Dictionary<string, Action<object>> handlers = [];

    // T is inferred from the key, as TypeScript infers K from the string
    public void On<T>(HubEvent<T> hubEvent, Action<T> handler) => handlers[hubEvent.Name] = data => handler((T)data);

    public void Receive(string name, object data) => handlers[name](data);
}
