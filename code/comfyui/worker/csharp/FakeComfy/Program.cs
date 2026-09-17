// ComfyUI course, lesson 12: the fake ComfyUI server, as a program, for check.sh and for the Java tests.
//   fake-comfy [--port 0] [--script ok,500,drop,...] [--step-ms 20] [--busy 0]
// Prints "listening on <url>" once it accepts connections, then runs until it is killed or its input closes.
using Learn.Comfy.Fake;

int port = 0;
var options = new FakeOptions();
bool untilInputCloses = false;
for (int i = 0; i < args.Length; i++)
{
    switch (args[i])
    {
        case "--port": port = int.Parse(args[++i]); break;
        case "--script": options = options with { Script = args[++i].Split(',', StringSplitOptions.RemoveEmptyEntries) }; break;
        case "--step-ms": options = options with { StepMs = int.Parse(args[++i]) }; break;
        case "--busy": options = options with { Busy = int.Parse(args[++i]) }; break;
        // A parent process (the Java tests) closes our input when it stops, even if it dies without cleaning up.
        case "--until-input-closes": untilInputCloses = true; break;
        default: Console.Error.WriteLine($"unknown option {args[i]}"); return 2;
    }
}

await using var server = await FakeComfyServer.StartAsync(options, port);
Console.WriteLine($"listening on {server.BaseUri}");
Console.Out.Flush();
if (untilInputCloses)
    await Task.Run(() => { while (Console.In.ReadLine() is not null) { } });
else
    await Task.Delay(Timeout.Infinite);
return 0;
