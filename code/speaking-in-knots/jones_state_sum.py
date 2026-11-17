"""Jones polynomials of braid closures, by the Kauffman bracket's state sum.

Written for the Speaking in knots course. Each of the 2^crossings smoothings of the
closed braid is drawn, its circles are counted, and the terms are added up: the
construction of the state_sum helper in IX's own tests (crates/ix-knot/src/jones.rs
at e8684cf), rewritten in Python so that it runs without Rust or IX's repository.
IX's library evaluates the same bracket in the Temperley-Lieb algebra instead, and
its tests already compare the two on 150 words; the independent reference for the
results is a published knot table, not this script.

Run it with no arguments: it recomputes every Jones polynomial, number of
components, writhe, permutation and symmetry that IX's tests assert at commit
e8684cf (pull request #366) on words of up to 6 crossings, compares each with IX's
value, prints one line per check and exits with status 1 if any of them disagrees.
One of IX's tests is out of its reach: words_at_the_caps_evaluate (64 and 63
crossings, 2^64 smoothings). The 150 generated words of
the_algebra_agrees_with_the_state_sum_and_the_markov_moves are not reproduced
either: that test checks relations, not written values. Give it a word, and
optionally a repeat count, to compute that word instead:

    python jones_state_sum.py "s1 s2^-1" 2

Standard library only.
"""

import sys

IX = "e8684cf"

# Each case: (strands or None, word, what IX's tests assert at e8684cf).
# Sources at that commit: crates/ix-knot/src/braid.rs components_count_the_cycles_
# of_the_permutation and writhe_and_mirror; crates/ix-knot/src/jones.rs
# known_knots_and_links; crates/ix-agent/src/skills/knot.rs the_plait_closes_into_
# the_figure_eight_then_the_borromean_rings (writhe 0, permutation [0, 1, 2]).
CASES = [
    (1, "", {"jones": "1"}),
    (None, "s1", {"components": 1, "jones": "1"}),
    (None, "s1^-1 s2 s3^-1", {"jones": "1"}),
    (3, "", {"jones": "t^-1 + 2 + t"}),
    (4, "", {"components": 4}),
    (None, "s1^2", {"components": 2, "jones": "-t^(1/2) - t^(5/2)"}),
    (None, "s1^3", {"components": 1, "jones": "t + t^3 - t^4"}),
    (None, "s1^-3", {"jones": "-t^-4 + t^-3 + t^-1"}),
    (None, "s1^3 s2^-1", {"writhe": 2}),
    (None, "s1^-3 s2", {"writhe": -2}),
    (None, "s1 s2^-1 s1 s2^-1",
     {"components": 1, "writhe": 0, "jones": "t^-2 - t^-1 + 1 - t + t^2"}),
    (None, "s1 s2^-1 s1 s2^-1 s1 s2^-1",
     {"components": 3, "permutation": [0, 1, 2],
      "jones": "-t^-3 + 3t^-2 - 2t^-1 + 4 - 2t + 3t^2 - t^3"}),
]

# Words whose symmetry IX's tests assert (jones.rs the_reef_knot_is_symmetric_and_
# the_granny_is_not, and knot.rs): the reef knot and the figure-eight are symmetric,
# the granny and the trefoil are not.
SYMMETRY = [("s1^3 s2^-3", True), ("s1^3 s2^3", False), ("s1^3", False),
            ("s1 s2^-1 s1 s2^-1", True)]


