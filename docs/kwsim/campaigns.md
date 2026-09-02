# Reproducible Simulation Campaigns

`simcampaigns` is the backend-neutral orchestration layer for reproducible groups of simulations.

A campaign does not introduce a second solver pipeline. Each expanded run is still executed through the normal backend public interface.

## When to use a campaign

Campaigns are appropriate for:

- shear-wave-speed sweeps;
- frequency sweeps;
- seed sweeps;
- grid-resolution studies;
- source-count and source-regime studies;
- heterogeneous material studies;
- convergence and sensitivity analyses;
- reproducible benchmark datasets.

Use a single JSON configuration when there is only one simulation condition.

## Two campaign representations

Use `sweep` when parameters vary independently and every Cartesian combination is scientifically intended.

Use explicit `runs` when several values jointly define one named physical scenario and must remain paired.

Both forms pass through:

```text
campaign JSON
→ simcampaigns.expandCampaign
→ simcampaigns.validateCampaign
→ simcampaigns.runCampaign
→ standard backend outputs
```

## Cartesian sweep example

```json
{
  "schema_version": "1.0",
  "campaign_name": "homogeneous_directional_2d_sweep",
  "base_config": "configs/kwsim/two_d/homogeneous_directional_cli.json",
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

This produces 12 deterministic run definitions.

## Sweep paths

Nested configuration values use dot notation:

```text
medium.cs_m_s
source.f0_hz
grid.dx_m
seed
```

Indexed paths can address existing array elements:

```text
geometry.objects[1].cs_m_s
geometry.objects[1].radius_m
source.vibrators[5].weight
```

Indices are one-based and must refer to elements already present in the base configuration. Campaign expansion does not create missing fields or append array elements implicitly.

## Explicit runs

Use explicit runs for named or paired scenarios, for example when source count, angular support, in-plane contributors, and geometry constraints must change together.

Do not encode such cases as independent sweep dimensions unless every cross-combination is physically intended.

See [`../campaigns/explicit_campaign_api.md`](../campaigns/explicit_campaign_api.md) for the explicit-run construction API.

## Expansion

```matlab
[runs, expansion] = simcampaigns.expandCampaign( ...
    'configs/campaigns/kwsim/scientific/homogeneous_directional_2d_sweep.json');

disp(expansion.run_count)
disp(string({runs.run_id})')
```

Expansion is deterministic. The declared parameter order is preserved and the last Cartesian sweep dimension varies fastest.

## Validation before execution

Validate all expanded configurations before launching solver work:

```matlab
[~, validation] = simcampaigns.validateCampaign( ...
    'configs/campaigns/kwsim/scientific/homogeneous_directional_2d_sweep.json');

disp(validation.summary)
assert(validation.valid)
```

If an expanded configuration is invalid, campaign execution should be corrected before expensive simulations are started.

## Execute and resume

```matlab
report = simcampaigns.runCampaign( ...
    'configs/campaigns/kwsim/scientific/homogeneous_directional_2d_sweep.json', ...
    Resume=true, ...
    ContinueOnError=true);
```

Each run receives a deterministic identifier derived from its expansion order and configuration hash.

With `Resume=true`, completed matching runs are skipped rather than recomputed. Existing directories that cannot be verified as matching completed runs are blocked rather than overwritten automatically.

## Campaign outputs

A campaign output directory has the general structure:

```text
outputs/campaigns/<campaign_name>/
├── campaign_summary.json
├── campaign_runs.csv
├── run_000001_<hash>/
├── run_000002_<hash>/
└── ...
```

Each run directory contains the normal outputs of its backend, such as resolved configuration, simulation result, physical validation report, optional standardized wavefield sample, figures, and manifest.

`campaign_summary.json` records aggregate execution state. `campaign_runs.csv` provides one row per expanded simulation for downstream aggregation.

## Backend neutrality

The campaign layer orchestrates backends; it does not own their physics. Backend-specific configuration validation, simulation execution, physical validation, and output generation remain inside `kwsim` or `swsynth`.

This separation keeps campaigns reproducible while allowing the same campaign machinery to be reused across simulation backends.

## Recommended workflow

```text
1. Verify one single-run base configuration.
2. Define the scientific sweep or explicit run list.
3. Expand the campaign and inspect run count.
4. Validate all expanded configurations.
5. Execute with deterministic output paths.
6. Resume interrupted campaigns rather than duplicating runs.
7. Aggregate campaign-level summaries only after checking run status.
```
