#!/bin/sh
# GitHub Actions course, lesson 10: runs inside the container; the workspace is mounted at /github/workspace
set -e
echo "hello $1 from $(. /etc/os-release && echo "$PRETTY_NAME")"
echo "workdir: $(pwd)"
echo "INPUT_WHO=$INPUT_WHO"
echo "greeting=hello $1" >> "$GITHUB_OUTPUT"
