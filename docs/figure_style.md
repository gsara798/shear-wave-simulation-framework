# Figure style and scientific notation

All project-generated figures use `kwsim.common.figureTemplate` followed by
`kwsim.common.applyFigureStyle`. The shared defaults are Times New Roman,
12 pt axes/labels/panel titles, an optional 14 pt figure title, 11 pt legends,
and 300 dpi export.

Scientific labels follow these rules:

- axes identify the physical coordinate and unit, for example
  `Lateral position, x (mm)` and `Axial position, z (mm)`;
- amplitudes are written as phasor magnitudes, such as `|U_z|`;
- phases use `angle U_z` and radians;
- shear and compressional components use superscripts `(S)` and `(P)`;
- decibel maps state the exact amplitude ratio represented by
  `20 log10(...)`;
- velocity uses `V_z` and displacement uses `U_z`;
- phase maps are displayed throughout the ROI. Their reliability is assessed
  from the accompanying amplitude map rather than hidden by a plotting mask.

New plotting functions should read the template rather than defining local
font sizes or export resolutions.
