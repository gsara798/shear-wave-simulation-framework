# k-Wave User Guide

This directory documents the active k-Wave backend and the public workflow exposed by the framework.

The recommended reading order is:

```text
1. Quick Start
2. Configuration Guide
3. Outputs and Validation
4. Campaigns
5. Physics Guides
6. Detailed parameter and terminology references
```

## Public workflow

Configure the MATLAB session once:

```matlab
setup_simulation_framework( ...
    KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")
```

Run one configuration:

```matlab
outcome = run_simulation("path/to/config.json");
```

Validate without executing:

```matlab
outcome = run_simulation("path/to/config.json", DryRun=true);
```

Run a campaign:

```matlab
report = run_campaign("path/to/campaign.json");
```

These root-level entry points are the recommended user API. Package functions under `kwsim.*` and `simcampaigns.*` are implementation-level interfaces for advanced development.

## Guides

- [Quick Start](quickstart.md) — setup, dry runs, single-run execution, figures, and terminal usage.
- [Configuration Guide](configuration_guide.md) — how to modify k-Wave JSON configurations safely.
- [Outputs and Validation](outputs_and_validation.md) — standardized output layout, validation artifacts, and `wavefield_sample`.
- [Campaigns](campaigns.md) — repeated simulations, explicit runs, sweeps, validation, and resume behavior.
- [Simulation Parameters](simulation_parameters.md) — detailed field-level parameter reference.
- [Terminology](terminology.md) — numerical and physical terminology.

## Physics guides

- [Finite-Contact Sources](physics/finite_contact_sources.md)
- [Multiface and Angular Sources](physics/multiface_and_angular_sources.md)
- [Heterogeneous Materials](physics/heterogeneous_materials.md)
- [Harmonic Analysis and P/S Separation](physics/harmonic_analysis_and_ps_separation.md)

These documents explain physical interpretation and implementation details. Execution examples in older detailed physics notes should be interpreted in the context of the current public runners above.

## Public examples

The simplest starting points are under:

```text
examples/kwave/2d/
examples/kwave/3d/
```

with homogeneous, inclusion, and bilayer cases in each dimensionality.

## Public array orientation

```text
2D: [Nz, Nx]     suffix _zx
3D: [Nz, Ny, Nx] suffix _zyx
```

The k-Wave solver's internal orientation is handled inside the adapter layer. The exported 3D `wavefield_sample` contains the full sensor volume rather than a central 2D slice.

## Scope

The framework owns simulation configuration, execution, harmonic extraction, validation, standardized visualization, campaign orchestration, and backend-neutral wavefield export. Estimator-specific analysis is intentionally outside this repository.

## Validation rule

Solver completion is not equivalent to scientific validity. Before using a simulation result, inspect the validation artifacts, resolved configuration, truth maps, and standard figures.
