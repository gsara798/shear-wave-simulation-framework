> **Important**
>
> This repository is **not a replacement for the k-Wave toolbox**. It provides
> a reproducible simulation framework, configuration system, validation
> procedures, output organization, and analysis tools built on top of
> **k-Wave 1.4.1**.

# Reproducible k-Wave shear-wave simulations

This repository provides a MATLAB framework for reproducible 2D and 3D elastic
shear-wave simulations using the pinned k-Wave 1.4.1 toolbox.

The framework currently includes:

- a validated homogeneous directional 2D reference case;
- 2D circular-inclusion, field-regime, and finite-contact benchmarks;
- configured 3D directional and multi-source simulations;
- multiface finite-contact source banks;
- generated angular source banks, including N8 P2, N32 P8, and N128 P8 cases;
- heterogeneous 3D spheres, finite cylinders, bilayers, and combined geometry;
- full 3D harmonic-field analysis and P/S diagnostics;
- central x-z plane export for external REQ validation;
- timestamped outputs with requested and resolved configurations;
- structured numerical and physical validation reports.

Historical scripts under `archive/` are retained as implementation evidence and
are not used by the current configured workflow.

## User documentation

The complete user guide is available at:

[docs/user_guide/README.md](docs/user_guide/README.md)

Recommended starting points:

- [Quick Start](docs/user_guide/quickstart.md)
- [Configuration Guide](docs/user_guide/configuration_guide.md)
- [Terminology](docs/user_guide/terminology.md)
- [Simulation Parameters](docs/user_guide/simulation_parameters.md)
- [Outputs and Validation](docs/user_guide/outputs_and_validation.md)

Physics documentation:

- [Finite-Contact Sources](docs/user_guide/physics/finite_contact_sources.md)
- [Multiface and Angular Sources](docs/user_guide/physics/multiface_and_angular_sources.md)
- [Heterogeneous Materials](docs/user_guide/physics/heterogeneous_materials.md)
- [Harmonic Analysis and P/S Separation](docs/user_guide/physics/harmonic_analysis_and_ps_separation.md)

## Command-line quick start

Run all commands from the repository root.

Display the CLI help:

```bash
./scripts/kwsim-run --help
```

Validate a configuration without running k-Wave:

```bash
./scripts/kwsim-run \
  configs/two_d/homogeneous_directional_cli.json \
  --dry-run
```

Execute the verified 2D configured reference:

```bash
./scripts/kwsim-run \
  configs/two_d/homogeneous_directional_cli.json
```

The verified reference completed successfully and produced:

```text
truth SWS:       2.0000 m/s
estimated SWS:   2.0043 m/s
relative error:  0.214%
P/S energy:      4.974e-4
steady change:   2.014e-5
overall valid:   yes
```

Runtime depends on hardware and configuration. The verified reference completed
in approximately 23 seconds on the development computer.

## Configured 3D examples

### Homogeneous directional field

```bash
./scripts/kwsim-run \
  configs/three_d/homogeneous_directional_req_validation.json \
  --dry-run
```

### Heterogeneous spherical inclusion

```bash
./scripts/kwsim-run \
  configs/three_d/heterogeneous_sphere_3d.json \
  --dry-run
```

### Generated angular N32 P8 field

```bash
./scripts/kwsim-run \
  configs/three_d/homogeneous_generated_angular_n32_p8_req_validation.json \
  --dry-run
```

These three commands have been verified through the configured dry-run path.

A dry run resolves and validates the configuration without executing the solver
or creating outputs.

## MATLAB interface

The lower-level MATLAB interface remains available.

```matlab
addpath('/absolute/path/to/k-wave_simulations/src');

cfg = kwsim.two_d.defaultConfig();
[result, report] = kwsim.two_d.run(cfg);
disp(report.summary);
```

Save a self-contained result and diagnostic figures:

```matlab
kwsim.io.saveRun(result, report, 'outputs/my_run');
```

Visualize the measured axial field:

```matlab
kwsim.viz.plotAxialField(result, report);
```

Compare motion components:

