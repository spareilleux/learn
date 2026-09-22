---
title: Dogfood the course method
description: Treat course authoring, verification and multilingual journals as an engineering system with measurable quality.
sidebar:
  order: 3
---

Courses can teach good engineering while being produced by a weak process. This course evaluates its own production system.

## Five quality dimensions

1. **Executable examples:** every claimed output comes from runnable code or is marked untested.
2. **Journal evidence:** hypothesis, baseline, result, verdict and artifact are distinct fields.
3. **Locale parity:** EN, FR and ES share the same files and links; automation checks structure, humans review meaning.
4. **Adoption feedback:** the journal follows candidates beyond publication into rejection, incubation or repository integration.
5. **Agentic efficiency:** measure cost per accepted result, not agent activity or tokens alone.

## A better publication gate

A course page is ready when:

- official sources support time-sensitive facts;
- commands and outputs were reproduced on the stated environment;
- untested statements are explicit;
- the journal links each measured claim to code or raw evidence;
- translations mirror the source structure;
- repository recommendations remain hypotheses until tested there.

Automation can prove file parity, links, generated-matrix freshness and test results. It cannot prove that a translation is idiomatic or an architectural recommendation is wise; those remain review responsibilities.

<details>
<summary>Exercise: deliberately stale the matrix</summary>

Change one score in `opportunities.json` without regenerating `matrices.md`, then run `python dogfood.py check`. The command must fail. Restore the file or run `python dogfood.py write` and re-run the tests.

</details>
