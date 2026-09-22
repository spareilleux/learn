---
title: '3. Workflows as JSON: the UI format, the API format, and diffs'
description: 'The two JSON formats of a ComfyUI graph — the workflow the frontend saves, with positions, link tables and positional widget values, and the prompt the server runs — converted from one to the other in C# byte for byte like the frontend, the metadata ComfyUI writes into PNG files, a workflow validated offline against /object_info and by the server, and diffs that ignore layout.'
sidebar:
  order: 3
---

Code: the three JSON files of the lesson 1 graph in [`workflows/`](https://github.com/spareilleux/learn/tree/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows), the conversion, validation and diff in [`csharp/Workflow.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Workflow.cs), the PNG reader in [`csharp/Png.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Png.cs), and the node definitions they use in [`data/object_info.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/data/object_info.json).

## Two formats for one graph

ComfyUI stores a graph in two JSON formats, and you will meet both.

- **The workflow**, or UI format, is what the frontend saves with File → Save, what you drag into the browser, and what workflow templates are. It describes the drawing: where each node is, how big, which links connect which slots, and the widget values.
- **The prompt**, or API format, is what the server runs. The frontend builds it when you press Run, and File → Export Workflow (API) saves it. It has only node types, inputs and links.

The [API format page](https://docs.comfy.org/development/api-development/workflow-api-format) puts it this way: "API format omits UI metadata (positions, colors, groups, node sizes) that is only needed for visual editing in the frontend." The same page's table says the save format keys nodes by "Node titles or labels"; both formats actually use the numeric node id, as the files below show.

To get a real pair, the course loaded the lesson 1 API file into the frontend, version 1.52.7, and let the frontend export both formats, from the browser's JavaScript console:

```js
await app.loadApiJson(apiWorkflow, '01-txt2img');
const { workflow, output } = await app.graphToPrompt();
```

`workflow` became [`01-txt2img.ui.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.ui.json), 6,660 bytes, and `output` became [`01-txt2img.exported.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.exported.api.json), 1,792 bytes. `app` is the frontend's global object; these two functions are what its menus call, but they aren't a documented API, so the menu entries are the stable way.

| | Workflow (UI format) | Prompt (API format) |
|---|---|---|
| Top level | an object with `nodes`, `links`, `groups`, `extra` and `version` | an object whose keys are node ids |
| A node | `id`, `type`, `pos`, `size`, `order`, `mode`, `inputs`, `outputs`, `widgets_values` | `class_type`, `inputs`, and `_meta.title` |
| A widget value | by position, in `widgets_values` | by name, in `inputs` |
| A link | a row in the top-level `links` table, referenced by id from both nodes | `["4", 1]` in the input that receives it |
| Frontend-only nodes, like notes | kept | dropped |
| Schema | [workflow JSON 0.4](https://docs.comfy.org/specs/workflow_json_0.4), and a newer [1.0](https://docs.comfy.org/specs/workflow_json) | none published; the server's validation defines it |

## The workflow format

Here is the `KSampler` node in the UI file, without its `widgets_values_named`, which comes up below:

```json
{
  "id": 3,
  "type": "KSampler",
  "pos": [970, 130],
  "size": [270, 262],
  "flags": {},
  "order": 4,
  "mode": 0,
  "inputs": [
    { "name": "model", "type": "MODEL", "link": 10 },
    { "name": "positive", "type": "CONDITIONING", "link": 11 },
    { "name": "negative", "type": "CONDITIONING", "link": 12 },
    { "name": "latent_image", "type": "LATENT", "link": 13 }
  ],
  "outputs": [
    { "name": "LATENT", "type": "LATENT", "links": [16] }
  ],
  "properties": { "Node name for S&R": "KSampler" },
  "widgets_values": [42, "randomize", 25, 7, "euler", "normal", 1]
}
```

And the `links` table, where each row is `[link id, origin node, origin slot, target node, target slot, type]`:

```json
[[10, 4, 0, 3, 0, "MODEL"], [11, 6, 0, 3, 1, "CONDITIONING"], [12, 7, 0, 3, 2, "CONDITIONING"],
 [13, 5, 0, 3, 3, "LATENT"], [14, 4, 1, 6, 0, "CLIP"], [15, 4, 1, 7, 0, "CLIP"],
 [16, 3, 0, 8, 0, "LATENT"], [17, 4, 2, 8, 1, "VAE"], [18, 8, 0, 9, 0, "IMAGE"]]
```

Three things surprise a developer who expects a data format:

- **Links are stored in three places.** Link 10 is a row in `links`, an id in node 3's `model` input, and an id in node 4's `MODEL` output. A tool that edits one place must edit the others.
- **Widget values are positional.** `widgets_values` has seven entries for six widget inputs. The second, `"randomize"`, is the *control after generate* widget that the frontend adds after any seed: after each run, it sets the seed to a random number, or adds or subtracts one. The server never sees it.
- **Layout is data.** Move a node by one pixel and `pos` changes. A version-control diff of UI files mixes layout changes with the changes that matter.

The export also has a `widgets_values_named` object next to `widgets_values`, with the same values by name. The schema doesn't mention it, and the course's converter doesn't use it.

## From the workflow to the prompt

Converting means resolving every link id through the `links` table, and naming every widget value. The names come from the server: `/object_info` lists each node's inputs, in order, under `input_order`. The course's C# converter follows the frontend's rules, in [`Workflow.FromUi`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Workflow.cs):

```csharp
var values = new Queue<JsonNode?>(node["widgets_values"] as JsonArray ?? []);
var order = definition["input_order"]?["required"]?.AsArray().Concat(definition["input_order"]?["optional"]?.AsArray() ?? []) ?? [];
foreach (string name in order.Select(n => n!.GetValue<string>()))
{
    var spec = InputSpec(definition, name)!;
    if (!IsWidget(spec) || values.Count == 0) continue;
    inputs[name] = values.Dequeue()?.DeepClone();
    // A seed has a second widget, "control after generate", that the server never sees.
    if (spec.Count > 1 && spec[1]?["control_after_generate"]?.GetValue<bool>() == true && values.Count > 0)
        values.Dequeue();
}
foreach (var input in (node["inputs"] as JsonArray ?? []).Select(i => i!.AsObject()))
    if (input["link"]?.GetValue<int>() is int linkId)
    {
        var (origin, slot) = links[linkId];
        inputs[input["name"]!.GetValue<string>()] = new JsonArray(origin.ToString(), slot);
    }
```

An input is a widget when its type is `INT`, `FLOAT`, `STRING`, `BOOLEAN`, or a list of choices. `seed` is declared with `"control_after_generate": true` in [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1603), which is how the converter knows to skip the next value.

`check.sh` runs the converter on the UI file and compares its output with the frontend's export: they are the same bytes, apart from line endings. The converter is deliberately small. It rejects reroute nodes, primitive nodes, bypassed nodes and subgraphs, and a real tool would have to handle them; for those, let the frontend do the export.

The hand-written file and the frontend's export aren't the same bytes: the export adds `_meta.title`, orders keys differently, and writes `7` where the file had `7.0`. The course's `diff` command compares what the server uses, node types and inputs, and treats numbers as numbers:

```text
> comfy diff workflows/01-txt2img.api.json workflows/01-txt2img.exported.api.json
same nodes and inputs
```

That is the diff to put in a code review. Keep the UI file if people edit the graph in the browser, but review changes on the API format, where one changed seed is one changed line:

```text
> comfy diff workflows/01-txt2img.api.json workflows/03-broken.api.json
~ 3.steps: 25 -> 0
~ 3.sampler_name: "euler" -> "euler_a"
~ 3.negative: ["7",0] -> ["12",0]
~ 3.latent_image: ["5",0] -> ["4",2]
4 differences
```

## Validating a workflow

[`03-broken.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/03-broken.api.json) is the lesson 1 workflow with four mistakes: those four lines of the diff. The course's `validate` command checks what it can offline. Without node definitions, it checks the structure: every node has a `class_type`, every link points at an existing node, and there is no cycle. With the definitions saved from a server's `/object_info`, it checks what the server checks: known node types, required inputs, value ranges and choices, and that each link's output type is the type the input expects.

```text
> comfy validate workflows/03-broken.api.json data/object_info.json
error: node 4 (CheckpointLoaderSimple) input ckpt_name: "sd_xl_base_1.0.safetensors" is not one of the 0 allowed values
error: node 3 (KSampler) input steps: 0 is below the minimum 1
error: node 3 (KSampler) input sampler_name: "euler_a" is not one of the 45 allowed values
error: node 3 (KSampler) input negative: links to node 12, which doesn't exist
error: node 3 (KSampler) input latent_image: expects LATENT, node 4 output 2 is VAE
```

The first error is not one of the four: `data/object_info.json` was saved from the CI server, which has no model, so the list of allowed checkpoint names is empty. The server itself says the same thing, since a combo input's choices are the files it finds on disk. On a valid graph, `validate` also prints an order in which the nodes can run:

```text
> comfy validate workflows/01-txt2img.api.json
valid; the nodes can run in this order: 4 5 6 7 3 8 9
```

Posted to the server, the broken workflow is rejected with HTTP 400:

```json
{"error": {"type": "prompt_outputs_failed_validation", "message": "Prompt outputs failed validation", "details": "", "extra_info": {}},
 "node_errors": {
  "4": {"errors": [{"type": "value_not_in_list", "message": "Value not in list",
        "details": "ckpt_name: 'sd_xl_base_1.0.safetensors' not in []", …}], "dependent_outputs": ["9"], "class_type": "CheckpointLoaderSimple"},
  "3": {"errors": [{"type": "exception_during_inner_validation", "message": "Exception when validating inner node",
        "details": "'12'", "extra_info": {…, "exception_type": "KeyError", "traceback": ["  File \"C:\\Users\\…\\ComfyUI\\execution.py\", line 933, in validate_inputs\n    o_class_type = prompt[o_id]['class_type']\n…"]}}], …}}}
```

The server reported two errors where the offline check found five, and the second one is odd: it is filed under node 3, but its `extra_info` names the input `samples` and the linked node `["3", 0]`, which is node 8's input. The code explains it. The server validates from each output node up through its links. For a linked input, [`validate_inputs`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L933) reads `prompt[o_id]['class_type']` before its `try` block, so node 3's link to the missing node 12 raised a `KeyError` that escaped node 3's validation. Node 8, `VAEDecode`, caught it while validating its `samples` input, and [stored it as node 3's result](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L962-L979). Node 3's other inputs were never checked, or only some of them: `validate_inputs` walks the inputs of a node in the order of a Python set ([line 896](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L896)), which changes from one server start to the next. The answer also includes a Python traceback with the server's installation path, which is one more reason not to expose the port. Validating offline first gives a better error list; the server's answer is still the one that decides.

### Inputs with a dot in their name

Some recent nodes take their options as a tree. `SaveImageAdvanced` in lesson 9 and `SaveVideo` in lesson 10 declare an input of type `COMFY_DYNAMICCOMBO_V3`: the value chosen for `format` decides which other inputs exist, and the workflow names them with dots.

```json
{"images": ["1", 0], "format": "png", "format.bit_depth": "16"}
```

`/object_info` describes such an input as a list of options, each carrying its own `required` and `optional` inputs, nested as deep as the node needs: `SaveVideo`'s `format` holds a `codec`, which holds an `encoding`, which holds a `crf`. A validator that reads only the node's top-level `required` and `optional` calls `format.bit_depth` an unknown input. That was this course's own bug, found while checking the lesson 10 workflows before spending a GPU window on them. `validate` now follows the options of the value the workflow chose:

```text
> comfy validate workflows/03-dynamic-broken.api.json data/object_info-dynamic.json
error: node 2 (SaveImageAdvanced): no input named format.bit_depth
error: node 3 (SaveImageAdvanced) input format: "tiff" is not one of the 2 allowed values
error: node 4 (SaveImageAdvanced) input format.bit_depth: "24" is not one of the 2 allowed values
```

The first error is the one worth knowing: node 2 asks for `exr`, and `bit_depth` belongs to `png`. The name exists on the node, but not under the option this node picked, so nothing will read it. Whether the server refuses that prompt or quietly ignores the extra input is *to verify*; it is a mistake either way.

## The metadata in PNG files

A PNG file is a signature and a list of chunks, each with a length, a four-letter type, data and a CRC-32 ([PNG specification](https://www.w3.org/TR/png-3/#11tEXt)). `SaveImage` adds a `tEXt` chunk for the prompt, and one for each key the client sent in `extra_pnginfo`, in [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1701-L1707):

```python
metadata = PngInfo()
if prompt is not None:
    metadata.add_text("prompt", json.dumps(prompt))
if extra_pnginfo is not None:
    for x in extra_pnginfo:
        metadata.add_text(x, json.dumps(extra_pnginfo[x]))
```

The frontend sends the UI workflow in `extra_pnginfo`; the API clients of this course don't. The `prompt` is the one the server validated, and validation writes converted values back: `"cfg": 7.0` below comes from a frontend that sent `7`, converted by `float(val)` ([`execution.py`, line 995](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L995-L997)). So an image queued from the browser has two text chunks, and one queued through the API has one:

```text
> comfy png-info output/l01/metronome_00001_.png
chunk IHDR: 1 x, 13 bytes
chunk tEXt: 1 x, 921 bytes
chunk IDAT: 23 x, 3146752 bytes once inflated
chunk IEND: 1 x, 0 bytes
text prompt: 914 characters: {"4": {"class_type": "CheckpointLoaderSimple", "inputs": {"c...
image: 1024 x 1024, 3 channels, pixel SHA-256 698e7867e7fc04fb

> comfy png-info output/l03/from-ui_00001_.png
chunk IHDR: 1 x, 13 bytes
chunk tEXt: 2 x, 4886 bytes
chunk IDAT: 23 x, 3146752 bytes once inflated
chunk IEND: 1 x, 0 bytes
text prompt: 1191 characters: {"3": {"inputs": {"seed": 42, "steps": 25, "cfg": 7.0, "samp...
text workflow: 3679 characters: {"id": "00000000-0000-0000-0000-000000000000", "revision": 0...
image: 1024 x 1024, 3 channels, pixel SHA-256 5374ac40a393cf78
```

The C# reader in [`Png.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Png.cs) checks each chunk's CRC, reads `tEXt` and `iTXt` chunks, and decodes the pixels itself, with `ZLibStream` and PNG's five row filters, so that the hash covers pixels and not file bytes. The IDAT line shows why. On the first CI run, the same 64 × 48 image was 84 compressed bytes on Linux and 88 on Windows and macOS: most likely, the zlib library that Pillow uses differs between the platforms' builds. The inflated size, 9,264 bytes, is the same everywhere, and so are the pixels.

Two cautions about this metadata:

- **It travels with the image.** A PNG you publish carries your prompt, your negative prompt, the model's file name and your node setup. Start the server with `--disable-metadata`, or strip the chunks, when that matters.
- **It proves nothing.** The [metadata page](https://docs.comfy.org/development/api-development/workflow-metadata) says it plainly: "Embedded metadata is not a digital signature. It does not prove who created or modified a file." Anyone can write any prompt into a PNG.

The PNG queued from the browser also shows the control widget at work. Its `workflow` chunk records seed 42, the value when Run was pressed; right after queuing, the frontend replaced the seed with 140956311522585, so pressing Run a second time would not have made the same image.

## Key takeaways

- The UI format describes a drawing: positions, positional widget values, and links stored in a table and on both nodes. The API format has only node types, named inputs and links.
- Converting needs the node definitions from `/object_info`, for the input names and order, and must skip the control-after-generate values. The course's C# converter matches the frontend's export byte for byte on a simple graph.
- Review workflow changes on the API format, with a diff that compares node types and inputs.
- Validate offline for a complete error list; the server stops at the first problem of a node, and may answer with a traceback.
- PNG files carry the prompt, and the workflow when queued from the browser. Hash pixels, not files.

## Your turn

Build a small graph in the browser — a checkpoint, two prompts, a sampler, a save — and export it in both formats. Convert the UI file with the course's converter and diff the result against the frontend's own API export: they should match. Then break it on purpose, with a link to a node that no longer exists or a `steps` of `-1`, and compare what the offline validator lists with what the server answers when you queue it.

## Exercises

1. Add a second `SaveImage` node to `01-txt2img.api.json`, fed by the `VAEDecode` node, with the prefix `l03/copy`. Run `comfy validate` on it: what order does it print?
2. In `03-broken.api.json`, fix everything except the link to node 12, and post it to a running server. Which errors does the server report now?
3. The UI file's node 9 has `"outputs": [{"name": "images", "type": "IMAGE", "links": null}]`. `SaveImage` is an output node; why does it have an output at all? Look at its `RETURN_TYPES` in [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1660-L1720) and at `/object_info/SaveImage`.

<details>
<summary>Solution 1</summary>

```json
  "10": {
    "class_type": "SaveImage",
    "inputs": { "filename_prefix": "l03/copy", "images": ["8", 0] }
  }
```

`valid; the nodes can run in this order: 4 5 6 7 3 8 10 9`. The command sorts the nodes that are ready at the same time by id, as strings, so `10` comes before `9`. Both output nodes depend only on node 8, so either order is correct. The server picks its own order, and lesson 4 shows that it changes from one start to the next.

</details>

<details>
<summary>Solution 2</summary>

With the checkpoint present on the server, `steps` set back to 25, `sampler_name` to `euler`, and `latent_image` to `["5", 0]`, only `negative` still points at node 12. Posted three times to a server with the SDXL file in its models folder, it got the same answer each time: HTTP 400 with one entry in `node_errors`, for node 3, of type `exception_during_inner_validation`, with details `'12'`, input name `samples`, and a `KeyError` traceback. The error type describes a failure of the validation code, not a missing node, and the input it names is node 8's, so a client that shows only `type` to its users should also show `details`.

</details>

<details>
<summary>Solution 3</summary>

`SaveImage` declares `RETURN_TYPES = ("IMAGE",)` and its `save_images` method returns `{"ui": {"images": results}, "result": (images,)}`: the `ui` part is what the server sends to clients and stores in the history, and `result` passes the images on, so another node can use them after saving. `/object_info/SaveImage` shows `"output": ["IMAGE"]` and `"output_node": true`. The frontend draws the output slot; `"links": null` means nothing is connected to it.

</details>

## Sources

- ComfyUI documentation: [workflow API format](https://docs.comfy.org/development/api-development/workflow-api-format), [workflow JSON 0.4](https://docs.comfy.org/specs/workflow_json_0.4) and [1.0](https://docs.comfy.org/specs/workflow_json) specifications, [workflow metadata](https://docs.comfy.org/development/api-development/workflow-metadata), [SaveImage](https://docs.comfy.org/built-in-nodes/SaveImage).
- ComfyUI at v0.36.0: [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py), [`comfy_execution/graph_utils.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/graph_utils.py#L1-L10).
- W3C, [Portable Network Graphics (PNG) Specification (Third Edition)](https://www.w3.org/TR/png-3/).
- .NET: [`System.Text.Json.Nodes`](https://learn.microsoft.com/dotnet/api/system.text.json.nodes), [`ZLibStream`](https://learn.microsoft.com/dotnet/api/system.io.compression.zlibstream).
