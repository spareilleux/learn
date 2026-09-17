// ComfyUI course: one command-line tool for lessons 1 to 8.
using Learn.Comfy;

if (args.Length == 0)
{
    Console.Error.WriteLine("""
        usage: comfy <command> ...
          png-info <file.png>                       chunks, text metadata and a pixel hash (lessons 1 and 3)
          compare <a.png> <b.png> [--outside mask.png]
                                                    how much two images differ, optionally only where a mask is opaque (lessons 2 and 5)
          validate <api.json> [object_info.json]    check an API-format workflow offline (lesson 3)
          ui-to-api <ui.json> <object_info.json>    convert a saved workflow to API format (lesson 3)
          diff <a.api.json> <b.api.json>            the inputs that differ between two workflows (lesson 3)
          object-info <server> <class>...           save node definitions from a running server (lesson 3)
          run <server> <api.json> [--set node.input=json]... [--image node.input=file.png]... [--out dir]
                                                    queue a workflow, follow it on the WebSocket, download its images (lessons 4 and 5)
          upload <server> <file.png> [--subfolder dir] [--overwrite]
                                                    upload an image to the server's input folder (lesson 5)
          make-image <width> <height> <out.png>     a test pattern, for workflows that need no model (lesson 5)
          cut <in.png> <out.png> <cx> <cy> <rx> <ry> [feather]
                                                    make an ellipse transparent: LoadImage's mask for inpainting (lesson 5)
          safetensors-info <file.safetensors>       tensors, dtypes, LoRA rank and quantized layers of a model file (lessons 7 and 8)
        """);
    return 2;
}

try
{
    return args[0] switch
    {
        "png-info" => PngCommands.Info(args[1]),
        "compare" => PngCommands.Compare(args[1], args[2], args.Length > 4 && args[3] == "--outside" ? args[4] : null),
        "validate" => WorkflowCommands.Validate(args[1], args.Length > 2 ? args[2] : null),
        "ui-to-api" => WorkflowCommands.UiToApi(args[1], args[2]),
        "diff" => WorkflowCommands.Diff(args[1], args[2]),
        "object-info" => await ComfyClient.SaveObjectInfo(new Uri(args[1]), args[2..]),
        "run" => await ComfyClient.Run(args[1..]),
        "upload" => await ComfyClient.Upload(args[1..]),
        "make-image" => ImageCommands.Make(int.Parse(args[1]), int.Parse(args[2]), args[3]),
        "cut" => ImageCommands.Cut(args[1], args[2], double.Parse(args[3]), double.Parse(args[4]), double.Parse(args[5]), double.Parse(args[6]), args.Length > 7 ? double.Parse(args[7]) : 0),
        "safetensors-info" => Safetensors.Info(args[1]),
        _ => throw new ArgumentException($"unknown command {args[0]}"),
    };
}
catch (Exception e) when (e is IOException or InvalidDataException or ArgumentException or HttpRequestException)
{
    Console.Error.WriteLine($"{e.GetType().Name}: {e.Message}");
    return 1;
}
