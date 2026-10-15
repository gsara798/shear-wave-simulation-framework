# swsynth: use this V2 path

**New work should use the modular V2 API.** The duplicated pre-V2 functions are being deleted in stages; legacy code remains in the user's backup worktree / Git history.

## V2 entry points

```matlab
result = swsynth.propagation.synthesize(scenario);
wavefield_sample = swsynth.io.buildWavefieldSampleV2(result,scenario);
```

- `+domain/buildGrid.m`: grid/coordinates
- `+medium/buildMaps.m`, `validate.m`: isotropic elastic `c_s` and inclusions
- `+excitation/resolve.m`: global harmonic drive frequency
- `+sources/prepare.m`, `+sources/+positions`, `+sources/+excitation`, `+sources/+aperture`: physical parent source positions, force, amplitude, phase, aperture
- `+phase/compute.m`, `+phase/+analytical`, `+phase/+eikonal`: travel times; heterogeneous Eikonal only for incident plane waves in projected3d or volumetric3d
- `+polarization/compute.m`: shear polarization / source radiation
- `+propagation/+plane_wave/computeContribution.m`, `+propagation/+spherical/+point_source/computeContribution.m`: one coherent contribution
- `+propagation/accumulate.m`, `synthesize.m`: vector field assembly
- `+observation/projectComponent.m`: signed axis projection
- `+io/buildWavefieldSampleV2.m`, `+io/resolveConfigV2.m`: V2 sample adapter and JSON configuration resolver; **schema-2 swsynth campaigns are now integrated and smoke-tested**
- `+numerics/+eikonal`: actual numerical Eikonal kernels; **not duplicate/legacy**.

## V2-only maintenance status

As of October 2026 the old `swsynth.run`, `run3D`, legacy default/validation configuration, scalar synth adapters and old physical-source compatibility API have been **removed** from `src/+swsynth`. The `simrunner` and `simcampaigns` entrypoints require `schema_version: "2.0"` for swsynth; k-Wave keeps its own unchanged routing.

No V2 replacement for *automatically generated plane-wave directions* exists yet. Plane waves currently require explicit `scenario.incidence.direction_xyz`. Physical point-source placements still support random and Fibonacci generation. This separate development is tracked in [issue #32](https://github.com/gsara798/shear-wave-simulation-framework/issues/32).

The shared `+phase/resolveSolver.m` and `+phase/validateCompatibility.m` remain because V2's Eikonal and analytical phase backends call them. The numerical Eikonal kernels are also active.

Historical input fixtures and examples may still exist in `examples/swsynth/` but are **not supported inputs to the V2-only runner**. The old physical implementation is preserved in the user's backup worktree/Git history; do not silently reinterpret old JSON as a V2 scenario.

Run the V2 unit and end-to-end campaign suite before further removal. The audit and migration boundary are documented in `docs/architecture/V2_AUDIT_POST_CAMPAIGN_INTEGRATION_20261015.md`.
