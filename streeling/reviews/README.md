# Streeling review packets

One pair per module:

- `<code>-review-brief.md` is the bounded review a reviewer follows: the frozen target, the checks to rerun, the
  questions to challenge, and what a verdict must record;
- `<code>-learner-task.md` is the answer-free transfer task the reviewer hands to a learner.

No verdict exists yet. Each brief says so and keeps the review and publication flags of its production record, in
[`../course-productions/`](../course-productions/), false until one is recorded.

## Their targets are Demerzel files

These packets were written in GuitarAlchemist/Demerzel and copied here unchanged from commit `1beb089`. They name
their targets by Demerzel path and Git blob id:

| The brief names | Now in this repository |
|---|---|
| `state/streeling/courses/<department>/en/<module>.md` | `streeling/courses/<department>/en/<module>.md` |
| `state/streeling/fixtures/<department>/<module>/` and `scripts/streeling_fixtures/<department>/<module>/` | `code/streeling/<department>/<module>/` |
| `state/streeling/course-productions/<record>.json` | `streeling/course-productions/<record>.json` |

The files here are not those blobs. Of the 22 briefs, 6 name the course blob that Demerzel still had at `1beb089`,
and none names the one in this repository: the copy pinned the links that leave the course corpus, and the fixture
links now point at `code/streeling/`. The fixture programs also find their folder differently, and `extract.py`
needs `--repo-root <Demerzel clone>`. As each brief says, review that diff before extending a verdict to the files
here. To read a pinned blob, `git -C <Demerzel clone> cat-file -p <blob>`.

`python scripts/check-streeling-records.py` checks that every brief has its learner task, that each names an
English module, and that their links resolve.
