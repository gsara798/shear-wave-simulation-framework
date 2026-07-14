# Power-law attenuation benchmark

This benchmark validates recovery of a prescribed shear-wave attenuation law
from matched, independent monofrequency simulations.

For each requested frequency, the benchmark runs:

1. a lossless reference simulation;
2. an attenuated simulation with the same grid, source, seed, frequency, and
   elastic material properties;
3. a matched spatial attenuation estimate;
4. a cross-frequency power-law fit.

No simulated wavefield contains more than one excitation frequency.

## Quick start

```matlab
cfg = kwsim_benchmarks.attenuation_power_law_2d.config();

sweep = kwsim_benchmarks.attenuation_power_law_2d.run( ...
    cfg, ...
    [300, 400, 500]);
```

To save all runs, diagnostics, figures, and the sweep summary:

```matlab
output_directory = fullfile( ...
    kwsim.io.projectRoot(), ...
    "outputs", ...
    "attenuation_power_law");

sweep = kwsim_benchmarks.attenuation_power_law_2d.run( ...
    cfg, ...
    [300, 400, 500], ...
    output_directory);
```

## Setting the attenuation law

The homogeneous reference configuration exposes the shear and compressional
attenuation laws directly:

```matlab
cfg = kwsim_benchmarks.attenuation_power_law_2d.config( ...
    ShearAlphaRefDbCm=1.5, ...
    ShearReferenceFrequencyHz=500, ...
    ShearPowerY=1.1, ...
    CompressionAlphaRefDbCm=0.1, ...
    CompressionReferenceFrequencyHz=500, ...
    CompressionPowerY=1.1, ...
    Seed=1001);
```

Each attenuation law follows

```text
alpha(f) = alpha_ref * (f / f_ref)^y
```

where:

- `alpha_ref` is an amplitude attenuation coefficient in dB/cm;
- `f_ref` is the reference frequency in Hz;
- `y` is the requested power-law exponent.

The shear law is the quantity recovered and validated by this benchmark. The
compressional law is retained separately because the elastic k-Wave solver
requires independent shear and compressional absorption coefficients.

## Reproducibility contract

A benchmark run is reproducible when the following inputs are unchanged:

- complete requested configuration;
- random seed;
- frequency list;
- k-Wave version;
- MATLAB version;
- solver backend and numerical precision.

The runner sorts the requested frequencies before execution. For each
frequency, the lossless and attenuated simulations are cloned from the same
base configuration. The pair therefore shares:

- grid and time sampling;
- source position and waveform;
- source seed;
- material density and wave speeds;
- sensor region;
- solver settings.

The only intentional physical difference within each pair is whether
attenuation is enabled.

The returned sweep records:

```text
benchmark
frequencies_hz
base_configuration
pairs
reproducibility
target_attenuation_db_cm
recovered_attenuation_db_cm
requested_power_y
recovered_power_y
checks
summary
```

## Custom frequencies

At least three unique, finite, positive frequencies are required:

```matlab
frequencies_hz = [250, 350, 500, 650];

sweep = kwsim_benchmarks.attenuation_power_law_2d.run( ...
    cfg, ...
    frequencies_hz);
```

The frequencies do not need to be supplied in ascending order. The runner
sorts them deterministically before simulation.

## Compact regression configuration

Use the compact configuration for integration tests and fast regression runs:

```matlab
cfg = kwsim_benchmarks.attenuation_power_law_2d.compactConfig( ...
    ShearAlphaRefDbCm=1.0, ...
    ShearReferenceFrequencyHz=500, ...
    ShearPowerY=1.2, ...
    Seed=1001);
```

The compact configuration preserves the attenuation model and deterministic
source setup while reducing computational cost. It is not a replacement for
the reference benchmark when reporting final numerical acceptance results.

## Material-level API

Reusable attenuation laws for custom or heterogeneous simulations are created
with:

```matlab
material = kwsim.materials.makeAttenuationMaterial( ...
    2, ...
    ShearAlphaRefDbCm=2.0, ...
    ShearReferenceFrequencyHz=500, ...
    ShearPowerY=1.3, ...
    CompressionAlphaRefDbCm=0.1, ...
    CompressionReferenceFrequencyHz=500, ...
    CompressionPowerY=1.3);
```

The returned structure contains separate `shear` and `compression` laws and an
explicit `material_id`.

Every material ID present in an attenuated simulation must have exactly one
corresponding attenuation-law definition.

## Physical model

The elastic k-Wave solver uses Kelvin-Voigt absorption, whose solver
coefficient follows an effective frequency-squared dependence.

To represent a requested arbitrary power law, the framework:

1. evaluates the requested law at the current excitation frequency;
2. converts that target into the Kelvin-Voigt coefficient required at that
   frequency;
3. runs one monofrequency simulation;
4. repeats the calibration independently for every frequency.

This benchmark therefore validates a power law across a collection of
independent monofrequency fields. It does not claim that one time-domain
simulation implements an arbitrary broadband attenuation law.

## Matched attenuation measurement

Attenuation is estimated from the amplitude ratio between the attenuated and
lossless vector-shear fields. Using a matched reference suppresses geometric
spreading, source directivity, and common numerical effects.

Each frequency pair validates:

- successful attenuated and lossless simulations;
- minimum number of spatial fit points;
- attenuation-fit coefficient of determination;
- relative error in recovered attenuation;
- change in recovered shear phase speed.

The sweep additionally validates the recovered cross-frequency power-law
exponent.

## Output structure

When an output directory is supplied, the benchmark saves:

```text
attenuation_power_law/
  sweep_index.mat
  attenuation_power_law_summary.txt
  attenuation_power_law.png
  f_000300_hz/
    lossless/
    attenuated/
    attenuation_diagnostics.png
  f_000400_hz/
    ...
  f_000500_hz/
    ...
```

The saved MAT files contain resolved configurations, truth fields, source
metadata, complex harmonic fields, diagnostics, and provenance information.
