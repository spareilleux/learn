---------------------------- MODULE PetriNet ----------------------------
(***************************************************************************)
(* The firing rule of a place/transition net, written once. A generated    *)
(* module supplies the net itself and instantiates this one.               *)
(*                                                                         *)
(* A marking is a function from places to naturals, so TLC's notion of a   *)
(* state and the net's notion of a marking are the same object. TLC has no *)
(* idea whether the net is bounded: the generated .cfg carries a           *)
(* CONSTRAINT that caps every place, and that cap comes from the place     *)
(* invariants of lesson 5.                                                 *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Places, Transitions, PreArcs, PostArcs, M0, Cap

(* An arc is a record [p |-> place, t |-> transition, w |-> weight]. A pair *)
(* with no arc between it weighs nothing.                                   *)
Weight(Arcs, p, t) ==
    LET a == {r \in Arcs : r.p = p /\ r.t = t}
    IN IF a = {} THEN 0 ELSE (CHOOSE r \in a : TRUE).w

Pre  == [t \in Transitions |-> [p \in Places |-> Weight(PreArcs, p, t)]]
Post == [t \in Transitions |-> [p \in Places |-> Weight(PostArcs, p, t)]]

VARIABLE marking

TypeOK == marking \in [Places -> Nat]

Enabled(t) == \A p \in Places : marking[p] >= Pre[t][p]

Fire(t) ==
    /\ Enabled(t)
    /\ marking' = [p \in Places |-> marking[p] - Pre[t][p] + Post[t][p]]

Init == marking = M0
Next == \E t \in Transitions : Fire(t)
Spec == Init /\ [][Next]_marking

(* The cap TLC needs and the net does not: without it an unbounded net     *)
(* would enumerate for ever, and TLC would never say so.                   *)
Bounded == \A p \in Places : marking[p] =< Cap

(* Deadlock freedom, stated the way the analyser states it.                *)
NoDeadlock == \E t \in Transitions : Enabled(t)
=============================================================================
