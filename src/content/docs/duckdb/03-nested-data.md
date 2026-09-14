---
title: 3. Nested data
description: Lists and structs from JSON, unnest to turn a list into rows, lambdas to filter lists in place, ANTI JOIN, and building nested values — on the jobs and steps of this site's CI.
sidebar:
  order: 3
---

The runs of lessons 1 and 2 are flat: one value per field. Their jobs aren't. The queries are in [`sql/03-nested-data.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/03-nested-data.sql).

## The jobs file

`data/jobs.json` holds the 315 jobs of the runs, as returned by the GitHub REST API endpoint [List jobs for a workflow run](https://docs.github.com/rest/actions/workflow-jobs), with a subset of the fields. For a run that was re-run, the API returns only the jobs of the latest attempt: 4 jobs for the `GHA 09: debugging` run attempted three times, where `?filter=all` returns 12. One job, shortened:

```json
{
  "id": 104004920113,
  "run_id": 34852867099,
  "name": "build",
  "conclusion": "success",
  "started_at": "2026-09-14T14:01:14Z",
  "labels": ["ubuntu-latest"],
  "steps": [
    {"number": 1, "name": "Set up job", "conclusion": "success", "started_at": "2026-09-14T14:01:15Z", "completed_at": "2026-09-14T14:01:19Z"},
    …
  ]
}
```

```sql
CREATE TABLE runs AS FROM 'data/runs.json';
CREATE TABLE jobs AS FROM 'data/jobs.json';
DESCRIBE jobs;
```

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                          jobs                                                          │
│                                                                                                                        │
│ id           bigint                                                                                                    │
│ run_id       bigint                                                                                                    │
│ name         varchar                                                                                                   │
│ status       varchar                                                                                                   │
│ conclusion   varchar                                                                                                   │
│ created_at   timestamp                                                                                                 │
│ started_at   timestamp                                                                                                 │
│ completed_at timestamp                                                                                                 │
│ runner_name  varchar                                                                                                   │
│ labels       varchar[]                                                                                                 │
│ steps        struct(number bigint, "name" varchar, conclusion varchar, started_at timestamp, completed_at timestamp)[] │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

The JSON reader turned the arrays into [`LIST`](https://duckdb.org/docs/current/sql/data_types/list) types, written `type[]`, and the objects into [`STRUCT`](https://duckdb.org/docs/current/sql/data_types/struct) types, with named and typed fields. `steps` is a list of structs. In C#, that's a `List<Step>` property on a `Job` record; in SQL Server, the JSON would stay a `nvarchar(max)` string, and every query would go through `OPENJSON` again.

## Reading into lists and structs

```sql
SELECT name, labels, labels[1] AS os, labels[0] AS index_zero, len(steps) AS steps, steps[1].name AS first_step
FROM jobs
ORDER BY id
LIMIT 3;
```

```text
┌─────────┬─────────────────┬───────────────┬────────────┬───────┬────────────┐
│  name   │     labels      │      os       │ index_zero │ steps │ first_step │
│ varchar │    varchar[]    │    varchar    │  varchar   │ int64 │  varchar   │
├─────────┼─────────────────┼───────────────┼────────────┼───────┼────────────┤
│ build   │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     6 │ Set up job │
│ deploy  │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     3 │ Set up job │
│ build   │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     6 │ Set up job │
└─────────┴─────────────────┴───────────────┴────────────┴───────┴────────────┘
```

- **Lists start at 1**, as everywhere in SQL. `labels[0]` isn't an error, just `NULL`, and so is any index past the end: a C# or Java habit that fails silently.
- `steps[1].name` reads a field of a struct with a dot, like a property.
- `len` counts the elements of a list.

## `unnest`: one row per element

[`unnest`](https://duckdb.org/docs/current/sql/query_syntax/unnest) turns a list into rows. Placed in the `FROM` clause after the table, it runs once per job, with access to that job's columns: the `CROSS APPLY OPENJSON(...)` of SQL Server, or `SelectMany` in LINQ.

```sql
SELECT j.name AS job, s.number, s.name AS step, s.completed_at - s.started_at AS took
FROM jobs j, unnest(j.steps) AS t(s)
WHERE j.id = 104004920113
ORDER BY s.number;
```

```text
┌─────────┬────────┬──────────────────────────────────────┬──────────┐
│   job   │ number │                 step                 │   took   │
│ varchar │ int64  │               varchar                │ interval │
├─────────┼────────┼──────────────────────────────────────┼──────────┤
│ build   │      1 │ Set up job                           │ 00:00:04 │
│ build   │      2 │ Checkout                             │ 00:00:02 │
│ build   │      3 │ Install, build, and upload site      │ 00:00:48 │
│ build   │      5 │ Post Install, build, and upload site │ 00:00:00 │
│ build   │      6 │ Post Checkout                        │ 00:00:01 │
│ build   │      7 │ Complete job                         │ 00:00:00 │
└─────────┴────────┴──────────────────────────────────────┴──────────┘
```

`AS t(s)` names the table `t` and its single column `s`, a struct. This is the build job of the deployment of this site: 48 of its 58 seconds are in the `withastro/action` step. Step 4 is missing from the API response itself (`gh run view 34852867099 --json jobs` shows the same numbers); probably an internal step of that composite action, *to verify*.

## Aggregating nested data

The same pattern as flat data, once the list is unnested. The job timestamps give a better duration than the run fields of lesson 2, and one more: the time spent **waiting** for a runner, from `created_at` to `started_at`.

```sql
SELECT labels[1] AS os, count(*) AS jobs,
       avg(started_at - created_at) AS avg_wait, avg(completed_at - started_at) AS avg_run
FROM jobs
GROUP BY ALL
ORDER BY os;
```

```text
┌────────────────┬───────┬─────────────────┬────────────────┐
│       os       │ jobs  │    avg_wait     │    avg_run     │
│    varchar     │ int64 │    interval     │    interval    │
├────────────────┼───────┼─────────────────┼────────────────┤
│ macos-latest   │    34 │ 00:00:08.470596 │ 00:00:55.67649 │
│ ubuntu-latest  │   246 │ 00:00:03.5      │ 00:00:21.43097 │
│ windows-latest │    35 │ 00:00:03.4      │ 00:01:36.71431 │
└────────────────┴───────┴─────────────────┴────────────────┘
```

macOS runners take more than twice as long to start; Windows jobs run more than four times longer than Ubuntu jobs. Not a fair comparison, since most Ubuntu jobs are small ones like the site deployment; exercise 3 compares the same job on the three systems.

## Lambdas: working on a list without unnesting it

Which steps fail most? Each job keeps its failed steps in its own list; [`list_filter`](https://duckdb.org/docs/current/sql/functions/list) keeps the elements for which a [lambda](https://duckdb.org/docs/current/sql/functions/lambda) is true, before `unnest` turns what's left into rows:

```sql
SELECT f.name AS failed_step, count(*) AS failures, list(DISTINCT r.workflowName ORDER BY r.workflowName) AS workflows
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id,
     unnest(list_filter(j.steps, lambda s: s.conclusion = 'failure')) AS t(f)
GROUP BY ALL
ORDER BY failures DESC, failed_step
LIMIT 5;
```

```text
┌───────────────────────────────────────┬──────────┬───────────────────────────────────────────────────────┐
│              failed_step              │ failures │                       workflows                       │
│                varchar                │  int64   │                       varchar[]                       │
├───────────────────────────────────────┼──────────┼───────────────────────────────────────────────────────┤
│ Formatting                            │        6 │ [Rust course examples]                                │
│ Run actions/setup-dotnet@v6           │        3 │ ['GHA 05: exercise checks']                           │
│ Run exit 3                            │        3 │ ['GHA 09: debugging', 'GHA 09: exercise checks']      │
│ Run ./.github/actions/hello-container │        2 │ ['GHA 10: custom actions', 'GHA 10: exercise checks'] │
│ Compile-fail doctests                 │        1 │ [Rust course examples]                                │
└───────────────────────────────────────┴──────────┴───────────────────────────────────────────────────────┘
```

- Two of the three Rust failures of lesson 2 were formatting, `cargo fmt --check`, on each of the three operating systems; the third was a compile-fail doctest. `Run actions/setup-dotnet@v6` is the missing lock file of the GitHub Actions course, lesson 5.
- `lambda s: s.conclusion = 'failure'` is the C# lambda `s => s.Conclusion == "failure"`. `list_transform` is `Select`, `list_filter` is `Where`, `list_reduce` is `Aggregate`.
- `list(… ORDER BY …)` is an aggregate that builds a list: `STRING_AGG` without the string. Some values are quoted in the display (`'GHA 05: exercise checks'`) and others aren't (`Rust course examples`): the quotes belong to the display, not to the values.

The arrow syntax found in older examples still works in 1.5.5, with a warning:

```text
WARNING:
Deprecated lambda arrow (->) detected. Please transition to the new lambda syntax, i.e.., lambda x, i: x + i, before DuckDB's next release.
Use SET lambda_syntax='ENABLE_SINGLE_ARROW' to revert to the deprecated behavior.
For more information, see https://duckdb.org/docs/stable/sql/functions/lambda.html.
```

## `ANTI JOIN`: rows without a match

125 runs in `runs.json`, but `count(DISTINCT run_id)` in `jobs` is 121. Which runs have no job? `NOT EXISTS` works, and so does DuckDB's [`ANTI JOIN`](https://duckdb.org/docs/current/sql/query_syntax/from), which reads like what it does:

```sql
SELECT r.workflowName, r.event, r.conclusion, r.createdAt
FROM runs r
ANTI JOIN jobs j ON j.run_id = r.databaseId
ORDER BY r.createdAt;
```

```text
┌──────────────────────────┬───────────────────┬─────────────────┬─────────────────────┐
│       workflowName       │       event       │   conclusion    │      createdAt      │
│         varchar          │      varchar      │     varchar     │      timestamp      │
├──────────────────────────┼───────────────────┼─────────────────┼─────────────────────┤
│ GHA 03: triggers         │ push              │ failure         │ 2026-09-14 12:45:24 │
│ GHA 03: triggers         │ push              │ failure         │ 2026-09-14 12:45:38 │
│ GHA 03: triggers         │ workflow_dispatch │ cancelled       │ 2026-09-14 12:47:19 │
│ GHA 06: undeclared input │ push              │ startup_failure │ 2026-09-14 13:24:30 │
└──────────────────────────┴───────────────────┴─────────────────┴─────────────────────┘
```

All four are in the [GitHub Actions course journal](../../github-actions/journal/): the two pushes of a workflow file with invalid YAML, a manual run cancelled by a newer one before its job started, and the workflow calling another with an undeclared input. A run can fail without running anything. `SEMI JOIN` is the opposite: the rows that **have** a match, each once, like `EXISTS`.

## Building nested values

The other direction: grouping rows into a list of structs, with a struct literal `{'key': value}`:

```sql
SELECT run_id, list({'job': name, 'conclusion': conclusion} ORDER BY name) AS jobs
FROM jobs
WHERE run_id = (SELECT databaseId FROM runs WHERE workflowName = 'GHA 10: exercise checks')
GROUP BY ALL;
```

```text
┌─────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│   run_id    │                                                                   jobs                                                                   │
│    int64    │                                                struct(job varchar, conclusion varchar)[]                                                 │
├─────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 34852035176 │ [{'job': commonjs, 'conclusion': failure}, {'job': container-on-windows, 'conclusion': failure}, {'job': inputs, 'conclusion': success}] │
└─────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

`to_json` turns any value into JSON text, for an API response or a file: `to_json({'job': 'commonjs', 'steps': [1, 2]})` gives `{"job":"commonjs","steps":[1,2]}`.

## Key takeaways

- JSON arrays become `LIST`, objects become `STRUCT`, with types; nested data stays queryable without parsing strings.
- Lists are indexed from 1, and an index out of range is `NULL`, not an error.
- `unnest` in the `FROM` clause turns a list into rows, like `CROSS APPLY` or `SelectMany`.
- `list_filter` and `list_transform` with `lambda x: …` work on a list in place.
- `ANTI JOIN` and `SEMI JOIN` say "without a match" and "with a match" directly.
- `list(…)` and `{'key': value}` build nested values back.

## Exercises

The solutions are in [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/03-exercises.sql), checked by CI.

1. Some jobs have no step at all. Which ones, and what's in their `runner_name`?

<details>
<summary>Solution</summary>

```sql
SELECT r.workflowName, j.name AS job, j.conclusion, j.runner_name, j.runner_name IS NULL AS runner_is_null
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id
WHERE len(j.steps) = 0
ORDER BY j.id;
```

```text
┌─────────────────────────────────────┬──────────────┬────────────┬─────────────┬────────────────┐
│            workflowName             │     job      │ conclusion │ runner_name │ runner_is_null │
│               varchar               │   varchar    │  varchar   │   varchar   │    boolean     │
├─────────────────────────────────────┼──────────────┼────────────┼─────────────┼────────────────┤
│ GHA 04: data between steps and jobs │ consume      │ skipped    │ NULL        │ true           │
│ Deploy to GitHub Pages              │ deploy       │ failure    │             │ false          │
│ GHA 09: exercise checks             │ job-timeout  │ skipped    │ NULL        │ true           │
│ GHA 09: exercise checks             │ step-timeout │ skipped    │ NULL        │ true           │
└─────────────────────────────────────┴──────────────┴────────────┴─────────────┴────────────────┘
```

Three skipped jobs, which never got a runner: `NULL`. And a `deploy` job that failed with no step: the deployment from a branch other than `main`, rejected by the environment's branch policy in the GitHub Actions course. It got an **empty string** as runner name, not `NULL`. `WHERE runner_name IS NULL` would miss it: check both, or `coalesce(runner_name, '') = ''`, whenever the source is someone else's JSON.

</details>

2. `SELECT name, unnest(steps, recursive := true) FROM jobs` expands each step struct into columns. The job has a `name`, and so does each step. What are the columns called?

<details>
<summary>Solution</summary>

In the CLI display, two columns are both called `name`. Referencing them from an outer query shows the real names:

```sql
SELECT name, name_1, conclusion
FROM (SELECT name, unnest(steps, recursive := true) FROM jobs WHERE id = 104004920113)
ORDER BY number
LIMIT 3;
```

```text
┌─────────┬─────────────────────────────────┬────────────┐
│  name   │             name_1              │ conclusion │
│ varchar │             varchar             │  varchar   │
├─────────┼─────────────────────────────────┼────────────┤
│ build   │ Set up job                      │ success    │
│ build   │ Checkout                        │ success    │
│ build   │ Install, build, and upload site │ success    │
└─────────┴─────────────────────────────────┴────────────┘
```

The [deduplication rule](https://duckdb.org/docs/current/sql/dialect/keywords_and_identifiers) keeps the first `name` and renames the next one `name_1`. And `conclusion` is the **step's**: the job has no `conclusion` in this subquery, since only `name` was selected. When both sides have fields in common, alias them explicitly, as the lesson does with `j.name AS job, s.name AS step`.

</details>

3. `GHA 02: build and test` builds the same .NET and Java projects on three operating systems. What's the slowest step on each?

<details>
<summary>Solution</summary>

```sql
SELECT j.labels[1] AS os, j.name AS job, s.name AS step, s.completed_at - s.started_at AS took
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id,
     unnest(j.steps) AS t(s)
WHERE r.workflowName = 'GHA 02: build and test'
QUALIFY row_number() OVER (PARTITION BY os ORDER BY took DESC, j.id, s.number) = 1
ORDER BY os;
```

```text
┌────────────────┬─────────────────────────┬─────────────────────────────┬──────────┐
│       os       │           job           │            step             │   took   │
│    varchar     │         varchar         │           varchar           │ interval │
├────────────────┼─────────────────────────┼─────────────────────────────┼──────────┤
│ macos-latest   │ dotnet (macos-latest)   │ Run actions/setup-dotnet@v6 │ 00:00:11 │
│ ubuntu-latest  │ java (ubuntu-latest)    │ Run mvn -B verify           │ 00:00:11 │
│ windows-latest │ dotnet (windows-latest) │ Run actions/setup-dotnet@v6 │ 00:00:31 │
└────────────────┴─────────────────────────┴─────────────────────────────┴──────────┘
```

On Windows and macOS, installing the .NET SDK costs more than any build or test. On Ubuntu, where it's faster, Maven's build and tests come first. `j.id, s.number` in the window's `ORDER BY` break ties: several steps can take the same whole number of seconds, and without a tie-breaker `row_number()` would pick one arbitrarily, possibly a different one on the next run.

</details>

## Sources

- [List](https://duckdb.org/docs/current/sql/data_types/list) and [struct](https://duckdb.org/docs/current/sql/data_types/struct) types
- [`unnest`](https://duckdb.org/docs/current/sql/query_syntax/unnest)
- [List functions](https://duckdb.org/docs/current/sql/functions/list) and [lambda functions](https://duckdb.org/docs/current/sql/functions/lambda)
- [`FROM` and joins, including `SEMI` and `ANTI`](https://duckdb.org/docs/current/sql/query_syntax/from)
- [Loading JSON](https://duckdb.org/docs/current/data/json/overview)
- [GitHub REST API: workflow jobs](https://docs.github.com/rest/actions/workflow-jobs)
