// compare/l04_hub_json.cs
// What GovernanceHub.cs puts on the wire: SignalR's JSON hub protocol, with its default serializer options
#:sdk Microsoft.NET.Sdk.Web
// File-based apps are AOT-ready by default, which disables reflection-based JSON: anonymous types need it
#:property PublishAot=false
using System.Buffers;
using System.Text;
using Microsoft.AspNetCore.SignalR.Protocol;

var protocol = new JsonHubProtocol();

// BroadcastNodeChanged sends an anonymous object whose first property is nodeId, not id
var nodeChanged = new
{
    nodeId = "policy-7",
    health = new HealthMetrics(0.4, 0, 3),
    healthStatus = "warning",
    color = "#FFB300",
    timestamp = new DateTime(2026, 9, 15, 12, 0, 1, DateTimeKind.Utc),
};
Console.WriteLine(Write(new InvocationMessage("NodeChanged", [nodeChanged])));

// ViewersChanged sends ViewerInfo records: PascalCase properties become camelCase, and null is written as null
var viewer = new ViewerInfo("c3", "#d2a8ff", "Firefox", new DateTime(2026, 9, 15, 12, 0, 0, DateTimeKind.Utc));
Console.WriteLine(Write(new InvocationMessage("ViewersChanged", [new List<ViewerInfo> { viewer }])));

string Write(HubMessage message)
{
    var buffer = new ArrayBufferWriter<byte>();
    protocol.WriteMessage(message, buffer);
    // Each message ends with the record separator character, 0x1E
    return Encoding.UTF8.GetString(buffer.WrittenSpan).TrimEnd((char)0x1E);
}

record HealthMetrics(double ResilienceScore, int LolliCount, int ErgolCount);
record ViewerInfo(string ConnectionId, string Color, string Browser, DateTime ConnectedAt, string? DisplayName = null, string? AvatarUrl = null);
