# swsynth V2 — physical point sources

These examples use **physical force sources** (`sources.positions` and `sources.excitation`), not the plane-wave incidence model. The propagation model is `spherical_wave`, homogeneous analytical travel time and a shear far-field radiation approximation. All field amplitudes are **relative**, not meters of calibrated displacement; no attenuation, scattering, boundary reflections or ultrasound readout noise are modeled.

| Example | What changes |
| --- | --- |
| `single_point_projected3d.json` | One off-plane z-directed force; 2D x-z observation |
| `single_point_projected3d_force_x.json` | Same source position with x-directed force and x-axis observation |
| `two_coherent_points_projected3d.json` | Two sources, equal phase and amplitude |
| `two_out_of_phase_points_projected3d.json` | Same sources with relative phase pi |
| `two_force_orientations_projected3d.json` | Same source positions; z and y force directions |
| `random_excitation_points_projected3d.json` | Eight specified source positions; independently random force orientations, amplitudes and phases, fixed seed |
| `coherent_line_aperture_projected3d.json` | One parent source expanded into seven coherent, uniformly weighted line elements |
| `single_point_volumetric3d.json` | One physical force source, full 3D volume rather than a 2D observation plane |

Most projected examples use a 24×24 mm x-z observation domain, 0.3 mm spacing; the volumetric case uses a 12 mm cube, 0.4 mm spacing. Material shear speed is 2 m/s and the harmonic frequency is 500 Hz (wavelength 4 mm).

**Source positioning:** the source coordinates are physical 3D positions in meters, distinct from the x-z observation plane. Sources need not lie inside the observed FOV. This is not a planar point-source model.

**Geometric decay:** these examples set `geometric_decay_exponent: 1` for the spherical wave contribution. This is geometric spreading, *not* dissipative shear-wave attenuation. In the coherent line example, node weights are normalized within the parent source. Fixed `relative_amplitude=1` is not a 1-meter displacement.

## Run

```matlab
setup_simulation_framework
folder="examples/swsynth/v2/02_point_sources";
file=fullfile(folder,"single_point_projected3d.json");
run_simulation(file,DryRun=true);
out=run_simulation(file,PlotFigures=true);
```

Change the filename to run another case. To isolate the effect of force and observation orientation, compare `single_point_projected3d.json` (z-force, z-readout) with `single_point_projected3d_force_x.json` (x-force, x-readout). Since both change together, this is not a controlled test of force orientation alone; for that, hold the measurement axis fixed. Standard figures include complex amplitude, phase, real and imaginary phasor components, and four real-time snapshots. The full run exports `data/wavefield_sample.mat`.

## Interpreting the results

- The z-projected radiation pattern depends on force orientation **and** observation direction. An amplitude minimum need not mean attenuation.
- Equal source phases are **source** phases; propagation introduces position-dependent delays.
- The two-source phase comparison isolates a 0 versus pi relative drive phase, but does not imply that the resulting spatial fields simply differ by a global phase.
- For the stochastic case, `seed: 53053` makes the results reproducible. The `random_normal` amplitude policy samples around 1 with relative jitter and truncates negative magnitudes at zero; amplitudes above 1 are expected.
- The line aperture is a collection of coherent *point-force elements*, not a fully modeled finite-contact elastodynamic boundary condition.
- The `volumetric3d` case exports the full volume; standard 2D image figures display the central x-z slice.

A 3D spherical source should not be interpreted as a uniform circular wave in the measurement plane: projection of vector shear radiation matters. Heterogeneous spherical Eikonal propagation is not implemented (issue #31).
