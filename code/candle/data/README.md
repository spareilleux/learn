# Data of the Candle course

## builds.csv

A copy of the IX course's file, from commit `d9ef7fb`, so that lesson 4 trains on the same 52 builds.

## iris.data and bezdekIris.data

Iris, from the UCI Machine Learning Repository: Fisher, R. (1936). Iris [Dataset]. UCI Machine Learning
Repository. https://doi.org/10.24432/C56C76. Licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Both files are unchanged copies from the
archive https://archive.ics.uci.edu/static/public/53/iris.zip, downloaded on 2026-09-30:

| File | SHA-256 |
|---|---|
| `iris.data` | `6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0` |
| `bezdekIris.data` | `0fed2a99db77ec533a62dc66894d3ec6df3b58b6a8f3cf4a6b47e4086b7f97dc` |

150 rows each (50 per species) and a trailing blank line: sepal length, sepal width, petal length and petal
width in centimetres, then the species. They differ in two rows, which the archive's `iris.names` lists:
in `iris.data`, row 35 should be `4.9,3.1,1.5,0.2` and row 38 `4.9,3.6,1.4,0.1`, as in Fisher's paper.
`bezdekIris.data` carries the corrected rows (Bezdek et al., "Will the real iris data please stand up?",
IEEE Transactions on Fuzzy Systems 7(3), 1999, https://doi.org/10.1109/91.771092). Lesson 5 trains on
`bezdekIris.data`; its exercises compare the two files.
