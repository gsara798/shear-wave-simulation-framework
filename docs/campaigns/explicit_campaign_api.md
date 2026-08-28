# Explicit Campaign Construction API

The simulation framework separates scientific study design from generic campaign
execution.

## Campaign lifecycle

A typical explicit-run workflow is:

```text
scientific run plan
        ↓
simcampaigns.makeExplicitRuns
        ↓
schema 1.2 explicit run definitions
        ↓
simcampaigns.writeCampaign
        ↓
simulation_campaign.json
        ↓
simcampaigns.expandCampaign
        ↓
simcampaigns.validateCampaign
        ↓
simcampaigns.runCampaign
```

## Responsibility boundaries

The calling project is responsible for scientific design decisions such as:

- which physical conditions to simulate;
- parameter combinations;
- realization counts;
- random-seed policy;
- pairing or blocking between conditions;
- study-specific provenance.

The simulation framework is responsible for:

- converting tabular plans to explicit-run definitions;
- campaign serialization;
- campaign schema validation;
- configuration-path validation;
- deterministic expansion;
- dry-run validation;
- execution;
- resume behavior;
- run identity and completion tracking.

The generic campaign API contains no project-specific assumptions.

## makeExplicitRuns

`simcampaigns.makeExplicitRuns` converts one table row per planned simulation
into schema-1.2 explicit run definitions.

The override map is an N-by-2 string array:

```matlab
mapping = [
    "seed"                    "random_seed"
    "wavefield.frequency_hz"  "frequency_hz"
];
```

The first column contains simulation configuration paths.
The second column contains source table columns.

Example:

```matlab
plan = table( ...
    ["run_a";"run_b"], ...
    [101;102], ...
    [300;500], ...
    VariableNames=["design_id","random_seed","frequency_hz"]);

definitions = simcampaigns.makeExplicitRuns( ...
    plan,mapping);
```

Optional provenance can be preserved using:

```matlab
definitions = simcampaigns.makeExplicitRuns( ...
    plan,mapping, ...
    DesignIdColumn="design_id", ...
    ConditionIdColumn="condition_id", ...
    RealizationIdColumn="realization_id");
```

`makeExplicitRuns` deliberately does not validate simulator configuration
paths. This keeps the function backend-neutral. Configuration paths are
validated later by the canonical campaign loader against the selected base
configuration.

## writeCampaign

`simcampaigns.writeCampaign` atomically writes a campaign struct and validates
it using `simcampaigns.loadCampaignJson` before publication.

Example:

```matlab
campaign = struct();
campaign.schema_version = "1.2";
campaign.backend = "swsynth";
campaign.campaign_name = "example_campaign";
campaign.base_config = "path/to/base_config.json";
campaign.runs = definitions;
campaign.output = struct("directory","outputs/example_campaign");

simcampaigns.writeCampaign( ...
    campaign, ...
    "campaigns/example_campaign.json");
```

The same construction API supports any backend accepted by the campaign
contract, including `swsynth` and `kwsim`.

## Validation and execution

Before execution:

```matlab
[runs,validation] = ...
    simcampaigns.validateCampaign("campaigns/example_campaign.json");

assert(validation.valid);
```

Run the campaign with:

```matlab
report = simcampaigns.runCampaign( ...
    "campaigns/example_campaign.json", ...
    Resume=true, ...
    ContinueOnError=false);
```

`runCampaign` performs validation before execution and records campaign state,
run identity, completion markers, and resume information.
