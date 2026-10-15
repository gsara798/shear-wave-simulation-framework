# Propagation modules

## New V2 harmonic synthesis orchestrator (additive, not yet used by legacy runs)

`+propagation/synthesize.m` coordinates `swsynth.domain.buildGrid`, `swsynth.medium.buildMaps`, the new shared drive `swsynth.excitation.resolve`, V2 physical sources **or** explicit plane-wave incidence, a compatible phase/polarization model, individual contributions and `swsynth.propagation.accumulate`. The result is a complex **vector** field and simulation metadata; sensor projection remains separate. See `docs/architecture/HARMONIC_SYNTHESIS_V2.md` and `tests/unit/test_swsynth_excitation_and_synthesize_v2.m`. No legacy `swsynth.run` backend is replaced. The initial V2 path stores all contributions in memory; a streaming reduction is pending.

## Coherent accumulation (V2, not yet integrated)

`+propagation/accumulate.m` coherently sums a nonempty cell/struct array of `plane_wave.computeContribution` and/or `spherical.point_source.computeContribution` results into one **complex vector wavefield**, validating shared frequency, spatial coordinates (including observation-plane y), geometry and phase sign before addition. Normalization is explicitly `none` (default) or `sqrt_count` (`1/sqrt(N)`); no scalar observation, noise, or wave physics is added. See `docs/architecture/PROPAGATION_ACCUMULATE_V2.md`. Tests: `tests/unit/test_swsynth_propagation_accumulate_v2.m`.

## New spherical point-source API (V2, not yet integrated)

`+spherical/+point_source/computeContribution.m` builds the *vector* 3D point-force shear far-field for one V2 physical source, optionally as a coherent line aperture; each node uses spherical analytical `T=r/c_s` from `swsynth.phase.compute` and unnormalized transverse radiation from `swsynth.polarization.compute`. Its outputs can be coherently accumulated across parent sources and combined with plane waves when units/conventions match. See `docs/architecture/SPHERICAL_POINT_SOURCE_CONTRIBUTION_V2.md`. Tests: `tests/unit/test_swsynth_spherical_point_source_contribution_v2.m`.

## Single-component plane-wave API (V2, not yet integrated)

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
