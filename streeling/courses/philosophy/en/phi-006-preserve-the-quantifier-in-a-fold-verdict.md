---
module_id: phi-006-preserve-the-quantifier-in-a-fold-verdict
department: philosophy
course: "Preserve the Quantifier in a Fold Verdict"
level: intermediate
prerequisites: ["phi-002-when-is-an-advisory-decision-justified", "phy-010-check-local-flat-fold-angles", "cs-009-composing-origami-panel-constraints"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preserve the Quantifier in a Fold Verdict

> **Draft scope.** Primary theorem interpretation, pinned source inspection and authored counterexamples. Human technical, fluent-language and learner reviews and deployed course HTML verification remain pending. No complete IX analysis, physical fold, mesh export or [Godot](https://docs.godotengine.org/en/4.6/) scene trial was executed.

## The project question

An agent says “the vertex folds flat.” Is it asserting that some assignment exists, that the supplied assignment works, or that a whole object has been validated? These claims have different subjects and quantifiers. A high-level agentic message should preserve that distinction when it compresses API details into a conclusion.

[PHY-010](../../physics/en/phy-010-check-local-flat-fold-angles.md) supplies one authored neighborhood: sectors 60, 90, 120 and 90 degrees in crease order e0 through e3. [CS-009](../../computer-science/en/cs-009-composing-origami-panel-constraints.md) already distinguishes local overlap checks from global rigid-panel ordering. This lesson focuses on a prior logical step: what a theorem or a bounded check actually licenses us to assert.

## 1. Read existence as existence

The [primary Demaine survey](https://erikdemaine.org/papers/OSME2001/paper.pdf#page=6) states the single-vertex angle characterization without specified crease directions. Under its ideal hypotheses, even degree and Kawasaki's angular condition establish that there exists a mountain/valley assignment admitting a local flat-folded state. They do not say that every assignment works.

For this authored geometry, the alternating sum is `60-90+120-90=0`. Passing it answers an unassigned existence question under the theorem's assumptions. A receiver must not silently insert a particular assignment and attach the same conclusion to it. Preserve zero thickness, a single interior neighborhood, used creases and the absence of prescribed directions in the statement.

### Practice exercise 1: restore the missing quantifier

An agent reads the angular pass and writes “every M/V assignment of these four creases folds flat.” Rewrite the conclusion licensed by the theorem. What additional claim did the agent insert?

> **Answer:** Under the stated ideal unassigned single-vertex assumptions, there exists an M/V assignment admitting a local flat folding. The agent replaced existence with a universal claim over all assignments. The angular condition alone does not license that replacement or a claim about a whole sheet or thick object.

## 2. Do not turn necessary conditions into a certificate

The pinned [IX local helper](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs) computes alternating angles and the mountain-minus-valley count. For the labeling `MMMV`, the angular residual is zero and `M-V=2`.

Yet the two mountains e0 and e1 bound the strict 60-degree minimum, whose neighboring sectors are both 90 degrees. They violate the additional opposite-label restriction described by [Hull's smallest-angle argument](https://arxiv.org/pdf/1307.1065#page=8). This provides a counterexample to sufficiency of those two numerical conditions for a prescribed assignment. It does not refute the unassigned angle theorem: its existential witness can be a different assignment.

### Practice exercise 2: separate two propositions

Why can the geometry admit some flat assignment while `MMMV` is rejected by an additional necessary rule? Does this contradiction show that Kawasaki's theorem failed?

> **Answer:** Existence of some assignment and validity of this particular assignment are different propositions. The authored geometry satisfies the unassigned angle condition; `MMMV` violates the strict-smallest-angle label restriction despite passing the two numerical filters. There is no contradiction and no refutation of the existence theorem.

## 3. Treat an empty checked domain honestly

The [IX applicability logic](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs#L106-L143) excludes border, isolated and other-crease vertices from these local theorem checks. The [pinned FOLD specification](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) gives unknown `U` its own meaning; it is not a successful M/V choice.

In the [authored applicability card](../../../../code/streeling/evidence/origami-local-2026-10-22/applicability-cards.json), changing one center crease to `U` leaves 0 applicable vertices. The failure lists are empty and the maximum residual is 0. “No checked vertex failed” can be true with no checked vertices. It does not imply that at least one vertex was checked, that unknown choices were solved, or that the intended full domain passed.

### Practice exercise 3: expose vacuous coverage

A summary keeps empty failure lists and maximum 0 but discards `applicable=0`. What inference can the recipient wrongly make? Write a precise replacement statement.

> **Answer:** The recipient can mistake absence of failures for positive coverage. A precise statement is: the local checked set is empty because the center has an unknown incident crease; no failure was reported within that empty set. The authored card is a source-branch model, not a full analyzer run or a solved assignment.

## 4. Keep the whole analyzer distinct from one helper

The [IX aggregate predicate](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L879-L889) combines local failures with isometry, crease-orientation, order and other checks. Our counterexample was not supplied as a complete crease pattern plus folded frame and layer order. Therefore we have not observed what that entire analyzer would return for a completed object.

Similarly, a local flat-fold result does not supply a nonintersecting whole-sheet state, a positive-thickness rigid stack or a motion path. The [library's scope statement](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/lib.rs#L1-L46) describes checks of one stated folded state and a separate thickness reading. The relevant lesson is to preserve the claim's domain and witness; no current complexity or physical-manufacturing claim is needed.

### Practice exercise 4: bound the implementation claim

An agent reports “IX accepts an impossible origami” because `MMMV` passes the two local formulas. What evidence is missing? State what this packet actually establishes about the helper.

> **Answer:** A complete source-bound input, folded frame and order plus an actual full-analysis result are missing. This packet establishes that the two local numerical conditions are insufficient for the prescribed assignment, with an additional necessary-rule counterexample. It does not establish acceptance by the whole analyzer, physical impossibility under other models, or a reproduced production bug.

## 5. Compose conclusions at a higher level

A useful proposed handoff states the subject, input identity, predicate, checked domain, assumptions and available witness. For the angle result, the subject is an unassigned ideal single-vertex neighborhood and the conclusion is existential. For a supplied assignment, report which necessary filters were checked and which remain absent. For empty coverage, retain the reason for skipping.

These distinctions can live in a typed report; a new DSL remains a candidate until it reduces actual downstream errors against that simpler alternative. A renderer may display a candidate, while a solver may still lack its folded witness. The [logical claim cards](../../../../code/streeling/evidence/origami-local-2026-10-22/logical-claims.json) are teaching examples, not a normative schema or an implemented scene bridge.

### Practice exercise 5: write the semantic handoff

Replace “origami validated, ready for Godot” for the `MMMV` example with a message that preserves the assignment, numerical results, additional restriction and missing outcomes. Does writing that message implement the proposed DSL?

> **Answer:** The authored `MMMV` assignment on sectors 60, 90, 120 and 90 passes Kawasaki's angular condition and Maekawa's count, but violates the strict-smallest-angle opposite-label rule. No complete folded-state witness, full IX result, physical fold or Godot import was observed. This message preserves the conclusion's scope; it does not implement or validate a new DSL.
