# swsynth V2 — advanced volumetric 3D

These independent examples exercise **three-dimensional vector shear-wave fields**, physical point-force sources, and prescribed 3D material variations. They use the existing swsynth V2 models and have no dependency on any downstream estimation method.

| Configuration | Propagation model | Purpose |
| --- | --- | --- |
| `two_coherent_point_sources.json` | Homogeneous analytical spherical waves | Two external coherent force sources, observed throughout a volume |
| `eight_random_point_sources.json` | Homogeneous analytical spherical waves | Eight external point forces with seeded random directions, amplitudes and phases; parallel contributions |
| `diffuse_plane_waves_3d.json` | Homogeneous analytical plane waves | 24 Fibonacci-distributed 3D directions with seeded random phases and transverse polarizations |
| `sphere_multi_incidence_eikonal.json` | Plane-wave Eikonal | Three incident directions through a faster spherical region |
| `two_spheres_eikonal.json` | Plane-wave Eikonal | Faster and slower spherical regions in the same 3D volume |

All volumes span 12 mm along x, y and z. The point-force cases use 0.4 mm spacing; the Eikonal cases use 0.6 mm spacing. The background shear-wave speed is 2 m/s, frequency is 500 Hz, and the measured component is z. The full vector field is synthesized; the z readout is an observation projection.

## Run

```matlab
setup_simulation_framework
file="examples/swsynth/v2/05_advanced_volumetric3d/eight_random_point_sources.json";
run_simulation(file,DryRun=true);
out=run_simulation(file,PlotFigures=true);
```

The eight-source example sets `execution.parallel=true` with four workers; other cases run sequentially by default. The random seed ensures reproducible source excitations. The saved `wavefield_sample.mat` contains the volumetric field; standard 2D visualizations show representative slices.

## Physical limits

The spherical point-force model uses far-field transverse shear radiation and homogeneous analytical travel times, with a configurable geometric spreading exponent. It does **not** implement scattering, heterogeneous point-source Eikonal propagation, near-field elastodynamics or interfaces.

Heterogeneous material examples use plane-wave Eikonal travel times rather than solving full elastodynamic boundary/interface physics. Consequently, they do **not** model reflected waves, full mode conversion, diffraction or multiple scattering.

The ideal diffuse 3D field is approached only approximately with a finite number of incident plane waves. The explicit number of waves and random phases do not by themselves establish isotropic observed energy.
