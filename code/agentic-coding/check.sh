#!/usr/bin/env bash
# Agentic coding course: everything here runs without an API key or an agent.
# The hook reads tool calls as JSON on stdin, the MCP server is driven by an MCP client, the config files are parsed.
set -uo pipefail
cd "$(dirname "$0")"
dotnet --version
mkdir -p out
status=0

compare() {
  if diff --strip-trailing-cr "$1" "$2"; then
    echo "ok   $3"
  else
    echo "FAIL $3"
    status=1
  fi
}

# Lesson 3: the PreToolUse hook, one JSON tool call per case
(
  cd hooks
  for call in cases/*.json; do
    dotnet run guard-git-push.cs < "$call" > /dev/null 2> ../out/stderr.txt
    code=$?
    echo "$(basename "$call" .json): exit $code"
    # The JSON parser's message is .NET's, not ours: keep only our prefix
    sed -E 's/(stdin is not JSON):.*/\1/' ../out/stderr.txt
  done
) > out/hooks.txt
compare hooks/expected.txt out/hooks.txt hooks

# Lesson 4: the MCP server, started over stdio by the SDK's client
dotnet build mcp/LearnMcp -c Release -m:4 --nologo -v q > out/build.txt 2>&1 || { cat out/build.txt; status=1; }
dotnet build mcp/LearnMcp.Check -c Release -m:4 --nologo -v q >> out/build.txt 2>&1 || { cat out/build.txt; status=1; }
dotnet mcp/LearnMcp.Check/bin/Release/net10.0/LearnMcp.Check.dll \
  mcp/LearnMcp/bin/Release/net10.0/LearnMcp.dll ../../src/content/docs > out/mcp.txt 2>&1
compare mcp/expected.txt out/mcp.txt mcp
# The same server, spoken to by hand: the legacy handshake, then the stateless revision of the protocol
for session in legacy stateless; do
  dotnet mcp/LearnMcp.Check/bin/Release/net10.0/LearnMcp.Check.dll raw \
    mcp/LearnMcp/bin/Release/net10.0/LearnMcp.dll ../../src/content/docs "mcp/$session.jsonl" > "out/$session.txt" 2>&1
  compare "mcp/expected-$session.txt" "out/$session.txt" "mcp $session"
done

# Lessons 3 and 4: the configuration files parse, and point to files that exist
python=python3
python3 -c '' 2> /dev/null || python=python
$python config/validate.py > out/config.txt 2>&1
compare config/expected.txt out/config.txt config

exit $status
