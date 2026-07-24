# Reproducible Simulation Campaigns and Parameter Sweeps

## Overview

The campaign system provides a deterministic and resumable way to execute many validated simulations from one existing single-run configuration.

A campaign does not introduce a second simulation pipeline. It orchestrates the same configured-run entry point used for an individual simulation:

```matlab
kwsim.cli.runConfig
```

The campaign layer is responsible for:

- loading one campaign JSON file;
- loading one existing base simulation configuration;
- expanding a Cartesian parameter grid;
- applying configuration overrides;
- validating every expanded configuration before execution;
- assigning deterministic run identifiers;
- executing runs sequentially;
- resuming previously completed runs;
- recording failures and blocked directories;
- writing campaign-level summaries and a tabular run index.

The campaign layer does **not** duplicate or replace:

- the 2D or 3D solver;
- material or geometry construction;
- source construction;
- configuration validation;
- physical validation;
- harmonic analysis;
- REQ sample extraction;
- individual-run output saving.

This separation is important: every campaign run remains a normal, independently reproducible simulation.

---

## When to use campaigns

Campaigns are appropriate for:

- shear-wave-speed sweeps;
- frequency sweeps;
- seed sweeps;
- source-regime comparisons;
- grid-resolution studies;
- source-count studies;
- heterogeneous inclusion studies;
- REQ validation datasets;
- Adaptive REQ dataset generation;
- convergence and sensitivity analyses;
- reproducible benchmark studies.

A campaign is preferable to manually duplicating JSON files whenever the study differs only by a controlled set of parameter values.

A normal single-run JSON should always describe one valid simulation. Arrays of sweep values belong in the campaign JSON, not in the base simulation JSON.

---

## Conceptual model

```text
Validated base configuration
            │
            ▼
      Campaign JSON
            │
            ▼
Deterministic Cartesian expansion
            │
            ▼
One resolved configuration per run
            │
            ▼
Dry-run validation of every run
            │
            ▼
Sequential execution through
      kwsim.cli.runConfig
            │
            ▼
Per-run standard outputs
            │
            ▼
campaign_summary.json
campaign_runs.csv
```

---

# 1. Campaign contract

A campaign is defined by a JSON file.

Minimal example:

```json
{
  "schema_version": "1.0",
  "campaign_name": "homogeneous_directional_2d_sweep",
  "base_config": "configs/two_d/homogeneous_directional_cli.json",
  "output": {
    "directory": "outputs/campaigns"
  },
  "sweep": [
    {
      "path": "medium.cs_m_s",
      "values": [2.0, 2.5, 3.0]
    },
    {
      "path": "source.f0_hz",
      "values": [400, 500]
    },
    {
      "path": "seed",
      "values": [1001, 1002]
    }
  ]
}
```

This campaign expands to:

```text
3 shear-wave speeds
× 2 frequencies
× 2 seeds
= 12 runs
```

The last declared sweep parameter varies fastest.

---

## 1.1 `schema_version`

```json
"schema_version": "1.0"
```

The current campaign contract requires the string:

```text
1.0
```

Unsupported versions are rejected before expansion.

---

## 1.2 `campaign_name`

```json
"campaign_name": "homogeneous_directional_2d_sweep"
```

The campaign name is used as the campaign output directory name.

Allowed characters are:

- letters;
- numbers;
- underscores;
- hyphens.

The name must be non-empty.

Example output location:

```text
outputs/campaigns/homogeneous_directional_2d_sweep/
```

---

## 1.3 `base_config`

```json
"base_config": "configs/three_d/homogeneous_partial_3d_n8_p2_req_validation.json"
```

The base configuration must be an existing single-run JSON accepted by:

```matlab
kwsim.io.loadConfigJson
```

and:

```matlab
kwsim.cli.runConfig
```

Repository-relative paths are resolved from the repository root.

The base configuration fixes the simulation dimension. Campaign contract v1 does not allow sweeping between 2D and 3D.

