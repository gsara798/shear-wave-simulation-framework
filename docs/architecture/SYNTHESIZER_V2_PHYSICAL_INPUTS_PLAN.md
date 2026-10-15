# Synthesizer V2: domain, medium, harmonic drive — integration plan

**Status: `domain.buildGrid` and `medium.buildMaps` are implemented as standalone V2 APIs; shared-drive configuration and synthesizer orchestration remain proposals.** The legacy implementations `swsynth.buildMediumMaps` and `swsynth.buildMediumMaps3D` already build grids and material maps, while `swsynth.defaultConfig` and `swsynth.defaultConfig3D` contain the original settings. The new modules are documented in [DOMAIN_MEDIUM_V2.md](DOMAIN_MEDIUM_V2.md) and are not yet invoked by the legacy simulation runners. Keep legacy generation paths unchanged until regression-tested.

## Physical responsibilities

1. **`+domain` / grid** owns spatial coordinates and computational layout. Inputs: geometry (planar2d / projected3d / volumetric3d), physical origin/FOV, spatial increments or explicit axes `x_m`, `y_m`, `z_m`. Outputs: canonical coordinate vectors, sizes, spatial shape and `observation_y_m` for slice geometries. It does **not** own material speed, frequency, measurement resolution or noise. For projected3d, the observation grid is 2D but source positions may be 3D; do not automatically reject off-plane sources.

2. **`+medium`** owns frequency-independent material specification: background `cs_m_s` (or `shear_modulus_pa` with density), density `density_kg_m3` if modeling calibrated elastodynamics, heterogeneities/inclusions and optional constitutive viscoelastic model. Create medium maps on a supplied domain grid: `cs_map_zx` or `cs_map_zyx`, material IDs and potentially density/constitutive parameter maps. Derive `k(r,omega)` **after** choosing the drive frequency, not while defining the domain or medium. Do not claim density changes the present relative-amplitude V2 far-field model when it is not used.

3. **Harmonic `excitation` (drive)** owns one global `frequency_hz` per coherent phasor solution. Source-level `sources.excitation` retains per-source force directions, relative amplitudes and initial phases; `sources.positions` retains actuator positions, and `sources.aperture` retains coherent emitter elements. This models a common drive frequency across independent physical sources. The frequency is physically an excitation parameter, **not a spatial-grid or material parameter**. Legacy `cfg.wavefield.frequency_hz` can be mapped by an adapter to one canonical new frequency; do not keep competing independent copies. For multi-frequency sources, solve a separate complex wavefield per frequency and combine them in time, not as a single `accumulate` phasor.

4. **`+phase`** computes `T(r)` or a consistent frequency-dependent phase using the domain and medium. **`+polarization`** computes direction/strength of shear displacement from propagation or point force. **`+propagation`** computes contributions and coherently accumulates fields. A model selector explicitly controls plane wave versus 3D point-force far-field, analytic/Eikonal/straight ray and geometric decay exponent; no unsupported physics substitution.

5. **`+observation`** projects or samples the physical vector field. Its sensor FOV, spatial averaging, sampling frequency and ultrasound attenuation **must not silently change** the computational domain or the true mechanical wavefield. Ultrasound system modeling remains deferred.

6. **`+synthesize` orchestration** will build/validate a domain, generate medium maps, prepare sources or plane-wave incidences, resolve common frequency/phasor sign, compute individual contributions, accumulate and return a vector field with axes, geometry, model, units, seeds and provenance.

## Proposed configuration shape — for design discussion, not runnable yet

```matlab
scenario.geometry = "projected3d";
scenario.domain = struct( ...
    "x_m",0:0.0002:0.05, ...
    "z_m",0:0.0002:0.05, ...
    "observation_y_m",0);
scenario.medium = struct( ...
    "model","homogeneous_elastic", ...
    "cs_m_s",2.0, ...
    "density_kg_m3",1000);
scenario.excitation = struct("frequency_hz",500);  % one shared drive
scenario.sources = sourceRequest;                   % positions/force/phase
scenario.propagation = struct( ...
    "model","spherical_wave", ...
    "phase_method","analytical", ...
    "geometric_decay_exponent",1, ...
    "normalization","none");
```

The legacy configs already use `cfg.domain.Lx_m/dx_m`, `cfg.medium.background_cs_m_s`, and `cfg.wavefield.frequency_hz`; new modules should reuse validated formulas and provide explicit translation instead of changing those existing contracts unexpectedly.

## Work order and validation

1. **Implemented, MATLAB tests pending:** `swsynth.domain.buildGrid` for canonical axes, 2D/projected3d/volumetric3d layout, endpoint policy, and physical observation plane. Distinguish computational grid from observation/sensor sampling grid.
2. **Implemented, MATLAB tests pending:** `swsynth.medium.buildMaps` from the legacy map builders so material maps are generated on an existing grid and frequency is not needed to define material properties. Add explicit `medium.validate` and compatibility tests versus existing 2D/3D maps; do not silently add unmodeled viscosity/density effects.
3. **Pending:** resolve a single shared harmonic drive `frequency_hz`, preserving the legacy `wavefield.frequency_hz` adapter; update source/excitation contracts only after choosing a compatibility path.
4. **Pending:** implement the V2 `swsynth.propagation.synthesize` orchestration; regression-test simple homogeneous plane/spherical fields, multi-source coherence, apertures, 3D observed slices, RNG isolation, known legacy outputs.
5. **Pending:** expand medium and solver support to actual viscoelastic attenuation, dispersion, and heterogeneity only when physically specified and experimentally validated.

**Physical caveat:** `cs=sqrt(mu/rho)` assumes a homogeneous isotropic elastic material with the relevant constitutive assumptions. For viscoelastic media a complex, frequency-dependent shear modulus `G*(omega)` and density determine a complex wavenumber `k*(omega)`; prescribing both arbitrary `cs` and `G*` without consistency validation would be ambiguous.

**Numerical caveat:** the current V2 spherical contribution uses an uncalibrated shear far-field pattern, `exp(+ikr)*r^(-gamma)`, with positive spatial phasor sign inherited from legacy REQ synthesis. Its amplitude is relative, not in calibrated metres/N. Domain or material modules must not silently claim physical units not supported by that solver.
