Written 2026-10-05, before the oracle exists or has run.

Question: does an independent Python computation of the Jones polynomial, by the
Kauffman bracket's 2^crossings state sum written from its textbook definition, give
the same polynomials as IX's ix-knot (Temperley-Lieb algebra) at e8684cf?

Hypothesis: yes, for every braid word whose Jones polynomial IX's tests assert at
e8684cf (jones.rs known_knots_and_links, the_reef_knot..., knot.rs skill tests),
written identically in IX's text format; and the components and writhe asserted in
braid.rs agree too.

Second hypothesis: the right-handed trefoil s1^3 gives t + t^3 - t^4, and the Knot
Atlas page for 3_1 shows the mirror polynomial (-q^-4 + q^-3 + q^-1), because the
Knot Atlas draws the left-handed trefoil. Not yet checked.
