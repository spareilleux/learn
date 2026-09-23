using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Learn.Comfy;

// An API-format workflow is a JSON object: node id -> { "class_type", "inputs" }.
// Each input is a literal value, or a link written [source node id, output index].
public static class Workflow
{
    // Relaxed escaping writes quotes and non-ASCII characters as they are, instead of ' and the like.
    public static readonly JsonSerializerOptions Indented = new() { WriteIndented = true, IndentSize = 2, Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping };
    public static readonly JsonSerializerOptions Compact = new() { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping };

    public static JsonObject Load(string path) =>
        JsonNode.Parse(File.ReadAllText(path))?.AsObject() ?? throw new InvalidDataException($"{path} is empty");

    // The same test as is_link in comfy_execution/graph_utils.py.
    public static bool IsLink(JsonNode? value, out string source, out int output)
    {
        (source, output) = ("", 0);
        if (value is not JsonArray { Count: 2 } pair
            || pair[0]?.GetValueKind() != JsonValueKind.String
            || pair[1]?.GetValueKind() != JsonValueKind.Number)
            return false;
        (source, output) = (pair[0]!.GetValue<string>(), (int)pair[1]!.GetValue<double>());
        return true;
    }

    // Structural checks, then, when node definitions from /object_info are given,
    // the checks the server makes before it queues a prompt.
    public static (List<string> Errors, List<string> Order) Check(JsonObject workflow, JsonObject? objectInfo)
    {
        var errors = new List<string>();
        var dependencies = new Dictionary<string, HashSet<string>>();
        bool hasOutput = false;

        foreach (var (id, value) in workflow)
        {
            dependencies[id] = [];
            if (value is not JsonObject node || node["class_type"]?.GetValueKind() != JsonValueKind.String)
            {
                errors.Add($"node {id}: no class_type");
                continue;
            }
            string type = node["class_type"]!.GetValue<string>();
            var inputs = node["inputs"] as JsonObject ?? [];
            JsonObject? definition = objectInfo?[type] as JsonObject;
            if (objectInfo is not null && definition is null)
                errors.Add($"node {id}: unknown node type {type}");
            if (definition?["output_node"]?.GetValue<bool>() == true)
                hasOutput = true;

            foreach (var (name, input) in inputs)
            {
                JsonArray? spec = InputSpec(definition, name, inputs);
                if (IsLink(input, out string source, out int output))
                {
                    dependencies[id].Add(source);
                    if (workflow[source] is not JsonObject sourceNode)
                    {
                        errors.Add($"node {id} ({type}) input {name}: links to node {source}, which doesn't exist");
                        continue;
                    }
                    string sourceType = sourceNode["class_type"]?.GetValue<string>() ?? "";
                    if (objectInfo?[sourceType]?["output"] is JsonArray outputs && spec is not null)
                    {
                        if (output >= outputs.Count)
                            errors.Add($"node {id} ({type}) input {name}: {sourceType} has no output {output}");
                        else if (spec[0]?.GetValueKind() == JsonValueKind.String
                            && outputs[output]!.GetValue<string>() is var produced
                            && produced != spec[0]!.GetValue<string>() && produced != "*")
                            errors.Add($"node {id} ({type}) input {name}: expects {spec[0]}, node {source} output {output} is {produced}");
                    }
                }
                else if (definition is not null)
                {
                    if (spec is null)
                        errors.Add($"node {id} ({type}): no input named {name}");
                    else if (CheckValue(spec, input) is string problem)
                        errors.Add($"node {id} ({type}) input {name}: {problem}");
                }
            }

            if (definition?["input"]?["required"] is JsonObject required)
                foreach (var (name, _) in required)
                    if (!inputs.ContainsKey(name))
                        errors.Add($"node {id} ({type}): required input {name} is missing");
        }

        if (objectInfo is not null && !hasOutput)
            errors.Add("no output node: the server would answer prompt_no_outputs");

        // Kahn's algorithm: a node runs after the nodes it links to. What remains is a cycle.
        var order = new List<string>();
        var remaining = dependencies.ToDictionary(d => d.Key, d => d.Value.Where(dependencies.ContainsKey).ToHashSet());
        while (remaining.Count > 0)
        {
            var ready = remaining.Where(r => r.Value.Count == 0).Select(r => r.Key).Order(StringComparer.Ordinal).ToList();
            if (ready.Count == 0)
            {
                errors.Add($"cycle between nodes {string.Join(", ", remaining.Keys.Order(StringComparer.Ordinal))}");
                break;
            }
            foreach (string id in ready)
            {
                order.Add(id);
                remaining.Remove(id);
                foreach (var others in remaining.Values) others.Remove(id);
            }
        }
        return (errors, order);
    }