def parse(word, strands=None):
    """Generators +k or -k from "s1 s2^-1", "1,-2" or "σ1^3"; strands default to
    one more than the largest generator."""
    gens = []
    for token in word.replace(",", " ").split():
        bad = ValueError(f"cannot read {token!r} as a generator: write s1, s2^-1, "
                         "s1^3 or a signed integer")
        try:
            if token[0] in "sσ":
                body = token[1:]
                index, power = body, "1"
                if "^" in body:
                    index, power = body.split("^", 1)
                k, p = int(index), int(power)
                if k <= 0 or p == 0:
                    raise bad
                gens += [k if p > 0 else -k] * abs(p)
            else:
                g = int(token)
                if g == 0:
                    raise bad
                gens.append(g)
        except ValueError:
            raise bad from None
    if strands is None:
        strands = max([abs(g) + 1 for g in gens], default=1)
    if any(abs(g) >= strands for g in gens):
        raise ValueError("a generator needs |k| < strands")
    return strands, gens


def permutation(strands, gens):
    """end[i]: the position, 0-based, at which the strand that starts in position i
    ends, as IX's Braid::permutation returns it."""
    at = list(range(strands))
    for g in gens:
        k = abs(g)
        at[k - 1], at[k] = at[k], at[k - 1]
    end = [0] * strands
    for position, strand in enumerate(at):
        end[strand] = position
    return end


def components(strands, gens):
    """Cycles of the strand permutation: the braid is read from bottom to top, and
    the closure joins each end, at the top, to the start of the same position, at
    the bottom."""
    end = permutation(strands, gens)
    seen, cycles = set(), 0
    for start in range(strands):
        if start in seen:
            continue
        cycles += 1
        i = start
        while i not in seen:
            seen.add(i)
            i = end[i]
    return cycles


def add(poly, exponent, coeff):
    poly[exponent] = poly.get(exponent, 0) + coeff
    if poly[exponent] == 0:
        del poly[exponent]


def times_loop(poly):
    """Multiply by the loop value d = -A^2 - A^-2."""
    out = {}
    for e, c in poly.items():
        add(out, e + 2, -c)
        add(out, e - 2, -c)
    return out


def circles(strands, gens, mask):
    """Circles of one smoothing. Point (level, position): levels 0..c, with level c
    glued back to level 0 by the closure. Bit j of mask set: crossing j is replaced
    by a cap and a cup; clear: by two vertical arcs."""
    c = len(gens)
    if c == 0:
        return strands
    parent = list(range(c * strands))

    def node(level, position):
        return (level % c) * strands + position

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def join(a, b):
        parent[find(a)] = find(b)

    for j, g in enumerate(gens):
        k = abs(g) - 1
        for p in range(strands):
            if p not in (k, k + 1):
                join(node(j, p), node(j + 1, p))
        if mask >> j & 1:
            join(node(j, k), node(j, k + 1))
            join(node(j + 1, k), node(j + 1, k + 1))
        else:
            join(node(j, k), node(j + 1, k))
            join(node(j, k + 1), node(j + 1, k + 1))
    return sum(1 for x in range(c * strands) if find(x) == x)


def bracket(strands, gens):
    """<closure> in A, normalized so that one circle is 1. A positive crossing
    smoothed vertically weighs A, smoothed into a cap and cup A^-1; a negative
    crossing the other way round."""
    total = {}
    for mask in range(1 << len(gens)):
        exponent = 0
        for j, g in enumerate(gens):
            sign = 1 if g > 0 else -1
            exponent += -sign if mask >> j & 1 else sign
        term = {exponent: 1}
        for _ in range(circles(strands, gens, mask) - 1):
            term = times_loop(term)
        for e, c in term.items():
            add(total, e, c)
    return total


