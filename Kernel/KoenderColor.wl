(* ::Package:: *)

BeginPackage["KoenderColor`"];

KoenderinkData::usage = 
  "KoenderinkData[] returns the empirical dataset of 35 reference colors and fitted Sigma matrices from Koenderink et al. (2026).\n" <>
  "KoenderinkData[space] returns the list of points and matrices for \"sRGB\" (default) or \"LinearRGB\".\n" <>
  "KoenderinkData[\"Points\", space] returns the list of reference coordinate vectors.\n" <>
  "KoenderinkData[\"Sigmas\", space] returns the list of empirical Sigma matrices.";

KoenderinkWeights::usage = 
  "KoenderinkWeights[color, opts] computes the partition-of-unity Gaussian RBF weights for the 35 empirical reference points.";

KoenderinkMetricMatrix::usage = 
  "KoenderinkMetricMatrix[color, opts] computes the interpolated 3x3 symmetric positive-definite Sigma matrix at color.\n" <>
  "Options include \"ColorSpace\" (\"sRGB\" or \"LinearRGB\"), \"Bandwidth\", and \"Neighborhood\".";

KoenderinkMetricTensor::usage = 
  "KoenderinkMetricTensor[color, opts] returns the Riemannian metric tensor g(color) = Inverse[KoenderinkMetricMatrix[color]].";

KoenderinkEllipsoid::usage = 
  "KoenderinkEllipsoid[color, opts] returns a Graphics3D Ellipsoid primitive representing the Notable Qualitative Difference (NQD) region at color.";

KoenderinkColorDistance::usage = 
  "KoenderinkColorDistance[c1, c2, opts] computes the perceptual color distance between colors c1 and c2.\n" <>
  "\"Method\" can be \"Midpoint\" (default chord metric), \"LineIntegral\", or \"Geodesic\".";

FrobeniusMismatch::usage = 
  "FrobeniusMismatch[S, T] computes the normalized Frobenius mismatch ||S - T||_F / (||S||_F + ||T||_F) between two matrices.";

sRGBToLinearRGB::usage = 
  "sRGBToLinearRGB[rgb] converts gamma-encoded sRGB coordinates in [0, 1] to linear RGB.";

LinearRGBTosRGB::usage = 
  "LinearRGBTosRGB[rgb] converts linear RGB coordinates in [0, 1] to gamma-encoded sRGB.";

Begin["`Private`"];

(* --- Load Raw Empirical Data --- *)
$PackageDir = DirectoryName[$InputFileName];
$DataFile = FileNameJoin[{$PackageDir, "Data.wl"}];
$EmpiricalData = If[FileExistsQ[$DataFile], Get[$DataFile], <|"sRGB" -> {}, "LinearRGB" -> {}|>];

