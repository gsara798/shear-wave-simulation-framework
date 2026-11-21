# swsynth V2 — shear-field noise (first stage)

This set implements a **mechanical shear-field noise** layer, separate from the optional displacement observation/readout model. The clean shear propagation and scalar mechanical measurement projection are computed first. The optional disturbance is then applied to the complex projected mechanical phasor. Displacement readout noise is **not** included in these mechanical-only cases; see `../09_displacement_readout_noise/` for an independent temporal readout sweep.

- `shear_noise_disabled_reference.json` — clean control.
- `shear_noise_correlated_projected3d.json` — reproducible global acquisition amplitude/phase jitter plus spatially correlated complex shear disturbance.

Noise configuration:

```json
"shear_noise": {
  "enabled": true,
  "seed": 70001,
  "source_amplitude_jitter_std": 0.015,
  "source_phase_jitter_cycles_std": 0.008,
  "propagation_relative_std": 0.006,
  "correlation_m": 0.00075,
  "amplitude_floor_fraction": 0.05
}
```

**Interpretation:** source amplitude/phase jitter here is a single global acquisition perturbation of the field, **not** independent physical-source jitter. To model independently randomized excitations, configure `sources.excitation`. This first release does not account for attenuation, propagation distance weighting, wave-speed-dependent loss, boundary reflections, or ultrasound readout noise. The spatially correlated additive disturbance scales approximately with local shear amplitude (subject to a small local floor). It is a phenomenological field-level model; do not interpret it as a validated microscopic mechanism of tissue propagation noise.

The simulator saves `data/wavefield_sample.mat` with the perturbed field, `data/shear_clean_reference.mat` with the clean phasor and noise diagnostics, and `data/run_summary.json` with the realized SNR. Both files retain standard array ordering: z-x or z-y-x.

```matlab
setup_simulation_framework
f="examples/swsynth/v2/07_shear_noise/shear_noise_correlated_projected3d.json";
run_simulation(f,DryRun=true);
out=run_simulation(f,PlotFigures=true);
```

## Next stages

- **Shear attenuation** should live under `+swsynth/+propagation/+attenuation`, with distinct mechanisms for bulk viscoelastic attenuation and interface-induced transmission/amplitude loss. The original `simcore-wave` implements a ray-integrated `exp(-integral(alpha ds))`, an empirical interface shadow and a shear-impedance-based transmission-only approximation. Neither interface model generates reflected fields. Adapting these correctly requires compatible material/density maps and per-path geometry and is **not implemented here**.
- **Displacement readout noise** is implemented separately under `+swsynth/+observation/+readout`, using a temporal Boukraa-like additive/multiplicative model with depth weighting. It is not an IQ/RF tracking simulator or acoustic echo model. See `../09_displacement_readout_noise/`.

## Controlled noise sweep: one plane wave

The files `single_plane_wave_noise_base.json` and `single_plane_wave_noise_sweep.json` define a seven-run campaign with **one +x traveling plane shear wave**, z-directed polarization, no source jitter, and exactly the same clean field and noise seed in every run.

Only `shear_noise.propagation_relative_std` changes: **0, 0.002, 0.006, 0.015, 0.03, 0.06, 0.12**. All runs use 0.75 mm spatial noise correlation. The zero-noise case is a control and reports infinite SNR when the clean and noisy fields coincide. Relative standard deviation is not a prescribed SNR.

```matlab
setup_simulation_framework
campaign="examples/swsynth/v2/07_shear_noise/single_plane_wave_noise_sweep.json";
run_campaign(campaign,DryRun=true);
report=run_campaign(campaign,ParallelLevel="campaign",NumWorkers=4,PlotFigures=true);
```

Read `data/run_summary.json` in each run directory for `shear_noise_snr_db`, and compare `wavefield_sample.mat` against `shear_clean_reference.mat`. The perturbation is a spatially correlated complex phasor disturbance **after mechanical projection**, not a modeled ultrasound acquisition or physically propagated scattering.


## Uniform-amplitude correlated shear noise (new)

The optional `shear_noise.spatial_scaling` switch has two policies:

- `"relative_local"` (default, backward compatible): `sigma = beta * max(abs(Uclean), floor_fraction * median(nonzero abs(Uclean)))`.
- `"uniform_global_rms"`: `sigma = beta * rms(abs(Uclean(:)))` for every voxel. This yields spatially constant **noise standard deviation** while the local SNR varies with clean displacement amplitude.

The common `propagation_relative_std` coefficient `beta` is dimensionless; **it is not the requested SNR in dB**. Both policies retain the existing seeded independent real/imaginary complex normal draws, optional Gaussian spatial correlation, variance rescaling, and realized global SNR reporting. The global amplitude/phase jitter terms remain separate and are zero in these sweeps.

For matching clean fields, noise seed, spatial correlation and beta levels, run both:
```matlab
setup_simulation_framework
run_campaign("examples/swsynth/v2/07_shear_noise/single_plane_wave_noise_sweep.json",DryRun=true)
run_campaign("examples/swsynth/v2/07_shear_noise/single_plane_wave_uniform_noise_sweep.json",DryRun=true)
report=run_campaign("examples/swsynth/v2/07_shear_noise/single_plane_wave_uniform_noise_sweep.json", ...
    ParallelLevel="campaign",NumWorkers=4,PlotFigures=true);
```
The new files are `single_plane_wave_uniform_noise_base.json` and
`single_plane_wave_uniform_noise_sweep.json` (seven beta levels, same
clean reference and fixed noise seed as the relative-noise sweep).

Caveat: this is still a phenomenological **complex mechanical phasor**
perturbation applied after projection, *not* ultrasound readout noise or
a scattering model. It is useful for stress-testing low-amplitude regions
under approximately constant absolute measurement perturbations.