The base file is never modified by campaign expansion.

---

## 1.4 `output.directory`

```json
"output": {
  "directory": "outputs/campaigns"
}
```

This optional field selects the campaign output root.

The default is:

```text
outputs/campaigns
```

The final campaign directory is:

```text
<output.directory>/<campaign_name>/
```

Campaign execution controls the following single-run output fields:

```text
output.enabled
output.directory
output.run_name
output.append_timestamp
output.overwrite
```

These fields cannot be swept.

---

## 1.5 `sweep`

```json
"sweep": [
  {
    "path": "medium.cs_m_s",
    "values": [2.0, 3.0]
  }
]
```

`sweep` is a non-empty ordered array.

Each entry contains:

| Field | Meaning |
|---|---|
| `path` | Existing field in the loaded base configuration |
| `values` | Non-empty list of replacement values |

Duplicate paths are rejected.

Unknown paths are rejected.

Empty value arrays are rejected.

Paths under `output` are forbidden.

`dimension` is forbidden in campaign contract v1.

---

# 2. Sweep path syntax

## 2.1 Standard nested paths

Nested configuration fields use dot notation:

```text
medium.cs_m_s
source.f0_hz
grid.dx_m
req_validation.cs_guess_m_s
seed
```

Each field must already exist in the loaded base configuration.

Campaign paths do not create missing fields.

---

## 2.2 Indexed paths

One-based array indexing is supported with square brackets.

Examples:

```text
geometry.objects[1].cs_m_s
geometry.objects[1].radius_m
geometry.objects[2].center_m_xyz
source.vibrators[5].weight
```

Rules:

- indices are one-based;
- index `0` is invalid;
- negative indices are invalid;
- non-integer indices are invalid;
- out-of-range indices are invalid;
- the indexed element must already exist in the base configuration;
- indexed paths do not append or create array elements.

Example:

```json
{
  "path": "geometry.objects[1].cs_m_s",
  "values": [2.5, 4.0]
}
```

This changes only the shear-wave speed of the first object. All other object fields remain unchanged.

---

## 2.3 Replacing structural values

Campaign contract v1 also allows replacement of an addressed structural value as a complete unit.

For example, the entire object array can technically be swept with:

```text
geometry.objects
```

However, indexed scalar paths are usually preferable because they:

- keep campaign files compact;
- preserve the base geometry;
- reduce duplication;
- make the scientific variable explicit;
- reduce accidental changes to unrelated fields.

Preferred:

```json
{
  "path": "geometry.objects[1].cs_m_s",
  "values": [2.5, 4.0]
}
```

Less preferable for a simple material sweep:

```json
{
  "path": "geometry.objects",
  "values": [
    { "...complete object definition..." },
    { "...complete object definition..." }
  ]
}
```

---

# 3. Cartesian expansion

Campaign contract v1 supports deterministic Cartesian products.

Example:

```json
"sweep": [
  {
    "path": "medium.cs_m_s",
    "values": [2.0, 3.0]
  },
  {
    "path": "source.f0_hz",
    "values": [400, 500, 600]
  },
  {
    "path": "seed",
    "values": [1001, 1002]
  }
]
```

Run count:

```text
2 × 3 × 2 = 12
```

Ordering:

```text
The last declared parameter varies fastest.
```

For the example above:

```text
run 1: cs=2.0, f0=400, seed=1001
run 2: cs=2.0, f0=400, seed=1002
run 3: cs=2.0, f0=500, seed=1001
run 4: cs=2.0, f0=500, seed=1002
...
```

The ordering is stable across repeated expansion.

---

## 3.1 Current scope

Campaign contract v1 does not support:

- filtered Cartesian combinations;
- conditional combinations;
- dependent parameters;
- algebraic expressions;
- adaptive sampling;
- optimization-driven sampling;
- random sampling generated by the campaign layer;
- coupled sweeps such as `cp = 10 * cs`;
- dimension changes;
- parallel execution;
- MATLAB `parfor`;
- SLURM submission.

