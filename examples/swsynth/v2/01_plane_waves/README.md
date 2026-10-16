# swsynth V2 — plane-wave reference examples

Four homogeneous, analytical, **vector shear-wave** examples for learning the V2 API and validating directional wavefield physics. These use `incidence` (plane-wave directions), **not** physical `sources`. All configurations use schema `2.0` and the global `harmonic` drive field.

| JSON | Geometry | Incidence | Intended physics |
| --- | --- | --- | --- |
| `single_directional_2d.json` | `2d` | +x | Single plane shear wave; k=2πf/cs |
| `counterpropagating_2d.json` | `2d` | ±x, equal phase/amplitude | Interference/standing wave; SV polarization reverses when direction reverses |
| `multidirectional_2d.json` | `2d` | Four explicit x-z directions | Coherent interference with differing amplitudes and phases |
| `oblique_projected3d.json` | `projected3d` | [0.8, 0.45, 0.4] | Out-of-plane propagation seen on y=0 x-z observation plane |

All four use `cs=2 m/s`, `f=500 Hz`, `lambda=4 mm`, `k=1570.796 rad/m`, `Lx=Lz=24 mm`, `dx=dz=0.2 mm` (121 × 121 grid), and a z-axis measurement. The motion is *relative*, not a calibrated displacement in meters. These examples have no attenuation, random angular sampling or measurement noise.

## Run

From the repository root in MATLAB:

```matlab
setup_simulation_framework

folder = "examples/swsynth/v2/01_plane_waves";
files = ["single_directional_2d.json", ...
         "counterpropagating_2d.json", ...
         "multidirectional_2d.json", ...
         "oblique_projected3d.json"];

% Validate each config without running the synthesizer.
for file = files
    run_simulation(fullfile(folder,file),DryRun=true);
end

% Run one and generate the framework's standard figures and data.
outcome = run_simulation(fullfile(folder,files(1)),PlotFigures=true);
```

Each full run should produce the shared `data/wavefield_sample.mat` format plus standard run metadata under the framework output directory. Use `run_simulation` for V2 JSONs; do not call the solver using the full top-level JSON directly.

## Physical checks and limitations

- **Single wave:** observed spatial wavenumber should be consistent with `2*pi*f/cs`, within Fourier sampling and windowing limits. With `+x` incidence and `in_plane_sv` polarization, the z component is nonzero.
- **Counterpropagating:** `in_plane_sv` reverses polarization on reversing k, producing interference and nodes. Although both JSON `phase_rad` values are zero, the vector polarizations differ in sign.
- **Multidirectional:** four incident plane waves are coherent at a common frequency; their individual `relative_amplitude` and `phase_rad` values differ. This is *not* a statistically diffuse ensemble.
- **Projected 3D:** propagation includes a nonzero y component, but the observation is restricted to `y=0`. The measured in-plane wavelength is longer than the physical 3D wavelength; do not interpret the in-plane FFT peak as the full 3D k without accounting for projection.

Automatic direction sampling for diffuse fields is a separate pending V2 capability (issue #32). These four examples do not implement it.
