# swsynth V2 — parameter studies

This family illustrates reproducible, single-variable studies of synthetic harmonic shear-wave fields. It is independent of any reconstruction or estimation algorithm.

The base simulation is `plane_wave_base.json`: 16 plane-wave directions on a deterministic Fibonacci sphere, no forced in-plane directions, random transverse polarizations and seeded uniform random phases. The observation is the z component in a homogeneous 24 × 24 mm x-z plane. The grid spacing is 0.4 mm, and the baseline is f=500 Hz, cs=2 m/s. The background contains no objects; propagation uses homogeneous analytical phase.

The campaign JSON files live under `examples/swsynth/v2/06_parameter_studies/`:

| Campaign | Swept variable | Values | What to inspect |
| --- | --- | --- | --- |
| `frequency_sweep.json` | `harmonic.frequency_hz` | 300, 400, 500, 600, 700 Hz | Wavelength and spatial oscillation density |
| `material_speed_sweep.json` | `medium.cs_m_s` | 1.5, 2, 2.5, 3 m/s | Wavelength under fixed frequency |
| `incident_wave_count_sweep.json` | `incidence.sampling.count` | 4, 8, 16, 32, 64 waves | Angular sampling and interference |
| `random_realizations.json` | `seed` | 53053–53057 | Different phases and transverse polarizations |

**Interpretation:** for the first three sweeps, the same seed gives reproducible random draws but varying the number of incident waves also changes the sequence length and directional sampling. A finite collection of waves is not necessarily statistically diffuse. These are examples of simulation campaigns, not physical validation benchmarks.

## Run

```matlab
setup_simulation_framework
file="examples/swsynth/v2/06_parameter_studies/frequency_sweep.json";
dry=run_campaign(file,DryRun=true);
report=run_campaign(file,ParallelLevel="campaign",NumWorkers=4,PlotFigures=true);
```

Choose another campaign filename from the table for a different study. `ParallelLevel="campaign"` uses process workers so MAT V7.3 output can be saved. Alternatively, omit that option to run the campaign sequentially. These base simulations do not request per-source `parfor`, so campaign-level parallelism is not nested.

Campaign outputs are placed under the campaign directory and identified by run hashes. Repeating the same campaign with `Resume=true` skips previously completed runs. To rerun from scratch, use a new campaign name/output directory rather than deleting results unintentionally.

## Angular aperture: plane waves versus physical spherical sources

Two campaigns sweep an angular **half-aperture** while maintaining **64 contributions, exactly 8 in-plane** (12.5%) and 56 off-plane. The angular distributions use deterministic Fibonacci-like spherical-cap sampling with an explicit planar quota; this is not a perfectly uniform Fibonacci sphere because the exact quota introduces a planar component.

| Campaign | Quantity controlled | Base configuration |
| --- | --- | --- |
| `angular_aperture_plane_waves.json` | Incident plane-wave **propagation directions** | `angular_aperture_plane_waves_base.json` |
| `angular_aperture_spherical_sources.json` | Physical **point-source positions** on a sphere surrounding the observation region | `angular_aperture_spherical_sources_base.json` |

Both sweep half-angles **15°, 30°, 45°, 60°, 90°, 120°, 180°** around the **+x axis**. A half-angle of 180° spans the full sphere. The observation is the x-z plane (y=0), with z-component measurement. The 8 in-plane entries are exactly at y=0. In the source case, the source-placement sphere is centered at (12,0,12) mm and has radius 40 mm, keeping the physical sources outside the observation domain. Sources are excited with reproducible random force directions, phases and amplitude jitter; incident plane waves use random transverse polarizations and phases.

**Important physical distinction:** a spherical point source emits into many observation directions and has a spatially varying radiation pattern. An angular aperture of *source positions* cannot be identified with an aperture of a single *plane-wave propagation direction*. The two sweeps are analogous geometrically but do **not** produce identical fields. They are separate numerical studies.

```matlab
setup_simulation_framework
folder="configs/campaigns/swsynth/parameter_studies";
run_campaign(fullfile(folder,"angular_aperture_plane_waves.json"),DryRun=true);
run_campaign(fullfile(folder,"angular_aperture_spherical_sources.json"),DryRun=true);

plane=run_campaign(fullfile(folder,"angular_aperture_plane_waves.json"), ...
    ParallelLevel="campaign",NumWorkers=4,PlotFigures=true);
spherical=run_campaign(fullfile(folder,"angular_aperture_spherical_sources.json"), ...
    ParallelLevel="campaign",NumWorkers=4,PlotFigures=true);
```

Campaign-level parallelism distributes the **seven simulations** over process workers; each simulation's 64 contributions execute sequentially. This avoids nested parallelism and is appropriate for comparing many independent conditions.