    static JsonArray? InputSpec(JsonObject? definition, string name) => InputSpec(definition, name, []);

    // A COMFY_DYNAMICCOMBO_V3 input carries a set of nested inputs per option, and a
    // workflow names them with dots: "format", then "format.codec" for the child that
    // the chosen format declares. SaveImageAdvanced and SaveVideo take their options
    // that way, so a validator that only looks at the top level rejects valid files.
    static JsonArray? InputSpec(JsonObject? definition, string name, JsonObject inputs)
    {
        var declared = (definition?["input"]?["required"]?[name] ?? definition?["input"]?["optional"]?[name]) as JsonArray;
        if (declared is not null || !name.Contains('.')) return declared;

        string[] parts = name.Split('.');
        var spec = (definition?["input"]?["required"]?[parts[0]] ?? definition?["input"]?["optional"]?[parts[0]]) as JsonArray;
        for (int i = 1; i < parts.Length && spec is not null; i++)
            spec = ChildSpec(spec, inputs[string.Join('.', parts.Take(i))], parts[i]);
        return spec;
    }

    // The child under the option the workflow chose; under any option when it chose
    // none, since the server then fills the default.
    static JsonArray? ChildSpec(JsonArray parent, JsonNode? chosen, string child)
    {
        if (!IsDynamicCombo(parent) || parent[1]?["options"] is not JsonArray options) return null;
        string? key = chosen?.GetValueKind() == JsonValueKind.String ? chosen.GetValue<string>() : null;
        foreach (var option in options.OfType<JsonObject>())
        {
            if (key is not null && option["key"]?.GetValue<string>() != key) continue;
            if ((option["inputs"]?["required"]?[child] ?? option["inputs"]?["optional"]?[child]) is JsonArray spec) return spec;
        }
        return null;
    }

    static bool IsDynamicCombo(JsonArray spec) =>
        spec.Count > 1 && spec[0]?.GetValueKind() == JsonValueKind.String && spec[0]!.GetValue<string>() == "COMFY_DYNAMICCOMBO_V3";

    static string? CheckValue(JsonArray spec, JsonNode? value)
    {
        var options = spec.Count > 1 ? spec[1] as JsonObject : null;
        if (spec[0] is JsonArray choices)
            return choices.Any(c => JsonNode.DeepEquals(c, value)) ? null : $"{value?.ToJsonString(Compact)} is not one of the {choices.Count} allowed values";
        switch (spec[0]!.GetValue<string>())
        {
            case "INT" or "FLOAT":
                if (value?.GetValueKind() != JsonValueKind.Number) return $"expects a number, got {value?.ToJsonString(Compact)}";
                double number = value.GetValue<double>();
                if (options?["min"] is JsonNode min && number < min.GetValue<double>()) return $"{number} is below the minimum {min}";
                if (options?["max"] is JsonNode max && number > max.GetValue<double>()) return $"{number} is above the maximum {max}";
                return null;
            case "STRING":
                return value?.GetValueKind() == JsonValueKind.String ? null : $"expects a string, got {value?.ToJsonString(Compact)}";
            case "BOOLEAN":
                return value?.GetValueKind() is JsonValueKind.True or JsonValueKind.False ? null : $"expects true or false, got {value?.ToJsonString(Compact)}";
            case "COMFY_DYNAMICCOMBO_V3":
                var keys = (options?["options"] as JsonArray ?? []).OfType<JsonObject>().Select(o => o["key"]).ToList();
                return keys.Count == 0 || keys.Any(k => JsonNode.DeepEquals(k, value))
                    ? null : $"{value?.ToJsonString(Compact)} is not one of the {keys.Count} allowed values";
            default:
                return null;
        }
    }

