# Outputs and Validation

This document explains the structure of a configured simulation run, the purpose
of each saved file, and how to interpret validation results.

The examples below are based on the verified 2D configured run:

```text
outputs/20260722_204435_cli_homogeneous_directional_2d
```

## 1. Run directory structure

A successful configured run creates a timestamped directory:

```text
outputs/<timestamp>_<run_name>/
```

The verified 2D run produced:

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
│   ├── field_diagnostics.png
│   ├── motion_components.png
│   └── source_diagnostics.png
└── manifest.txt
```

The exact files depend on the selected scenario and output settings.

## 2. `requested_config.mat`

Path:

```text
config/requested_config.mat
```

This file stores the configuration requested by the user before all defaults and
derived values are resolved.

It records the original simulation intent.

Use it to answer:

```text
What did the user ask the framework to run?
```

It may not contain every parameter used by the solver.

## 3. `resolved_config.json`

Path:

```text
config/resolved_config.json
```

This is the human-readable resolved configuration.

It can include:

- requested values;
- defaults;
- derived values;
- resolved timing;
- source placement;
- source phases;
- geometry details;
- solver settings;
- validation thresholds;
- output settings.

Use it to answer:

```text
What configuration was actually resolved for execution?
```

This is one of the most important files for reproducibility.

## 4. `resolved_config.mat`

Path:

```text
config/resolved_config.mat
```

This stores the resolved configuration in MATLAB format.

It is useful for MATLAB-based analysis and automated post-processing.

The JSON and MAT versions serve different practical purposes:

```text
JSON:
human-readable and language-independent

MAT:
convenient for MATLAB workflows
```

## 5. `result.mat`

Path:

```text
data/result.mat
```

This contains the primary simulation result.

Depending on the scenario, it may include:

- complex harmonic fields;
- motion components;
- displacement or velocity fields;
- coordinate vectors;
- grid metadata;
- material maps;
- truth maps;
- source metadata;
- sensor metadata;
- selected diagnostics.

This is usually the main file for scientific analysis.

Do not assume that every scenario saves identical fields. Inspect the file
contents before writing analysis code.

In MATLAB:

```matlab
info = whos("-file", "data/result.mat");
disp(struct2table(info));
```

or:

```matlab
S = load("data/result.mat");
fieldnames(S)
```

## 6. `summary.mat`

Path:

```text
data/summary.mat
```

This contains a compact summary of the run.

It is intended for quick inspection and batch aggregation without loading the
full result.

Typical summary information may include:

- scenario;
- dimension;
- grid;
- source frequency;
- nominal shear-wave speed;
- validation status;
- main scalar metrics;
- output paths.

The exact fields depend on the implementation and scenario.

## 7. `validation_report.mat`

Path:

```text
data/validation_report.mat
```

This contains the structured validation report.

It is intended for programmatic use.

The report can include:

```text
check name
pass/fail status
measured value
threshold
meaning
overall validity
```

Use this file when analyzing many runs automatically.

## 8. `validation_summary.txt`

Path:

```text
data/validation_summary.txt
```

This is the human-readable validation report.

The verified 2D case produced:

```text
KWSIM VALIDATION REPORT
=======================

valid=1, source fundamental=1.000000, P/S energy=0.0004974,
steady change=2.014e-05, cs estimate=2.0043 m/s (error 0.214%)

