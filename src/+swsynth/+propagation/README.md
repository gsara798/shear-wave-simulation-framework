# Propagation modules

## New single-component plane-wave API (V2, not yet integrated)

`+plane_wave/computeContribution.m` constructs **one complex vector shear-wave contribution** from the existing `swsynth.phase.compute` and `swsynth.polarization.compute` modules. It supports analytical 2D/projected3d/volumetric3d incidence and supported directional eikonal routes, with spatial output `[Nz,Nx,3]` or `[Nz,Ny,Nx,3]`, final dimension `[Ux,Uy,Uz]`. It does not resample excitation, add noise, normalize a multi-wave ensemble or project onto an observation axis. Read `docs/architecture/PLANE_WAVE_CONTRIBUTION_V2.md` for the API and the explicit algebraic phase sign. Regression tests: `tests/unit/test_swsynth_plane_wave_contribution_v2.m`. This is an additive API; legacy field synthesizers are unchanged.


- `+plane_wave/synthesizeObserved2D.m`: compatibility entrypoint for directional plane-wave observations.
- `+spherical/+point_source/+shear_far_field/computeShearProjection.m`: canonical 3D transverse far-field polarization projector, shared across observation geometries.
- `+spherical/+point_source/+shear_far_field/synthesize2D.m`: planar observation of a **3D point source** (not a true 2D line-force Green function).
- `+spherical/+point_source/+shear_far_field/synthesizeProjected3D.m`: arbitrary 3D point sources observed on an x-z plane.
- `+spherical/+point_source/+shear_far_field/synthesizeVolumetric3D.m`: homogeneous 3D field with explicit point forces and selected measurement axis.

The first two spherical observation adapters intentionally call the existing `swsynth.synthesizeWavefield2D` numerical implementation to preserve output and seeded random-number behavior. The historical `computePointForceShearProjection` remains as a forwarding compatibility wrapper. Do not remove these wrappers until downstream usages have been audited.

## Phase organization

`propagation.phase_model` is **a configuration choice**, not a physical source type. Keep it as a property of a propagation model; only extract a shared `+phase` module if multiple models truly share reusable travel-time solvers. A generic `+phase_model` package would couple unrelated numerical methods.

For volumetric point forces, only homogeneous `homogeneous_analytic` phase is supported. The model is transverse far field, **not** a full elastodynamic Green tensor. The power-law geometric decay is configurable, with exponent 1 describing 3D spherical far-field spreading. Using exponent 0 retains the prior unscaled synthetic convention. No shear-wave attenuation or longitudinal/near-field terms are included.

## Regression tests

From the repo root in MATLAB:

```matlab
addpath(fullfile(pwd,'src'));
r = runtests('tests/unit/test_swsynth_modular_point_source.m');
disp(table(r));
assertSuccess(r);
```

To run the existing radiation and aperture tests too:

```matlab
r = runtests({'tests/unit/test_swsynth_point_force_radiation.m', ...
    'tests/unit/test_swsynth_finite_aperture.m', ...
    'tests/unit/test_swsynth_modular_point_source.m'});
assertSuccess(r);
```

These tests need MATLAB; they were added but could not be executed in the repository-editing environment.