These can be added in later contracts without changing the single-run interface.

---

# 4. Material-property sweeps

## 4.1 Background material

A homogeneous background speed sweep typically uses:

```json
{
  "path": "medium.cs_m_s",
  "values": [2.0, 3.0]
}
```

For a 3D base configuration using:

```json
"cp_mode": "reduced",
"reduced_cp_factor": 10
```

the standard 3D configuration resolver computes the background compression speed from the background shear speed.

This behavior belongs to the single-run configuration resolver, not to the campaign system.

---

## 4.2 Heterogeneous objects

A compact inclusion sweep uses an indexed object path:

```json
{
  "path": "geometry.objects[1].cs_m_s",
  "values": [2.5, 4.0]
}
```

The campaign layer changes only `cs_m_s`.

It does not automatically modify `cp_m_s`, density, radius, center, or material ID.

Those behaviors are determined by the base configuration and the material resolver.

---

## 4.3 Object compression speed

If an object explicitly contains:

```json
"cp_m_s": 20.0
```

then sweeping only:

```text
geometry.objects[1].cs_m_s
```

preserves `cp_m_s = 20.0`.

This is useful when the study is intended to vary shear stiffness while keeping compression speed uniform across the domain.

If an object omits `cp_m_s`, the existing 3D material resolver derives object compression speed using the current single-run material-resolution rules.

Campaigns do not create calculated relationships between sweep parameters.

---

## 4.4 Density

If object density is explicitly provided, it remains fixed unless swept.

If object density is omitted, the normal material resolver may inherit background density according to the single-run material contract.

Again, this is solver-configuration behavior rather than campaign behavior.

---

# 5. Deterministic run identity

Every expanded run receives:

```text
run_000001_<hash>
```

Example:

```text
run_000001_76f327620e2d
```

The run identifier contains:

- a six-digit deterministic ordinal;
- the first 12 hexadecimal characters of a SHA-256 hash.

The complete 64-character hash is also stored.

---

## 5.1 Hash input

The hash is calculated from the expanded single-run configuration:

1. load the base configuration;
2. apply all selected sweep values;
3. encode the resulting configuration;
4. compute SHA-256;
5. only afterward inject campaign-controlled output paths.

Therefore, changing the campaign output directory does not change run identity.

Changing a simulation parameter does change run identity.

---

## 5.2 Why deterministic identity matters

Deterministic hashes support:

- reproducible expansion;
- safe resume;
- detection of changed physics;
- avoidance of accidental reuse;
- traceability from a CSV row to a resolved configuration;
- stable downstream dataset indexing.

For example, changing object `cp_m_s` from 25 to 20 m/s changes the hash even if all other parameters remain the same.

The new run is therefore treated as a different simulation.

---

# 6. Campaign validation

Before creating campaign outputs, execution validates every expanded run through:

```matlab
kwsim.cli.runConfig(config_file, DryRun=true)
```

Conceptually, validation performs:

1. load campaign JSON;
2. validate campaign fields;
3. load the base configuration;
4. validate all sweep paths;
5. expand the Cartesian grid;
6. apply every combination;
7. dry-run every expanded single-run configuration;
8. aggregate any failures.

A campaign does not begin execution if any expanded run fails validation.

This all-or-nothing preflight behavior prevents a large study from starting with known invalid combinations.

---

## 6.1 What campaign dry-run validates

Dry-run verifies:

- campaign schema;
- base configuration path;
- sweep paths;
- indexed-path bounds;
- non-empty values;
- duplicate paths;
- forbidden paths;
- each expanded simulation configuration;
- normal 2D or 3D preflight constraints;
- geometry validity;
- grid constraints;
- source constraints;
- REQ sample feasibility when configured.

---

## 6.2 What campaign dry-run does not do

Dry-run does not:

