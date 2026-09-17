# P1 voicing space explorer: hypotheses, written before the measurements

Written on 2026-09-16 at 23:50 (UTC-4), committed before `scripts/measure.mjs` and the frame-time probe exist.
Data: GA's `optick.index` built at GuitarAlchemist/ga@66bdd049 (313,047 voicings, 297,910 of them guitar, 124 dimensions).

Honesty note: while testing the build step on a 2,000-voicing sample, its log printed the variance explained by the first three
components of a PCA fitted on every guitar voicing: 8.8 %, 8.2 % and 5.3 %, 22.2 % in total, with the first two dominated by the
MORPHOLOGY partition. H1 is therefore not a blind prediction; H2 to H6 are.

- **H1 (seen, not blind).** Three principal components explain less than 30 % of the variance of the guitar vectors.
- **H2.** Neighbours in the 3D projection are poor stand-ins for true neighbours: recall@10 of 3D Euclidean neighbours against
  the exact top 10 by dot product in 124 dimensions, within the 30,000-voicing sample, is below 0.15. With 32 components it is above 0.6.
- **H3.** Recall@10 is worse against the whole guitar index (297,910 voicings) than within the sample, because the true neighbours
  of a sampled voicing are mostly voicings that were not sampled: within the sample, a voicing's 10 nearest are on average farther away.
  Predicted: the mean dot product of the 10th true neighbour is at least 0.05 higher in the full index than in the sample.
- **H4.** Exact ties are common: for more than 5 % of sampled voicings, the 10th and 11th true neighbours have the same score,
  so "the" top 10 is not unique and recall must be read with that in mind.
- **H5 (frame time, RTX 5080, headless Chromium).** 30,000 points drawn as one `THREE.Points` take under 2 ms of GPU frame time
  on WebGPU; the whole guitar index (297,910 points) under 5 ms. The WebGL 2 backend is within a factor of 2 of WebGPU for this scene.
- **H6.** CPU picking with `Raycaster` against 30,000 points costs under 5 ms per pointer move, and more than 16 ms against 297,910:
  the full index would need a spatial grid or GPU picking.
- **H7 (diagrams).** GA's React `FretDiagram` base-fret rule (grid starts at the nut when the lowest fretted note is on fret 1 or 2)
  leaves at least one dot off its 5-fret grid for more than 1 % of guitar voicings.
