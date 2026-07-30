# Synthetic wavefield simulations

The `swsynth` backend provides lightweight synthetic shear-wave field
generation without running the k-Wave numerical solver.

Its current primary use is projected-3D harmonic shear-wave synthesis for:

- controlled homogeneous wavefields;
- heterogeneous phase-only Eikonal propagation;
- explicit and sampled propagation directions;
- reproducible REQ and REQ-ML simulation campaigns.

## Main interfaces

Run a resolved synthetic configuration with:

```matlab
swsynth.cli.runConfig(config_file)
```

Backend-neutral campaigns should be loaded, expanded, validated, and executed
through the `simcampaigns` package.

## Relevant documentation

- [Synthetic simulation architecture](../contracts/synthetic_simulation_architecture_plan.md)
- [Wavefield sample contract](../contracts/wavefield_sample_v1.md)
- [Campaign configuration v1.1](../contracts/simulation_campaign_configuration_v1_1.md)
- [Projected-3D clean campaign](../campaigns/homogeneous_projected3d_clean_v1.md)

Synthetic configuration files are stored under:

```text
configs/swsynth/
```

Synthetic campaigns are stored under:

```text
configs/campaigns/swsynth/
```