- execute k-Wave;
- create simulation outputs;
- create campaign run directories;
- save result volumes;
- save figures;
- measure runtime;
- confirm final physical validity after propagation.

---

# 7. Using the MATLAB API

## 7.1 Expand a campaign

```matlab
addpath("src");

[runs, expansion] = ...
    kwsim.campaigns.expandCampaign( ...
        "configs/campaigns/example.json");
```

Useful fields:

```matlab
expansion.run_count
expansion.value_counts
runs(1).ordinal
runs(1).run_id
runs(1).hash_sha256
runs(1).selection
runs(1).config
```

---

## 7.2 Validate a campaign

```matlab
addpath("src");

[runs, report] = ...
    kwsim.campaigns.validateCampaign( ...
        "configs/campaigns/example.json");

disp(report.summary);
```

Typical report fields:

```matlab
report.run_count
report.valid_count
report.failed_count
report.valid
report.runs
report.summary
```

Validation creates no simulation outputs.

---

## 7.3 Execute a campaign

```matlab
addpath("src");

report = kwsim.campaigns.runCampaign( ...
    "configs/campaigns/example.json", ...
    Resume=true, ...
    ContinueOnError=true);

disp(report.summary);
```

---

## 7.4 Execution options

### `Resume`

```matlab
Resume=true
```

Default:

```text
true
```

Completed runs with matching hashes are skipped.

### `ContinueOnError`

```matlab
ContinueOnError=true
```

Default:

```text
true
```

Failed or blocked runs are recorded while later runs continue.

Set:

```matlab
ContinueOnError=false
```

to stop after the first execution failure or blocked directory.

### `Runner`

The default runner is:

```matlab
@kwsim.cli.runConfig
```

A custom runner may be injected for unit tests or specialized orchestration:

```matlab
Runner=@customRunner
```

Production campaigns should normally use the default runner.

---

# 8. Run-state model

The campaign summary uses execution states.

## `pending`

The run has not started.

## `running`

The run has been selected for execution and the campaign summary has been updated.

## `completed`

The runner finished, produced the expected directory, and a completion marker was written.

## `skipped_completed`

A matching completed run already existed and `Resume=true`.

The solver was not executed again.

## `failed`

The run raised an exception.

The error identifier and message are recorded.

## `blocked_existing`

The expected run directory already exists but cannot be safely reused.

Common reasons:

- missing `campaign_run.json`;
- invalid completion marker;
- marker hash mismatch;
- marker status not equal to `completed`.

The directory is never overwritten automatically.

---

## 8.1 Outcome status

Execution state and simulation outcome are distinct.

Example:

```text
status = completed
outcome_status = completed_valid
```

After resume:

```text
status = skipped_completed
outcome_status = completed_valid
```

`status` describes what the campaign runner did during the current invocation.

`outcome_status` describes the stored result from the simulation runner.

---

# 9. Resume behavior

Resume uses the expected run directory:

```text
<campaign directory>/<run_id>/
```

and the marker:

```text
campaign_run.json
```

A run is reusable only if:

- the directory exists;
- the marker exists;
- the marker is valid JSON;
- the marker contains the expected SHA-256 hash;
- the marker records `status = completed`.

A directory without a valid matching marker is not overwritten.

This conservative behavior protects partial or scientifically different results.

---

## 9.1 Interrupted runs

If MATLAB stops while a run is executing, the output directory may exist without a completion marker.

On the next invocation, the run becomes:

```text
blocked_existing
```

Inspect the partial directory before deciding whether to archive or remove it.

The campaign system does not delete interrupted outputs automatically.

---

## 9.2 Changed base configuration

If the base configuration changes, hashes may change.

The campaign will then generate new run IDs.

Old directories can coexist with new directories under the same campaign name, but only current run IDs appear in the current:

```text
campaign_summary.json
campaign_runs.csv
```

This behavior correctly distinguishes different numerical experiments.

---

# 10. Output layout

Example:

