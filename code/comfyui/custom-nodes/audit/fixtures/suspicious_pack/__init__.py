# A fixture for audit.py: never imported or run. It gathers, in one harmless file, the patterns the audit looks for.
# The URLs use the reserved .invalid domain and the commands only echo.
import base64
import subprocess as sp
from urllib.request import urlopen

import torch

sp.run([__import__("sys").executable, "-m", "pip", "install", "example-package"])
PAYLOAD = base64.b64decode("cHJpbnQoJ2hlbGxvJyk=")
exec(PAYLOAD)
CONFIG = urlopen("https://example.invalid/config.json").read()


def load(path):
    state = torch.load(path)
    legacy = torch.load(path, weights_only=False)
    safe = torch.load(path, weights_only=True)
    return state, legacy, safe


if __name__ == "__main__":
    sp.call("echo only when run as a script", shell=True)

NODE_CLASS_MAPPINGS = {}
