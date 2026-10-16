# swsynth V2 — heterogeneous media

Five independent physical examples of shear-speed heterogeneity using **plane-wave Eikonal travel times**. All use prescribed shear-wave-speed materials, a 500 Hz harmonic drive, a single incident plane shear wave propagating along +x, and a z-axis observed component. No estimator or downstream reconstruction is involved.

| JSON | Geometry | Material configuration |
| --- | --- | --- |
| `circle_inclusion_projected3d.json` | projected3d | 3 m/s circular inclusion, radius 4 mm, in 2 m/s background |
| `bilayer_projected3d.json` | projected3d | 3 m/s half-space beyond x = 12 mm, background 2 m/s |
| `multiple_inclusions_projected3d.json` | projected3d | 3.2 m/s and 1.4 m/s circular inclusions |
| `s_curve_projected3d.json` | projected3d | 3 m/s curved ribbon, 2 mm thickness |
| `sphere_volumetric3d.json` | volumetric3d | 3 m/s sphere, radius 3 mm, in a 2 m/s cube |

Projected observations cover 24 × 24 mm with 0.3 mm spacing. The volumetric case covers a 12 mm cube at 0.6 mm spacing. The speed values define the **material truth**, not a wave-speed estimate.

## Run

```matlab
setup_simulation_framework
folder="examples/swsynth/v2/04_heterogeneous_media";
run_simulation(fullfile(folder,"circle_inclusion_projected3d.json"),DryRun=true);
out=run_simulation(fullfile(folder,"circle_inclusion_projected3d.json"),PlotFigures=true);
```

Use another filename from the table to select the other scenarios. Output includes `data/wavefield_sample.mat`, the material map, source incidence direction and harmonic-field visualizations.

## Model scope and cautions

- Eikonal changes **phase/travel time** according to the specified local shear speed. It is not a full elastic wave-equation solver.
- The model does **not** generate full reflection, interface mode conversion, diffraction, multiple scattering or amplitude transport. Apparent patterns should not be used as evidence of those mechanisms.
- Point-force spherical propagation through heterogeneous media is not implemented; these examples therefore use incident plane waves.
- The projected3d cases use a spatial x-z material map and an observation plane at y=0; the volumetric case calculates a full 3D field.
- The bilayer boundary is a plane normal to x; the `normal_angle_rad=0` definition is intentional.

Check `sws.png` for the material map and `wavefield_phase.png` for the phase geometry. Quantitative validation of Eikonal travel-time errors or interface behavior should be performed separately from simple schema checks.