```text
outputs/campaigns/
└── heterogeneous_large_sphere_n32_p8_smoke/
    ├── campaign_summary.json
    ├── campaign_runs.csv
    ├── run_000001_3135b9b72597/
    │   ├── campaign_run.json
    │   ├── manifest.txt
    │   ├── config/
    │   │   ├── requested_config.mat
    │   │   ├── resolved_config.json
    │   │   └── resolved_config.mat
    │   ├── data/
    │   │   ├── result.mat
    │   │   ├── summary.mat
    │   │   ├── validation_report.mat
    │   │   ├── validation_summary.txt
    │   │   └── req_validation_sample.mat
    │   └── figures/
    │       ├── material_geometry.png
    │       ├── material_geometry.fig
    │       ├── z_shear_slices.png
    │       └── z_shear_slices.fig
    └── run_000002_aac025a07772/
        └── ...
```

Exact per-run artifacts depend on the base configuration's output options.

---

# 11. `campaign_run.json`

Each successfully completed run contains a campaign completion marker.

Typical fields include:

```text
schema_version
status
ordinal
run_id
hash_sha256
outcome_status
completed
```

This marker is used for resume.

It is not a substitute for the full resolved configuration or validation report.

---

# 12. `campaign_summary.json`

This file records campaign-level execution state.

Typical fields:

```text
schema_version
campaign_file
campaign_name
campaign_directory
run_count
completed_count
skipped_count
failed_count
blocked_count
pending_count
running_count
success
runs
updated
summary
```

The `runs` array includes:

```text
ordinal
run_id
hash_sha256
status
outcome_status
run_directory
error_identifier
error_message
```

The file is updated atomically after state transitions.

---

## 12.1 Interpreting `success`

`success=true` requires:

```text
failed_count = 0
blocked_count = 0
pending_count = 0
running_count = 0
```

Resumed runs do not count as failures.

A campaign containing only `skipped_completed` runs can still be successful.

---

# 13. `campaign_runs.csv`

`campaign_runs.csv` contains one row per expanded run.

It combines:

- campaign identity;
- current execution state;
- selected physical parameters;
- validation metrics when available;
- artifact paths;
- failure information.

The CSV is rewritten atomically whenever campaign state is published.

---

## 13.1 Identity columns

```text
ordinal
run_id
hash_sha256
status
outcome_status
```

---

## 13.2 Configuration columns

```text
scenario
dimension
seed
frequency_hz
background_cs_m_s
background_cp_m_s
inclusion_cs_m_s
inclusion_cp_m_s
```

Homogeneous simulations have no inclusion. Inclusion columns are therefore:

```text
NaN
```

This is expected.

---

## 13.3 Runtime and validation columns

```text
solver_elapsed_s
valid
p_to_s_energy_ratio
total_shear_energy
total_compression_energy
req_ready
source_count
directional_bias
effective_angular_dimension
```

Some validators may not expose every metric under the same field names.

Unavailable values are written as:

```text
NaN
```

`NaN` means unavailable or not applicable. It does not automatically mean invalid.

---

## 13.4 Path columns

```text
run_directory
resolved_config_path
summary_path
validation_report_path
req_sample_path
```

These paths make the CSV directly useful as a dataset index.

For example, Adaptive REQ preprocessing can iterate over:

```text
req_sample_path
```

while retaining the associated physical parameters and source-geometry metrics.

---

## 13.5 Error columns

```text
error_identifier
error_message
```

These are empty for successful runs.

They are populated for failed or blocked runs.

---

## 13.6 Reading the CSV in MATLAB

Specify the delimiter explicitly:

```matlab
T = readtable( ...
    "outputs/campaigns/example/campaign_runs.csv", ...
    Delimiter=",", ...
    TextType="string");
```

Do not rely on delimiter autodetection for this file. Headers contain many underscores, and automatic detection may incorrectly infer `_` as the delimiter.

---

## 13.7 Reading the CSV in Python

