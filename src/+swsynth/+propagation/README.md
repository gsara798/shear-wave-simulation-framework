# V2 harmonic propagation

`swsynth.propagation.synthesize(scenario)` is the **only maintained swsynth field synthesis entry point** in `develop/v2`. For simulation JSONs use schema 2.0 via `simrunner.runConfig` or `simcampaigns`.

## Implementation

```text
synthesize
  -> domain.buildGrid / medium.buildMaps / excitation.resolve
  -> plane_wave.computeContribution
     OR spherical.point_source.computeContribution
      -> phase.compute / polarization.compute
  -> propagation.accumulate
  -> U_xyz (complex vector field)
```

The observation axis projection is separate: `observation.projectComponent`. The schema-v1 `wavefield_sample.mat` output uses `io.buildWavefieldSampleV2`, which preserves source/amplitude/phase metadata and local material truth.

- **Plane waves**: explicit 3D incidence directions, complex amplitudes/phases, transverse polarization, analytic phase in homogeneous 2D/projected3D/volumetric3D, or Eikonal projected3D/volumetric3D for heterogeneous media.
- **Spherical point-force waves**: physical positions, forces, coherent apertures, amplitudes/phases; transverse shear far-field radiation and analytic travel time in homogeneous media.
- **Heterogeneous spherical sources** are intentionally unsupported; do not substitute straight-ray time for an Eikonal solution.
- **Complex vector result** has 3 Cartesian motion components per grid point. `accumulate` validates coherent components before summation. Contributions are currently buffered in memory; streaming reduction is future work.

`+plane_wave/computeContribution.m` and `+spherical/+point_source/computeContribution.m` are the maintained kernels. Legacy scalar `synthesize*.m` and `+propagation/+projected3d` forwarding code are retired.

## Physical/spectral validation

`analysis/synthesizer_v2/validate_wavefields_v2.m` tests a single planar incident wave, two coherent spherical point-force sources, and a 30-wave partial angular ensemble. User-reported MATLAB validation: 9/9 physics tests passed on 2026-10-15. The later V2-to-simcampaigns integration suite (10 tests) also passed before the V2-only cleanup.

We must **rerun the updated suite after deleting legacy code**. Tests include `test_swsynth_synthesis_physics_v2.m`, `test_swsynth_excitation_and_synthesize_v2.m`, `test_swsynth_wavefield_sample_v2.m` and `test_simcampaigns_swsynth_v2_integration.m`. Do not interpret those smoke checks as complete physical validation of diffuse fields, wave scattering, RF tracking, attenuation, or the external REQ-ML reader.

See `docs/architecture/HARMONIC_SYNTHESIS_V2.md`, `docs/validation/SYNTHESIZER_V2_PHYSICAL_VALIDATION.md` and `docs/swsynth/README.md`.
