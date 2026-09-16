// ComfyUI course: one command-line tool for lessons 1 to 4.
using Learn.Comfy;

if (args.Length == 0)
{
    Console.Error.WriteLine("""
        usage: comfy <command> ...
          png-info <file.png>                       chunks, text metadata and a pixel hash (lessons 1 and 3)
          compare <a.png> <b.png>                   how much two images differ (lesson 2)
          validate <api.json> [object_info.json]    check an API-format workflow offline (lesson 3)
          ui-to-api <ui.json> <object_info.json>    convert a saved workflow to API format (lesson 3)
          diff <a.api.json> <b.api.json>            the inputs that differ between two workflows (lesson 3)
          object-info <server> <class>...           save node definitions from a running server (lesson 3)
          run <server> <api.json> [--set node.input=json]... [--out dir]
                                                    queue a workflow, follow it on the WebSocket, download its images (lesson 4)
        """);
    return 2;
}

try
{
    return args[0] switch
    {
        "png-info" => PngCommands.Info(args[1]),
        "compare" => PngCommands.Compare(args[1], args[2]),
        "validate" => WorkflowCommands.Validate(args[1], args.Length > 2 ? args[2] : null),
        "ui-to-api" => WorkflowCommands.UiToApi(args[1], args[2]),
        "diff" => WorkflowCommands.Diff(args[1], args[2]),
        "object-info" => await ComfyClient.SaveObjectInfo(new Uri(args[1]), args[2..]),
        "run" => await ComfyClient.Run(args[1..]),
        _ => throw new ArgumentException($"unknown command {args[0]}"),
    };
}
catch (Exception e) when (e is IOException or InvalidDataException or ArgumentException or HttpRequestException)
{
    Console.Error.WriteLine($"{e.GetType().Name}: {e.Message}");
    return 1;
}