```python
import pandas as pd

runs = pd.read_csv(
    "outputs/campaigns/example/campaign_runs.csv"
)

print(runs.head())
```

Filter valid REQ-ready runs:

```python
ready = runs[
    (runs["valid"] == 1)
    & (runs["req_ready"] == 1)
]
```

---

# 14. Example: homogeneous 3D partial field

Campaign:

```json
{
  "schema_version": "1.0",
  "campaign_name": "homogeneous_partial_3d_n8_p2_smoke",
  "base_config": "configs/three_d/homogeneous_partial_3d_n8_p2_req_validation.json",
  "output": {
    "directory": "outputs/campaigns"
  },
  "sweep": [
    {
      "path": "medium.cs_m_s",
      "values": [2.0, 3.0]
    }
  ]
}
```

This produces two runs at the frequency and seed fixed by the base configuration.

Expected CSV interpretation:

```text
background_cs_m_s = 2.0 or 3.0
inclusion_cs_m_s = NaN
source_count = 8
req_ready = 1 when the saved validation reports readiness
```

---

# 15. Example: homogeneous 3D generated angular field

```json
{
  "schema_version": "1.0",
  "campaign_name": "homogeneous_generated_angular_n32_p8_smoke",
  "base_config": "configs/three_d/homogeneous_generated_angular_n32_p8_req_validation.json",
  "output": {
    "directory": "outputs/campaigns"
  },
  "sweep": [
    {
      "path": "medium.cs_m_s",
      "values": [2.0, 3.0]
    }
  ]
}
```

This campaign uses the same orchestration but a broader source geometry.

Useful CSV fields for comparing source regimes:

```text
source_count
directional_bias
effective_angular_dimension
```

These describe the configured source geometry, not a universal measured-field diffusivity.

---

# 16. Example: heterogeneous 3D sphere

Base configuration:

```text
configs/three_d/heterogeneous_large_sphere_n32_p8_req_validation.json
```

Campaign:

```json
{
  "schema_version": "1.0",
  "campaign_name": "heterogeneous_large_sphere_n32_p8_smoke",
  "base_config": "configs/three_d/heterogeneous_large_sphere_n32_p8_req_validation.json",
  "output": {
    "directory": "outputs/campaigns"
  },
  "sweep": [
    {
      "path": "geometry.objects[1].cs_m_s",
      "values": [2.5, 4.0]
    }
  ]
}
```

If the base object contains:

```json
"cp_m_s": 20.0
```

then both runs preserve:

```text
background cp = 20 m/s
inclusion cp = 20 m/s
```

while varying only inclusion shear-wave speed.

---

# 17. Example: multi-parameter Adaptive REQ study

A future controlled homogeneous campaign may use:

```json
{
  "schema_version": "1.0",
  "campaign_name": "adaptive_req_partial_3d_grid",
  "base_config": "configs/three_d/homogeneous_partial_3d_n8_p2_req_validation.json",
  "output": {
    "directory": "outputs/campaigns"
  },
  "sweep": [
    {
      "path": "medium.cs_m_s",
      "values": [2.0, 2.5, 3.0, 3.5, 4.0]
    },
    {
      "path": "source.f0_hz",
      "values": [400, 500, 600]
    },
    {
      "path": "seed",
      "values": [1001, 1002, 1003]
    }
  ]
}
```

Run count:

```text
5 × 3 × 3 = 45
```

Before launching a large grid:

1. validate the campaign;
2. inspect expansion count;
3. run a two-case smoke campaign;
4. estimate total runtime;
5. confirm disk requirements;
6. enable resume;
7. then launch the full campaign.

---

# 18. Recommended workflow

## Step 1: validate the base configuration

Run or dry-run the single JSON independently.

## Step 2: create a small campaign

Start with two values for one parameter.

## Step 3: inspect expansion