    // The frontend's "Export (API)" does this: widget values are stored by position in
    // widgets_values, and links are stored once, in the top-level links array.
    public static JsonObject FromUi(JsonObject ui, JsonObject objectInfo)
    {
        if (ui["version"]?.GetValue<double>() != 0.4)
            throw new InvalidDataException("only the 0.4 workflow format is handled here");

        // A link is [link id, origin node, origin slot, target node, target slot, type].
        var links = ui["links"]!.AsArray().Select(l => l!.AsArray())
            .ToDictionary(l => l[0]!.GetValue<int>(), l => (Node: l[1]!.GetValue<int>(), Slot: l[2]!.GetValue<int>()));

        var api = new JsonObject();
        foreach (var node in ui["nodes"]!.AsArray().Select(n => n!.AsObject()).OrderBy(n => n["id"]!.GetValue<int>()))
        {
            string type = node["type"]!.GetValue<string>();
            int mode = node["mode"]?.GetValue<int>() ?? 0;
            if (objectInfo[type] is not JsonObject definition)
            {
                // Notes and other frontend-only nodes have no definition on the server.
                if (type is "Note" or "MarkdownNote") continue;
                throw new InvalidDataException($"node {node["id"]}: {type} is not a server node; reroutes and primitives aren't handled here");
            }
            if (mode == 2) continue; // muted: left out of the prompt
            if (mode == 4) throw new InvalidDataException($"node {node["id"]}: bypassed nodes aren't handled here");

            var inputs = new JsonObject();
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

            api[node["id"]!.GetValue<int>().ToString()] = new JsonObject
            {
                ["inputs"] = inputs,
                ["class_type"] = type,
                ["_meta"] = new JsonObject { ["title"] = node["title"]?.GetValue<string>() ?? definition["display_name"]!.GetValue<string>() },
            };
        }
        return api;
    }

    static bool IsWidget(JsonArray spec) =>
        spec[0] is JsonArray || spec[0]!.GetValue<string>() is "INT" or "FLOAT" or "STRING" or "BOOLEAN" or "COMBO";
}

public static class WorkflowCommands
{
    public static int Validate(string path, string? objectInfoPath)
    {
        var objectInfo = objectInfoPath is null ? null : Workflow.Load(objectInfoPath);
        var (errors, order) = Workflow.Check(Workflow.Load(path), objectInfo);
        foreach (string error in errors) Console.WriteLine($"error: {error}");
        if (errors.Count == 0) Console.WriteLine($"valid; the nodes can run in this order: {string.Join(" ", order)}");
        return errors.Count == 0 ? 0 : 1;
    }

    public static int UiToApi(string uiPath, string objectInfoPath)
    {
        var api = Workflow.FromUi(Workflow.Load(uiPath), Workflow.Load(objectInfoPath));
        Console.WriteLine(api.ToJsonString(Workflow.Indented));
        return 0;
    }

    public static int Diff(string firstPath, string secondPath)
    {
        JsonObject a = Workflow.Load(firstPath), b = Workflow.Load(secondPath);
        int differences = 0;
        void Report(string line) { Console.WriteLine(line); differences++; }

        foreach (string id in a.Select(n => n.Key).Union(b.Select(n => n.Key)).Order(StringComparer.Ordinal))
        {
            if (b[id] is null) { Report($"- node {id} ({a[id]!["class_type"]})"); continue; }
            if (a[id] is null) { Report($"+ node {id} ({b[id]!["class_type"]})"); continue; }
            string typeA = a[id]!["class_type"]!.GetValue<string>(), typeB = b[id]!["class_type"]!.GetValue<string>();
            if (typeA != typeB) Report($"~ node {id}: {typeA} -> {typeB}");
            var inputsA = a[id]!["inputs"]!.AsObject();
            var inputsB = b[id]!["inputs"]!.AsObject();
            foreach (string name in inputsA.Select(i => i.Key).Union(inputsB.Select(i => i.Key)))
            {
                // 7 and 7.0 are the same number to the server.
                JsonNode? x = inputsA[name], y = inputsB[name];
                bool same = x?.GetValueKind() == JsonValueKind.Number && y?.GetValueKind() == JsonValueKind.Number
                    ? x.GetValue<double>() == y.GetValue<double>()
                    : JsonNode.DeepEquals(x, y);
                if (!same)
                    Report($"~ {id}.{name}: {x?.ToJsonString(Workflow.Compact) ?? "(none)"} -> {y?.ToJsonString(Workflow.Compact) ?? "(none)"}");
            }
        }
        Console.WriteLine(differences == 0 ? "same nodes and inputs" : $"{differences} differences");
        return 0;
    }
}
