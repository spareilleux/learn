# Anonymous Streeling deployment readback

Observation: 2026-10-22, 01:56:01 through 01:56:51 UTC. Result: all 348 expected public HTML pages matched the uploaded deployment artifact exactly; no missing pages or mismatches were observed.

## Revision and artifact

- Learn revision: `09b13e7f9eddc2b4ddbd87356001c1da2eec6b58`.
- Successful deployment: [run 39702018408](https://github.com/spareilleux/learn/actions/runs/39702018408).
- Uploaded `github-pages` artifact: ID `12392898635`; its API record associates it with that run and revision.
- The artifact ZIP digest is server-reported and **not locally verified**. The extracted `artifact.tar` was read with `tarfile`; expected hashes below are hashes of each HTML member, not of the ZIP.
- A post-observation query still returned this run as the latest successful `deploy.yml` deployment. This is an observation at a time, not a perpetual freshness guarantee.

`artifact-api.json`, `deployment-api.json` and `latest-successful-deployments.json` preserve the GitHub responses used for this association. They contain no authentication headers or tokens.

## Coverage

| Cohort | Localized course pages | Department indexes | Shared pages | Total |
| --- | ---: | ---: | ---: | ---: |
| Original 21 departments | 273 | 63 | 0 | 336 |
| Shared overview and author journals | 0 | 0 | 6 | 6 |
| Additional IX Research department | 3 | 3 | 0 | 6 |
| Total | 276 | 66 | 6 | 348 |

The original cohort contains 91 distinct course modules, mirrored in English, French and Spanish. Translations and index pages do not increase the 525-course target. The added IX Research department is reported separately. Department registry entries with no generated tracked pages are outside this deployment-page inventory.

## Method and evidence

1. Enumerate every tracked generated Streeling Markdown page at the deployment revision using Git. Derive its public URL and HTML archive path. Do not use the current candidate branch's course count as the deployed inventory.
2. For each of the 276 course pages, bind the generated Markdown blob and canonical `streeling/courses/<department>/<locale>/...` authoring blob separately at that revision. Overview, index and journal pages retain their generated-page blob identity.
3. Read only the 348 expected HTML members from the uploaded Pages artifact. Compute each complete entity body's SHA-256, byte count and H1.
4. Request all 348 public URLs anonymously, with at most three concurrent requests. Compare complete HTTP entity bodies, response status, final URL, byte count and H1 with the artifact. No cookies or authenticated browser state were used.
5. Run bounded negative controls: a one-byte HTML mutation and a source-link-only mutation both change the expected hash. The latter leaves the visible heading unchanged and demonstrates why heading-only checks are insufficient.

`source-manifest.json` binds immutable Git paths and blobs. `readback.json` contains every observed page, timestamp, response status, final URL, entity hash, byte count and expected artifact result. `controls.json` records the two local mutations and one actual candidate URL check.

The candidate DV008 English URL returned HTTP 404 during the separate control request. This claim applies only to that URL at that time. [Draft PR 201](https://github.com/spareilleux/learn/pull/201) contains newer course work; this deployment receipt does not validate the PR's rendered content.

## Limits and next gate

This receipt establishes publication identity for the observed deployment. It supplies no subject-matter approval, fluent-language approval, accessibility or interactive browser assessment, learner result, or completion credit toward the reviewed-course goal. Human review of AUD-001 remains pending; no reviewer or approval is invented. Historical review records must be matched to the exact source blobs before any course can be counted as reviewed and published.

The production readback used a disposable local analysis script; no new supported validator or CI gate is introduced here. The read-only native audit checks coverage, provenance bindings, report consistency and sampled archive bytes; its result is recorded separately in `native-audit.json`.
