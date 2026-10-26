# KoenderColor

`KoenderColor` is a Wolfram Language paclet implementing the empirical three-dimensional color metric field developed by Jan Koenderink, Andrea van Doorn, Doris I. Braun, and Karl R. Gegenfurtner (2026).

## Metric & Color Distance Functions

* [`KoenderinkColorDistance`](../ReferencePages/Symbols/KoenderinkColorDistance.md) — perceptual distance between colors using the empirical metric field
* [`KoenderinkMetricMatrix`](../ReferencePages/Symbols/KoenderinkMetricMatrix.md) — interpolated 3×3 positive-definite Sigma matrix at an arbitrary color
* [`KoenderinkMetricTensor`](../ReferencePages/Symbols/KoenderinkMetricMatrix.md) — Riemannian metric tensor $g(c) = \Sigma(c)^{-1}$
* [`KoenderinkEllipsoid`](../ReferencePages/Symbols/KoenderinkMetricMatrix.md) — 3D `Ellipsoid` graphics primitive of the discrimination region

## Empirical Data & Mismatch

* [`KoenderinkData`](../ReferencePages/Symbols/KoenderinkMetricMatrix.md) — raw empirical measurements at the 35 body-centered cubic (BCC) lattice locations
* [`FrobeniusMismatch`](../ReferencePages/Symbols/KoenderinkMetricMatrix.md) — normalized Frobenius distance between two matrices

## Coordinate Transformations

* `sRGBToLinearRGB` — convert gamma-encoded sRGB to linear RGB coordinates
* `LinearRGBTosRGB` — convert linear RGB to gamma-encoded sRGB coordinates
