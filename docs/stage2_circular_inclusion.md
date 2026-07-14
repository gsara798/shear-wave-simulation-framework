# Stage 2 circular-inclusion benchmark

Stage 2 extends the validated directional 2D solver with ordered physical
geometry objects. The reference contains one circle centred on the domain
mid-plane with radius 8 mm. Background properties are `cs=2 m/s` and
`rho=1000 kg/m^3`; inclusion properties are `cs=3 m/s` and
`rho=1020 kg/m^3`.

The reference uses `Nx=96` and `Nz=95`. The odd axial count provides an
exact grid-node symmetry plane shared by the source, circle, and exterior
PMLs; the Stage 1 reference remains 96-by-96.

In reduced-compressional-speed mode, `cp` is resolved once as
`10*max(cs)=30 m/s` and remains spatially constant. This avoids introducing
an unintended compressional-speed boundary at the inclusion.

## Geometry contract

Objects are defined in metres with `center_m_xz` and `radius_m`. Rasterized
solver maps use `[Nx,Nz]`; saved public maps use `[Nz,Nx]`. Material ID 1 is
reserved for the background. Ordered composition is explicit: later objects
overwrite earlier objects where they overlap.

Preflight rejects objects that overlap the source, violate boundary
clearance, fall outside the required sensor ROI, have duplicate material IDs,
or exceed the 5% discrete-area error threshold.

## Acceptance suite

`kwsim.diagnostics.runStage2Validation` performs three simulations with the
same constant `cp`:

1. requested contrast inclusion;
2. homogeneous reference;
3. circle with background properties (zero contrast).

The zero-contrast axial phasor must agree with the homogeneous result within
`1e-6` relative L2 error. Inclusion-induced amplitude is obtained after
subtracting the homogeneous complex field. Its energy imbalance between the
two mirrored axial half-domains must not exceed 2%. Mirror correlation and
pointwise L2 mismatch are also reported but are not substituted for this
energy-based acceptance metric. Homogeneous subtraction prevents
staggered-grid source placement and common boundary residuals from being
misclassified as an asymmetric inclusion response.

`saveStage2Validation` writes both the complete MAT suite and a plain-text
table containing every cross-run acceptance value and threshold.
