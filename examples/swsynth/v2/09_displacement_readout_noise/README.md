# swsynth V2 — displacement readout noise, single x-force point source

This example introduces an optional **Boukraa-like temporal displacement-readout**
stage. It perturbs the measured displacement phasor, **not** the mechanics of
propagation. It is not an IQ/Loupas or RF simulator. The temporal
additive/multiplicative mechanism follows SimCore Wave; only depth weighting
is included here (no acoustic echo/backscatter weighting).

## Physics held fixed

- One spherical point-force source at [-12, 8, 12] mm in (x,y,z),
  outside the x-z FOV and 8 mm out of plane.
- Force along **x** (`force_direction_xyz=[1,0,0]`); observation along **z**
  (`measurement.axis_xyz=[0,0,1]`).
- Homogeneous shear speed 2 m/s, frequency 500 Hz, 24-by-24 mm x-z FOV,
  0.3 mm spacing, spherical geometric-decay exponent 1.
- Mechanical `shear_noise` is disabled to isolate displacement readout.
- The propagation seed and readout seed are identical across all runs.

The `single_point_force_x_readout_base.json` is a standalone simulation.
The `single_point_force_x_readout_sweep.json` changes only
`readout_noise.strength = [0, 0.25, 0.5, 1, 2, 4]`. The factor scales
both additive and multiplicative standard deviations of the medium preset
(0.030 and 0.010 before temporal projection scaling). It is **not an SNR
in dB**. At strength zero the input complex phasor is returned exactly.
All variants reuse the same noise seed and draws.

The readout reconstructs real harmonic displacement at 32 samples
(PRF=4000 Hz), adds correlated noise at every temporal sample
(0.45 mm spatial correlation) with exponential depth weighting, then
recovers the complex phasor by harmonic least squares. It runs **after**
mechanical projection and any optional mechanical shear noise.

## Run from repository root

```matlab
setup_simulation_framework
base="examples/swsynth/v2/09_displacement_readout_noise/single_point_force_x_readout_base.json";
sweep="examples/swsynth/v2/09_displacement_readout_noise/single_point_force_x_readout_sweep.json";

run_simulation(base,DryRun=true);
out=run_simulation(base,PlotFigures=true);

run_campaign(sweep,DryRun=true);
report=run_campaign(sweep,ParallelLevel="campaign",NumWorkers=4,PlotFigures=true);
```

Without Parallel Computing Toolbox, use
`report=run_campaign(sweep,PlotFigures=true);`.

## Standard figure output — unchanged order

Every run uses the existing `simviz.generateSampleFigures` path, without a
custom plotting routine. Export order:

1. `sws.png` — true SWS map
2. `wavefield_real.png` — real observed phasor
3. `wavefield_phase.png` — observed phase
4. `wavefield_amplitude.png` — observed amplitude
5. `wavefield_imag.png` — imaginary observed phasor
6. `wavefield_snapshots.png` — four real-time snapshots
7. `source_positions.png` — physical source position

The original axes, color maps, snapshots and plot appearance are reused.
Compare the same figure across levels; separately normalized color scales
should not be interpreted as quantitative SNR comparisons.

## Saved data and limitations

- `data/wavefield_sample.mat`: final observed complex field for REQ.
- `data/shear_clean_reference.mat`: `cleanShear`, `preReadoutShear`,
  `noiseDiag`, and `readoutDiag`.
- `data/run_summary.json`: realized `readout_noise_snr_db` and
  `total_noise_snr_db`.

This isolated fixed-field sweep uses `amplitude_normalization="max_abs"`,
which has the same amplitude reference for every noise level. For Q0
cross-geometry training, use `fixed_reference` with an explicitly chosen
positive `reference_amplitude` common to all runs.

The model does not simulate acoustic echoes, RF/IQ acquisition, beamforming,
or Loupas tracking. It is a controlled temporal readout approximation, not
an experimentally calibrated observation model.
