"""Exposes whether DLSS really runs: dlss.cpp counts each successful DLSS / DLSS-RR evaluation and
keeps the last render and output sizes; Streamline.get_status() hands them to scripts, with whether
frame generation holds a viewport. The demo's badge (artpass/dlss/dlss_play.gd) reads the rate."""
import sys
root = r"C:\tmp\godot-nvidia-dlss\godot"

def patch(path, old, new, marker):
    p = root + "\\" + path
    s = open(p, encoding="utf-8", newline="").read()
    if marker in s:
        print("already:", path); return
    assert s.count(old) == 1, (path, s.count(old))
    s = s.replace(old, new)
    open(p, "w", encoding="utf-8", newline="").write(s)
    print("patched:", path)

nl = "\r\n" if "\r\n" in open(root + r"\drivers\streamline\streamline_context.h", encoding="utf-8", newline="").read() else "\n"
patch(r"drivers\streamline\streamline_context.h",
      "\tint dlssg_delay = 0;" + nl,
      "\tint dlssg_delay = 0;" + nl + nl +
      "\t// Counted where dlss.cpp evaluates a feature successfully, for Streamline.get_status()." + nl +
      "\tuint64_t dlss_evaluations = 0;" + nl +
      "\tuint64_t dlss_rr_evaluations = 0;" + nl +
      "\tint dlss_render_width = 0;" + nl +
      "\tint dlss_render_height = 0;" + nl +
      "\tint dlss_output_width = 0;" + nl +
      "\tint dlss_output_height = 0;" + nl,
      "dlss_rr_evaluations")

p = root + r"\servers\rendering\renderer_rd\effects\dlss.cpp"
s = open(p, encoding="utf-8", newline="").read()
nl2 = "\r\n" if "\r\n" in s else "\n"
rec = lambda kind: (nl2 + "\t\t\tStreamlineContext::get()." + kind + "++;" + nl2 +
    "\t\t\tStreamlineContext::get().dlss_render_width = p_params.internal_size.x;" + nl2 +
    "\t\t\tStreamlineContext::get().dlss_render_height = p_params.internal_size.y;" + nl2 +
    "\t\t\tStreamlineContext::get().dlss_output_width = context->currentDlssOptions.outputWidth;" + nl2 +
    "\t\t\tStreamlineContext::get().dlss_output_height = context->currentDlssOptions.outputHeight;")
a = 'ERR_FAIL_MSG("Failed to call streamline slEvaluateFeature for DLSS Ray Reconstruction. Result: " + String(StreamlineContext::result_to_string(result)));' + nl2 + "\t\t\t}"
b = 'ERR_FAIL_MSG("Failed to call streamline slEvaluateFeature for DLSS Super Resolution. Result: " + String(StreamlineContext::result_to_string(result)));' + nl2 + "\t\t\t}"
if "dlss_rr_evaluations++" not in s:
    assert s.count(a) == 1 and s.count(b) == 1
    s = s.replace(a, a + rec("dlss_rr_evaluations")).replace(b, b + rec("dlss_evaluations"))
    open(p, "w", encoding="utf-8", newline="").write(s)
    print("patched: dlss.cpp")
else:
    print("already: dlss.cpp")

p = root + r"\drivers\streamline\streamline.h"
s = open(p, encoding="utf-8", newline="").read()
nl3 = "\r\n" if "\r\n" in s else "\n"
patch(r"drivers\streamline\streamline.h",
      "\tbool get_capability(StreamlineCapabilityType p_capability_type);" + nl3,
      "\tbool get_capability(StreamlineCapabilityType p_capability_type);" + nl3 +
      "\tDictionary get_status();" + nl3,
      "get_status")
patch(r"drivers\streamline\streamline.h",
      '#include "core/variant/variant.h"' + nl3,
      '#include "core/variant/dictionary.h"' + nl3 + '#include "core/variant/variant.h"' + nl3,
      "core/variant/dictionary.h")

p = root + r"\drivers\streamline\streamline.cpp"
s = open(p, encoding="utf-8", newline="").read()
nl4 = "\r\n" if "\r\n" in s else "\n"
patch(r"drivers\streamline\streamline.cpp",
      '\tClassDB::bind_method(D_METHOD("get_capability", "capability_type"), &Streamline::get_capability);' + nl4,
      '\tClassDB::bind_method(D_METHOD("get_capability", "capability_type"), &Streamline::get_capability);' + nl4 +
      '\tClassDB::bind_method(D_METHOD("get_status"), &Streamline::get_status);' + nl4,
      '"get_status"')
patch(r"drivers\streamline\streamline.cpp",
      "Streamline *Streamline::get_singleton() {",
      "// Whether DLSS really runs: successful evaluations so far (a script reads the rate), the last" + nl4 +
      "// render and output sizes, and whether frame generation holds a viewport." + nl4 +
      "Dictionary Streamline::get_status() {" + nl4 +
      "\tDictionary d;" + nl4 +
      "#ifdef STREAMLINE_ENABLED" + nl4 +
      "\tStreamlineContext &c = StreamlineContext::get();" + nl4 +
      '\td["dlss_evaluations"] = (int64_t)c.dlss_evaluations;' + nl4 +
      '\td["dlss_rr_evaluations"] = (int64_t)c.dlss_rr_evaluations;' + nl4 +
      '\td["render_size"] = Vector2i(c.dlss_render_width, c.dlss_render_height);' + nl4 +
      '\td["output_size"] = Vector2i(c.dlss_output_width, c.dlss_output_height);' + nl4 +
      '\td["frame_generation"] = c.dlssg_viewport != sl::ViewportHandle(-1);' + nl4 +
      "#endif" + nl4 +
      "\treturn d;" + nl4 +
      "}" + nl4 + nl4 +
      "Streamline *Streamline::get_singleton() {",
      "Streamline::get_status() {")