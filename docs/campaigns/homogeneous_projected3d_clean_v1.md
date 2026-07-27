# Homogeneous projected-3D clean campaign v1

## Scientific purpose

This is the first reproducible scientific reference family for the REQ-ML
rebuild.

It studies homogeneous wavefields generated from propagation directions
sampled in three dimensions and observed on the public two-dimensional
`U(z,x)` plane.

This is a projected-3D wavefield campaign. It is not a volumetric
`U(z,y,x)` simulation.

## Parameter grid

- background SWS: 2.0, 2.5, 3.0, 3.5, and 4.0 m/s;
- frequency: 300, 400, 500, and 600 Hz;
- three-dimensional direction count: 1, 4, 8, 32, and 128;
- independent random seeds: 3101, 3102, and 3103.

Total:

```text
5 SWS values × 4 frequencies × 5 direction counts × 3 seeds
= 300 wavefield samples
```

## Directional regimes

- `N=1`: single projected three-dimensional direction;
- `N=4`: sparse partial-3D field;
- `N=8`: low-order partial-3D field;
- `N=32`: dense partial-3D field;
- `N=128`: approximately diffuse projected-3D field.

Directions are sampled on the full sphere. Polarization is transverse and
three-dimensional. The measured output remains the axial component on the
`z-x` observation plane.

## Fixed settings

- 50 mm × 50 mm observation plane;
- 0.5 mm isotropic sampling;
- homogeneous medium;
- plane-wave superposition;
- full-sphere three-dimensional direction support with at least one exactly in-plane direction for stable observation-plane estimation;
- transverse random polarization;
- effectively noise-free output;
- internal parallel execution enabled.

## Parallel execution

`execution.use_parallel=true` enables the internal `parfor` implementation in
`swsynth`.

The campaign engine still executes runs sequentially. Parallelism occurs
inside each run, avoiding nested parallel campaigns and preserving clear
resume semantics.

## Intended use

This campaign supports:

1. directional-to-diffuse projected-3D reference analysis;
2. geometry-dependent REQ quantile analysis;
3. initial feature-distribution inspection;
4. grouped train/test controls;
5. end-to-end campaign-to-dataset validation.

It is a homogeneous control family, not the final heterogeneous training
dataset.
