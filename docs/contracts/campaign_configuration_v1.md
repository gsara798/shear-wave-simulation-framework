# Campaign configuration contract v1

A simulation campaign defines a deterministic Cartesian expansion of one
existing, validated simulation configuration.

Campaigns orchestrate `kwsim.cli.runConfig`. They do not implement solver,
source, material, geometry, validation, or single-run output logic.

## Required fields

```json
{
  "schema_version": "1.0",
  "campaign_name": "example_campaign",
  "base_config": "configs/two_d/example.json",
  "sweep": [
    {
      "path": "medium.cs_m_s",
      "values": [2.0, 2.5]
    }
  ]
}
```

### `schema_version`

Must be the string `"1.0"`.

### `campaign_name`

Non-empty identifier used as the campaign directory name. It must contain only
letters, numbers, underscores, and hyphens.

### `base_config`

Path to an existing single-run JSON configuration accepted by
`kwsim.io.loadConfigJson` and `kwsim.cli.runConfig`.

Repository-relative paths are resolved from the repository root. The base
configuration fixes the simulation dimension; `dimension` cannot be swept in
contract v1.

### `sweep`

Non-empty ordered array of sweep definitions.

Each definition contains:

- `path`: path to an existing field in the resolved base configuration.
- `values`: non-empty JSON array of replacement values.

The Cartesian expansion follows the declared parameter order. The last
parameter varies fastest.

Unknown paths are errors. Duplicate paths are errors. Structural values,
including geometry object arrays, replace the addressed value as a complete
unit.

Paths under `output` cannot be swept. Campaign execution owns the output
directory, run name, timestamp policy, and overwrite policy.

## Sweep path syntax

Campaign paths use dot notation for nested fields.

Examples:

```text
medium.cs_m_s
source.f0_hz
req_validation.cs_guess_m_s
```

A path may also select one element of an existing array using a one-based index
in square brackets.

Examples:

```text
geometry.objects[1].cs_m_s
geometry.objects[1].radius_m
geometry.objects[2].center_m_xyz
```

Indexed paths follow these rules:

- indices are one-based;
- the selected array element must already exist in the base configuration;
- indexed paths do not create new array elements;
- index `0`, negative indices, non-integer indices, and out-of-range indices
  are invalid;
- all non-indexed path components must identify existing structure fields.

For example:

```json
{
  "path": "geometry.objects[1].cs_m_s",
  "values": [2.5, 4.0]
}
```

changes only the shear-wave speed of the first object while preserving its
geometry, material identifier, density, compression speed, and other fields.

## Optional fields

### `output.directory`

Root directory for campaign outputs. The default is:

```text
outputs/campaigns
```

The campaign runner creates:

```text
<output.directory>/<campaign_name>/
```

## Expansion and identity

The example

```text
3 SWS values × 2 frequencies × 2 seeds
```

expands to 12 runs.

Each run receives a deterministic ordinal and hash:

```text
run_000001_<hash>
```

The hash is calculated from the canonical single-run definition after applying
the sweep overrides and before injecting campaign-controlled output paths.
Therefore, relocating a campaign does not change run identity.

The last declared sweep parameter varies fastest.

## Validation

Campaign dry-run must:

1. load and validate the campaign configuration;
2. load the base configuration;
3. expand every Cartesian combination;
4. apply each override;
5. validate every expanded configuration through
   `kwsim.cli.runConfig(..., DryRun=true)`;
6. create no campaign or simulation outputs.

A campaign is not executable if any expanded configuration fails dry-run
validation.

## Execution and resume

Campaign execution delegates every expanded run to `kwsim.cli.runConfig`.

Each run is written to:

```text
<output.directory>/<campaign_name>/<run_id>/
```

Campaign-controlled single-run output settings are:

```text
output.enabled = true
output.directory = <campaign directory>
output.run_name = <run_id>
output.append_timestamp = false
output.overwrite = false
```

A completed run contains a `campaign_run.json` completion marker with the
expected configuration hash.

When resume is enabled:

- a matching completed run is skipped;
- a directory without a valid completion marker is treated as incomplete;
- an incomplete or identity-mismatched directory is never overwritten;
- failed or blocked runs are recorded in the campaign summary;
- execution may continue after a failed run when `ContinueOnError=true`.

The campaign runner writes:

```text
<output.directory>/<campaign_name>/campaign_summary.json
```

The summary records campaign status, run identifiers, hashes, output
directories, completed runs, resumed runs, failures, blocked runs, and pending
runs.

## Material-property sweeps

A campaign changes only the explicitly addressed value.

For heterogeneous 3D simulations, a compact inclusion sweep can use:

```json
{
  "path": "geometry.objects[1].cs_m_s",
  "values": [2.5, 4.0]
}
```

Other object properties remain fixed by the base configuration.

In particular, `cp_m_s` is not changed automatically by the campaign layer.
Its behavior is determined by the single-run material configuration and the
3D material resolver:

- if an object defines `cp_m_s`, that value is preserved while `cs_m_s` is
  swept;
- if an object omits `cp_m_s`, the material resolver derives it according to
  the existing single-run material-resolution rules.

Campaigns do not introduce calculated relationships such as
`cp_m_s = 10 * cs_m_s`.

## Backward compatibility

Contract v1 preserves all existing single-run behavior.

Campaign support does not change:

- existing simulation JSON files;
- configured CLI commands;
- 2D or 3D solvers;
- source or material builders;
- physical validation;
- output formats for individual runs;
- existing tests outside the campaign package.

A campaign is only an orchestration layer around validated single-run
configurations.

## Scope exclusions in v1

Contract v1 does not include:

- sweeping between 2D and 3D;
- calculated parameter expressions;
- dependent or coupled sweep parameters;
- filtered Cartesian combinations;
- parallel or cluster execution;
- MATLAB `parfor`;
- SLURM;
- adaptive or optimization-driven sampling;
- automatic ML feature extraction;
- train/test splitting;
- new solver physics;
- changes to physical validation behavior.