Overall valid: 1
```

It also listed each check with:

```text
Pass
Value
Threshold
Meaning
```

This should be the first validation file inspected after a run.

## 9. `manifest.txt`

Path:

```text
manifest.txt
```

The manifest records the contents and provenance of the run directory.

It provides a compact inventory of saved products.

Use it to confirm that the expected outputs were created.

## 10. Figures

The verified 2D run produced:

```text
figures/field_diagnostics.png
figures/motion_components.png
figures/source_diagnostics.png
```

### `field_diagnostics.png`

Used to inspect the propagated field.

Depending on the scenario, it may show amplitude, phase, or selected field
quantities.

### `motion_components.png`

Used to inspect different displacement or velocity components.

This helps assess intended polarization and unwanted component leakage.

### `source_diagnostics.png`

Used to inspect source geometry and source behavior.

This can reveal:

- source location;
- contact extent;
- driven nodes;
- source waveform;
- source frequency purity.

Figures are diagnostic products. They do not replace numerical validation.

## 11. Overall validity

The summary includes:

```text
Overall valid: 1
```

Interpretation:

```text
1 = all required checks passed
0 = one or more required checks failed
```

A run can complete successfully at the solver level and still be invalid.

Therefore:

```text
solver completed successfully
!=
scientifically valid result
```

## 12. Verified 2D validation checks

The verified directional run included the following checks.

### Preflight

```text
preflight
```

Meaning:

```text
All configuration and resource checks must pass.
```

Verified value:

```text
1
```

Threshold:

```text
1
```

### Shear points per wavelength

```text
shear_ppw
```

Verified value:

```text
8
```

Threshold:

```text
8
```

Meaning:

```text
The shear wavelength must be sufficiently resolved.
```

The text shown in the report describes the failure condition. Because the pass
flag was one, the case met the minimum PPW requirement.

### Source fundamental fraction

```text
source_fundamental_fraction
```

Verified value:

```text
1.000000
```

Threshold:

```text
0.999
```

Meaning:

```text
The stationary source must be dominated by the intended excitation frequency.
```

### Finite fields

```text
finite_fields
```

Verified value:

```text
1
```

Threshold:

```text
1
```

Meaning:

```text
The harmonic fields contain no NaN or Inf values.
```

### P/S energy ratio

```text
p_to_s_energy_ratio
```

Verified value:

```text
0.000497421
```

Threshold:

```text
0.05
```

Meaning:

```text
Compressional energy must remain small relative to shear energy.
```

This case was strongly shear-dominant.

### Steady-state change

```text
steady_state_change
```

Verified value:

```text
2.01429e-05
```

Threshold:

```text
0.01
```

Meaning:

```text
The late-time harmonic field must remain sufficiently stable.
```

### Shear-speed relative error

```text
shear_speed_relative_error
```

Verified value:

```text
0.00214051
```

Threshold:

```text
0.02
```

Equivalent percentage:

```text
0.214%
```

Meaning:

```text
The phase-gradient SWS estimate must agree with homogeneous ground truth.
```

## 13. Verified directional result

The verified run reported:

```text
truth SWS:       2.0000 m/s
estimated SWS:   2.0043 m/s
relative error:  0.214%
P/S energy:      4.974e-4
steady change:   2.014e-5
overall valid:   yes
```

This validates the specific homogeneous directional reference case.

It does not establish the same accuracy for heterogeneous, broad-angular, or
projected 3D fields.

## 14. Validation thresholds are case-specific

Thresholds are part of the simulation contract.

They should not be treated as universal constants.

Examples:

```text
maximum P/S energy ratio
maximum steady-state change
maximum speed error
minimum angular entropy
maximum directional bias
maximum mapping error
```

A directional benchmark and a broad-angular heterogeneous case may require
different checks.

Do not change thresholds only to make a failing run pass.

## 15. Failure interpretation

When a check fails:

```text
1. Identify the failing metric.
2. Read its value and threshold.
3. Inspect the resolved configuration.
4. Inspect the relevant figure.
5. Determine whether the issue is numerical, physical, or operational.
6. Change the model only after understanding the cause.
```

Examples:

### Low PPW

Possible causes:

```text
frequency too high
SWS too low
grid spacing too large
```

### High P/S energy ratio

Possible causes:

```text
polarization not transverse
source geometry
near-field contamination
heterogeneous mode conversion
boundary effects
```

### High steady-state change

Possible causes:

```text
simulation too short
insufficient settling
strong late reflections
source ramp too long
```

### High SWS error

Possible causes:

```text
insufficient resolution
phase unwrap failure
ROI contamination
non-directional field
boundary reflections
```

## 16. Finding the latest run

From the repository root:

```bash
LATEST_RUN="$(
  find outputs \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -print0 |
  xargs -0 ls -td |
  head -1
)"

echo "$LATEST_RUN"
```

## 17. Listing saved files

```bash
find "$LATEST_RUN" \
  -maxdepth 2 \
  -type f \
  | sort
