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

## Spherical source radiation

Spherical-wave configurations retain the historical source radiation model
by default:

```json
"sources": {
  "radiation": {
    "model": "constant_directional_polarization",
    "force_direction_xyz": [0, 0, 1]
  }
}
```

`constant_directional_polarization` is backward compatible: each spherical
component receives the same spatially constant polarization coefficient used
before source-radiation configuration was introduced. The force direction is
stored but does not alter this legacy model.

The optional `point_force_shear_far_field` model represents the vector
far-field shear radiation from a point force. For source position
`r_source`, observation position `r_observation`, and unit force direction
`F`, it evaluates the complete three-dimensional geometry

```text
n = (r_observation - r_source) / |r_observation - r_source|
p_shear = (I - n n^T) F
U_observed projection = e_observed^T p_shear
```

Coordinates and vectors use `[x,y,z]`. The existing two-dimensional output is
still the physical `x-z` observation plane, `U_zx(z,x)`, so the current axial
output uses `e_observed = [0,0,1]`. Source positions may have nonzero `y`; the
projection is nevertheless evaluated in full 3D before sampling the plane.

For example, lateral SOURCE-X motion observed axially is configured with:

```json
"propagation": { "model": "spherical_wave" },
"sources": {
  "radiation": {
    "model": "point_force_shear_far_field",
    "force_direction_xyz": [1, 0, 0]
  }
}
```

The point-force projection changes only vector radiation. Random source
radius, amplitude, phase, phase accumulation, and optional geometric spreading
remain independent parts of the spherical synthesizer. In particular, the
projection is applied once and is not multiplied by the legacy polarization.
Point-force radiation is rejected for plane-wave and projected-3D Eikonal
propagation, where the source interpretation is different.

This is the far-field transverse shear radiation factor of an ideal vector
point force. It is not the complete elastodynamic Green tensor and does not
model longitudinal-wave radiation, near-field tensor terms, a finite contact
aperture, reflections, or physical boundaries.

Resolved samples expose `sources.radiation_model`,
`sources.force_direction_xyz`, and `sources.observed_direction_xyz`. Small
validation configurations for SOURCE-X, SOURCE-Z, and nonzero-y source
geometry are under:

```text
configs/swsynth/validation/point_force_shear_radiation/
```