(* --- Data Accessor --- *)
KoenderinkData[] := $EmpiricalData;
KoenderinkData[space : ("sRGB" | "LinearRGB")] := Lookup[$EmpiricalData, space, {}];
KoenderinkData["Points", space : ("sRGB" | "LinearRGB") : "sRGB"] := 
  Lookup[#, "Point"] & /@ KoenderinkData[space];
KoenderinkData["Sigmas", space : ("sRGB" | "LinearRGB") : "sRGB"] := 
  Lookup[#, "Sigma"] & /@ KoenderinkData[space];

(* --- Coordinate helpers --- *)
toCoords[RGBColor[r_, g_, b_, ___]] := N[{r, g, b}];
toCoords[{r_?NumericQ, g_?NumericQ, b_?NumericQ}] := N[{r, g, b}];
toCoords[other_] := (Message[KoenderinkMetricMatrix::invcolor, other]; $Failed);

KoenderinkMetricMatrix::invcolor = "`` is not a valid RGB color specification.";

sRGBToLinearRGB[c_?NumericQ] := 
  If[c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055)^2.4];
sRGBToLinearRGB[rgb_List] := sRGBToLinearRGB /@ rgb;
sRGBToLinearRGB[RGBColor[r_, g_, b_, a___]] := 
  RGBColor[Sequence @@ (sRGBToLinearRGB /@ {r, g, b}), a];

LinearRGBTosRGB[c_?NumericQ] := 
  If[c <= 0.0031308, 12.92 * c, 1.055 * (c^(1 / 2.4)) - 0.055];
LinearRGBTosRGB[rgb_List] := LinearRGBTosRGB /@ rgb;
LinearRGBTosRGB[RGBColor[r_, g_, b_, a___]] := 
  RGBColor[Sequence @@ (LinearRGBTosRGB /@ {r, g, b}), a];

(* Default bandwidth: tuned so that weight at sampled point ~= 0.5 (paper lines 394-396, 624-626) *)
$DefaultBandwidth = Sqrt[Log[8.0]] / (0.15 * Sqrt[3.0]); (* ~ 5.55036 *)

(* --- RBF Weights --- *)
Options[KoenderinkWeights] = {
  "ColorSpace" -> "sRGB",
  "Bandwidth" -> Automatic,
  "Neighborhood" -> All
};

KoenderinkWeights[color_, OptionsPattern[]] := Module[{
  pt = toCoords[color],
  space = OptionValue["ColorSpace"],
  eps = OptionValue["Bandwidth"],
  kNeigh = OptionValue["Neighborhood"],
  pts, dists, phi, weights
},
  If[pt === $Failed, Return[$Failed]];
  pts = KoenderinkData["Points", space];
  If[eps === Automatic, eps = $DefaultBandwidth];
  dists = EuclideanDistance[pt, #] & /@ pts;
  
  If[IntegerQ[kNeigh] && kNeigh < Length[pts],
    Module[{ordering = Ordering[dists, kNeigh], mask},
      phi = ConstantArray[0.0, Length[pts]];
      phi[[ordering]] = Exp[-(eps * dists[[ordering]])^2];
    ],
    phi = Exp[-(eps * dists)^2];
  ];
  
  weights = phi / Total[phi];
  weights
];

(* --- Metric Matrix & Metric Tensor --- *)
Options[KoenderinkMetricMatrix] = {
  "ColorSpace" -> "sRGB",
  "Bandwidth" -> Automatic,
  "Neighborhood" -> All,
  "Inverse" -> False
};

KoenderinkMetricMatrix[color_, opts : OptionsPattern[]] := Module[{
  weights = KoenderinkWeights[color, FilterRules[{opts}, Options[KoenderinkWeights]]],
  space = OptionValue[KoenderinkMetricMatrix, {opts}, "ColorSpace"],
  invert = TrueQ[OptionValue[KoenderinkMetricMatrix, {opts}, "Inverse"]],
  sigmas, sigmaInterp
},
  If[weights === $Failed, Return[$Failed]];
  sigmas = KoenderinkData["Sigmas", space];
  sigmaInterp = Total[weights * sigmas];
  If[invert, Inverse[sigmaInterp], sigmaInterp]
];

Options[KoenderinkMetricTensor] = Options[KoenderinkMetricMatrix];
KoenderinkMetricTensor[color_, opts : OptionsPattern[]] := 
  KoenderinkMetricMatrix[color, "Inverse" -> True, opts];

(* --- Ellipsoid Primitive --- *)
Options[KoenderinkEllipsoid] = Join[
  {
    "Scale" -> 1.0
  },
  Options[KoenderinkMetricMatrix]
];

KoenderinkEllipsoid[color_, opts : OptionsPattern[]] := Module[{
  pt = toCoords[color],
  scale = OptionValue["Scale"],
  matOpts = FilterRules[{opts}, Options[KoenderinkMetricMatrix]],
  sigma
},
  If[pt === $Failed, Return[$Failed]];
  sigma = KoenderinkMetricMatrix[color, matOpts];
  If[sigma === $Failed, Return[$Failed]];
  (* Ellipsoid[center, A] represents (x-center).Inverse[A].(x-center) <= 1 *)
  Ellipsoid[pt, (scale^2) * sigma]
];

(* --- Distance Metric --- *)
Options[KoenderinkColorDistance] = {
  "Method" -> "Midpoint",
  "ColorSpace" -> "sRGB",
  "Bandwidth" -> Automatic,
  "Steps" -> 20
};

KoenderinkColorDistance[c1_, c2_, OptionsPattern[]] := Module[{
  p1 = toCoords[c1],
  p2 = toCoords[c2],
  method = OptionValue["Method"],
  space = OptionValue["ColorSpace"],
  bw = OptionValue["Bandwidth"],
  steps = OptionValue["Steps"],
  delta, mid, gMid
},
  If[p1 === $Failed || p2 === $Failed, Return[$Failed]];
  delta = p2 - p1;
  If[Norm[delta] == 0., Return[0.]];

  Switch[method,
    "Midpoint" | "Local" | "Chord",
    mid = (p1 + p2) / 2.;
    gMid = KoenderinkMetricTensor[mid, "ColorSpace" -> space, "Bandwidth" -> bw];
    Sqrt[Max[0., delta . gMid . delta]],

    "LineIntegral" | "Trapezoid",
    (* Simpson / Trapezoid numerical quadrature along straight segment in color space *)
    Module[{ts, dt, pts, gVals, integrand},
      dt = 1.0 / steps;
      ts = Subdivide[0.0, 1.0, steps];
      pts = (1 - #) p1 + # p2 & /@ ts;
      gVals = KoenderinkMetricTensor[#, "ColorSpace" -> space, "Bandwidth" -> bw] & /@ pts;
      integrand = Sqrt[Max[0., delta . # . delta]] & /@ gVals;
      (* Trapezoidal rule *)
      dt * (0.5 * First[integrand] + Total[integrand[[2 ;; -2]]] + 0.5 * Last[integrand])
    ],

    "Geodesic",
    (* Discretized path relaxation (energy minimization) *)
    Module[{dt, path0, pathVars, pathCost, sol, pathPoints},
      path0 = Subdivide[p1, p2, steps];
      pathVars = Table[Unique["p"], {steps - 1}];
      pathCost = Function[vars,
        Module[{allPts = Join[{p1}, vars, {p2}], segs, mids, segCost},
          segs = Differences[allPts];
          mids = MovingAverage[allPts, 2];
          Total[MapThread[
            Function[{s, m},
              Sqrt[Max[10^-12, s . KoenderinkMetricTensor[m, "ColorSpace" -> space, "Bandwidth" -> bw] . s]]
            ],
            {segs, mids}
          ]]
        ]
      ];
      sol = FindMinimum[pathCost[pathVars], Transpose[{Flatten[pathVars], Flatten[path0[[2 ;; -2]]]}]];
      First[sol]
    ],

    _,
    Message[KoenderinkColorDistance::invmeth, method];
    $Failed
  ]
];

KoenderinkColorDistance::invmeth = "Method `` is not one of {\"Midpoint\", \"LineIntegral\", \"Geodesic\"}.";

(* --- Frobenius Mismatch --- *)
FrobeniusMismatch[S_?MatrixQ, T_?MatrixQ] := Module[{
  diffNorm = Norm[S - T, "Frobenius"],
  normSum = Norm[S, "Frobenius"] + Norm[T, "Frobenius"]
},
  If[normSum == 0., 0., diffNorm / normSum]
];

End[];

EndPackage[];
