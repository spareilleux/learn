---
module_id: fut-006-test-a-no-stretch-craft-automation-claim
department: futurology
course: "Test a No-Stretch Craft Automation Claim"
level: intermediate
prerequisites: ["fut-003-agent-substitution-readiness-drill", "phy-011-compute-bend-length-on-a-declared-neutral-layer", "sem-007-preserve-the-meaning-of-a-bend-angle"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Test a No-Stretch Craft Automation Claim

> **Draft scope.** Authored ideal surface calculations, capability counterexamples and pinned source/primary-document reading. Human technical, artisan, fluent-language and learner reviews and deployed course HTML verification remain pending. No CAD unroll, host surface, IX full check, mesh export or physical manufacture was performed.

## The project question

A future craft agent promises to turn any scene surface into an exact flat blank without stretching. Before estimating when that capability will arrive, can we state a model and a case that would refute the claim? Foresight needs a bounded target and a discriminating test, not a stronger name for a preview.

The [Rhino UnrollSrf documentation](https://docs.mcneel.com/rhino/8/help/en-us/commands/unrollsrf.htm) distinguishes developable surfaces from material-dependent or approximate flattening and discusses seams, tolerances and pitfalls. It also says those tools were not designed for sheet-metal bending/unfolding like duct work. Reading the documentation is not an observed command run or a claim that another tool implements the same behavior.

## 1. Test the unrestricted geometric premise

The [Rhino surface mathematics guide](https://developer.rhino3d.com/en/guides/general/essential-mathematics/parametric-curves-surfaces/) defines Gaussian curvature as the product of principal curvatures. In authored millimetre-based examples, a plane has principal curvatures 0 and 0; a cylinder of radius 10 has 0 and `1/10`; a sphere of radius 10 has `1/10` and `1/10`. Their Gaussian curvatures are 0, 0 and `1/100` in `mm^-2`.

For an exact smooth regular development preserving the surface's intrinsic metric, nonzero Gaussian curvature is an obstruction. The sphere therefore refutes the unrestricted smooth no-stretch claim in this model. It does not prove that a sphere cannot be manufactured, approximated by panels or formed using material strain. Those are different targets and processes.

### Practice exercise 1: locate a falsifier

Compute the three curvature products and identify a counterexample to exact smooth no-stretch flattening of every surface. Does the counterexample refute every way to make a spherical object?

> **Answer:** Plane and cylinder products are 0; the sphere's is `1/100 mm^-2`. The sphere refutes the unrestricted claim under the stated regular smooth no-stretch assumptions. It refutes neither strained forming nor a changed, faceted approximation or other manufacturing process.

## 2. Specify a tractable positive case

Take an authored ideal zero-thickness cylinder of radius 10 mm and height 30 mm. A quarter-cylinder patch has angular extent `pi/2`; the unrolled circumferential coordinate is arc length `x=R*theta`, while the axial coordinate remains unchanged. Its flat width is `5*pi` mm and its height 30 mm, so its area is `150*pi` square mm.

This is an analytic positive case for a selected reference surface. It is not a parsed IX object, an emitted blank or a calibrated finite-thickness bend. [PHY-011](../../physics/en/phy-011-compute-bend-length-on-a-declared-neutral-layer.md) separately locates a neutral layer in an authored thickness model. Choosing which surface is being developed belongs in the target definition.

### Practice exercise 2: make the milestone measurable

Give the quarter-patch flat dimensions and area. What reference-surface and process assumptions must remain attached before presenting this as a future automation milestone?

> **Answer:** Width is `5*pi` mm, height 30 mm and area `150*pi` square mm. Retain the ideal zero-thickness cylinder, radius, angular extent, axial length, units and chosen reference surface. These dimensions do not include a calibrated neutral-layer rule, physical bend process or successful host export.

## 3. Compare the right distances

At the same axial height, the quarter-cylinder's curved circumferential path has length `5*pi`, approximately 15.707963268 mm. Its spatial endpoint chord is `10*sqrt2`, approximately 14.142135624 mm. The chord passes through space inside the cylinder; it is not that path on the surface.

An intrinsic development can preserve the curved surface path while changing the endpoints' 3D Euclidean separation. Rejecting it because every spatial chord is not preserved would test the wrong equivalence. Conversely, matching a few displayed chords or a bounding box would not verify the surface metric.

### Practice exercise 3: avoid a false rejection

Give the quarter-path and chord lengths. Does their difference demonstrate that the analytic development stretched the surface? State which length the claimed development preserves.

> **Answer:** The surface path is `5*pi`, approximately 15.707963268 mm; the chord is `10*sqrt2`, approximately 14.142135624 mm. They measure different paths. Their difference does not demonstrate surface stretching: the unroll preserves intrinsic lengths of surface paths, not every spatial chord.

## 4. Name the seam in a global claim

The whole lateral cylinder has width `20*pi` and height 30 when opened along one axial seam; its area is `600*pi` square mm. Before cutting, angular parameters 0 and `2*pi` identify the same surface location. In the rectangle they become opposite boundary sides. A seam correspondence is therefore part of this construction, rather than evidence that the original closed loop already had a single cut-free rectangular chart.

Zero Gaussian curvature is a local geometric property. It alone is not a guarantee of a global, cut-free, one-to-one development or a physical fabrication certificate. The original surface and its opened chart must be compared with the declared seam treatment.

### Practice exercise 4: challenge a missing global condition

Give the opened full lateral dimensions and area. Which coincident input locations become distinct flat sides, and why does zero curvature not establish the proposed cut-free global claim?

> **Answer:** The rectangle is `20*pi` by 30 mm with area `600*pi` square mm. Input parameters 0 and `2*pi` are the same cylinder location but map to opposite seam sides. A selected cut and correspondence open that loop; the local zero-curvature test does not remove the global seam requirement.

## 5. Forecast a bounded capability, then demand its evidence

The pinned [IX thickness ADR](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md#L7-L34) scopes its parallel-panel reading separately from bend radius and motion. It supplies no execution evidence for the cylinder examples. A preview, a stated flat-fold check, an ideal development and a calibrated fabrication process are different capabilities.

A smaller candidate milestone is to compare a declared reference-surface patch and its chart using explicit length/area tolerances and seam correspondence. Its assumptions are regular ideal geometry and the chosen domain. A strongest objection is that a manual analytic construction may already meet the immediate scene need, while a new adapter adds conversion, validation and maintenance work. That simpler alternative should be tried before treating a new DSL as necessary. A failed metric or seam check would reject the candidate's geometric claim; physical radius, thickness, neutral rule, relief, tooling, springback and motion remain separate unresolved obligations.

### Practice exercise 5: repair the automation forecast

An agent promotes a visually plausible cylinder and a passing stack report to “all craft surfaces will yield manufacturing-ready blanks.” Replace that forecast with a falsifiable candidate and identify evidence still required.

> **Answer:** A bounded candidate would develop the declared ideal cylindrical patch, retaining its reference surface, units and seams and checking intrinsic lengths/area against stated tolerances. The sphere counterexample rejects the unrestricted smooth no-stretch promise. A stack report and preview do not provide an executed adapter, calibrated finite-thickness rule or process evidence. Compare the simpler analytic construction first; actual host and fabrication outcomes remain unverified.

The [scope record](../../../../code/streeling/evidence/bend-development-2026-10-22/development-scope.json) retains positive cases, counterexamples and distinct pending claims. No new manufacturing DSL or deployment policy is ratified by these lessons.
