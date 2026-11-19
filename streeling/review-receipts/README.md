# Streeling review receipts

A receipt records one verdict on one exact text: a module file of [`../courses/`](../courses/), in one language, at
one Git blob. It is what the pages read. `npm run sync:streeling` shows a verdict on a module page only while the file
it names still has the blob it names, so a page never claims a review for a text nobody reviewed.

No receipt exists yet: no reviewer has given a verdict. Until one does, every page says that no review of its text is
recorded.

## One file per verdict

`<code>-<language>-<kind>-<date>.json`, for example `psy-004-fr-language-2026-11-20.json`. The name is for people;
the generator reads only the fields. The format is [`../schemas/review-receipt.schema.json`](../schemas/review-receipt.schema.json):

```json
{
  "source": "streeling/courses/psychohistory/fr/psy-004-how-large-is-large.fr.md",
  "blob": "<40 hex digits>",
  "kind": "language",
  "reviewer": "<name or agreed pseudonym>",
  "date": "2026-11-20",
  "verdict": "approved",
  "evidence": "https://github.com/spareilleux/learn/issues/<n>",
  "findings": "Optional, a few sentences."
}
```

- `source` is the reviewed file. Its path gives the module and the language, so a verdict on the French text says
  nothing about the English or Spanish one.
- `blob` is the Git blob id of the text the reviewer read: `git rev-parse <commit>:<source>` for the commit they
  reviewed, or `git hash-object <source>` on a checkout of it. The blobs that the review briefs in
  [`../reviews/`](../reviews/) name are Demerzel's, not this repository's.
- `kind`:
  - `subject`: a reviewer who knows the discipline checked the content, following the module's review brief;
  - `language`: a fluent speaker checked the language of this text;
  - `learner`: a learner attempted the module's learner task.
- `date` is the UTC date of the verdict.
- `verdict` is `approved`, `changes_requested` or `not_assessed`, the three a brief allows.
- `evidence` is where the review itself can be read.

A site owner's own study of a module is not a receipt. It goes in the Streeling journal.

## What the pages show

For each module page, the generator takes the receipts whose `source` is that page's file:

- of those whose `blob` is the file's current blob, the latest of each kind, with its verdict, reviewer, date and
  evidence;
- otherwise, that no review of the text is recorded;
- and how many verdicts were given on earlier texts of the file, for a kind with no verdict on the current one.

A receipt with a missing or malformed field shows nothing, and the page stays pending.

The Streeling overview counts the lesson pages that show a review, in the three languages.

Editing a reviewed file changes its blob, so its verdict stops showing at the next sync. Add a receipt for the new
blob once someone has reviewed the change. Keep the old receipt: it is the record of the earlier review.

## Checks

`python scripts/check-streeling-records.py` checks every receipt against the schema. It also checks that the file it
names exists and is named for its language folder, and that its date is no later than today. The Streeling workflow
runs it, and `node --test scripts/tests/sync-streeling.test.mjs` covers what the pages show.
