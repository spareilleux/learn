Learner identifier: AI learner, bounded DV-008 dry run. Relevant experience: general prior competence in evidence tracking, version control, and dashboard interpretation; a same-family AI learner, not a human participant.

1. **Card classifications**

   | Card | Exact public readback | All gates |
   |---|---|---|
   | U | No | No |
   | V | Yes | No |
   | W | Yes | Yes |
   | X | No | No |

   U fails public readback because it returns 404. V passes every public check but has pending review. W satisfies the stated classroom gates. X demonstrates why HTTP 200 and a matching heading are insufficient: both source links identify an older SHA.

   These classifications assume that “Approved” means approval for the card’s exact source version, as required by the task’s definition.

2. **Counts and denominator**

   - Authored source: **4/4**
   - Approved review: **2/4** — U and W
   - Exact public readback: **2/4** — V and W
   - All gates: **1/4** — W

   The denominator is the **four synthetic cards in this classroom exercise**. These figures do not estimate the real Streeling catalog or publication rate.

3. **Two-sentence dashboard caption**

   “At the pinned Demerzel revision, the progress script reports 120 of 525 core courses authored and zero production records marked review approved among those 120. The exact public count is unknown because no exhaustive anonymous public sweep has run; overall completion cannot be certified from these inputs.”

4. **Evidence-producing next actions**

   - **U:** Investigate the missing deployment for its pinned source SHA, then record an anonymous probe of the index and module page against that same SHA, checking HTTP status, both source links, and the rendered heading.
   - **V:** Have a human subject reviewer assess the exact authored content blob and record a verdict identifying that blob and its source revision. The existing public pass alone cannot supply review approval.

5. **An observable fact that would overturn W’s real-world claim**

   Inspecting the review receipt could reveal that it approves an older content blob, while the deployed course contains substantive edits made afterward. That version mismatch would invalidate the claimed intersection of approved review and public content, even if the dashboard displayed three green labels.

6. **Evidence after migration to Learn**

   No. A Learn `main` link is mutable, and a matching heading does not identify the reviewed lesson version.

   Before reporting current completion, I would gather:

   - The immutable Learn commit actually deployed.
   - The course path and content blob at that commit.
   - The underlying human review receipt, including reviewer, verdict, and the source blob it covers.
   - The supplemental origin and its mapping to the deployed content, when applicable.
   - A timestamped anonymous readback of the deployed lesson, with evidence binding its rendered content to the reviewed source version.

   I would also check the applicable evidence for project usefulness and verifiable exercises; the three-stage map alone does not establish those qualities.

   The historical script checks Demerzel-specific index and module link patterns. Current Learn provenance requires a different binding between deployment, reviewed blob, origins, and rendered content. The unchanged script therefore cannot establish current completion, and failure to match its old link pattern would not by itself show that a current page is wrong.

**Uncertainty and ambiguity:** I am confident in the classroom classifications and counts under the stated definitions. The table abbreviates version-bound review as “Approved”; my assumption about that abbreviation is explicit above. The handout says to administer the tasks before showing the lesson, but this dry run exposed the lesson first, so the result cannot be interpreted as a blind transfer attempt. No other ambiguity materially affected my answers.

**Sources and limitations:** I consulted only `C:\tmp\dv008-redacted-learner-packet-20261022.md`. I did not open its links, run its evaluator, inspect other files, or access the network. This response combines the exposed lesson with same-family AI general prior competence. There was no pretest, no measurement of causal learning gain, and no human learner result. Actual completion time was not independently measured. This response grants no subject, fluent-language, or publication approval.
