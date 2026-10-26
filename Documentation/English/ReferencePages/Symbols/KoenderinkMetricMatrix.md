# KoenderinkMetricMatrix

`KoenderinkMetricMatrix[color]` returns the interpolated $3 \times 3$ symmetric positive-definite covariance matrix $\Sigma(\text{color})$ characterizing the local discrimination ellipsoid at `color`.

## Usage

* `KoenderinkMetricMatrix[color]`
  Returns the interpolated $\Sigma$ matrix at `color` in gamma sRGB space.
* `KoenderinkMetricMatrix[color, "Inverse" -> True]`
  Returns the Riemannian metric tensor $g(\text{color}) = \Sigma(\text{color})^{-1}$.
* `KoenderinkMetricMatrix[color, "ColorSpace" -> "LinearRGB"]`
  Evaluates the metric matrix in linear RGB space.

## Options

| Option | Default | Description |
|---|---|---|
| `"ColorSpace"` | `"sRGB"` | `"sRGB"` (Table A2) or `"LinearRGB"` (Table A3) |
| `"Bandwidth"` | `Automatic` | RBF bandwidth $\epsilon$ (default $\approx 5.55$, calibrated to weight $\approx 0.5$ at lattice nodes) |
| `"Neighborhood"` | `All` | Restrict interpolation to $k$ nearest neighbors (e.g. 6, 8, 14, or `All`) |
| `"Inverse"` | `False` | When `True`, returns the metric tensor $g = \Sigma^{-1}$ |

## Related Functions

* `KoenderinkMetricTensor[color, opts]`
  Equivalent to `KoenderinkMetricMatrix[color, "Inverse" -> True, opts]`.
* `KoenderinkEllipsoid[color, opts]`
  Returns a `Graphics3D` `Ellipsoid[coords, scale^2 * Sigma]` primitive for rendering discrimination regions.
* `KoenderinkData[]`
  Returns the empirical datasets containing the 35 measured BCC lattice locations and their corresponding $\Sigma$ matrices.

## Examples

Interpolate $\Sigma$ at the midpoint of RGB space:
```mathematica
Needs["KoenderColor`"]

sigma = KoenderinkMetricMatrix[{0.5, 0.5, 0.5}]
Eigenvalues[sigma]
```

Render discrimination ellipsoids in `Graphics3D`:
```mathematica
pts = KoenderinkData["Points", "sRGB"];

Graphics3D[
  {
    Map[
      {RGBColor @@ #, Opacity[0.6], KoenderinkEllipsoid[#, "Scale" -> 1.5]} &,
      pts
    ]
  },
  Axes -> True,
  AxesLabel -> {"R", "G", "B"},
  PlotRange -> {{0, 1}, {0, 1}, {0, 1}}
]
```

## See Also

* [KoenderinkColorDistance](KoenderinkColorDistance.md)
* [Ellipsoid](https://reference.wolfram.com/language/ref/Ellipsoid.html)