```matlab
kwsim.viz.plotMotionComponents(result, report);
```

The complete 2D reference example is:

```text
examples/two_d/run_directional_homogeneous_benchmark.m
```

## Two-dimensional examples

### Homogeneous directional benchmark

```text
examples/two_d/run_directional_homogeneous_benchmark.m
```

The compact cross-run reliability suite is:

```text
examples/two_d/run_directional_homogeneous_validation.m
```

### Circular inclusion

```text
examples/two_d/run_circular_inclusion_benchmark.m
```

This benchmark compares a contrast inclusion against homogeneous and
zero-contrast cases before saving material and field diagnostics.

### Field regimes

```text
examples/two_d/run_field_regimes_benchmark.m
```

This benchmark runs directional, partial, and broad angular source regimes and
evaluates angular diagnostics.

Definitions and source limitations are documented in:

```text
benchmarks/+kwsim_benchmarks/+field_regimes_2d/README.md
```

### Finite contacts

```text
examples/two_d/run_finite_contacts_benchmark.m
```

The benchmark includes validated finite perimeter contacts while retaining
point-contact comparisons.

Additional details are documented in:

```text
docs/finite_contacts_2d.md
```

## Three-dimensional capabilities

The current 3D framework supports:

- homogeneous directional single-contact fields;
- same-face and multiface finite-contact source banks;
- generated angular source banks;
- controlled in-plane and out-of-plane contributors;
- independent source phases and transverse polarizations;
- total-drive normalization across source counts;
- N8 P2, N32 P8, and N128 P8 configurations;
- spherical inclusions;
- arbitrarily oriented finite cylinders;
- arbitrarily oriented bilayers;
- combined heterogeneous geometry with defined precedence;
- full-volume harmonic fields;
- 3D P/S diagnostics;
- central x-z acquisition-plane export;
- material and SWS truth maps;
- external REQ-readiness assessment.

The geometry precedence is:

```text
background
-> bilayer
-> cylinders
-> spheres
```

Later geometry types overwrite earlier assignments where regions overlap.

## Wavefield terminology

Source count alone does not establish diffusivity.

Use the following terminology carefully:

```text
directional
multi-source
partial 3D
broad angular
projected 3D
diffuse idealization
```

N8 P2, N32 P8, and N128 P8 describe source-bank construction:

```text
N = total number of sources
P = configured number of explicitly in-plane contributors
```

They do not guarantee an ideal isotropic diffuse field.

See:

[Multiface and Angular Sources](docs/user_guide/physics/multiface_and_angular_sources.md)

## Coordinate and field contract

Public coordinates are:

```text
x = lateral
y = elevational / out-of-plane
z = axial / depth
```

Public 2D maps use:

```text
[Nz, Nx]
suffix: _zx
```

Public 3D volumes use:

```text
[Nz, Ny, Nx]
suffix: _zyx
```

k-Wave solver orientation is handled inside the adapter layer.

Velocity phasors use m/s.

Displacement phasors use m.

The phasor convention is:

```text
signal(t) = real(phasor * exp(1i*2*pi*f0*t)) + dc
```

## Finite-contact source model

The framework uses prescribed boundary particle velocity.

Typical contact models are:

```text
2D: finite_segment
3D: finite_disk
```

A left-face source with principal propagation in +x and polarization in z is
transverse and therefore shear-dominant.

The source is a controlled boundary-motion approximation. It is not a complete
model of actuator mass, force, coupling, contact pressure, or electromechanics.

See:

[Finite-Contact Sources](docs/user_guide/physics/finite_contact_sources.md)

## Reduced compressional speed

Development configurations commonly use:

```text
cp = reduced_cp_factor * cs
```

with a typical factor of 10.

This reduces the time-step cost while preserving an admissible elastic model.

It is an explicit computational approximation, not a claim that tissue has a
compressional speed near 20 m/s.

Configurations with an inadmissible P/S speed relationship are rejected during
validation.

## Harmonic analysis

The solver runs in the time domain.

Late-time samples are reduced to complex fields at the source frequency using
the configured harmonic-analysis method.

