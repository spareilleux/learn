# P5, 3D-printable bracelets: hypotheses, written before the measurements

Written on 2026-09-17 at 18:00 (UTC-4) and committed before `mesh/build.py`, `mesh/measure.py` and `mesh/slice.py` exist.
Nothing in this file was measured first; the only numbers already known are the design's own dimensions, listed below,
and what a pocket calculator gets from them.

## The object

A bangle, printed flat on its bottom face, axis along Z.

| Parameter | Value |
|---|---|
| Inner diameter | 65.0 mm |
| Band wall thickness | 2.0 mm |
| Band height | 12.0 mm |
| Positions | 12, every 30 degrees, pitch class 0 at the top (+Y), clockwise seen from +Z |
| Member of the set | a bead protruding 3.0 mm, base radius 3.0 mm |
| Non-member | a vertical rib 1.2 mm wide protruding 0.8 mm over the full height |
| Pitch class 0 | an extra vertical keel, 2.5 mm wide, protruding 1.6 mm, chamfered at 45 degrees top and bottom |
| Segments per circle | 192 |

Two bead shapes are built and measured: **v1**, a sphere centred on the outer surface, and **v2**, a cone with its base
on the surface and its apex outwards.

The band's analytic volume is `pi * (34.5^2 - 32.5^2) * 12 = 5051 mm3`; twelve ribs, three beads and one keel add
roughly 320 mm3, so a C major bracelet should be a little under 5.4 cm3.

## Hypotheses

- **H1 (mesh validity).** The boolean union of the band with the fourteen features, computed by
  [manifold3d](https://github.com/elalish/manifold) through [trimesh](https://trimesh.org/), is watertight, has
  consistent winding, one connected body and Euler characteristic 0 for the bangle (a torus-like solid, genus 1), on the
  first attempt, for both bead shapes and for all 13 chord qualities.
- **H2 (the naive union fails).** Simply concatenating the band and the features into one file — what a script that
  writes an STL without a boolean engine does — is *not* watertight: `is_watertight` is false and the mesh has more than
  one body. This is the failure mode the lesson exists to show.
- **H3 (volume and mass).** The measured volume of the C major bracelet, v2, is between 5.2 and 5.6 cm3, and its mass in
  PLA at 1.24 g/cm3 between 6.4 and 7.0 g.
- **H4 (inner diameter).** The minimum distance from the axis to any vertex is 32.500 mm, and to any point of the
  surface 32.49 mm or more: the 192-segment faceting costs less than 0.02 mm of radius, ten times less than the
  0.1 to 0.3 mm a printer's own tolerance costs. The measured inner diameter is therefore 64.98 mm or more.
- **H5 (wall thickness).** Rays fired outwards from 2,000 points sampled on the inner surface all report a first hit at
  1.99 mm or more, and the minimum over the band alone, away from the features, is 2.00 mm plus or minus 0.01.
- **H6 (overhangs, v1).** With spherical beads, the area whose normal is within 45 degrees of -Z, excluding the faces
  resting on the bed, is between 3 % and 8 % of the total area: a slicer would ask for supports.
- **H7 (overhangs, v2).** With conical beads of equal height and base radius, that area falls below 0.5 % of the total,
  and the steepest overhang outside the bed contact is 45 degrees or less: the object prints without supports.
- **H8 (size).** The union has fewer than 60,000 triangles and its binary STL is under 3 MB.
- **H9 (build time).** Building all 13 chord bracelets, both bead shapes, measuring them and writing the files takes
  under 60 s of CPU on the author's machine (Ryzen, no GPU used).
- **H10 (GA's order).** The pitch-class sets parsed from GA's `CanonicalChordPatternCatalog.cs` agree, for the 13
  qualities P2 uses, with the values already committed in `code/ga-protos/p2-chord-universe/src/dsp/chords.ts`, and
  `Scale.Major` in GA's `Scale.cs` parses to {0, 2, 4, 5, 7, 9, 11}. The twelve bead angles match P2's bracelet:
  `angle = pi/2 - pc * pi/6`.
- **H11 (the slicer).** No slicer is installed on this machine at the time of writing. If a PrusaSlicer console build
  is obtained, it reports 0 repaired errors for the manifold3d union and at least 1 for the naive union of H2, and for
  the C major v2 bracelet at 0.2 mm layers, 3 perimeters and 15 % infill it estimates between 6.0 and 7.5 g of filament
  and between 25 and 50 minutes of printing. If no slicer can be run, every line of this hypothesis stays *to verify*.
- **H12 (what only the slicer sees).** Prediction about the checks a geometric measurement cannot make: the slicer will
  find at least one feature too thin to be filled by whole extrusions — the 1.2 mm ribs at a 0.45 mm extrusion width are
  2.67 perimeters wide — and will either widen them or leave a gap. A mesh that passes every trimesh check can still
  print badly.
