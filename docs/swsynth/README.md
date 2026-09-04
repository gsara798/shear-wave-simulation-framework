# Synthetic Wavefield Simulations

The `swsynth` backend provides fast synthetic harmonic shear-wave fields without running the k-Wave time-domain solver.

It currently supports:

- 2D analytical plane-wave fields;
- projected-3D observations `U(z,x)` with 3D directions and polarization;
- true volumetric 3D fields `U(z,y,x)`;
- homogeneous media;
- heterogeneous Eikonal propagation;
- inclusions and bilayers;
- explicit or generated propagation directions;
- deterministic seeds and campaign execution.

## Public interface

Use the same public runner as every other backend:

```matlab
outcome = run_simulation( ...
    "examples/swsynth/volumetric3d/inclusion/config.json");
```

Validate only:

```matlab
outcome = run_simulation( ...
    "examples/swsynth/volumetric3d/inclusion/config.json", ...
    DryRun=true);
```

For campaigns:

```matlab
report = run_campaign( ...
    "examples/swsynth/projected3d/campaign_field_regimes/campaign.json", ...
    DryRun=true);

report = run_campaign( ...
    "examples/swsynth/projected3d/campaign_field_regimes/campaign.json");
```

Users normally do not need to call `swsynth.*` or `simcampaigns.*` directly.

## Example organization

```text
examples/swsynth/
├── 2d/
│   └── homogeneous/
├── projected3d/
│   ├── inclusion/
│   ├── bilayer/
│   └── campaign_field_regimes/
└── volumetric3d/
    ├── homogeneous/
    ├── inclusion/
    └── bilayer/
```

`projected3d` means that the propagation directions and polarization live in three dimensions while the observed wavefield is a 2D `x-z` plane. `volumetric3d` produces a true 3D `z-y-x` volume.

## Standard output

Synthetic runs use the same public layout as k-Wave:

```text
<config-folder>/outputs/<scenario>_<timestamp>/
├── config/
├── data/
│   ├── wavefield_sample.mat
│   └── run_summary.json
├── figures/
└── validation/
```

## Wavefield contract

Synthetic and k-Wave runs export the same backend-neutral `wavefield_sample` contract. See [Wavefield Sample Contract](../contracts/wavefield_sample_v1.md).

## Field-regime example

The public projected-3D campaign uses example direction counts of 1, 16, and 128 to create increasingly complex angular fields labeled directional, intermediate, and diffuse. These counts are example settings, not universal thresholds defining physical diffusivity.
