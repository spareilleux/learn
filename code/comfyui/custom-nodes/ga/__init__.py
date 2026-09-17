"""Guitar Alchemist nodes for ComfyUI: chord diagrams, fretboard control maps and mode prompts.

ComfyUI imports this file from custom_nodes/<folder>/__init__.py and reads NODE_CLASS_MAPPINGS; there is no
WEB_DIRECTORY, so the pack adds no JavaScript to the browser.
"""

from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS

__all__ = ["NODE_CLASS_MAPPINGS", "NODE_DISPLAY_NAME_MAPPINGS"]
