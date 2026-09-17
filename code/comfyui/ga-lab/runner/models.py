"""The model files a workflow loads: where they are, their size and their SHA-256.

The runner can't read file sizes through ComfyUI's API, so it looks for the files under --models-dir, the same
folders the server was started with (models/checkpoints, models/diffusion_models, ...). Hashes are cached in a
JSON file keyed by path, size and modification time: hashing SDXL (6.9 GB) once takes tens of seconds.
"""
import json
import os

from .experiment import sha256_file

# class_type -> {input name: model folder}
LOADERS = {
    "CheckpointLoaderSimple": {"ckpt_name": "checkpoints"},
    "CheckpointLoader": {"ckpt_name": "checkpoints"},
    "UNETLoader": {"unet_name": "diffusion_models"},
    "CLIPLoader": {"clip_name": "text_encoders"},
    "DualCLIPLoader": {"clip_name1": "text_encoders", "clip_name2": "text_encoders"},
    "VAELoader": {"vae_name": "vae"},
    "LoraLoader": {"lora_name": "loras"},
    "LoraLoaderModelOnly": {"lora_name": "loras"},
    "ControlNetLoader": {"control_net_name": "controlnet"},
    "UpscaleModelLoader": {"model_name": "upscale_models"},
    "CLIPVisionLoader": {"clip_name": "clip_vision"},
}
# Older folder names ComfyUI still reads (folder_paths.py maps them to the same list).
ALIASES = {"diffusion_models": ["unet"], "text_encoders": ["clip"], "controlnet": ["t2i_adapter"]}
# VAELoader names that are not files.
BUILTIN = {"pixel_space", "taesd", "taesdxl", "taesd3", "taef1"}


def referenced_models(prompt):
    """Sorted unique (folder, name) pairs of the models a prompt loads."""
    found = set()
    for node in prompt.values():
        for name, folder in LOADERS.get(node.get("class_type"), {}).items():
            value = node.get("inputs", {}).get(name)
            if isinstance(value, str) and value not in BUILTIN:
                found.add((folder, value))
    return sorted(found)


def locate(models_dirs, folder, name):
    for root in models_dirs:
        for sub in [folder] + ALIASES.get(folder, []):
            candidate = os.path.join(root, sub, name)
            if os.path.isfile(candidate):
                return candidate
    return None


class HashCache:
    def __init__(self, path):
        self.path = path
        self.entries = {}
        if path and os.path.isfile(path):
            with open(path, encoding="utf-8") as f:
                self.entries = json.load(f)

    def sha256(self, file):
        st = os.stat(file)
        key = f"{os.path.abspath(file)}|{st.st_size}|{st.st_mtime_ns}"
        if key not in self.entries:
            self.entries[key] = sha256_file(file)
            if self.path:
                os.makedirs(os.path.dirname(self.path) or ".", exist_ok=True)
                tmp = self.path + ".tmp"
                with open(tmp, "w", encoding="utf-8") as f:
                    json.dump(self.entries, f, indent=1)
                os.replace(tmp, self.path)
        return self.entries[key]


def describe(prompt, models_dirs, hashes=None):
    """[{folder, name, path, bytes, sha256}] with path None for a file that isn't under any models dir."""
    result = []
    for folder, name in referenced_models(prompt):
        path = locate(models_dirs, folder, name)
        entry = {"folder": folder, "name": name, "path": path, "bytes": None, "sha256": None}
        if path:
            entry["bytes"] = os.path.getsize(path)
            if hashes is not None:
                entry["sha256"] = hashes.sha256(path)
        result.append(entry)
    return result
