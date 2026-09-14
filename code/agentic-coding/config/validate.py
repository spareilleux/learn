# Parses the example configuration files of lessons 3 and 4 and checks that every file they point to exists.
# The paths in these files are relative to the root of the repository, where Claude Code and Codex start.
import json
import re
import sys
import tomllib
from pathlib import Path

here = Path(__file__).parent
root = here.parents[2]
problems = 0


def report(ok, message):
    global problems
    print(("ok   " if ok else "FAIL ") + message)
    problems += not ok


def paths_in(command):
    # Words that look like repository paths: they contain a slash and no shell syntax
    words = re.findall(r'"([^"]+)"|(\S+)', command)
    for quoted, bare in words:
        word = (quoted or bare).replace("${CLAUDE_PROJECT_DIR}/", "").replace("$(git rev-parse --show-toplevel)/", "")
        if "/" in word and not word.startswith("-") and "$" not in word:
            yield word


def check_paths(label, words):
    for word in words:
        report((root / word).exists(), f"{label}: {word} exists")


# Claude Code: .mcp.json
mcp = json.loads((here / "claude" / ".mcp.json").read_text(encoding="utf-8"))
for name, server in mcp["mcpServers"].items():
    report(server.get("type", "stdio") in ("stdio", "http") and "command" in server, f"claude .mcp.json: server {name} is stdio with a command")
    check_paths(f"claude .mcp.json: {name}", [a for a in server.get("args", []) if "/" in a])

# Claude Code: .claude/settings.json
settings = json.loads((here / "claude" / "settings.json").read_text(encoding="utf-8"))
rule = re.compile(r"^(mcp__\w+(__\w+)?|[A-Z]\w*(\(.+\))?)$")
for kind in ("allow", "ask", "deny"):
    for entry in settings.get("permissions", {}).get(kind, []):
        report(bool(rule.match(entry)), f"claude settings.json: {kind} rule {entry}")
for event, groups in settings["hooks"].items():
    for group in groups:
        for handler in group["hooks"]:
            report(handler["type"] == "command", f"claude settings.json: {event} {group['matcher']} is a command hook")
            check_paths(f"claude settings.json: {event}", paths_in(handler["command"]))

# Codex: .codex/config.toml
config = tomllib.loads((here / "codex" / "config.toml").read_text(encoding="utf-8"))
for name, server in config["mcp_servers"].items():
    report("command" in server, f"codex config.toml: mcp_servers.{name} has a command")
    check_paths(f"codex config.toml: {name}", [a for a in server.get("args", []) if "/" in a])
for event, groups in config["hooks"].items():
    for group in groups:
        for handler in group["hooks"]:
            report(handler["type"] == "command" and "command_windows" in handler, f"codex config.toml: {event} {group['matcher']} has command and command_windows")
            check_paths(f"codex config.toml: {event}", paths_in(handler["command"]))
            check_paths(f"codex config.toml: {event} (Windows)", paths_in(handler["command_windows"]))

# Skills: the same SKILL.md works in .claude/skills (Claude Code) and .agents/skills (Codex)
for skill in sorted((here / "skills").glob("*/SKILL.md")):
    text = skill.read_text(encoding="utf-8")
    front = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    fields = dict(line.split(":", 1) for line in front.group(1).splitlines()) if front else {}
    folder = skill.parent.name
    report(fields.get("name", "").strip() == folder, f"skill {folder}: name matches the folder")
    report(bool(fields.get("description", "").strip()), f"skill {folder}: has a description")
    report(len(text.splitlines()) <= 500, f"skill {folder}: {len(text.splitlines())} lines, under 500")

sys.exit(1 if problems else 0)
