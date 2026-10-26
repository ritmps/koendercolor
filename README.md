# KoenderColor

A Wolfram Language paclet implementing the empirical three-dimensional metric field for color space described by  Koenderink, van Doorn, Braun, and  Gegenfurtner (2026).

<p align="center">
  <img src="assets/preview.png" width="480" alt="KoenderColor Empirical 3D Metric Field" />
  <br />
  <em>The empirical 3D metric field rendered in sRGB space (reproducing Figure 8 of the paper).</em>
</p>

## Overview

Classical color metrics such as CIEDE2000 apply heuristic weighting functions layered over CIELAB. In contrast, Koenderink et al. empirically measured local regions of **Notable Qualitative Differences (NQD)** throughout the full 3D color cube on a body-centered cubic (BCC) lattice.

At each of the 35 reference locations, color discrimination was probed along 7 orientations (14 directions) and fitted by a Löwner–John minimum-volume bounding ellipsoid:

$$(x - x_0)^T \Sigma(x_0)^{-1} (x - x_0) \le 1$$

`KoenderColor` provides the raw empirical data from the paper (both gamma-encoded sRGB and linear RGB) along with tools for continuous RBF field interpolation, Riemannian metric tensor evaluation, and perceptual distance calculations.

## Intuition & Scale Relation to Traditional $\Delta E$

To develop an intuition for the metric's values compared to standard industrial metrics ($\Delta E_{ab}^*$, CIEDE2000):

