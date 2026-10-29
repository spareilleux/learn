# Visible public counts and dynamic Streeling navigation

The user could not find a total on the public overview and explicitly requested a slightly wider left nav, with department course counts calculated dynamically when the page loads.

## Requirements

1. Show near-top EN/FR/ES overview totals, core quota and optional IX Research separately, and a total table row. Derive totals from actual generated locale pages; do not count English fallbacks as translations.
2. Count published course-link identities at initial load and astro:page-load within each controlled nav tree. Deduplicate aliases/repeated anchors; exclude journals, overviews, external links and non-module routes. Preserve empty departments and reuse badges on repeated initialization.
3. Slightly widen the desktop sidebar (22rem at >=72rem), retaining smaller-screen behavior, all links, current-page state, keyboard accessibility, mobile/home global menu, theme/language controls and the native modal contract from PR160.
4. Retain actual RED/GREEN evidence, review changed runnable code, run existing/new regressions, full build and repeat-sync equality. Check actual browser appearance, dynamic recomputation, EN/FR/ES, sidebar width and mobile dialog behavior.
5. Publish the correction, verify actual public overview counters/navigation and recheck all 1,518 article routes. Update the same-session curriculum count/spec from actual deployment evidence. No additional courses, human acceptance or navigation-size redesign is included.

Root owns generator/overview tests, shared evidence/journals, Git/build/publication. The nav worker owns only the five explicit nav/CSS/test files. Courses themselves remain unchanged from PR201. Full source/body verification is retained in site-readback.json and the preceding batch records.
