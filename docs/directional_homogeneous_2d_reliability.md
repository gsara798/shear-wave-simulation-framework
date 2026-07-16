# Directional homogeneous 2D reliability contract

The directional homogeneous 2D benchmark answers one narrow question: can k-Wave 1.4.1 produce a stable,
directional, axial shear-wave field in a homogeneous 2D elastic medium with a
known speed? It does not yet validate inclusions, diffuse fields, arbitrary
power-law attenuation, physical compressional speed, or 3D propagation.

## Source reliability

The source is an axial velocity sine at one frequency. A three-cycle
half-cosine ramp prevents an instantaneous discontinuity. Source spectral
purity is measured only over the stationary recording interval; including the
ramp would incorrectly classify intentional startup shaping as harmonic
contamination.

Acceptance requires at least 99.9% of the demeaned stationary waveform energy
to be explained by the fitted fundamental.

The prescribed contact uses non-adjacent nodes because adjacent Dirichlet
velocity points in the elastic MATLAB solver were empirically found to grow
exponentially. Any recurrence is caught by the finite-field and stationarity
checks.

## Wave reliability

The solver records all four 2D split-velocity outputs. The energy diagnostic
uses both spatial components:

```text
P/S = (|Vx_P|^2 + |Vz_P|^2) / (|Vx_S|^2 + |Vz_S|^2)
```

The homogeneous directional benchmark requires `P/S <= 0.05`.

The shear speed is estimated by unwrapping phase along the source-center depth
and fitting a straight line against lateral distance. Samples below 20% of the
line maximum are excluded. Acceptance requires a relative error no greater
than 2% from the configured `cs`.

Steady state is assessed by independently fitting the first and second halves
of the eight recorded cycles. Their complex shear phasors must differ by no
more than 1% in relative L2 norm.

## Numerical reliability

Preflight requires:

- at least eight points per minimum shear wavelength;
- `0 < CFL <= 0.30` (the reference uses 0.20);
- `cp/cs > sqrt(4/3)`;
- exterior PML with at least eight points and positive absorption strength;
- CPU backend with single-precision solver arrays for the reference;
- a source radius of at least two grid points;
- a non-empty sensor ROI separated from source and boundaries;
- predicted split-field sensor storage below the configured memory limit.

The cross-run validation suite requires:

- repeated-run relative L2 error `<= 1e-7` on the same backend;
- complex correlation `>= 0.98` after interpolating a 25% finer grid onto the
  baseline coordinates;
- shear-speed difference between grids `<= 2%` of ground truth;
- interior-field relative difference `<= 1%` against a physically larger
  downstream domain with the same PML settings.

The suite returns every metric even when a threshold fails. A failed result is
scientific diagnostic evidence and must not be silently relabeled as valid.