```

## 18. Reading the validation summary

```bash
cat "$LATEST_RUN/data/validation_summary.txt"
```

## 19. Inspecting MAT files in MATLAB

```matlab
run_dir = "outputs/<timestamp>_<run_name>";

whos("-file", fullfile(run_dir, "data", "result.mat"))
whos("-file", fullfile(run_dir, "data", "summary.mat"))
whos("-file", fullfile(run_dir, "data", "validation_report.mat"))
```

To load one file:

```matlab
result = load(fullfile(run_dir, "data", "result.mat"));
```

Inspect fields:

```matlab
fieldnames(result)
```

## 20. Comparing requested and resolved configurations

The requested and resolved configurations answer different questions.

```text
requested configuration:
what the user supplied

resolved configuration:
what the framework completed and prepared for execution
```

When debugging unexpected behavior, compare both.

Important differences may include:

- defaults;
- automatic end time;
- generated source placement;
- normalized amplitudes;
- derived material maps;
- resolved output name;
- memory estimates;
- validation thresholds.

## 21. Output reproducibility

For every scientific result, preserve:

```text
requested configuration
resolved configuration
result.mat
validation report
software commit
seed
source-bank geometry seed
run directory name
analysis code version
```

A figure alone is not sufficient for reproducibility.

## 22. REQ validation sample

Some 3D runs can save:

```text
data/req_validation_sample.mat
```

when:

```json
"save_req_validation_sample": true
```

This is a lightweight export for external REQ processing.

It may include:

- complex 2D field;
- frequency;
- spatial spacing;
- orientation metadata;
- SWS truth map;
- material ID map;
- source-regime metadata.

The exact fields should be inspected before analysis.

## 23. REQ-ready status

REQ-ready means the exported sample satisfies operational requirements such as:

```text
finite complex field
known spacing
known frequency
sufficient dimensions
compatible analysis window
documented orientation
```

REQ-ready does not mean:

```text
REQ was executed
REQ was accurate
contrast was recovered
all regions had pure windows
```

## 24. Pure and mixed truth regions

For heterogeneous REQ analysis, classify each sliding window using the material
ID map.

Possible classes:

```text
background-pure
inclusion-pure
mixed
```

Report region-specific results separately.

Do not compare a mixed window to one material value as though it had unique
ground truth.

## 25. No pure background region

A heterogeneous validation may produce no background-pure windows.

This can happen when:

```text
analysis window is large
inclusion is large
saved field is cropped
ROI excludes outer background
```

In that case, do not claim background accuracy or complete contrast recovery.

## 26. Figures versus numerical metrics

Use figures to answer:

```text
Does the field look physically plausible?
Is the source where expected?
Are there obvious boundary artifacts?
Is the geometry aligned with truth?
```

Use numerical validation to answer:

```text
Did the configured criteria pass?
How large was the error?
How stable was the field?
How shear-dominant was the result?
```

Both are necessary.

## 27. Recommended run-review sequence

After every solver run:

```text
1. Read terminal summary.
2. Open validation_summary.txt.
3. Confirm Overall valid.
4. Inspect every failed or marginal check.
5. Inspect source diagnostics.
6. Inspect field and motion figures.
7. Inspect resolved_config.json.
8. Inspect result.mat field names.
9. Record the run directory.
10. Only then begin downstream analysis.
```

## 28. What a valid run establishes

A valid run establishes that the simulation passed the checks defined for that
configured scenario.

It may establish:

- acceptable spatial resolution;
- valid source waveform;
- finite harmonic fields;
- low compressional contamination;
- stable late-time field;
- agreement with known homogeneous SWS;
- valid geometry;
- operational REQ readiness.

## 29. What a valid run does not establish

A valid run does not automatically establish:

- experimental realism;
- physiological compressional speed;
- realistic attenuation;
- realistic actuator coupling;
- accurate ultrasound readout;
- universal estimator performance;
- accurate mixed-region SWS;
- ideal diffuse-field behavior.

These require separate evidence.

## 30. Summary

The run-review workflow is:

```text
configured simulation
-> timestamped run directory
-> requested and resolved configuration
-> primary result
-> structured validation
-> human-readable validation summary
-> diagnostic figures
-> downstream analysis
```

The most important principle is:

```text
a completed solver run is not automatically a valid scientific result
```
