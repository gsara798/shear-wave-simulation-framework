# Documentation

This directory contains both active user documentation and older technical notes retained for provenance.

## Start here

For normal use, read these documents in order:

1. [`../README.md`](../README.md) — repository overview and public API.
2. [`../examples/README.md`](../examples/README.md) — runnable examples and dimensionality conventions.
3. [`kwsim/quickstart.md`](kwsim/quickstart.md) — k-Wave setup and single-run workflow.
4. [`kwsim/configuration_guide.md`](kwsim/configuration_guide.md) — editing k-Wave JSON configurations.
5. [`kwsim/outputs_and_validation.md`](kwsim/outputs_and_validation.md) — standardized outputs and validation.
6. [`kwsim/campaigns.md`](kwsim/campaigns.md) — public campaign workflow.
7. [`swsynth/README.md`](swsynth/README.md) — synthetic backend overview.
8. [`contracts/wavefield_sample_v1.md`](contracts/wavefield_sample_v1.md) — backend-neutral wavefield interchange contract.

## Public execution API

User-facing documentation should use the root-level entry points:

```matlab
setup_simulation_framework(...)
outcome = run_simulation("path/to/config.json");
report = run_campaign("path/to/campaign.json");
```

Package-level functions such as `kwsim.*`, `swsynth.*`, and `simcampaigns.*` are implementation-level APIs unless a document explicitly targets framework developers.

## Active physics documentation

The detailed k-Wave physics guides remain useful references:

- [`kwsim/physics/finite_contact_sources.md`](kwsim/physics/finite_contact_sources.md)
- [`kwsim/physics/multiface_and_angular_sources.md`](kwsim/physics/multiface_and_angular_sources.md)
- [`kwsim/physics/heterogeneous_materials.md`](kwsim/physics/heterogeneous_materials.md)
- [`kwsim/physics/harmonic_analysis_and_ps_separation.md`](kwsim/physics/harmonic_analysis_and_ps_separation.md)

These documents explain physical and numerical implementation details. If an old command example conflicts with the root README or current quick start, the root-level public runners are authoritative.

## Detailed references

`kwsim/simulation_parameters.md` and `kwsim/terminology.md` contain detailed field-level reference material accumulated during development. Their physical definitions remain useful, but older workflow terms or command examples may predate the unified runners. Use the current quick start for execution instructions.

## Historical technical notes

Several older files under `docs/` describe development-era benchmark contracts, validation studies, or architecture plans. They are retained as provenance rather than as the recommended user workflow. Examples include the older directional-homogeneous reliability notes, field-regime benchmark notes, and early synthetic architecture plans.

Historical scripts and retired interfaces are stored under [`../archive/`](../archive/) and are not part of the active public API.

## Documentation rule

The current code and executable examples are authoritative for supported behavior. New public documentation should describe only workflows that can be reproduced through `setup_simulation_framework`, `run_simulation`, or `run_campaign`, and should keep estimator-specific processing outside this repository.
