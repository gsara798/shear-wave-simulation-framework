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

## Old code still present (temporarily)

`run.m`, `run3D.m`, `+internal/runVolumetric.m`, `synthesizeWavefield2D.m`, `+propagation/+plane_wave/synthesize*.m`, `+propagation/+spherical/+point_source/+shear_far_field/synthesize*.m`, legacy configuration, direction, map, sample builders and a number of `+propagation/+projected3d` helpers are **old execution paths**. They are retained for now because the old `simcampaigns` backend calls them. They are **not** part of the new `propagation.synthesize` implementation.

The first cleanup pass removed six no-value forwarding wrappers. See `docs/architecture/V2_CLEANUP_LOG.md` for the deletion log and regression tests. The next large pass will remove the old backend as a unit alongside an explicit V2 runner migration, rather than silently breaking campaign output.
