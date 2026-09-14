---
title: "7. Security: permissions, secrets, pinning, OIDC"
description: Least-privilege GITHUB_TOKEN, what masking does and doesn't, actions pinned to a commit SHA, OIDC tokens instead of cloud secrets, and a script injection run for real.
sidebar:
  order: 7
---

## What a workflow can do

A workflow runs code — yours and the actions' — with a token that can act on the repository, sometimes secrets, and sometimes cloud credentials. Four questions structure this lesson:

| Question | Tool | Azure Pipelines |
|---|---|---|
| What may the automatic token do? | `permissions:` | job authorization scope, project permissions |
| Where do secrets go, and who sees them? | `secrets`, masking | secret variables, variable groups |
| Is the action I run the one I reviewed? | pinning to a commit SHA | task versions |
| How do I reach a cloud without a stored password? | OpenID Connect (`id-token: write`) | workload identity federation service connections |

Everything below comes from [`.github/workflows/gha-07-security.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-07-security.yml). Its first lines ([lines 15-16](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L15-L16)):

```yaml
permissions:
  contents: read
```

## `GITHUB_TOKEN` permissions

Every job gets a `GITHUB_TOKEN`, valid for the job only. Its default permissions depend on a repository (or organization) setting; the *Set up job* step of every run of [lesson 1](../01-first-workflow/) listed them for this repository: `Contents: read`, `Metadata: read`, `Packages: read`. Don't rely on the setting: declare what the workflow needs, as above, and add more per job.

Two jobs call the same API — create a label with an **empty** name, so that nothing can be created — one without and one with `issues: write` ([lines 28-38](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L28-L38)):

```yaml
  token-with-issues-write:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
    steps:
      - name: Create a label with an empty name, token with issues:write
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh api --method POST "repos/$GITHUB_REPOSITORY/labels" -f name= || echo "gh exit code: $?"
```

```text
token-without-issues-write | Contents: read
token-without-issues-write | Metadata: read
token-without-issues-write | gh: Resource not accessible by integration (HTTP 403)

token-with-issues-write    | Contents: read
token-with-issues-write    | Issues: write
token-with-issues-write    | Metadata: read
token-with-issues-write    | gh: Validation Failed (HTTP 422)
```

- 403, *Resource not accessible by integration*: the token isn't allowed. That's the message to recognize when a workflow suddenly lacks a permission.
- 422, *Validation Failed*: the permission was granted, only the request was wrong.
- My first attempt used `gh run list`, which needs `actions: read`, from a job with `contents: read` only. It **worked**: on a public repository, reading public data doesn't need the permission. Test permissions with a write call.

The rule to remember, from the workflow syntax reference: "If you specify the access for any of these permissions, all of those that are not specified are set to `none`" — exercise 1.

## Secrets and masking

Secrets are stored in the repository, environment or organization settings and read with `${{ secrets.NAME }}`. [Lesson 4](../04-expressions-and-outputs/) showed that their values are replaced by `***` in the logs. Two more facts, tested in the `masking` job:

```text
echo "value=''"
value=''
```

A secret that doesn't exist is an **empty string**, without error or warning — "If a secret has not been set, the return value of an expression referencing the secret … will be an empty string". A typo in a secret name produces a job that runs with an empty password; check it at the start of the job (`test -n "$TOKEN"`).

A value **derived** from a secret isn't masked. Register it with the `add-mask` workflow command:

```text
before add-mask: 849f6dc993e40726
after add-mask:  ***
```

The first line is already in the log for good: masking only applies to what is printed after the command.

And forks: "With the exception of `GITHUB_TOKEN`, secrets are not passed to the runner when a workflow is triggered from a forked repository. The `GITHUB_TOKEN` has read-only permissions in pull requests from forked repositories." That's why a pull request from a fork can't deploy — and why the `pull_request_target` event, which runs with the base repository's secrets and a read/write token, must never check out and run the pull request's code.

## Script injection, for real

[Lesson 4](../04-expressions-and-outputs/) explained why `${{ }}` must not paste untrusted text into a script. Here it is on a runner. The `injection` job ([lines 84-94](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L84-L94)):

```yaml
  injection:
    runs-on: ubuntu-latest
    steps:
      - name: Unsafe, the expression is pasted into the script
        run: |
          echo "Title: ${{ inputs.title }}"
      - name: Safe, the value goes through the environment
        env:
          TITLE: ${{ inputs.title }}
        run: |
          echo "Title: $TITLE"
```

```powershell
gh workflow run gha-07-security.yml --field 'title=$(whoami)'
```

```text
Unsafe | echo "Title: $(whoami)"
Unsafe | Title: runner
Safe   | echo "Title: $TITLE"
Safe   |   TITLE: $(whoami)
Safe   | Title: $(whoami)
```

The unsafe step **ran** `whoami`: the input became part of the script before bash read it. The safe step printed the text. Replace `inputs.title` by a pull request title, an issue comment or a branch name, and anyone who can open a pull request runs commands with your token.

## Pinning actions

`uses: actions/checkout@v7` points to a **tag**, and a tag can be moved to another commit by whoever controls the action's repository. The documentation: "Pinning an action to a full-length commit SHA is currently the only way to use an action as an immutable release."

Find the commit behind a tag with the API:

```powershell
gh api repos/actions/checkout/commits/v7 --jq .sha
```

```text
3d3c42e5aac5ba805825da76410c181273ba90b1
```

From [`.github/workflows/gha-07-security.yml`, lines 53-57](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L53-L57):

```yaml
  pinned:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - run: git log -1 --format='%h %s'
```

```text
Download action repository 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1' (SHA:3d3c42e5aac5ba805825da76410c181273ba90b1)
```

The *Set up job* step of an unpinned run also logs the SHA it resolved — `Download action repository 'actions/checkout@v7' (SHA:3d3c42e5…)` in [lesson 5](../05-caches-and-artifacts/)'s runs — which tells you what ran, but not what will run next time. The comment `# v7.0.1` keeps the pin readable, and tools such as [Dependabot](https://docs.github.com/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot) update SHA and comment together. The other lessons keep tags so that the YAML stays readable; for workflows that hold secrets or deploy, pin.

## OpenID Connect instead of cloud secrets

To deploy to Azure, AWS or Google Cloud, the old way stores a long-lived key as a secret. With [OIDC](https://docs.github.com/actions/concepts/security/openid-connect), the job asks GitHub for a signed token describing **who** it is, and the cloud exchanges it for short-lived credentials if its trust policy matches. The job needs one permission ([lines 59-63](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L59-L63)):

```yaml
  oidc:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
```

The `oidc` job requests a token for the audience `learn-course` and prints its claims — never the token itself:

```text
iss: https://token.actions.githubusercontent.com
aud: learn-course
sub: repo:spareilleux@6644695/learn@1368550922:ref:refs/heads/main
repository: spareilleux/learn
ref: refs/heads/main
event_name: push
job_workflow_ref: spareilleux/learn/.github/workflows/gha-07-security.yml@refs/heads/main
runner_environment: github-hosted
lifetime: 300 s
```

- `sub` is what a cloud trust policy usually matches. It contains the owner and repository **IDs** (`@6644695`, `@1368550922`): "repositories created after July 15, 2026 now use an immutable default subject format that includes both the owner ID and repository ID". This repository was created on 2026-09-13. Older repositories keep `repo:owner/repo:ref:…` unless they opt in, and a trust policy written for one format doesn't match the other.
- The token lives 5 minutes (`exp - iat`).
- Without `id-token: write`, the `no-oidc` job printed `ACTIONS_ID_TOKEN_REQUEST_URL is not set`: no way to ask.

Configuring the cloud side (an Azure federated credential, for example) is outside this course; *to verify* in a deployment course.

## Key takeaways

- Declare `permissions:` at the top of every workflow, add per job; a 403 *Resource not accessible by integration* means a missing permission.
- A missing secret is an empty string; derived values need `::add-mask::`; forks get no secrets.
- Never paste untrusted `${{ }}` into `run:` — the injection ran `whoami` on a real runner.
- A tag can move, a commit SHA can't.
- OIDC replaces stored cloud keys: `id-token: write`, a 5-minute token, a `sub` claim to trust — in the immutable format for new repositories.

## Exercises

1. The workflow declares `permissions: contents: read`. A job declares `permissions: actions: read` and runs `actions/checkout`. What permissions does the job's token have, and does the checkout work on this public repository?

<details>
<summary>Solution</summary>

The job-level block **replaces** the workflow-level one; unspecified permissions become `none`. From [`gha-07-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-07-exercises.yml):

```text
GITHUB_TOKEN Permissions
Actions: read
Metadata: read
93a0ea8 GitHub Actions course: lesson 7 workflows (permissions, masking, pinning, OIDC, injection)
```

No `Contents` any more, and the checkout still worked: anyone can clone a public repository. On a private repository the same job would fail to fetch — *to verify*. Repeat every permission a job needs, including `contents: read`.

</details>

2. Run the injection job with the title `x"; echo INJECTED; echo "y`. What do the two steps print?

<details>
<summary>Solution</summary>

```text
Unsafe | echo "Title: x"; echo INJECTED; echo "y"
Unsafe | Title: x
Unsafe | INJECTED
Unsafe | y
Safe   | Title: x"; echo INJECTED; echo "y
```

The quote in the input closed the string of the unsafe step, and `echo INJECTED` became a separate command. The safe step printed the value unchanged, quotes included.

</details>

3. Pin `actions/setup-dotnet@v6`. Which command gives the SHA, and what's the line to write?

<details>
<summary>Solution</summary>

```powershell
gh api repos/actions/setup-dotnet/commits/v6 --jq .sha
```

```text
a98b56852c35b8e3190ac28c8c2271da59106c68
```

```yaml
      - uses: actions/setup-dotnet@a98b56852c35b8e3190ac28c8c2271da59106c68 # v6
```

It's the SHA the runner logged for `actions/setup-dotnet@v6` in lesson 5: `Download action repository 'actions/setup-dotnet@v6' (SHA:a98b56852c35b8e3190ac28c8c2271da59106c68)`. Prefer the full release tag in the comment (`# v6.x.y`) so that the update tool knows the exact version.

</details>

## Sources

- [Secure use reference](https://docs.github.com/actions/reference/security/secure-use)
- [Workflow syntax: `permissions`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#permissions)
- [Using secrets in GitHub Actions](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
- [Script injections](https://docs.github.com/actions/concepts/security/script-injections)
- [OpenID Connect](https://docs.github.com/actions/concepts/security/openid-connect) and the [OIDC reference](https://docs.github.com/actions/reference/security/oidc)
- [Events that trigger workflows: `pull_request_target`](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request_target)
