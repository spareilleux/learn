// compare_fail/l01_infer_from_name.cs
// With a string name, nothing tells the compiler which payload the handler receives
var hub = new Hub();
hub.On("NavigateToPlanet", data => Console.WriteLine(data.Target));

class Hub
{
    public void On<T>(string name, Action<T> handler) { }
}
