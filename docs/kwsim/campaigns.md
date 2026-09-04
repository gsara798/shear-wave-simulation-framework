# Reproducible Simulation Campaigns

Campaigns run reproducible groups of simulations through the same framework used for single runs.

The public user interface is:

```matlab
report = run_campaign("path/to/campaign.json");
```

The internal `simcampaigns` package performs expansion, validation, deterministic run identity, execution, resume logic, and campaign summaries. Users normally do not need to call that package directly.

## When to use a campaign

Use a campaign for repeated conditions such as frequency, shear-wave speed, seed, source count, source regime, geometry, or resolution studies. Use `run_simulation` when only one configuration is needed.

## Campaign JSON

A campaign points to one base configuration and defines either a Cartesian `sweep` or explicit `runs`.

Use `sweep` when every cross-combination is scientifically intended. Use explicit `runs` when values belong together as named physical conditions.

Example explicit campaign:

```json
{
  "schema_version": "1.2",
  "backend": "swsynth",
  "campaign_name": "example_field_regimes",
  "base_config": "base_config.json",
  "output": {
    "directory": "outputs"
  },
  "runs": [
    {
      "design_id": "directional_r1",
      "condition_id": "directional",
      "realization_id": 1,
      "overrides": [
        {"path": "directions.count", "value": 1},
        {"path": "seed", "value": 7101}
      ]
    }
  ]
}
```

A complete public example is available at:

```text
examples/swsynth/projected3d/campaign_field_regimes/campaign.json
```

## Validate before execution

Validate every expanded run without executing a solver:

```matlab
report = run_campaign( ...
    "examples/swsynth/projected3d/campaign_field_regimes/campaign.json", ...
    DryRun=true);
```

A successful validation reports that all expanded runs are valid. No simulation output directories are created by the dry run.

## Execute

```matlab
report = run_campaign( ...
    "examples/swsynth/projected3d/campaign_field_regimes/campaign.json");
```

The default public behavior is:

```text
Resume = true
ContinueOnError = true
PlotFigures = true
FigureVisible = "off"
```

Completed matching runs are skipped when `Resume=true`. Existing directories that cannot be verified as the same completed run are blocked instead of being silently overwritten.

## Campaign output

The campaign JSON controls the campaign output root. A typical campaign contains:

```text
<campaign-output>/<campaign_name>/
├── campaign_summary.json
├── campaign_runs.csv
├── <run_id>/
│   ├── config/
│   ├── data/
│   │   ├── wavefield_sample.mat
│   │   └── run_summary.json
│   ├── figures/
│   └── validation/
└── ...
```

`campaign_summary.json` records aggregate state. `campaign_runs.csv` provides one row per expanded run. Each completed run uses the same backend-neutral `wavefield_sample` contract as a single run.

## Terminal interface

```bash
bash scripts/campaign-run path/to/campaign.json
```

Validate only:

```bash
bash scripts/campaign-run path/to/campaign.json --dry-run
```

## Internal API

Advanced developers may use `simcampaigns.expandCampaign`, `simcampaigns.validateCampaign`, and `simcampaigns.runCampaign` directly. These are implementation-level interfaces; user documentation and examples should prefer `run_campaign`.

## Recommended workflow

```text
1. Verify the base configuration with run_simulation(..., DryRun=true).
2. Execute one representative single run.
3. Define the campaign sweep or explicit run list.
4. Validate the whole campaign with run_campaign(..., DryRun=true).
5. Execute with run_campaign(...).
6. Resume interrupted work rather than duplicating completed runs.
7. Check campaign_summary.json before downstream aggregation.
```

For the campaign schema details, see [`../contracts/campaign_configuration_v1.md`](../contracts/campaign_configuration_v1.md) and [`../campaigns/explicit_campaign_api.md`](../campaigns/explicit_campaign_api.md).
