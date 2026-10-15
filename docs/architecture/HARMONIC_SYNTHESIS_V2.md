# Shared harmonic drive and V2 synthesis orchestration

**Status: new additive MATLAB API in `develop/v2`; tests must be executed in MATLAB.**
The legacy `swsynth.run`, `run3D`, `defaultConfig` and existing synthesizer backends are unchanged.

## Physical ownership

| Responsibility | Module | Key quantities |
|---|---|---|
| Computational grid | `swsynth.domain.buildGrid` | `geometry`, `x_m/z_m/y_m` or physical lengths and spacings |
| Elastic material | `swsynth.medium.buildMaps` | `cs_map_zx/zyx`, object masks/material IDs |
| Shared harmonic drive | `swsynth.excitation.resolve` | one `frequency_hz` per phasor field |
| Physical sources | `swsynth.sources.prepare` | position, force direction, relative amplitude, initial phase, coherent aperture |
| Plane wave incidence | `scenario.incidence` | propagation direction, amplitude, phase, **displacement** polarization |
| Physics | `swsynth.phase` / `swsynth.polarization` | travel time, transverse shear radiation |
| Superposition | `swsynth.propagation.accumulate` | coherent complex sum; explicit normalization |
| Future observation | `swsynth.observation` | projection, sampling, transducer/readout model |

**The drive is shared**: `scenario.excitation.frequency_hz` describes the frequency of all physical sources or plane-wave components of this **one harmonic solution**. It does not belong to `scenario.medium`, `scenario.domain`, or nested `scenario.sources.excitation`.

The source-level `sources.excitation` still independently chooses force orientations, **relative** amplitudes and initial phases, including a random phase or synchronized sources. Distinct source frequencies require a separate solution **for each frequency**, then an appropriate time-domain combination, never one mixed-frequency complex phasor.

`swsynth.excitation.resolve(struct("frequency_hz",500))` returns frequency, `omega_rad_s`, period, `quantity`, and inherited spatial phase sign. Default `quantity="relative_motion"`, meaning the result should **not** be reported as quantitatively calibrated displacement or velocity without a separately consistent physical amplitude model. Callers may use `quantity="displacement"` or `"velocity"` when their input amplitude scale already has the corresponding units: the current solver does not convert units.

To adapt an old configuration **without editing it**:
```matlab
drive = swsynth.excitation.fromLegacy(swsynth.defaultConfig3D());
% derives drive.frequency_hz from cfg.wavefield.frequency_hz
```

## End-to-end entrypoint

`result=swsynth.propagation.synthesize(scenario)`

The orchestrator:
1. canonicalizes geometry and resolves the spatial domain;
2. builds and validates the elastic `c_s` maps;
3. resolves a single global harmonic drive;
4. validates the propagation model and solver compatibility;
5. prepares physical sources **or** explicitly defined plane-wave incidence;
6. computes one field contribution per wave or **per physical parent source**, including all its coherent aperture nodes;
7. calls `swsynth.propagation.accumulate` with explicit normalization;
8. returns the complex vector field plus grid/material/drive/propagation metadata.

### Example A: planar, two plane waves

```matlab
scenario=struct();
scenario.geometry="2d";
scenario.domain=struct("x_m",.01:.001:.05, ...
    "z_m",.01:.001:.05,"observation_y_m",0);
scenario.medium=struct("cs_m_s",2);
scenario.excitation=struct("frequency_hz",500);
scenario.propagation=struct("model","plane_wave", ...
    "phase_method","analytical", ...
    "normalization","sqrt_count");
scenario.incidence=struct();
scenario.incidence.direction_xyz=[1 0 0;0 0 1];
scenario.incidence.relative_amplitude=[1;1];
scenario.incidence.phase_rad=[0;pi/2];
scenario.incidence.polarization=struct("policy","in_plane_sv");

result=swsynth.propagation.synthesize(scenario);
Uz=swsynth.observation.projectComponent(result.U_xyz,[0 0 1]);
```

A plane-wave component is defined by **propagation direction**, *not* by force direction of an actuator. `scenario.incidence.polarization.policy` is explicitly required; available policies follow `swsynth.polarization.compute`. `transverse_explicit` accepts a shared 1-by-3 or per-wave N-by-3 vector set. Amplitude and phase can be a scalar applied to all waves, or one value per wave. Defaults are amplitude 1 and phase 0, so runs are deterministic unless random polarization is explicitly requested.

