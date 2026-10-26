(* ::Package:: *)
(* scripts/generate_docs.wl
   Automated documentation generator for KoenderColor paclet symbols.
   Generates standard Wolfram Reference Notebooks (.nb) and Guides
   styled with the native Wolfram Reference.nb stylesheet.
*)

Print["=================================================="];
Print["Generating KoenderColor Paclet Documentation..."];
Print["=================================================="];

Module[{
  repoRoot, docRootDir, guideDir, curatedUsages, seeAlsoMap,
  getSeeAlso, createDocNotebook, createGuideNotebook, totalCreated = 0
},
  repoRoot = DirectoryName[ExpandFileName[If[StringQ[$InputFileName] && $InputFileName =!= "", $InputFileName, "scripts/generate_docs.wl"]], 2];
  PacletDirectoryLoad[repoRoot];
  Needs["KoenderColor`"];

  docRootDir = FileNameJoin[{repoRoot, "Documentation", "English", "ReferencePages", "Symbols"}];
  guideDir   = FileNameJoin[{repoRoot, "Documentation", "English", "Guides"}];

  If[!DirectoryQ[docRootDir], CreateDirectory[docRootDir, CreateIntermediateDirectories -> True]];
  If[!DirectoryQ[guideDir], CreateDirectory[guideDir, CreateIntermediateDirectories -> True]];

  curatedUsages = <|
    "KoenderinkColorDistance" -> "KoenderinkColorDistance[c1, c2, opts] computes the perceptual color distance between colors c1 and c2 in units of Notable Qualitative Differences (NQD).",
    "KoenderinkMetricMatrix" -> "KoenderinkMetricMatrix[color, opts] computes the interpolated 3x3 symmetric positive-definite Sigma matrix at color.",
    "KoenderinkMetricTensor" -> "KoenderinkMetricTensor[color, opts] returns the Riemannian metric tensor g(color) = Inverse[KoenderinkMetricMatrix[color]].",
    "KoenderinkEllipsoid" -> "KoenderinkEllipsoid[color, opts] returns a Graphics3D Ellipsoid primitive representing the Notable Qualitative Difference (NQD) region at color.",
    "KoenderinkData" -> "KoenderinkData[] returns the empirical dataset of 35 reference colors and fitted Sigma matrices from Koenderink et al. (2026).",
    "KoenderinkWeights" -> "KoenderinkWeights[color, opts] computes the partition-of-unity Gaussian RBF weights for the 35 empirical reference points.",
    "FrobeniusMismatch" -> "FrobeniusMismatch[S, T] computes the normalized Frobenius mismatch ||S - T||_F / (||S||_F + ||T||_F) between two matrices.",
    "sRGBToLinearRGB" -> "sRGBToLinearRGB[rgb] converts gamma-encoded sRGB coordinates in [0, 1] to linear RGB.",
    "LinearRGBTosRGB" -> "LinearRGBTosRGB[rgb] converts linear RGB coordinates in [0, 1] to gamma-encoded sRGB."
  |>;

  seeAlsoMap = <|
    "Metric" -> {"KoenderinkColorDistance", "KoenderinkMetricMatrix", "KoenderinkMetricTensor", "KoenderinkEllipsoid"},
    "Data" -> {"KoenderinkData", "KoenderinkWeights", "FrobeniusMismatch"},
    "Transform" -> {"sRGBToLinearRGB", "LinearRGBTosRGB"}
  |>;

  getSeeAlso[symName_String] := Module[{matches},
    matches = Select[Values[seeAlsoMap], MemberQ[#, symName] &];
    If[Length[matches] > 0,
      DeleteCases[DeleteDuplicates[Flatten[matches]], symName],
      {"KoenderinkColorDistance", "KoenderinkMetricMatrix", "KoenderinkData"}
    ]
  ];

  formatSignatureBoxes[sig_String] := Module[{held, boxes, symHead},
    symHead = First[StringCases[sig, RegularExpression["^[A-Za-z0-9`]+"]]];
    held = Quiet @ Check[ToExpression[sig, InputForm, HoldComplete], Null];
    If[held =!= Null && MatchQ[held, HoldComplete[_[___]]],
      boxes = MakeBoxes @@ held;
      boxes = boxes /. s_String /; StringMatchQ[s, RegularExpression["[a-zA-Z][a-zA-Z0-9]*"]] && s =!= symHead && s =!= "List" && s =!= "Rule" && s =!= "Automatic" && s =!= "True" && s =!= "False" :> StyleBox[s, "TI"];
      boxes
    ,
      sig
    ]
  ];

  formatUsageCell[uText_String] := Module[{lines, gridRows},
    lines = Select[StringSplit[uText, "\n"], StringLength[StringTrim[#]] > 0 &];
    gridRows = Map[
      Function[{line},
        Module[{trimmed = StringTrim[line], parsed, sig, desc, sigBox},
          parsed = StringCases[trimmed, RegularExpression["(?s)^([A-Za-z0-9`]+(?:\\[[^\\]]*\\])?)\\s+(.*)$"] -> {"$1", "$2"}];
          If[Length[parsed] > 0,
            sig = parsed[[1, 1]];
            desc = parsed[[1, 2]];
            sigBox = formatSignatureBoxes[sig];
            {"", Cell[TextData[{Cell[BoxData[sigBox], "InlineFormula", FontFamily -> "Source Sans Pro"], "\[LineSeparator]", desc}]]}
          ,
            {"", Cell[TextData[{trimmed}]]}
          ]
        ]
      ],
      lines
    ];
    Cell[BoxData[GridBox[gridRows]], "Usage", CellID -> 982511436]
  ];

  createDocNotebook[symName_String, usageInput_, ctx_String, opts_List, seeAlsoList_List] := Module[
    {notesCells, seeAlsoCell, moreAboutCell, optionsRows, optionsTable, nbPath, usageText = ToString[usageInput]},

    If[opts =!= {},
      optionsRows = Map[
        Function[{opt},
          {
            "",
            Cell[BoxData[StyleBox[ToString[First[opt]], "InlineFormula"]]],
            Cell[BoxData[StyleBox[ToString[Last[opt]], "InlineFormula"]]]
          }
        ],
        opts
      ];
      optionsTable = Cell[BoxData[GridBox[optionsRows]], "2ColumnTableMod"];
      notesCells = {
        Cell["The following options can be given:", "Notes"],
        optionsTable
      };
    ,
      notesCells = {
        Cell[symName <> " has no options.", "Notes"]
      };
    ];

    seeAlsoCell = If[Length[seeAlsoList] > 0,
      Cell[TextData[
        Riffle[
          Map[
            Function[{s},
              Cell[BoxData[TemplateBox[{Cell[TextData[s]], "paclet:KoenderColor/ref/" <> s}, "RefLink", BaseStyle -> {"InlineFormula"}]]]
            ],
            seeAlsoList
          ],
          " \[FilledSmallSquare] "
        ]
      ], "SeeAlso"]
    ,
      Cell[TextData[{
        Cell[BoxData[TemplateBox[{Cell[TextData["KoenderColor Guide"]], "paclet:KoenderColor/guide/KoenderColor"}, "RefLink", BaseStyle -> {"InlineFormula"}]]]
      }], "SeeAlso"]
    ];

    moreAboutCell = Cell[TextData[{
      Cell[BoxData[
        TemplateBox[{Cell[TextData["KoenderColor Guide"]], "paclet:KoenderColor/guide/KoenderColor"}, "RefLink", BaseStyle -> {"MoreAbout"}]
      ]]
    }], "MoreAbout"];

    nbPath = FileNameJoin[{docRootDir, symName <> ".nb"}];
    Export[nbPath,
      Notebook[{
        Cell[ctx, "ContextNameCell"],
        Cell[CellGroupData[{
          Cell[symName, "ObjectName"],
          formatUsageCell[usageText],

          Cell[CellGroupData[Join[{Cell["Details and Options", "NotesSection"]}, notesCells], Closed]],

          Cell[CellGroupData[{
            Cell["Examples", "PrimaryExamplesSection"],
            Cell[CellGroupData[{
              Cell["Basic Examples", "ExampleSection"],
              Cell["Load the KoenderColor package:", "ExampleText"],
              Cell[BoxData[RowBox[{"Needs", "[", "\"KoenderColor`\"", "]"}]], "Input"]
            }, Open]]
          }, Open]],

          Cell[CellGroupData[{
            Cell["See Also", "SeeAlsoSection"],
            seeAlsoCell
          }, Open]],

          Cell[CellGroupData[{
            Cell["Related Guides", "MoreAboutSection"],
            moreAboutCell
          }, Open]]
        }, Open]]
      },
      TaggingRules -> <|
        "Metadata" -> <|
          "context" -> ctx,
          "type" -> "Symbol",
          "paclet" -> "KoenderColor",
          "language" -> "en",
          "title" -> symName,
          "windowtitle" -> symName,
          "uri" -> "KoenderColor/ref/" <> symName,
          "summary" -> usageText,
          "index" -> True
        |>
      |>,
      ScreenStyleEnvironment -> "Working",
      WindowTitle -> symName,
      StyleDefinitions -> FrontEnd`FileName[{"Wolfram"}, "Reference.nb"],
      FrontEndVersion -> "13.0+"
      ]
    ];
    nbPath
  ];

  createGuideNotebook[] := Module[{nbPath, guideSections, sectionsCells},
    guideSections = {
      "Metric & Color Distance" -> {"KoenderinkColorDistance", "KoenderinkMetricMatrix", "KoenderinkMetricTensor", "KoenderinkEllipsoid"},
      "Empirical Lattice Data & Interpolation" -> {"KoenderinkData", "KoenderinkWeights", "FrobeniusMismatch"},
      "Color Coordinate Conversions" -> {"sRGBToLinearRGB", "LinearRGBTosRGB"}
    };

    sectionsCells = Map[
      Function[{subsec},
        Module[{subTitle = subsec[[1]], symList = subsec[[2]], funcCells},
          funcCells = Map[
            Function[{sName},
              Module[{uText = Lookup[curatedUsages, sName, sName <> " function"], shortDesc, parsed, cleanDesc},
                shortDesc = First[StringSplit[uText, ". "]];
                If[!StringEndsQ[shortDesc, "."], shortDesc = shortDesc <> "."];
                parsed = StringCases[shortDesc, RegularExpression["(?s)^[A-Za-z0-9`]+(?:\\[[^\\]]*\\])?\\s+(.*)$"] -> "$1"];
                cleanDesc = If[Length[parsed] > 0,
                  ToUpperCase[StringTake[parsed[[1]], 1]] <> StringDrop[parsed[[1]], 1]
                ,
                  shortDesc
                ];
                Cell[TextData[{
                  Cell[BoxData[TemplateBox[{Cell[TextData[sName]], "paclet:KoenderColor/ref/" <> sName}, "RefLink", BaseStyle -> {"InlineFormula"}]]],
                  " \[LongDash] ",
                  cleanDesc
                }], "GuideText"]
              ]
            ],
            symList
          ];
          Cell[CellGroupData[Join[{Cell[subTitle, "GuideFunctionsSubsection"]}, funcCells], Open]]
        ]
      ],
      guideSections
    ];

    nbPath = FileNameJoin[{guideDir, "KoenderColor.nb"}];
    Export[nbPath,
      Notebook[{
        Cell[CellGroupData[{
          Cell["Categorization", "CategorizationSection"],
          Cell["Guide", "Categorization", CellLabel -> "Entity Type"],
          Cell["KoenderColor", "Categorization", CellLabel -> "Paclet Name"],
          Cell["KoenderColor`", "Categorization", CellLabel -> "Context"],
          Cell["KoenderColor/guide/KoenderColor", "Categorization", CellLabel -> "URI"]
        }, Closed]],
        Cell[CellGroupData[{
          Cell["KoenderColor Guide", "GuideTitle"],
          Cell["KoenderColor provides tools for analyzing and computing color differences using the 3D empirical metric field developed by Jan Koenderink, Andrea van Doorn, Doris Braun, and Karl Gegenfurtner (2026).", "GuideAbstract"],
          Cell[CellGroupData[Join[{Cell["Reference", "GuideReferenceSection"]}, sectionsCells], Open]]
        }, Open]]
      },
      TaggingRules -> <|
        "Metadata" -> <|
          "context" -> "KoenderColor`",
          "type" -> "Guide",
          "paclet" -> "KoenderColor",
          "language" -> "en",
          "title" -> "KoenderColor Guide",
          "windowtitle" -> "KoenderColor Guide",
          "uri" -> "KoenderColor/guide/KoenderColor",
          "summary" -> "Empirical 3D metric field for color space after Koenderink et al. (2026).",
          "index" -> True
        |>
      |>,
      ScreenStyleEnvironment -> "Working",
      WindowTitle -> "KoenderColor Guide",
      StyleDefinitions -> FrontEnd`FileName[{"Wolfram"}, "Reference.nb"],
      FrontEndVersion -> "13.0+"
      ]
    ];
    nbPath
  ];

  (* Run generation *)
  KeyValueMap[
    Function[{sName, uText},
      Module[{sym, opts},
        sym = ToExpression["KoenderColor`" <> sName];
        opts = Options[sym];
        createDocNotebook[sName, uText, "KoenderColor`", opts, getSeeAlso[sName]];
        totalCreated++;
      ]
    ],
    curatedUsages
  ];

  createGuideNotebook[];
  Print["Generated ", totalCreated, " symbol reference notebooks and Guide notebook."];
];
