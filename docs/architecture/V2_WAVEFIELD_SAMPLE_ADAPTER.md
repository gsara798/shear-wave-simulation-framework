# V2 vector field to wavefield_sample v1.0 adapter

**Status (2026-10-15):** implemented and integrated with `simcampaigns`/`simrunner` **for schema-2 swsynth configurations**. The user reported all 10 end-to-end MATLAB integration tests passing, including the saved-MAT path. The V2-only cleanup has now removed `swsynth.run`, `run3D`, legacy sample builders, and old-config routing; independent acceptance in the separate REQ-ML reader is still outstanding.

## Why this adapter

The V2 synthesizer returns the true complex vector field `result.U_xyz` and material maps. REQ-ML and other downstream tooling currently consume a scalar observed wavefield in a `wavefield_sample` MATLAB struct, validated by `wavefield.validateSample`:

- `wavefield.data_zx` with `coordinates.array_order="zx"` for 2D or projected3d, or `wavefield.data_zyx` with order `"zyx"` for volumes;
- `truth.cs_map_*`, `truth.k_map_*`, `truth.material_id_*`, `truth.valid_mask_*` matching the spatial grid;
- frequency and observation metadata, source/direction provenance.

`swsynth.io.buildWavefieldSampleV2(result,scenario,options)` bridges these without changing the already validated v1.0 schema.

## Usage after a V2 scenario is assembled

```matlab
result = swsynth.propagation.synthesize(scenario);

wavefield_sample = swsynth.io.buildWavefieldSampleV2( ...
    result, scenario, struct( ...
        "measurement_axis_xyz",[0 0 1], ...
        "scenario_name","my_scenario", ...
        "seed",53053));  % supply ONLY if a controlled seed was used

info = wavefield.validateSample(wavefield_sample);
save("wavefield_sample.mat","wavefield_sample","-v7.3");

loaded=load("wavefield_sample.mat","wavefield_sample");
wavefield.validateSample(loaded.wavefield_sample);
```

Default axis is `[0 0 1]` (axial), normalized before the signed vector projection. Nonaxial axes explicitly yield `component="projected"` and preserve `measurement.axis_xyz`. The axis is a **motion observation direction**, not an ultrasound attenuation/acquisition/noise model.

The original `scenario` must be supplied so the adapter can retain it as `provenance.resolved_config`, including user-configured material inclusions and source requests. It verifies the scenario geometry and drive frequency against the actual V2 result. The resolved physical source bundle or normalized plane-wave incidence from the result is saved separately, avoiding fictitious `directions.xyz` for point sources.

## Semantics preserved

1. **Shear-wave speed map** `truth.cs_map`: from V2 `medium.buildMaps`.
2. **Local material wavenumber** `truth.k_map=2*pi*f./truth.cs_map`: this is the scalar *local elastic material* relationship. For heterogeneous Eikonal fields it is **not** a measurement of the wavefront gradient `|grad(phi)|` nor an REQ estimate. This distinction is recorded in `propagation.k_map_definition` and `k_map_is_eikonal_phase_gradient=false`.
3. **Material ID and valid mask**: copied from V2 medium, valid where material and projected field are finite and speed is positive. This is **not** a clinically/physically motivated REQ reliability mask.
4. **Quantity and units**: V2 defaults to `quantity="relative_motion"`, exposed as `units="arbitrary_relative_motion"`. If a scenario declares displacement/velocity, units are still prefixed `arbitrary_` because the synthetic amplitudes are not calibrated to metres or m/s. `measurement.calibrated=false`.
5. **Phase convention**: copied directly from V2 drive, preserving the inherited **positive spatial** phase sign and documenting that the temporal reconstruction convention is not defined; do not silently replace it with a legacy temporal convention.
6. **Directions**: for plane-wave incidence use actual input `incidence.direction_xyz`. For point sources, `directions.xyz` is empty and `sources` retains physical positions, forces, phases, amplitudes and aperture nodes. This is not a loss of information: point-source propagation direction varies spatially.
7. **Seed and provenance**: sample seed/commit remain empty unless explicitly provided through adapter options. No invented random seed, timestamp, or Git commit. Runner integration is responsible for filling run/campaign IDs and verified provenance.
8. **Validation status**: `validation.scope="schema_and_finite_phasor_only"` and `physics_validated=false`; `analysis_ready` currently means finite/nonzero observed data, not sufficient wavelengths, reliable estimator performance, or wavefield physical calibration.

## Scope and next step

The adapter is a **necessary compatibility component**, not yet an executable campaign backend. Tests cover planar plane-wave, projected3d spherical physical metadata, 3D volume layout, heterogeneous projected3d Eikonal local k maps, observation axes, declared quantity, source provenance and a MATLAB v7.3 save/load roundtrip.

Tests:

```matlab
cd('/Users/sara/local/shear-wave-simulation-framework')
!git pull --ff-only
clear functions
rehash
addpath(fullfile(pwd,'src'))
results=runtests('tests/unit/test_swsynth_wavefield_sample_v2.m');
disp(table(results))
assertSuccess(results)
```

**Current next step:** rerun MATLAB regression after the V2-only deletion, then perform an independent REQ-ML loader roundtrip with real V2 `wavefield_sample.mat` artifacts (2D plane, projected3D spherical, volumetric3D). `simrunner` and `simcampaigns` both route swsynth directly to V2. See [issue #30](https://github.com/gsara798/shear-wave-simulation-framework/issues/30) for cleanup validation, and [issue #31](https://github.com/gsara798/shear-wave-simulation-framework/issues/31) for deferred heterogeneous spherical Eikonal.