```matlab
[runs, expansion] = ...
    kwsim.campaigns.expandCampaign(campaign_file);

disp(expansion.run_count);
disp(string({runs.run_id})');
```

## Step 4: dry-run all expanded configurations

```matlab
[~, validation] = ...
    kwsim.campaigns.validateCampaign(campaign_file);

assert(validation.valid);
```

## Step 5: execute the smoke campaign

```matlab
report = kwsim.campaigns.runCampaign( ...
    campaign_file, ...
    Resume=true, ...
    ContinueOnError=false);
```

## Step 6: inspect campaign outputs

Review:

```text
campaign_summary.json
campaign_runs.csv
validation_summary.txt
resolved_config.json
```

## Step 7: test resume

Run the same campaign again and confirm:

```text
skipped_count > 0
```

## Step 8: expand to the scientific grid

Only after the smoke campaign is validated.

---

# 19. Failure recovery

## 19.1 One run fails

With:

```matlab
ContinueOnError=true
```

the failed row is recorded and subsequent runs continue.

Inspect:

```text
error_identifier
error_message
```

in `campaign_runs.csv`.

---

## 19.2 Existing incomplete directory

Status:

```text
blocked_existing
```

Inspect the run directory.

Do not delete it until determining whether useful partial outputs exist.

After archiving or intentionally removing the incomplete directory, rerun the campaign.

---

## 19.3 Hash mismatch

A directory may exist at a run location but contain a marker for another hash.

This indicates inconsistent or manually altered state.

The campaign blocks the run rather than overwriting it.

---

## 19.4 Invalid campaign

If any expanded configuration fails dry-run validation:

```text
kwsim:CampaignValidationFailed
```

No campaign output directory should be created by execution.

Fix the invalid parameter combination before rerunning.

---

## 19.5 Unknown sweep path

Typical causes:

- typographical error;
- field absent from the base configuration;
- index out of range;
- zero-based indexing used accidentally;
- attempting to create a new field.

Example invalid path:

```text
geometry.objects[0].cs_m_s
```

Correct:

```text
geometry.objects[1].cs_m_s
```

---

## 19.6 Forbidden output path

Campaign execution owns output naming.

Invalid examples:

```text
output.run_name
output.directory
output.append_timestamp
```

Select campaign output location through:

```json
"output": {
  "directory": "outputs/campaigns"
}
```

---

# 20. Performance planning

Campaign execution is sequential in contract v1.

Total runtime is approximately:

```text
sum of individual solver runtimes
+ validation and saving overhead
```

For large 3D cases, estimate runtime from a smoke campaign before launching the complete grid.

Runtime can vary with:

- grid dimensions;
- number of time steps;
- compression speed;
- shear speed;
- source count;
- settling cycles;
- sensor size;
- output saving;
- figure generation;
- machine load.

Use `solver_elapsed_s` in `campaign_runs.csv` for empirical estimates.

---

## 20.1 Reducing smoke-test cost

For infrastructure checks, use:

- small grids;
- few sweep values;
- one frequency;
- one seed;
- reduced compression speed where scientifically acceptable;
- no native time-series saving;
- minimal figure output.

Do not reduce scientific campaign settings without documenting the change.

---

# 21. Reproducibility and provenance

A campaign run is reproducible through the combination of:

```text
campaign JSON
base configuration
resolved_config.json
full SHA-256 hash
run identifier
summary.mat
validation_report.mat
req_validation_sample.mat
framework commit
k-Wave version
```

The resolved configuration is the authoritative record of the actual run.

The campaign JSON records how the run was selected.

The hash records configuration identity.

The validation report records whether the result satisfied the configured checks.

---

# 22. Version-control recommendations

Commit:

- campaign JSON files;
- base configuration JSON files;
- campaign contract documentation;
- user-guide documentation;
- campaign code;
- tests.

Do not normally commit:

- `outputs/campaigns/`;
- large `.mat` results;
- figures generated during smoke runs;
- k-Wave toolbox files;
- `.DS_Store`.

