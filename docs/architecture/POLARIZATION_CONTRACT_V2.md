# Polarization contract V2

Implemented as a new **additive** MATLAB module in `src/+swsynth/+polarization`. The legacy field synthesizers remain untouched until wavefield-level regressions have passed.

## Physics and module ownership

`swsynth.sources.excitation` describes the actuator **force vector, amplitude and phase**. `swsynth.polarization` computes *material displacement polarization* induced by the wave/radiation model. `swsynth.phase` supplies travel time. `swsynth.propagation` will combine them. The axis of an ultrasound probe or an OCT measurement belongs in `swsynth.observation`, **not** in polarization.

Entrypoint: `result = swsynth.polarization.compute(request)`; `swsynth.polarization.validate(request)` checks physical compatibility. `geometry`: `"2d"` (alias of `"planar2d"`), `"projected3d"`, `"volumetric3d"`.

### Plane shear waves

```matlab
req=struct("model","plane_wave","geometry","projected3d", ...
    "direction_xyz",[1 0 0;0 0 1], ...
    "policy","transverse_preferred", ...
    "reference_axis_xyz",[0 0 1]);
p=swsynth.polarization.compute(req);
```

Supported policies:
- `"in_plane_sv"`: `[k_z, 0, -k_x]`, normalized (deterministic fallback if k along y).
- `"transverse_random"`: random transverse vectors, with optional `request.stream=RandStream(...)`. For planar2d the only in-plane shear orientation is SV, up to random sign; projected3d and volumetric3d permit the whole transverse plane.
- `"transverse_preferred"`: project `reference_axis_xyz` perpendicular to the wavevector, normalize and use a deterministic transverse fallback when parallel. The reference axis need not be the measurement axis.
- `"transverse_explicit"`: caller supplies `explicit_polarization_xyz` N-by-3; all vectors must be transverse; normalized.

Returns `vector_xyz` and `unit_vector_xyz` (N-by-3), `magnitude` (N-by-1 ones), normalized `direction_xyz`, `model`, `geometry`, `policy`, and diagnostics. Vectors are dimensionless unit polarizations; amplitude and phase are **not** included.

### Point-force shear far-field

```matlab
req=struct("model","point_force_shear_far_field", ...
    "geometry","projected3d", ...
    "source_xyz_m",[0 .02 0], ...
    "observation_xyz_m",[.01 0 0;.02 0 .01], ...
    "force_direction_xyz",[0 1 0]);
p=swsynth.polarization.compute(req);
```

For each observation point `r`, with `n=(r-source)/norm(r-source)` and force unit vector `F`:

`p(r) = F - n * dot(n,F)`.

- `vector_xyz` is the **unnormalized far-field shear radiation vector** M-by-3; its magnitude carries physically important angular dependence and may be zero along the force axis.
- `unit_vector_xyz` is M-by-3 unit polarization, or zero where no shear radiation exists.
- `magnitude` is M-by-1 radiation strength, `radial_direction_xyz` M-by-3, `distance_m` M-by-1.
- Not included: wave propagation phase, material shear attenuation, spreading `1/r`, absolute force calibration, longitudinal-wave component, finite/aperture near field, ultrasound observation effects.

The new point-force implementation is tested against the existing `swsynth.propagation.spherical.point_source.shear_far_field.computeShearProjection`, without changing the legacy code. In 2D, point-force geometry and force are constrained to the x-z plane; projected3d can use off-plane sources and forces.

### Randomness and orientation

Optional `request.stream` controls random polarization without reseeding the global RNG. When omitted, MATLAB's global RNG is used. The new API is not yet integrated into `swsynth.run(cfg)`, and random draw patterns may differ from legacy synthesis. Regression tests in `tests/unit/test_swsynth_polarization_v2.m` cover transversality, degenerate cases, 2D/3D physics, stream behavior and point-force equivalence.

### Scope

This is an **isotropic far-field shear / plane-wave** polarization model. Do not apply it without modification to anisotropic shear polarization, mode conversion, boundaries, near-field point-force radiation, viscoelastic vector coupling, or imaging readout.
