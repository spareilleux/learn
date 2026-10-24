---
module_id: cyb-008-check-convergence-before-repeating-a-correction
department: cybernetics
course: "Check Convergence Before Repeating a Correction"
level: intermediate
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "phy-012-rotate-directional-stiffness-with-the-material"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Check Convergence Before Repeating a Correction

> **Draft scope.** Authored exact-arithmetic iterations for a stipulated linear equilibrium. No physical controller, material calibration, native solver or agent loop was run. Human technical, artisan, fluent-language and learner reviews remain pending; deployed course HTML verification is separate.

## The project question

Could an observatory agent solve a material response by repeatedly correcting the force residual? [PHY-012](../../physics/en/phy-012-rotate-directional-stiffness-with-the-material.md) supplies an authored spring law, not a calibrated cloth model. [CYB-004](cyb-004-observe-before-correcting-a-feedback-loop.md) distinguishes a useful correction from successful execution. Here we derive when one precise numerical correction converges and when repetition amplifies its error.

Use local stiffness `K=diag(4,1)` in N/mm, target force `F=[4,1]` N and starting displacement `u[0]=[0,0]` mm. The exact equilibrium is `u*=[1,1]` mm. No receiving-host frame convention is implied.

## 1. Define the residual and gain

Let the residual be `F-K*u[n]`, in N. The numerical update is `u[n+1]=u[n]+alpha*(F-K*u[n])`, so `alpha` has units mm/N. With error `e[n]=u[n]-u*`, substitution gives `e[n+1]=(I-alpha*K)*e[n]`.

This is an update-indexed algebraic iteration, not an equation of motion in seconds. It has no inertia, contact, measurement noise or actuator limits. Those omissions are assumptions, not a validated description of a craft machine.

### Practice exercise 1: compute the first corrections

Set `alpha=0.25` mm/N. Compute the first two displacements and the two error factors. Why does a dimensionless gain with the same numeric value not define the same update?

> **Answer:** The first two displacements are `[1,0.25]` and `[1,0.4375]` mm. The error factors are `1-4*alpha=0` and `1-alpha=0.75`. Multiplying force residual by the gain must produce displacement, so its mm/N units are necessary. Changing units without transforming the gain changes the numerical model.

## 2. Derive the strict convergence interval

For every starting error to converge to zero, both error factors must have magnitude below one. The conditions are `abs(1-4*alpha)<1` and `abs(1-alpha)<1`, giving `0<alpha<0.5` mm/N together. The endpoints are excluded.

At `alpha=0.25`, the stiff-axis error disappears after the first update; the other contracts by 0.75 per update. At update 8 the displacement is `[1,0.8998870849609375]` mm. The residual on the second axis is 0.1001129150390625 N. Geometric contraction per update does not establish wall-clock speed or improvement in a physical process.

### Practice exercise 2: prove convergence under the stated premises

Derive the interval from both eigenmodes. Explain why the result at update 8 is still short of the exact equilibrium and whether observing eight completed updates would prove convergence.

> **Answer:** The first mode requires `0<alpha<0.5`; the second requires `0<alpha<2`, so their intersection is `0<alpha<0.5`. The slow error at update 8 is `-0.75^8` mm, not zero. A finite trace alone is not the proof: the contraction follows from the exact linear recurrence and its assumptions. No native runtime or physical convergence was observed.

## 3. Test boundary oscillation and divergence

At `alpha=0.5`, the stiff error factor is -1. With our initial condition, the first displacement alternates between 0 and 2 mm. Its pairwise average is 1 mm, but the sequence does not converge to that value. The other coordinate converges.

At `alpha=0.6`, the factors are -1.4 and 0.4. A nonzero stiff-mode error grows in magnitude while alternating sign. Measuring only the improving second coordinate would miss the unstable mode.

Define the quadratic potential gap by `0.5*e^T*K*e` in N*mm. At the boundary gain, its stiff contribution remains 2 N*mm. A correct average displacement or one shrinking coordinate is insufficient as a stopping criterion.

### Practice exercise 3: reject an incomplete success metric

An agent averages the boundary-gain first coordinate to 1 mm and declares success. Diagnose the claim using the error sequence and potential gap. What changes at gain 0.6?

> **Answer:** Averaging hides the alternating displacement error of magnitude 1 mm, leaving a stiff-mode potential gap of 2 N*mm. The iterates do not converge. At gain 0.6, a nonzero stiff error instead multiplies by -1.4, so its magnitude grows. Inspect all relevant modes and a declared residual/error criterion, not just an average or the stable coordinate.

## 4. Change the delay and rederive the model

Now deliberately use the previous update's displacement in the residual: `u[n+1]=u[n]+alpha*(F-K*u[n-1])`. Set both starting values to zero. This is a different recurrence, not a harmless implementation detail.

For the stiff mode at `alpha=0.4`, the characteristic equation is `r^2-r+1.6=0`. Its complex roots have magnitude `sqrt(1.6)`, greater than one. The undelayed iteration at the same gain has factors -0.6 and 0.6 and converges; that conclusion cannot be transferred to the delayed version. Its first-coordinate displacements begin `[0,1.6,3.2,2.24,-1.28]` mm and do not provide a monotone error trace.

### Practice exercise 4: expose the changed assumption

Derive the stiff-mode characteristic equation and root magnitude for the delayed recurrence. Why does the earlier gain interval fail to justify this loop?

> **Answer:** Substituting an error mode proportional to `r^n` gives `r^2-r+alpha*4=0`, hence `r^2-r+1.6=0`. The conjugate roots have product 1.6 and magnitude `sqrt(1.6)>1`. The earlier proof used the current residual and a different characteristic equation. Delayed observations can require another analysis; this authored counterexample is not a measurement of a real controller.

## 5. Compare against the simpler solve

For this known diagonal matrix, direct multiplication by `K^-1=diag(0.25,1)` immediately gives `[1,1]` mm. An agentic loop or new DSL must justify its extra cost against that simple baseline. The [retained prior spring record](https://github.com/spareilleux/learn/blob/d488be4c2fda37afa06a4f87e322b73f21e46313/code/streeling/evidence/weave-material-2026-10-22/directional-response.json) remains authored mathematics.

The pinned [teaching scene](https://github.com/spareilleux/learn/blob/d488be4c2fda37afa06a4f87e322b73f21e46313/code/streeling/weave-godot/trial.gd) creates static bodies. [Godot StaticBody3D](https://docs.godotengine.org/en/4.6/classes/class_staticbody3d.html) does not move under external forces or contacts; these bodies do not implement our iterative spring solver.

### Practice exercise 5: prepare a source-assisted solver comparison

Read the scene and static-body reference, then use the [fixed iteration record](../../../../code/streeling/evidence/constraint-feedback-2026-10-22/residual-iterations.json). Specify a bounded future comparison before an agent promises recursive improvement.

> **Answer:** Pin the actual response law, frame, units, gain, observation age, update policy and stopping criterion. Compare against the direct solve on this small known system and retain residuals, errors, iteration counts and elapsed costs separately. Include boundary-gain, delayed and invalid-input controls, then test any intended nonlinear or physical extension under its own assumptions. Reject a claimed advantage if added orchestration costs more without improving the declared outcome. The present calculations establish neither a deployed solver nor calibrated material, real-time control or general agent improvement.