### Example B: physical point-force sources with coherent apertures

```matlab
scenario=struct();
scenario.geometry="projected3d";
scenario.domain=struct("x_m",.005:.001:.04, ...
    "z_m",.005:.001:.04,"observation_y_m",0);
scenario.medium=struct("background_cs_m_s",2);
scenario.excitation=struct("frequency_hz",500);
scenario.propagation=struct("model","spherical_wave", ...
    "phase_method","analytical", ...
    "geometric_decay_exponent",1, ...
    "normalization","none");

scenario.sources=struct();
scenario.sources.count=2;
scenario.sources.positions=struct("method","explicit", ...
    "position_xyz_m",[0 .025 0;.02 -.025 0]);
scenario.sources.excitation=struct( ...
    "force_direction_xyz",[1 0 0;0 0 1], ...
    "relative_amplitude",[1;1], ...
    "phase_rad",[0;pi]);
scenario.sources.aperture=struct( ...
    "model","line_segment","span_m",.002, ...
    "axis_xyz",[1 0 0],"node_spacing_m",.001);

result=swsynth.propagation.synthesize(scenario);
Uz=swsynth.observation.projectComponent(result.U_xyz,[0 0 1]);
```

`scenario.sources` follows the **source preparation request** contract, not a precomputed `source_bundle`. For a single source, a point aperture is assumed when aperture is omitted. Each parent's coherent nodes share phase and force orientation; `normalization="sqrt_count"` divides by square root of the count of *physical sources*, **not** the number of aperture elements.

For projected3d physical sources, the sources may be off the observation x-z plane; their radiation is full 3D before sampling the slice.

## Compatibility, model limits and validation

- Valid geometry: `2d`/`planar2d`, `projected3d`, `volumetric3d`.
- Plane wave: homogeneous analytical phase in all geometries; **directional Eikonal** for `projected3d` and `volumetric3d`. Eikonal is explicitly unsupported for `2d` in the current V2 phase router.
- Point-force spherical wave: **only homogeneous analytical** travel time `r/c_s`; heterogeneous material and spherical Eikonal are rejected until implemented.
- Homogeneous analytical phase checks **actual material map uniformity**, not only whether the user supplied objects.
- **Projected3d plane-wave phase** currently corresponds to `observation_y_m=0`; nonzero observation planes are rejected until the travel-time phase reference is generalized. Projected3d spherical sources allow any finite observation-y plane.
- `geometric_decay_exponent` is restricted to spherical waves, default 0 to preserve historical synthetic conventions. Exponent 1 gives the relative three-dimensional far-field `1/r` term, not a calibrated elastodynamic Green tensor.
- `normalization="none"` (default) or `"sqrt_count"` is applied **only once**, after summing components.
- No ultrasound receiver, mechanical viscosity, shear attenuation, near-field/longitudinal Green terms, anisotropy, scattering, reflections, externally calibrated source force, or absolute displacement/velocity conversion is implied by this V2 API.
- Relative harmonic waves use `exp(+i*(omega*T+phase_0))` **spatial phasors**, matching the standalone contributions' historical algebraic sign. The temporal sign choice of a future `u(r,t)` reconstruction must be specified separately.
- Random generation is delegated to individual source and polarization modules; supply caller-owned `RandStream` instances to isolate global RNG where random policies are used.
- The first V2 synthesizer holds each component field in a cell until accumulation. For large source counts and volumetric datasets, a future streaming/reduction implementation is needed to reduce peak memory use.
- The new medium model is speed-prescribed; density is optional metadata and does not currently affect amplitudes. Medium is independent of frequency. Do **not** claim time/frequency dispersion from this model.

Output `result` includes `U_xyz` (complex `[Nz,Nx,3]` or `[Nz,Ny,Nx,3]`), `field` (coherent accumulator result), `domain`, `medium`, `excitation`, `propagation`, `model`, `geometry`, `component_count`, `quantity`, plus `sources` or `incidence` metadata as applicable. It does **not** save each intermediate component field.

Tests: `tests/unit/test_swsynth_excitation_and_synthesize_v2.m`; run with `test_swsynth_domain_build_grid_v2.m`, `test_swsynth_medium_build_maps_v2.m`, `test_swsynth_sources_prepare_v2.m`, and the standalone contribution/accumulator tests.