* **Thresholds (JND) vs. Categorical Grains (NQD)**:
  * $\mathbf{\Delta E = 1.0}$ represents a **Just Noticeable Difference (JND)** measured with adjacent color patches separated by a sharp edge (relying on edge-contrast detection).
  * $\mathbf{1.0\text{ unit}}$ in this metric represents a **Notable Qualitative Difference (NQD)** — the point where observers judge an area color to be perceptually distinct across a thick black dividing boundary.
  * **Scale Ratio**: $1\text{ NQD unit} \approx 5 \pm 2\ \text{CIEDE2000 units}$. (In Wolfram Language's built-in `ColorDistance`, which normalizes black-to-white to $1.0$, $1\text{ NQD} \approx 0.05$ `ColorDistance`).

* **Gamut Capacity**:
  * Counting unit $\Delta E$ cubes yields **$\approx 2.2$ million** discriminable colors in the optimal color solid.
  * Scaling the linear grain by $\approx 5\text{--}10\times$ reduces volume cubically: the entire sRGB cube accommodates only **$\approx 1,200$ qualitatively distinct color grains** (Figure 12 of the paper packs 1,241 BCC grains).

* **Black-to-White Span**:
  * In CIELAB, $L^*$ spans $0$ to $100$ ($\Delta E \approx 100$).
  * In Koenderink space, the line-integral distance from $(0.2, 0.2, 0.2)$ to $(0.8, 0.8, 0.8)$ is **$\approx 21.3$ NQD units**, extrapolating to roughly **$25\text{--}30$ NQD units** across the full $[0, 1]^3$ cube ($25 \times 5\ \Delta E \approx 125\ \Delta E$).

* **Systematic Divergence from CIEDE2000**:
  * **Grayscale Tolerance**: Empirical grayscale ellipsoids are $\approx 3\times$ larger than CIEDE2000 predicts — human observers tolerate much greater luminance variation along neutral grays before perceiving a qualitative step.
  * **Ellipsoid Shape**: Empirical grains are closer to spheroidal with a mild prolate bias along the luminance axis, avoiding the extreme eccentricities imposed by CIEDE2000's separable $S_L, S_C, S_H$ formulas.

## Features & Tools

* **`KoenderinkData`**: Access the empirical 35-point BCC lattice data and fitted covariance tensors $\Sigma$ (from Appendix Tables A2 and A3).
* **`KoenderinkMetricMatrix`**: Interpolates the $3 \times 3$ symmetric positive-definite covariance matrix $\Sigma(c)$ at any color $c \in [0, 1]^3$ using Gaussian RBF partition of unity.
* **`KoenderinkMetricTensor`**: Computes the Riemannian metric tensor $g(c) = \Sigma(c)^{-1}$.
* **`KoenderinkEllipsoid`**: Generates native Wolfram Language `Ellipsoid[coords, scale^2 * Sigma]` primitives for 3D graphics.
* **`KoenderinkColorDistance`**: Evaluates perceptual color distances in NQD units using:
  * `"Midpoint"`: Fast symmetric chord metric via the midpoint Riemannian tensor.
  * `"LineIntegral"`: Numerical quadrature along straight color paths.
  * `"Geodesic"`: Shortest path along the Riemannian manifold via energy-minimizing relaxation.
* **`FrobeniusMismatch`**: Normalized matrix mismatch $\mu_F(S, T) = \frac{\|S - T\|_F}{\|S\|_F + \|T\|_F}$.
* **Coordinate Transformations**: Smooth conversion between sRGB and linear RGB (`sRGBToLinearRGB`, `LinearRGBTosRGB`).

## Quickstart

```mathematica
(* Load paclet from local checkout *)
PacletDirectoryLoad["/path/to/koendercolor"];
Needs["KoenderColor`"];

(* 1. Distance between two colors *)
c1 = RGBColor[0.5, 0.5, 0.5];
c2 = RGBColor[0.6, 0.5, 0.5];
KoenderinkColorDistance[c1, c2]
(* Out: ~1.49 NQD units *)

(* 2. Black to white line-integral distance *)
cBlack = RGBColor[0.2, 0.2, 0.2];
cWhite = RGBColor[0.8, 0.8, 0.8];
KoenderinkColorDistance[cBlack, cWhite, "Method" -> "LineIntegral"]
(* Out: ~21.29 NQD units *)

(* 3. Query the local metric tensor g = Sigma^-1 *)
g = KoenderinkMetricTensor[{0.5, 0.5, 0.5}];
MatrixForm[g]

(* 4. 3D visualization of the empirical field *)
Graphics3D[{
  Opacity[0.7],
  Specularity[White, 20],
  Map[
    {Apply[RGBColor, #], KoenderinkEllipsoid[#, "Scale" -> 2.0]} &,
    KoenderinkData["Points"]
  ]
},
  BoxRatios -> {1, 1, 1},
  PlotRange -> {{0, 1}, {0, 1}, {0, 1}},
  Axes -> True,
  AxesLabel -> {"R", "G", "B"},
  Background -> GrayLevel[0.15]
]
```

## Interactive Exploration

An interactive Mathematica notebook is included at [`examples/Exploration.nb`](examples/Exploration.nb), demonstrating:
* Empirical data inspection and matrix positive-definiteness verification.
* 3D rendering of the discrimination ellipsoids.
* Local vs. line-integral distance comparisons.
* Grain volume scaling along the achromatic axis (reproducing Figure 13 of the paper).

## Documentation

Standard Wolfram Reference Notebooks and Guides styled with `Reference.nb` are located in:
* Guide: [`Documentation/English/Guides/KoenderColor.nb`](Documentation/English/Guides/KoenderColor.nb)
* Reference Pages: [`Documentation/English/ReferencePages/Symbols/`](Documentation/English/ReferencePages/Symbols/)

To rebuild all documentation notebooks from source symbol usages, run:
```bash
wolframscript -file scripts/generate_docs.wl
```
## ToDo

- At some point, we should just implement this as a `ColorDistance` method in the Wolfram Language core, so that it can be used seamlessly with built-in functions like `Nearest`, `FindClusters`, and `ImageDistance`. For now, the paclet provides a standalone implementation.

## Reference

* Koenderink, J., van Doorn, A., Braun, D. I., & Gegenfurtner, K. R. (2026). *An empirical three-dimensional metric field for color space*. bioRxiv preprint [doi:10.64898/2026.03.09.710376](https://doi.org/10.64898/2026.03.09.710376).
