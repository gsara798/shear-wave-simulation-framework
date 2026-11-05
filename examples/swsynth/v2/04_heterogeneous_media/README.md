# swsynth V2 — heterogeneous media

Seven examples of shear-speed heterogeneity: five existing **plane-wave Eikonal** controls and two new **elastic point-source Eikonal** demonstrations. All prescribe the shear-wave-speed map rather than estimating it. The original plane-wave cases use 500 Hz and +x incidence; the new point-source cases use two coherent explicit sources at 500 Hz and z-axis readout. No estimator or downstream reconstruction is involved.

| JSON | Geometry | Material configuration |
| --- | --- | --- |
| `circle_inclusion_projected3d.json` | projected3d | 3 m/s circular inclusion, radius 4 mm, in 2 m/s background |
| `bilayer_projected3d.json` | projected3d | 3 m/s half-space beyond x = 12 mm, background 2 m/s |
| `multiple_inclusions_projected3d.json` | projected3d | 3.2 m/s and 1.4 m/s circular inclusions |
| `s_curve_projected3d.json` | projected3d | 3 m/s curved ribbon, 2 mm thickness |
| `sphere_volumetric3d.json` | volumetric3d | 3 m/s sphere, radius 3 mm, in a 2 m/s cube |
| `point_source_elastic_bilayer_projected3d.json` | projected3d | Two opposed coherent sources outside a 2/3 m/s x-normal bilayer |
| `point_source_elastic_inclusion_projected3d.json` | projected3d | Two external, off-plane coherent sources; 3 m/s circle in 2 m/s background |

Original plane-wave projected observations cover 24 × 24 mm with 0.3 mm spacing. Updated point-source examples use **24 × 24 mm** with **0.2 mm** observation sampling, an independent **0.5 mm** Eikonal calculation grid, and a 250,000-cell safety limit for the extended 3D solve. The bilayer interface is at x = 12 mm; the inclusion has **10 mm diameter** centered at (12, 12) mm. Both sources are outside the observed x-domain (x = -6 and 30 mm); the inclusion example also places them at y = -3 and +3 mm. The volumetric case covers a 12 mm cube at 0.6 mm spacing. The speed values define the **material truth**, not a wave-speed estimate.

## Run

```matlab
setup_simulation_framework
folder="examples/swsynth/v2/04_heterogeneous_media";
run_simulation(fullfile(folder,"circle_inclusion_projected3d.json"),DryRun=true);
out=run_simulation(fullfile(folder,"circle_inclusion_projected3d.json"),PlotFigures=true);
```

For the new **lossless point-source** examples:

```matlab
setup_simulation_framework
folder="examples/swsynth/v2/04_heterogeneous_media";
file=fullfile(folder,"point_source_elastic_bilayer_projected3d.json");
run_simulation(file,DryRun=true); % validates before propagation
out=run_simulation(file,PlotFigures=true,Parallel=false);
```

Change `file` to `point_source_elastic_inclusion_projected3d.json` for
the off-plane case. **These updated examples will be slower and use more RAM** than the 12-mm / 1-mm-grid prototypes. First run one example serially to measure execution time, then run the second. A `DryRun` validates the configuration but does not establish time/memory feasibility or Eikonal convergence. Do not extrapolate their runtimes to 20-source RSWE without a separate benchmark.

Use another filename from the table to select the other scenarios. Output includes `data/wavefield_sample.mat`, the material map, source incidence direction and harmonic-field visualizations.

## Model scope and cautions

- Eikonal changes **phase/travel time** according to the specified local shear speed. It is not a full elastic wave-equation solver.
- The model does **not** generate full reflection, interface mode conversion, diffraction, multiple scattering or amplitude transport. Apparent patterns should not be used as evidence of those mechanisms.
- **Elastic point-source Eikonal is now implemented only for projected3d.**
  It computes first-arrival travel times in a 3D extended computational
  volume, while the prescribed material speed map is 2D and **assumed
  invariant along y**. Outside the observed x-z FOV, speed uses
  nearest-edge constant extrapolation; a single sharp planar bilayer can
  instead use its explicit plane geometry. This exterior is a modeling
  assumption, not a physical boundary.
- Amplitude still uses point-force far-field radiation based on the
  straight source-to-receiver vector and simple geometric spreading;
  **polarization bending, interface transmission amplitude, caustics,
  diffraction, reflections and mode conversion are not modeled**.
- Lossless elastic Eikonal requires **neither** `medium.viscoelastic`
  **nor** `propagation.attenuation`. The existing viscoelastic
  attenuation-on path remains separate and unchanged.
- A source may lie outside the FOV and/or off the observation plane.
  The internal on-plane branch keeps its existing two-dimensional Eikonal
  calculation. External and off-plane sources use the extended 3D solver.
- The full 120-arrangement RSWE campaign may require substantial Eikonal
  time and memory per source. `solver_options.GridSpacingM` and
  `MaxGridCells` are explicit and require convergence/resolution checks.
  These examples do not establish physical RSWE validity.
- The projected3d cases use a spatial x-z material map and an observation plane at y=0; the volumetric case calculates a full 3D field.
- The bilayer boundary is a plane normal to x; the `normal_angle_rad=0` definition is intentional.

Check `sws.png` for the material map and `wavefield_phase.png` for the phase geometry. Quantitative validation of Eikonal travel-time errors or interface behavior should be performed separately from simple schema checks.

## Resolution/convergence check

The 0.2 mm observation spacing is **not** the same as the 0.5 mm
Eikonal-grid spacing. Visual smoothness alone does not establish
convergence. For a controlled comparison, copy one example to a **new**
JSON file, change only `propagation.solver_options.GridSpacingM` to
`0.00075` (and keep the observation domain, sources and material identical),
then compare the resulting complex phase fields away from amplitude nodes.
This is a **coarser comparison**, not proof of convergence; a finer grid
and quantitative travel-time/phase differences are needed before using
these examples to calibrate a training campaign.
