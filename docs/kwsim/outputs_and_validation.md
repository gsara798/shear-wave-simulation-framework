# Outputs and Validation

A configured simulation run stores enough information to reconstruct what was requested, what was executed, and whether the result passed the framework's physical and numerical checks.

## Run directory

A typical k-Wave run contains:

```text
outputs/<timestamp>_<run_name>/
├── config/
│   ├── requested_config.mat
│   ├── resolved_config.json
│   └── resolved_config.mat
├── data/
│   ├── result.mat
│   ├── summary.mat
│   ├── validation_report.mat
│   ├── validation_summary.txt
│   └── wavefield_sample.mat        optional
├── figures/
└── manifest.txt
```

The exact files depend on scenario and output settings.

## Requested configuration

`config/requested_config.mat` records the user's requested configuration before all defaults and derived values are resolved.

It answers:

```text
What did the user ask the framework to run?
```

## Resolved configuration

`config/resolved_config.json` and `config/resolved_config.mat` record the complete resolved simulation configuration.

They can contain defaults, derived timing, generated source placement, material geometry, solver settings, validation thresholds, and output settings.

They answer:

```text
What configuration was actually prepared for execution?
```

The resolved configuration is a core reproducibility artifact.

## Simulation result

`data/result.mat` contains the main simulation result. Depending on the scenario it may include:

- complex harmonic fields;
- motion components;
- coordinate vectors;
- grid metadata;
- material maps;
- truth maps;
- source and sensor metadata;
- diagnostics.

Inspect file contents before assuming every scenario exposes identical fields.

```matlab
whos('-file', 'data/result.mat')
```

## Summary

`data/summary.mat` provides a smaller run-level summary for quick inspection and batch aggregation.

## Structured validation

`data/validation_report.mat` contains the programmatic validation report. Checks may contain:

```text
name
pass/fail
measured value
threshold
meaning
```

`data/validation_summary.txt` is the human-readable counterpart.

A solver can complete successfully while the resulting simulation fails one or more scientific checks. Therefore:

```text
solver completed
!=
scientifically valid simulation
```

## Physical validation checks

Depending on the scenario, the framework can evaluate quantities such as:

- configuration and resource preflight;
- shear points per wavelength;
- source fundamental-frequency fraction;
- finite-field checks;
- P/S energy ratio;
- cross-polarization or longitudinal leakage;
- steady-state change;
- homogeneous shear-speed recovery;
- heterogeneous material-region composition;
- source-bank geometry and angular coverage;
- deterministic repeatability.

Thresholds are part of the scenario contract and are not universal constants. Do not change thresholds merely to make a failing case pass.

## Validation plot

The public examples provide a compact pass/fail visualization:

```matlab
addpath('examples')
plot_validation_checks(outcome.report)
```

This plot complements the detailed numerical report; it does not replace it.

## Diagnostic figures

Configured runs can save figures for the propagated field, motion components, source geometry, material geometry, or 3D volume slices depending on the scenario.

Use figures to inspect physical plausibility and numerical metrics to decide whether configured validation criteria passed.

## Standardized wavefield sample

When enabled, `data/wavefield_sample.mat` stores the backend-neutral complex harmonic wavefield contract for downstream analysis.

The sample can include:

- complex 2D or 3D harmonic field;
- frequency;
- coordinate vectors and spatial spacing;
- measurement quantity and component metadata;
- material or shear-speed truth maps when available.

The simulation framework does not evaluate downstream estimators. Estimator-specific validation belongs in the downstream analysis repository.

## Failure interpretation

When a validation check fails:

```text
1. Identify the failing metric.
2. Compare its value with the configured threshold.
3. Inspect the resolved configuration.
4. Inspect the relevant diagnostic figures.
5. Determine whether the cause is numerical, physical, or operational.
6. Modify the model only after understanding the cause.
```

Typical examples include insufficient points per wavelength, excessive compressional contamination, inadequate settling, boundary effects, or unsuitable source polarization.

## Recommended review sequence

After a solver run:

```text
1. Read the terminal summary.
2. Inspect validation_summary.txt.
3. Confirm overall validity.
4. Review failed or marginal checks.
5. Inspect field/source/material figures.
6. Inspect resolved_config.json.
7. Inspect result.mat fields.
8. Record the output directory and software commit.
9. Only then begin downstream analysis.
```

## Reproducibility

For a scientific result, preserve at least:

```text
requested configuration
resolved configuration
simulation result
validation report
seed
software commit
analysis code version
```

A figure alone is not sufficient for reproducibility.

## Interpretation

A valid run establishes that the simulation passed the checks defined for its configured scenario. It does not automatically establish experimental realism, physiological material parameters, realistic actuator coupling, realistic ultrasound readout, or universal downstream algorithm performance.
