"""The memory rule, checked before every submission.

R2's rule for this machine (journal of the ComfyUI course, lesson 8, and the lane brief): a server only gets a
workflow when the weights it loads, plus an 8 GB margin, fit in the free RAM. With dynamic VRAM (ComfyUI v0.36.0
on NVIDIA, on by default) every model is staged in system memory and moves to the GPU as needed, so free RAM is
the limit that stopped earlier runs, not VRAM. The machine rule of common.md adds a VRAM floor: 10 GB free before
a batch starts.

    estimate = size of the model files not yet loaded by this run + margin (8 GB) + extra_memory_gb
    refuse when estimate > ram_free (from /system_stats)
    refuse when nothing is loaded yet by this run and vram_free < min_free_vram (10 GB)

Limits: the file size is the size of the weights on disk; a model loaded in another dtype takes more or less.
The margin stands for activations, latents and the Python process. ram_free is what the OS reports as available
(psutil.virtual_memory().available in ComfyUI), for the whole machine. Models loaded by an earlier run of the same
server are counted again, which errs on the safe side.
"""

GIB = 1024 ** 3


def first_device(stats):
    devices = stats.get("devices") or []
    return devices[0] if devices else {}


def check(models, stats, loaded, margin_gb=8.0, extra_gb=0.0, min_free_vram_gb=10.0):
    new = [m for m in models if (m["folder"], m["name"]) not in loaded]
    weights = sum(m["bytes"] or 0 for m in new)
    estimate = weights + int((margin_gb + extra_gb) * GIB)
    ram_free = int(stats.get("system", {}).get("ram_free") or 0)
    device = first_device(stats)
    vram_free = device.get("vram_free")
    reasons = []
    if estimate > ram_free:
        reasons.append(
            f"memory rule: {len(new)} model file(s) of {weights / GIB:.2f} GB + {margin_gb + extra_gb:.1f} GB margin "
            f"= {estimate / GIB:.2f} GB, but the server reports {ram_free / GIB:.2f} GB of free RAM")
    if not loaded and device.get("type") == "cuda" and vram_free is not None and vram_free < min_free_vram_gb * GIB:
        reasons.append(f"memory rule: {vram_free / GIB:.2f} GB of free VRAM, below the {min_free_vram_gb:.1f} GB floor")
    return {
        "ok": not reasons,
        "new_models": [m["name"] for m in new],
        "weights_bytes": weights,
        "estimate_bytes": estimate,
        "ram_free_bytes": ram_free,
        "vram_free_bytes": vram_free,
        "margin_gb": margin_gb,
        "extra_gb": extra_gb,
        "reasons": reasons,
    }
