---
title: Architecture patterns — Journal
description: Evidence, source provenance and unverified experiments for the architecture-patterns tracer course.
sidebar:
  label: Journal
  order: 5
---

## Progress

- [x] Define one use case and four focused lessons.
- [x] Compare all five patterns, their assumptions and rejection criteria.
- [x] Provide worked exercises in English, French and Spanish.
- [x] Pin ecosystem reading without claiming adoption.
- [ ] Execute a dependency-change experiment in an ecosystem repository.
- [ ] Run concurrency and recovery fixtures against a real persistence adapter.

## 2026-09-21 — A comparison course with bounded evidence

The baseline site revision is `c05b01f35c2a407e8b637db6f6c1bb5015c518d3`. The existing Architecture & design navigation was reused. No other course was edited.

Consulted primary sources: [layering](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures), [onion](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/), [clean](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html), [hexagonal](https://alistair.cockburn.us/hexagonal-architecture), [module fundamentals](https://docs.spring.io/spring-modulith/reference/fundamentals.html), [module verification](https://docs.spring.io/spring-modulith/reference/verification.html) and [idempotency](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). The Microsoft page resolved through its English locale URL. The ecosystem README links in [lesson 4](../04-ecosystem-decisions/) resolved at their pinned revisions.

The catalog, three-shape invariant, fixture budget and acceptance thresholds are authored teaching assumptions. The worked solutions are reasoned traces, not captured program output. No throughput, allocation, concurrency or architecture-compliance measurement is claimed. There is no QA or Experiments table yet because no software finding or measured architecture experiment was produced.

Site validation on Windows, Node.js v24.12.0 and npm 11.7.0:

- `npm ci --no-audit --no-fund`: installed the locked dependencies successfully.
- `npm run build`: passed; 1,138 pages built. Existing music lessons produced unsupported `play` highlighting warnings; those files were not changed.
- Course checks: 18 pages, six identical filenames per locale, matching sidebar order and link URLs, and 12 balanced collapsible solutions.
- All 11 unique external URLs returned HTTP 200; relative course links resolved to source pages and generated HTML.
- Generated HTML contains the course links on all three home pages and sidebars; all 18 course routes exist.
- `git diff --check`: passed.

These are site/content checks, not architecture experiments. Documentation rendering does not verify the proposed application designs.

## To verify

- Browser rendering and navigation on all three locales.
- Linux/macOS builds; no cross-platform execution was performed for this slice.
- Actual source dependencies, caller parity and permissions before any ecosystem change.
- Idempotency, concurrent uniqueness, catalog freshness and crash recovery in an executable implementation.

## Open questions

- Which real duplicated rule justifies the first extraction?
- What business freshness guarantee should apply to a saved catalog revision?
- Does any module require independent release or scaling today?
