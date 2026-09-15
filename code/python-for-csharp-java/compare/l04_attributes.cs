// compare/l04_attributes.cs
using System.Reflection;

Console.WriteLine("the program starts");
var handler = typeof(Program).GetMethod(nameof(GovernanceHandler), BindingFlags.NonPublic | BindingFlags.Static)!;
Console.WriteLine("reading the attributes");
var agent = handler.GetCustomAttribute<AgentAttribute>()!; // the attribute object is created here
Console.WriteLine($"{agent.Name} -> {handler.Invoke(null, ["show beliefs"])}");

partial class Program
{
    // An attribute is metadata: nothing runs until code asks for it through reflection
    [Agent("governance")]
    static string GovernanceHandler(string text) => $"governance: {text}";
}

[AttributeUsage(AttributeTargets.Method)]
class AgentAttribute : Attribute
{
    public AgentAttribute(string name)
    {
        Console.WriteLine($"AgentAttribute({name}) is created");
        Name = name;
    }

    public string Name { get; }
}