def jones(strands, gens):
    """V(t) = (-A^3)^(-writhe) <closure>, with t = A^-4. Returned as
    {power of t^(1/2): coefficient}."""
    writhe = sum(1 if g > 0 else -1 for g in gens)
    sign = -1 if writhe % 2 else 1
    out = {}
    for e, c in bracket(strands, gens).items():
        shifted = e - 3 * writhe
        assert shifted % 2 == 0, "every exponent has the parity of 3 * writhe"
        add(out, -shifted // 2, sign * c)
    return out


def text(poly):
    """Written as IX writes it: t + t^3 - t^4, -t^(1/2) - t^(5/2), t^-1 + 2 + t."""
    parts = []
    for i, half in enumerate(sorted(poly)):
        c = poly[half]
        if i == 0:
            parts.append("-" if c < 0 else "")
        else:
            parts.append(" - " if c < 0 else " + ")
        if half % 2:
            power = f"t^({half}/2)"
        elif half == 0:
            power = ""
        elif half == 2:
            power = "t"
        else:
            power = f"t^{half // 2}"
        size = abs(c)
        if not power:
            parts.append(str(size))
        elif size == 1:
            parts.append(power)
        else:
            parts.append(f"{size}{power}")
    return "".join(parts)


def mirror(poly):
    return {-half: c for half, c in poly.items()}


def times(a, b):
    """The product of two polynomials in t^(1/2)."""
    out = {}
    for ha, ca in a.items():
        for hb, cb in b.items():
            add(out, ha + hb, ca * cb)
    return out


def describe(word, repeat):
    """One word, written `repeat` times: what its closure is made of."""
    if repeat < 1:
        raise ValueError("the repeat count must be at least 1")
    n, gens = parse(word)
    gens = gens * repeat
    if len(gens) > 20:
        raise SystemExit("at most 20 crossings: the state sum doubles with each one")
    v = jones(n, gens)
    print(f"word: {word}" + (f", repeated {repeat} times" if repeat > 1 else ""))
    print(f"strands {n}, crossings {len(gens)}, "
          f"writhe {sum(1 if g > 0 else -1 for g in gens)}, "
          f"components {components(n, gens)}")
    print(f"V = {text(v)}")
    print(f"V(1) = {sum(v.values())}, {'symmetric' if v == mirror(v) else 'not symmetric'}")
    return 0


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) > 1:
        try:
            repeat = 1
            if len(sys.argv) > 2:
                if not sys.argv[2].isdigit():
                    raise ValueError("the repeat count must be a whole number")
                repeat = int(sys.argv[2])
            return describe(sys.argv[1], repeat)
        except ValueError as error:
            print(f"refused: {error}", file=sys.stderr)
            return 2
    agree = total = 0
    for strands, word, expected in CASES:
        n, gens = parse(word, strands)
        got = {
            "components": components(n, gens),
            "writhe": sum(1 if g > 0 else -1 for g in gens),
            "permutation": permutation(n, gens),
            "jones": text(jones(n, gens)),
        }
        for key, value in expected.items():
            total += 1
            ok = got[key] == value
            agree += ok
            label = word if word else "(empty)"
            print(f"{'OK  ' if ok else 'DIFF'} {label} on {n} strands: {key} {got[key]}"
                  + ("" if ok else f" (IX: {value})"))
    for word, symmetric in SYMMETRY:
        n, gens = parse(word)
        v = jones(n, gens)
        total += 1
        ok = (v == mirror(v)) == symmetric
        agree += ok
        print(f"{'OK  ' if ok else 'DIFF'} {word}: V = {text(v)}, "
              f"{'symmetric' if v == mirror(v) else 'not symmetric'}")
    # The identities of the same jones.rs test: a connected sum's polynomial is the
    # product of the summands', and s1^-3 is the trefoil's mirror image.
    trefoil = jones(*parse("s1^3"))
    for label, left, right in [
        ("granny = trefoil x trefoil", "s1^3 s2^3", times(trefoil, trefoil)),
        ("reef = trefoil x mirror", "s1^3 s2^-3", times(trefoil, mirror(trefoil))),
        ("s1^-3 = mirror of the trefoil", "s1^-3", mirror(trefoil)),
    ]:
        total += 1
        ok = jones(*parse(left)) == right
        agree += ok
        print(f"{'OK  ' if ok else 'DIFF'} {label}")
    print(f"{agree}/{total} agree with IX at {IX}")
    return 0 if agree == total else 1


if __name__ == "__main__":
    sys.exit(main())
