---
title: 10. Writing your own action
description: A JavaScript action without dependencies and a container action — inputs as INPUT_ variables, outputs, what the runner checks and what it doesn't, and three real failures.
sidebar:
  order: 10
---

## Three kinds of actions

[Lesson 6](../06-reuse/) wrote a composite action: YAML steps. The two other kinds run **code**:

| | Composite | JavaScript | Docker container |
|---|---|---|---|
| `runs.using` | `composite` | `node24` (or `node20`) | `docker` |
| Runs | steps in the caller's job | `node` on the runner | a container built or pulled on the runner |
| Operating systems | all | all | "can only execute on runners with a Linux operating system" |
| Inputs | `${{ inputs.x }}` | `INPUT_X` environment variables | `INPUT_X` variables and `args` |
| Startup cost | none | none | building or pulling the image |
| C# analogy | a method made of other method calls | a small console app | a console app shipped with its own OS |
| Azure Pipelines | step template | custom task (Node) | container job |

Both examples below live in this repository and are tested by [`.github/workflows/gha-10-action.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-10-action.yml).

## A JavaScript action without dependencies

The same slug function as the .NET and Java code of [lesson 2](../02-build-and-test/), as an action. [`.github/actions/slugify/action.yml`](https://github.com/spareilleux/learn/blob/main/.github/actions/slugify/action.yml):

```yaml
# GitHub Actions course, lesson 10: a JavaScript action without dependencies
name: Slugify
description: Turns a title into a URL slug, like the sample code of lesson 2.

inputs:
  text:
    description: The text to turn into a slug
    required: true
  max-length:
    description: Maximum length of the slug, 0 for no limit
    default: '0'

outputs:
  slug:
    description: The slug

runs:
  using: node24
  main: index.js
```

[`index.js`](https://github.com/spareilleux/learn/blob/main/.github/actions/slugify/index.js):

```js
// GitHub Actions course, lesson 10: inputs arrive as INPUT_<NAME> variables, outputs go to the GITHUB_OUTPUT file
import fs from "node:fs";

function input(name, { required = false } = {}) {
  const variable = `INPUT_${name.replace(/ /g, "_").toUpperCase()}`;
  const value = (process.env[variable] ?? "").trim();
  if (required && value === "") {
    throw new Error(`Input required and not supplied: ${name}`);
  }
  return value;
}

function slugify(text) {
  return text
    .normalize("NFD")
    .replace(/\p{Mn}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

try {
  const text = input("text", { required: true });
  const maxLength = Number(input("max-length") || "0");
  let slug = slugify(text);
  if (maxLength > 0) {
    slug = slug.slice(0, maxLength).replace(/-+$/, "");
  }
  console.log(`slug of "${text}" is "${slug}"`);
  fs.appendFileSync(process.env.GITHUB_OUTPUT, `slug=${slug}\n`);
} catch (error) {
  console.log(`::error::${error.message}`);
  process.exitCode = 1;
}
```

- The runner passes each input as an environment variable: "converts input names to uppercase letters and replaces spaces with `_` characters" ([`Runner.Worker/Handlers/Handler.cs`](https://github.com/actions/runner/blob/v2.337.0/src/Runner.Worker/Handlers/Handler.cs#L181-L187)). Hyphens stay: `max-length` becomes `INPUT_MAX-LENGTH`, a name bash can't read as `$INPUT_MAX-LENGTH` but Node can.
- Outputs use the same `$GITHUB_OUTPUT` file as `run:` steps ([lesson 4](../04-expressions-and-outputs/)); errors use the same `::error::` workflow command.
- Most real actions use the [`@actions/core`](https://github.com/actions/toolkit/tree/main/packages/core) package for this (`core.getInput`, `core.setOutput`, `core.setFailed`), and then must commit `node_modules` or a bundled `dist/index.js`: the runner doesn't run `npm install`. Without dependencies, there's nothing to bundle.

Because the action is just a script, test it locally before any push, with the variables the runner would set:

```powershell
$env:INPUT_TEXT = "C# 14 & .NET 10"; $env:GITHUB_OUTPUT = "out.txt"; node .github/actions/slugify/index.js
```

```text
slug of "C# 14 & .NET 10" is "c-14-net-10"
```

The same three cases as the .NET and Java tests gave `hello-world`, `github-actions` and `c-14-net-10`; an empty text gave `::error::Input required and not supplied: text` and exit code 1.

### Using it

From [`.github/workflows/gha-10-action.yml`, lines 23-29](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-10-action.yml#L23-L29):

```yaml
      - id: slug
        uses: ./.github/actions/slugify
        with:
          text: GitHub Actions course, lesson 10 — Wörld!
          max-length: 30
      - shell: bash
        run: echo "slug output = ${{ steps.slug.outputs.slug }}"
```

On the three operating systems:

```text
javascript (ubuntu-latest)  | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (windows-latest) | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (macos-latest)   | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (ubuntu-latest)  | slug output = github-actions-course-lesson-1
```

Same result everywhere, and the action step took under a second. Note the `1`: `max-length: 30` cut `10` in half. The code does exactly what it says; whether a slug should stop at a word boundary is a specification question the test didn't ask.

## A container action

[`.github/actions/hello-container`](https://github.com/spareilleux/learn/tree/main/.github/actions/hello-container) has three files:

[`.github/actions/hello-container/action.yml`](https://github.com/spareilleux/learn/blob/main/.github/actions/hello-container/action.yml):

```yaml
# GitHub Actions course, lesson 10: a container action (Linux runners only)
name: Hello from a container
description: Prints the operating system of the container it runs in.

inputs:
  who:
    description: Who to greet
    default: world

runs:
  using: docker
  image: Dockerfile
  args:
    - ${{ inputs.who }}
```

[`.github/actions/hello-container/Dockerfile`](https://github.com/spareilleux/learn/blob/main/.github/actions/hello-container/Dockerfile):

```dockerfile
# GitHub Actions course, lesson 10: the image of the container action, built on the runner at every run
FROM alpine:3.22
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

[`.github/actions/hello-container/entrypoint.sh`](https://github.com/spareilleux/learn/blob/main/.github/actions/hello-container/entrypoint.sh):

```sh
#!/bin/sh
# GitHub Actions course, lesson 10: runs inside the container; the workspace is mounted at /github/workspace
set -e
echo "hello $1 from $(. /etc/os-release && echo "$PRETTY_NAME")"
echo "workdir: $(pwd)"
echo "INPUT_WHO=$INPUT_WHO"
echo "greeting=hello $1" >> "$GITHUB_OUTPUT"
```

### First run: permission denied

```text
##[command]/usr/bin/docker build -t 128b89:7c5dc9951c794fae826f3098f2786173 -f "/home/runner/work/learn/learn/./.github/actions/hello-container/Dockerfile" "/home/runner/work/learn/learn/.github/actions/hello-container"
...
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "/entrypoint.sh": permission denied
```

The file was written on Windows, where Git doesn't track the executable bit (`git config core.filemode` → `false`), so it was committed as `100644` — left that way on purpose, to capture this error, which every Windows author of a container action meets once. The fix is in Git, not in the Dockerfile:

```powershell
git update-index --chmod=+x .github/actions/hello-container/entrypoint.sh
git diff --cached --summary
```

```text
 mode change 100644 => 100755 .github/actions/hello-container/entrypoint.sh
```

### Second run

```text
hello Grace from Alpine Linux v3.22
workdir: /github/workspace
INPUT_WHO=Grace
greeting output = hello Grace
```

The runner's `docker run` command shows how the container sees the job:

```text
-v "/var/run/docker.sock":"/var/run/docker.sock"
-v "/home/runner/work/_temp":"/github/runner_temp"
-v "/home/runner/work/_temp/_github_home":"/github/home"
-v "/home/runner/work/_temp/_github_workflow":"/github/workflow"
-v "/home/runner/work/_temp/_runner_file_commands":"/github/file_commands"
-v "/home/runner/work/learn/learn":"/github/workspace"
```

The workspace is mounted, so the container can read the checked-out code, and `$GITHUB_OUTPUT` points into the mounted `file_commands` folder, so outputs work. The step took 5 seconds, most of it building the image — against under a second for the JavaScript action. A published container action usually points `image:` to a prebuilt image (`docker://ghcr.io/…`) to skip the build.

## Publishing, briefly

An action in its own public repository, with `action.yml` at the root, is used as `owner/repo@v1`. The conventions, from [Manage custom actions](https://docs.github.com/actions/how-tos/create-and-publish-actions/manage-custom-actions): release with semantic version tags (`v1.2.0`) and move a major tag (`v1`) to the latest compatible release — the moving tag that [lesson 7](../07-security/) advises consumers not to trust blindly. Listing it on the Marketplace is optional. *Not done in this course*: the actions here stay local.

## Key takeaways

- JavaScript actions run on all runners and start instantly; container actions bring their own Linux and run only on Linux runners.
- Inputs arrive as `INPUT_<NAME>` variables (uppercase, hyphens kept); outputs and errors use `$GITHUB_OUTPUT` and workflow commands, like any step.
- The runner doesn't enforce `required: true`: the action must check.
- Commit what the action needs to run: no `npm install` on the runner, executable bits for scripts, and mind the repository's `package.json`.

## Exercises

1. A workflow passes `txt: Hello` instead of `text: Hello` to the slugify action. What does the runner do with the unknown input, and with the missing required one?

<details>
<summary>Solution</summary>

From [`gha-10-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-10-exercises.yml):

```text
##[warning]Unexpected input(s) 'txt', valid inputs are ['text', 'max-length']
##[error]Input required and not supplied: text
```

The unknown input only produces a **warning**, and the step ran anyway. The error comes from the action's own code: "Actions using `required: true` will not automatically return an error if the input is not specified." Without the check in `index.js`, the action would have produced an empty slug and a green step.

</details>

2. What happens when `hello-container` is used in a `windows-latest` job?

<details>
<summary>Solution</summary>

```text
##[error]Container action is only supported on Linux
```

The step fails immediately, before any build. An action meant for all three operating systems must be JavaScript or composite.

</details>

3. The first version of `index.js` started with `const fs = require("node:fs");`, valid Node.js. Would it run on the runner?

<details>
<summary>Solution</summary>

```text
ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and '/home/runner/work/learn/learn/package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
```

Node looks for the nearest `package.json` above the script, and in this repository that's the Astro site's, which declares `"type": "module"`. No. The error above comes from the runner, running the [`exercise-commonjs`](https://github.com/spareilleux/learn/tree/main/.github/actions/exercise-commonjs) copy; the same error had appeared locally first. Fixes: `import` syntax (chosen here), an `index.cjs` file, or a `package.json` in the action's folder. In a dedicated action repository, you control that file.

</details>

## Sources

- [About custom actions](https://docs.github.com/actions/concepts/workflows-and-actions/custom-actions)
- [Metadata syntax reference: inputs and `runs`](https://docs.github.com/actions/reference/workflows-and-actions/metadata-syntax)
- [Create a JavaScript action](https://docs.github.com/actions/tutorials/create-actions/create-a-javascript-action)
- [Manage custom actions](https://docs.github.com/actions/how-tos/create-and-publish-actions/manage-custom-actions)
- [Publish actions in GitHub Marketplace](https://docs.github.com/actions/how-tos/create-and-publish-actions/publish-in-github-marketplace)
- [`actions/toolkit`](https://github.com/actions/toolkit)
