# KoenderinkColorDistance

`KoenderinkColorDistance[c1, c2]` computes the perceptual color distance between `c1` and `c2` in units of Notable Qualitative Differences (NQD) using the empirical metric field from Koenderink et al. (2026).

## Usage

* `KoenderinkColorDistance[c1, c2]`
  Computes the distance between `c1` and `c2` using the midpoint Riemannian metric.
* `KoenderinkColorDistance[c1, c2, "Method" -> "LineIntegral"]`
  Integrates the Riemannian arc length along the straight color trajectory from `c1` to `c2`.
* `KoenderinkColorDistance[c1, c2, "Method" -> "Geodesic"]`
  Finds the geodesic path between `c1` and `c2` minimizing path length.

## Options

| Option | Default | Description |
|---|---|---|
| `"Method"` | `"Midpoint"` | Integration method: `"Midpoint"`, `"LineIntegral"`, or `"Geodesic"` |
| `"ColorSpace"` | `"sRGB"` | Base stimulus space: `"sRGB"` or `"LinearRGB"` |
| `"Bandwidth"` | `Automatic` | Spatial bandwidth $\epsilon$ for Gaussian RBF interpolation |
| `"Steps"` | `20` | Number of discretization segments for integration |

## Examples

Basic distance between two colors:
```mathematica
Needs["KoenderColor`"]

c1 = RGBColor[0.5, 0.5, 0.5];
c2 = RGBColor[0.6, 0.5, 0.5];

KoenderinkColorDistance[c1, c2]
```

Compare midpoint vs line integral along the achromatic axis:
```mathematica
cBlack = RGBColor[0.2, 0.2, 0.2];
cWhite = RGBColor[0.8, 0.8, 0.8];

KoenderinkColorDistance[cBlack, cWhite, "Method" -> "Midpoint"]
KoenderinkColorDistance[cBlack, cWhite, "Method" -> "LineIntegral", "Steps" -> 50]
```

Evaluate distance in linear RGB:
```mathematica
KoenderinkColorDistance[{0.2, 0.2, 0.2}, {0.3, 0.2, 0.2}, "ColorSpace" -> "LinearRGB"]
```

## See Also

* [KoenderinkMetricMatrix](KoenderinkMetricMatrix.md)
* [KoenderinkEllipsoid](KoenderinkMetricMatrix.md)
* [ColorDistance](https://reference.wolfram.com/language/ref/ColorDistance.html)