The current 3D baseline uses:

```json
"analysis": {
  "harmonic_method": "least_squares",
  "temporal_window": "none",
  "remove_mean": true
}
```

The resulting complex field contains harmonic amplitude and phase.

Temporal harmonic extraction and spatial wavenumber analysis are separate
steps:

```text
time-domain simulation
-> extraction at f0
-> complex spatial field
-> spatial spectrum
-> wavenumber or REQ analysis
```

See:

[Harmonic Analysis and P/S Separation](docs/user_guide/physics/harmonic_analysis_and_ps_separation.md)

## Reliability and validation

Configured runs may evaluate:

- configuration and resource preflight;
- grid resolution and points per wavelength;
- source fundamental-frequency fraction;
- finite harmonic fields;
- P/S energy ratio;
- cross-polarization and longitudinal leakage;
- harmonic steady-state change;
- homogeneous SWS agreement;
- source-bank angular properties;
- geometry containment and discretization;
- repeatability;
- REQ readiness.

Validation thresholds are scenario-specific.

A solver completing successfully does not automatically mean that the result is
scientifically valid.

Always inspect:

```text
data/validation_summary.txt
config/resolved_config.json
diagnostic figures
truth maps
```

See:

[Outputs and Validation](docs/user_guide/outputs_and_validation.md)

## Output structure

A configured run is saved under:

```text
outputs/<timestamp>_<run_name>/
```

Typical structure:

```text
<run_directory>/
├── config/
│   ├── requested_config.mat
│   ├── resolved_config.json
│   └── resolved_config.mat
├── data/
│   ├── result.mat
│   ├── summary.mat
│   ├── validation_report.mat
│   └── validation_summary.txt
├── figures/
└── manifest.txt
```

Some 3D cases can also save:

```text
data/req_validation_sample.mat
```

The full time series is disabled by default to prevent accidental
multi-gigabyte outputs.

Enable it only when required:

```matlab
cfg.output.save_time_series = true;
```

New outputs belong under `outputs/`, which is excluded by `.gitignore`.

## Heterogeneous truth interpretation

For heterogeneous sliding-window analysis, windows should be classified using
the material ID truth map:

```text
background-pure
inclusion-pure
mixed
```

Mixed windows do not have one unique local ground-truth SWS.

A displayed map can contain visible background and inclusion while still
providing no background-pure placements for a selected analysis window.

Do not claim background accuracy or contrast recovery unless the region
composition supports those claims.

See:

[Heterogeneous Materials](docs/user_guide/physics/heterogeneous_materials.md)

## Tests

From MATLAB:

```matlab
addpath('/absolute/path/to/k-wave_simulations/tests');
results = run_all_tests();
```

Unit tests are designed to run quickly.

Integration tests execute compact k-Wave simulations and take longer.

## Citation

When using this repository in research, cite both this software and the k-Wave
toolbox.

Repository citation metadata are provided in:

[CITATION.cff](CITATION.cff)

## License

This project is distributed under the [Apache License 2.0](LICENSE).

## Contributing

Bug reports, validation cases, documentation improvements, and numerical tests
are welcome.

See:

[CONTRIBUTING.md](CONTRIBUTING.md)

## Dependency: k-Wave Toolbox

This repository builds upon the open-source k-Wave MATLAB Toolbox for
time-domain acoustic and elastic-wave simulations.

The k-Wave toolbox is developed and maintained by Bradley E. Treeby and Ben T.
Cox.

Please cite the original k-Wave publications when using this repository in
research.

### k-Wave references

Treeby BE, Cox BT.

*K-Wave: MATLAB toolbox for the simulation and reconstruction of photoacoustic
wave fields.*

Journal of Biomedical Optics, 15(2), 021314, 2010.

Treeby BE, Jaros J, Rendell AP, Cox BT.

*Modeling nonlinear ultrasound propagation in heterogeneous media with power
law absorption using a k-space pseudospectral method.*

Journal of the Acoustical Society of America, 131(6), 4324-4336, 2012.

Official website:

```text
https://www.k-wave.org
```
