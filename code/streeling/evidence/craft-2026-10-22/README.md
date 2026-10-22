# Craft course transfer candidate

Status: draft review material on Learn's accepted source migration. Human subject, fluent-language and learner reviews remain open. No accepted course publication or public Learn readback is claimed.

## Review entry points

The three root courses teach a concrete IX-to-scene handoff:

- PHY-005: distinguish coordinate thickness, physical stock and proposed scene lengths.
- SEM-004: preserve the meaning of a selected face through a declared reindexing map.
- CS-009: compose flat-connected faces into panels before checking the global rigid-stack constraints.

Their EN/FR/ES sources live under `streeling/courses/`, with five answered exercises per source file: 45 pairs across nine root files. Seven supporting modules close the course dependency graph in their available languages. PT/IT/DE drafts and research cycles remain in the immutable [Demerzel archive](https://github.com/GuitarAlchemist/Demerzel/tree/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c), as required by Learn's merged source policy. `import.json` lists those 12 archive-only files and their exact blobs.

Hand-derived data for the three roots live under `code/streeling/fixtures/`. The production records, briefs, learner tasks, revised CS-009 task and raw AI responses below this directory are historical source-bound evidence. They are not canonical live production records or approval receipts: their source paths, word counts and locale inventories describe the archived Demerzel revision. The six-language manifests and earlier render reports are retained as historical reports; use `import.json` and `validation.json` for this Learn candidate.

## Provenance

`import.json` maps 46 original files from Demerzel `17f82a4b4b913d7c64942a3d3ff670abf4e6f85c`: 33 retain identical bytes, ten change only Markdown link destinations, and three PHY-005 status lines correctly identify PT/IT/DE drafts instead of claiming they are absent. The manifest records those exact prose corrections. Raw AI responses retain their original bytes and SHA-256 hashes.

Local links reach transferred lessons, fixtures or evidence. Three supporting observations remain pinned to the immutable archive; their anonymous readback matched the Git blobs in `public-source-readback.json`. There are 37 mapped relative references and 24 changed destinations.

The merged migration froze the initial whole-catalog copy at Demerzel `1beb0890faec827e1a9e5532abfdc97908de441d`. Its four fields in `streeling/source.json` remain unchanged. The optional supplement links this per-file manifest from all three generated overviews. Source/edit links target Learn `main` and resolve there after integration.

## Verification and remaining gates

`validation.json` records the craft-tranche verification at Learn `cf51371edc20692b9b103df29db39cdb960653a5`. At that revision, the generator produced 102 EN / 96 FR / 96 ES modules in 22 course departments. Later supplements can increase those counts; consult their validation receipts for cumulative results. This includes IX Research from merged `main`; the original goal remains 25 courses in each of the original 21 departments, or 525 courses.

The source-copy/generator suite passes all 17 tests, including a provenance regression observed failing before its implementation. The final build and rendered article-link results are recorded in `validation.json`. Existing dependencies were reused; there is no fresh `npm ci` proof.

The previous static AI review found no retained defects in the prototype-based import, but its formal run was degraded by a rejected cleanup operation. It did not cover this new-base adaptation. The final delta audit is recorded separately and grants no human or language approval. The personal journals lack these candidate entries and contain no invented study outcomes.

Before accepted publication: obtain source-bound subject and fluent-language verdicts and learner trials, integrate the reviewed sources, deploy and read back the public Learn revision. AUD-001's human reviewer remains for the user to designate.
