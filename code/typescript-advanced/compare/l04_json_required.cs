// compare/l04_json_required.cs
// C# types exist at run time: System.Text.Json can check the payload against the record it deserializes into
// File-based apps are AOT-ready by default, which disables reflection-based JSON
#:property PublishAot=false
using System.Text.Json;

var options = new JsonSerializerOptions(JsonSerializerDefaults.Web)
{
    RespectNullableAnnotations = true, // .NET 9: null for a non-nullable property is an error
    RespectRequiredConstructorParameters = true, // .NET 9: a missing constructor parameter is an error
};

string[] messages =
[
    """{"id":"policy-7","name":"Alignment policy"}""",
    """{"nodeId":"policy-7","health":{"resilienceScore":0.4}}""",
    """{"id":"policy-7","name":null}""",
];
foreach (var message in messages)
{
    try
    {
        var node = JsonSerializer.Deserialize<GovernanceNode>(message, options);
        Console.WriteLine($"ok: {node}");
    }
    catch (JsonException e)
    {
        Console.WriteLine($"JsonException: {e.Message}");
    }
}

record GovernanceNode(string Id, string Name);