Use exact staging paths rather than:

```bash
git add -A
```

---

# 23. Extending the campaign system

## 23.1 Adding a new sweepable parameter

If the field already exists in the base configuration and is supported by normal single-run validation, no campaign code change is normally required.

Example:

```text
req_validation.cs_guess_m_s
```

can be swept if present in the base config.

---

## 23.2 Adding a new CSV column

Update:

```text
src/+kwsim/+campaigns/writeCampaignRunsCsv.m
```

The new column should:

- be available for all runs or use `NaN`/empty string;
- avoid parsing human-readable text when a structured field exists;
- preserve backward-compatible existing columns;
- be covered by tests;
- be documented here.

---

## 23.3 Adding new campaign semantics

Features such as dependent parameters or filtered grids should use a new explicit contract rather than silently changing contract v1 behavior.

Potential future extensions:

- explicit case lists;
- filtered Cartesian products;
- dependent parameters;
- parallel local execution;
- cluster submission;
- retry policies;
- campaign-level dataset assembly;
- automatic train/validation/test partitioning.

---

# 24. Testing expectations

Campaign development should preserve tests for:

- contract loading;
- defaults;
- unknown fields;
- missing fields;
- unsupported schema;
- unknown paths;
- duplicate paths;
- forbidden paths;
- indexed paths;
- out-of-range indices;
- zero indices;
- deterministic expansion;
- stable hashes;
- output-location-independent identity;
- dry-run validation;
- failure aggregation;
- deterministic run directories;
- resume;
- blocked incomplete directories;
- invalid campaign output suppression;
- CSV creation;
- CSV status rows;
- CSV error recording.

Run the campaign suite before committing.

---

# 25. Best practices

- Keep each base configuration valid independently.
- Use campaigns only for controlled parameter variation.
- Start with a small smoke campaign.
- Validate every expanded run before execution.
- Estimate runtime from completed smoke runs.
- Preserve `Resume=true` for long studies.
- Use deterministic seeds.
- Keep source geometry fixed when comparing only material properties.
- Keep compression speed fixed when the scientific question concerns only shear contrast, when appropriate.
- Use indexed paths instead of duplicating complete object definitions.
- Treat `NaN` in the CSV as unavailable or not applicable, not automatically invalid.
- Archive `campaign_summary.json` and `campaign_runs.csv` with analyzed datasets.
- Never manually edit a completed run directory.
- Do not reuse outputs after changing physical configuration.
- Use resolved configs as the final record of what was simulated.

---

# 26. Quick reference

## Expand

```matlab
[runs, expansion] = ...
    kwsim.campaigns.expandCampaign(campaign_file);
```

## Validate

```matlab
[~, validation] = ...
    kwsim.campaigns.validateCampaign(campaign_file);
```

## Execute

```matlab
report = kwsim.campaigns.runCampaign( ...
    campaign_file, ...
    Resume=true, ...
    ContinueOnError=true);
```

## Read CSV in MATLAB

```matlab
T = readtable( ...
    fullfile(report.campaign_directory, "campaign_runs.csv"), ...
    Delimiter=",", ...
    TextType="string");
```

## Open the campaign folder on macOS

```bash
open outputs/campaigns/<campaign_name>
```

## Find campaign tables

```bash
find outputs/campaigns \
  -type f \
  -name 'campaign_runs.csv' \
  | sort
```

---

# 27. Summary

The campaign system converts one validated simulation configuration into a deterministic, validated, resumable collection of independent runs.

Its core guarantees are:

- no duplicated solver pipeline;
- deterministic Cartesian expansion;
- stable configuration hashes;
- validation before execution;
- safe resume;
- no automatic overwrite of incomplete state;
- standard outputs per run;
- campaign-level JSON and CSV indices;
- direct traceability from scientific parameters to saved REQ samples.

This makes campaigns the recommended foundation for reproducible parameter studies and Adaptive REQ dataset generation.
