# Plane-wave contribution V2 — additive implementation

New API: `swsynth.propagation.plane_wave.computeContribution(request)`

**Status:** implemented; MATLAB test execution still required. No legacy synthesizer has been replaced and this function synthesizes **one** harmonic incident plane-wave component rather than a multi-source field.

## Motivation

The source's applied force vector is *not* a synonym for the direction of plane-wave incidence. The new contribution uses:
- The incident wave unit vector `direction_xyz`.
- Phase/travel time from `swsynth.phase.compute`.
- **Shear displacement** polarization from `swsynth.polarization.compute`, not actuator-force orientation.
- Explicit real nonnegative scalar `amplitude` and constant initial `phase_rad`.

It does not draw amplitude/phase from RNG, add noise, model viscosity/attenuation, or project the motion onto a measurement axis. Such operations belong to other modules. It does not normalize by `sqrt(N)`, because normalization across waves belongs to the upcoming multi-wave synthesizer.

## Inputs

```matlab
request=struct();
request.geometry="2d";  % also accepts planar2d, projected3d, volumetric3d
request.direction_xyz=[1 0 0];          % incidence, 1x3, normalizes
request.frequency_hz=500;
request.amplitude=2;                    % optional, defaults 1
request.phase_rad=pi/3;                 % optional, defaults 0
request.phase=struct("method","analytical", ...
    "reference_cs_m_s",2, ...
    "x_m",0:.001:.02,"z_m",0:.001:.02);
request.polarization=struct("policy","in_plane_sv");
component=swsynth.propagation.plane_wave.computeContribution(request);
```

`phase.method`: `"analytical"` (or `"homogeneous_analytic"`) for all three geometries, and `"eikonal"` for `"projected3d"` or `"volumetric3d"`. Eikonal needs the relevant `phase.cs_map_zx` or `phase.cs_map_zyx`; optional `phase.solver_options`. Volumetric requests also need `phase.y_m`.

`polarization.policy`: supplied explicitly rather than silently inferring a polarization or sampling the global RNG. Available options are `"in_plane_sv"`, `"transverse_preferred"`, `"transverse_explicit"`, and `"transverse_random"`. Options requiring extra inputs must include them in `request.polarization`; to avoid global RNG use a `RandStream` for random polarization.

Top-level direction, geometry and wave type are authoritative. If the nested phase/polarization requests duplicate them inconsistently, the call fails instead of silently choosing a different wave.

## Physical and numerical convention

For ONE plane wave:

```text
omega = 2*pi*frequency_hz
scalar_phasor(r) = amplitude * exp( +1i*(omega*T(r) + phase_rad) )
U_xyz(r) = scalar_phasor(r) * polarization_xyz
```

The spatial sign `+1i*omega*T` intentionally agrees with the historical code's `exp(+1i*phase)` **algebraic spatial phasor** convention. **Sign caution:** paired with the temporal convention `Re{U exp(+i omega t)}`, a positive spatial phase gradient denotes propagation in the *opposite* direction. The time-sign/spatial-sign relationship must be made explicit when a physical real-time renderer is integrated. This is not a silent redefinition of the traveling-wave convention.

The `amplitude` parameter scales the vector displacement or velocity phasor according to the units chosen by the caller; polarization is dimensionless and `T` is in seconds. This function does not convert velocity into displacement or vice versa. The old `swsynth.defaultConfig3D` can use a velocity quantity; such quantity choices must be handled by the calling orchestrator.

For projected3d, `swsynth.phase.analytical.projected3d` returns the x-z slice at **y=0**. The contribution cannot yet be requested at arbitrary observation-y; doing so requires extending the phase contract rather than adding an untracked phase offset.

## Output

```matlab
component.U_xyz                % complex [Nz,Nx,3] or [Nz,Ny,Nx,3]
component.scalar_phasor        % complex [Nz,Nx] or [Nz,Ny,Nx]
component.travel_time_s        % corresponding real scalar travel-time grid
component.polarization_xyz     % 1x3 transverse displacement polarization
component.direction_xyz        % 1x3 normalized incident propagation vector
component.phase_sign           % +1 legacy spatial phase sign
component.phase_solver
component.phase_diagnostics
component.polarization_diagnostics
component.output_convention
```

`U_xyz` has LAST index `x,y,z` displacement components, **not** `U_xzy`; its spatial grid is [z,x] for 2d/projected3d or [z,y,x] for volumetric3d. It can be passed to `swsynth.observation.projectComponent(component.U_xyz,[0 0 1])` to obtain a signed axial component without losing the full physical vector field.

## Scope and next step

The logical next step is `swsynth.propagation.accumulate` for coherent superposition with explicit normalization, followed by the spherical point-source contribution. The new one-component function is **not** yet called by `swsynth.propagation.synthesize` or by the legacy synthesizers.

Tests: `tests/unit/test_swsynth_plane_wave_contribution_v2.m`. The tests check analytic 2D/projected3d/volumetric fields, homogeneous eikonal equivalence, explicit phase/amplitude, axis projection, geometry errors and polarization transversality.
