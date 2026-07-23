# Quick Start

This guide shows the shortest verified path from a configuration file to a
completed shear-wave simulation.

The framework is built on top of the k-Wave MATLAB toolbox. It organizes
configuration, execution, validation, figures, and simulation outputs; it does
not replace k-Wave.

## 1. Requirements

The current framework requires:

- MATLAB;
- the k-Wave MATLAB toolbox;
- Python 3, used by the command-line wrapper to resolve file paths;
- a Bash-compatible terminal.

The current development and validation environment uses k-Wave 1.4.1.

Run all commands from the repository root:

```bash
cd /absolute/path/to/k-wave_simulations
```

## 2. Check the command-line interface

Display the available CLI options:

```bash
./scripts/kwsim-run --help
```

Expected interface:

```text
Usage:
  ./scripts/kwsim-run CONFIG.json
  ./scripts/kwsim-run CONFIG.json --dry-run

Options:
  --dry-run    Validate and resolve the configuration without running k-Wave.
  -h, --help   Show this message.

Environment:
  MATLAB_BIN   Optional path to the MATLAB executable.
```

## 3. Run a dry run first

A dry run loads the JSON configuration, validates it, resolves the simulation
settings, and performs the preflight checks without invoking the k-Wave solver.

For the smallest configured 2D example:

```bash
./scripts/kwsim-run \
  configs/two_d/homogeneous_directional_cli.json \
  --dry-run
```

A successful dry run ends with:

```text
Dry run completed successfully.
No solver was executed and no outputs were created.
```

Dry runs are recommended before every new or modified configuration.

## 4. Execute the simulation

Run the same configuration without `--dry-run`:

```bash
./scripts/kwsim-run \
  configs/two_d/homogeneous_directional_cli.json
```

The CLI will:

1. load and validate the configuration;
2. construct the grid, medium, source, and sensor;
3. execute the k-Wave solver;
4. extract the harmonic field;
5. evaluate the validation checks;
6. save the requested outputs.

A successful configured run ends with messages similar to:

```text
Saved run to:
outputs/<timestamp>_cli_homogeneous_directional_2d

Validation:
valid=1, ...

Configured simulation completed successfully.
```

Runtime depends on grid size, simulation duration, solver settings, and computer
hardware. The verified reference 2D configuration completed in approximately
23 seconds on the development computer.

## 5. Find the generated output

Configured runs are saved under:

```text
outputs/<timestamp>_<run_name>/
```

The verified 2D reference run generated:

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

The exact files depend on the `output` section of the configuration.

### Configuration files

- `requested_config.mat` records the requested configuration.
- `resolved_config.json` records the complete configuration after defaults,
  derived parameters, and geometry resolution have been applied.
- `resolved_config.mat` stores the same resolved information in MATLAB format.

### Data files

- `result.mat` contains the primary simulation result and physical fields.
- `summary.mat` contains the compact run summary.
- `validation_report.mat` contains the structured validation report.
- `validation_summary.txt` provides a human-readable validation summary.

### Figures

The `figures/` directory contains the diagnostic images enabled by the selected
scenario and output configuration.

### Manifest

`manifest.txt` records the contents and provenance of the run directory.

## 6. Inspect the validation report

For the most recent output directory:

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

cat "$LATEST_RUN/data/validation_summary.txt"
```

The validated 2D reference case checks:

- configuration and resource preflight;
- shear-wave points per wavelength;
- source fundamental-frequency content;
- finite harmonic fields;
- compressional-to-shear energy ratio;
- harmonic steady-state convergence;
- shear-speed agreement with the known ground truth.

A run should not be treated as physically validated solely because the solver
completed. Inspect `Overall valid` and the individual validation checks.

## 7. Verified 3D dry-run examples

The following configurations have been verified through the CLI dry-run path.

### Homogeneous directional 3D field

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

These commands verify configuration resolution and preflight. A dry run does
not execute the solver and does not create output files.

## 8. MATLAB executable location

The CLI uses the `MATLAB_BIN` environment variable when provided.

Example:

```bash
export MATLAB_BIN="/path/to/MATLAB/bin/matlab"

./scripts/kwsim-run \
  configs/two_d/homogeneous_directional_cli.json \
  --dry-run
```

When `MATLAB_BIN` is not set, the current wrapper uses its configured default
MATLAB path.

## Next steps

After completing the Quick Start, continue with:

- the configuration guide, for modifying simulation parameters;
- the output and data-contract guide, for interpreting saved results;
- the example recipes, for creating homogeneous, heterogeneous, directional,
  and multi-source simulations.
