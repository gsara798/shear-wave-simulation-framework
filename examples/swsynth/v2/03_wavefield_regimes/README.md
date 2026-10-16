# V2 wavefield regimes: directional → diffuse

These examples generate *plane-wave incidence*, not finite-distance physical actuator positions. For these fields, `sampling.count` means the number of **incident plane waves**. It is not `sources.count`, which is reserved for physical point-force sources.

## Direction sampling

```json
"sampling": {
  "count": 64,
  "count_in_plane": 8,
  "method": "fibonacci",
  "support": "full_sphere"
}
```

For projected/volumetric 3D, `fibonacci` gives a deterministic near-uniform spherical direction set. Exactly `count_in_plane` directions lie on the x-z great circle; the remaining directions are sampled outside that plane. This is a **mixture with an exact planar quota**, not a single perfectly uniform spherical Fibonacci grid. It can intentionally create anisotropy or a planar component. Set `count_in_plane: 0` for a purely off-plane spherical set.

For 2D, use `method: "uniform_circle"`, `count_in_plane=count`, and `support: "full_circle"` or `"cone"`. In 3D, `support: "cone"` uses a spherical cap around the +x axis; give `cone_half_angle_deg` (0–180). For the 2D cone, directions are evenly sampled over the indicated sector. In-plane quota directions in a 3D cone are distributed over the corresponding x-z arc.

| JSON | Incident waves | In-plane waves | Support |
| --- | ---: | ---: | --- |
| `directional_2d.json` | 1 | 1 | single direction near +x |
| `counterpropagating_2d.json` | 2 | 2 | opposite ±x |
| `limited_aperture_2d.json` | 16 | 16 | 35° half-angle cone |
| `diffuse_2d.json` | 32 | 32 | entire 2D circle |
| `limited_aperture_projected3d.json` | 32 | 8 | 45° half-angle spherical cap |
| `diffuse_projected3d.json` | 64 | 8 | full sphere, observed at y=0 |
| `diffuse_volumetric3d.json` | 48 | 8 | full 3D sphere and volume |

Multiwave examples use `incidence.phase_policy: "random_uniform"` and `seed: 53053`. The framework automatically samples one phase per incident wave uniformly in [0, 2π). Repeating a run with the same seed reproduces exactly the same phases; changing the seed gives a different realization. A local random stream leaves MATLAB's global RNG untouched, even during DryRun. For prescribed phases instead, omit `phase_policy` and supply `phase_rad`. A finite number of waves with quasi-uniform directions is only an approximation to an ideal statistical diffuse field; the planar quota adds intended anisotropy.

Polarization: 2D examples use `in_plane_sv`, while the three projected/volumetric 3D multiwave examples use `transverse_random`. The latter samples a random transverse polarization for each incident wave; the run seed ensures repeatable realizations. The observed field remains projected onto z for the projected 3D cases.

All examples: f=500 Hz, cs=2 m/s (λ=4 mm), homogeneous analytical phase, z projection, no attenuation. Projected 2D fields cover 24 × 24 mm at 0.3 mm spacing; the full volume spans 12 × 12 × 12 mm at 0.4 mm spacing.

## Run

```matlab
setup_simulation_framework
folder="examples/swsynth/v2/03_wavefield_regimes";
run_simulation(fullfile(folder,"diffuse_projected3d.json"),DryRun=true);
out=run_simulation(fullfile(folder,"diffuse_projected3d.json"),PlotFigures=true);
```

Inspect `directions.png`, amplitude, phase and snapshots. The `sws.png` plot is material ground truth, not an estimate from REQ. To verify spectral angular coverage for REQ-ML, use the saved complex `wavefield_sample.mat` and its FFT; the number of configured incident directions alone does not establish diffuse **observed** energy.
