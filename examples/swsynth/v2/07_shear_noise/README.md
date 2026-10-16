# swsynth V2 — shear-field noise (first stage)

This set implements a **mechanical shear-field noise** layer, separate from the future ultrasound observation/readout model. The clean shear propagation and scalar mechanical measurement projection are computed first. The optional disturbance is then applied to the complex projected mechanical phasor. Ultrasound tracking noise is **not** included.

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
- **Ultrasound readout noise** should live under `+swsynth/+observation/+ultrasound` and can eventually support full time-domain Boukraa-like noise and a separately validated faster equivalent-phasor model. This stage is **not implemented here**.

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
