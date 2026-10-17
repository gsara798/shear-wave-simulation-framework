# swsynth V2 — shear attenuation, stage 1

This folder compares homogeneous elastic and Kelvin–Voigt shear propagation. This initial stage is opt-in and independent of mechanical noise and ultrasound observation noise.

## Physics

The constitutive law is defined in `+swsynth/+medium/+viscoelastic/dispersion.m`:

- Elastic: `G*=mu`
- Kelvin–Voigt: `G*=mu+i*omega*eta`
- The real phase wavenumber and positive attenuation coefficient are obtained consistently from the same complex modulus, density and frequency. The existing spatial phasor convention is `exp(+i*k*r)`.

The plane-wave contribution uses phase speed from the constitutive law and multiplies the amplitude by `exp(-alpha*d)`. Here `d` is distance from the first wavefront intersecting the field of view, projected along propagation direction. This is a finite-FOV convention, not an absolute physical source location.

The spherical point-force contribution uses `exp(-alpha*r)`, where `r` is distance to each aperture node, in addition to the already-existing `geometric_decay_exponent` spreading factor. The current geometric spreading exponent preserves existing legacy behavior; the standalone `+propagation/+spreading/factor.m` function provides a regularized reference-distance implementation for future explicit normalization, but has **not** replaced the existing spherical calculation.

The initial homogeneous stage supports analytical propagation; the heterogeneous projected-Eikonal extension is documented below. Neither mode implements interface transmission, multiple scattering, shear-to-compressional mode conversion or ultrasound noise.

## Config

```json
"propagation": {
  "model": "plane_wave",
  "phase_method": "analytical",
  "normalization": "none",
  "attenuation": {
    "enabled": true,
    "constitutive": {
      "model": "kelvin_voigt",
      "density_kg_m3": 1000,
      "mu_pa": 4000,
      "eta_pa_s": 0.25
    }
  }
}
```

Material reference speed in the existing `medium.cs_m_s` field remains required for compatibility; when attenuation is enabled, phase speed for the homogeneous analytical calculation comes from the constitutive parameters instead. Recorded phase-wavenumber truth reflects this constitutive law.

## Run

```matlab
setup_simulation_framework
runtests('tests/unit/test_swsynth_viscoelastic_attenuation_v2.m')
elastic=run_simulation("examples/swsynth/v2/08_shear_attenuation/plane_elastic_reference.json",PlotFigures=true);
kv=run_simulation("examples/swsynth/v2/08_shear_attenuation/plane_kelvin_voigt.json",PlotFigures=true);
```

The next planned stages are extending local attenuation to oblique/volumetric rays, followed by separate empirical-shadow and impedance-transmission approximations for interfaces. Reflections are **not** implemented by an amplitude-only transmission approximation.

## Stage 2 — Heterogeneous intrinsic loss (projected x-z Eikonal)

New examples in this same directory:
- `bilayer_kelvin_voigt_projected3d.json` — straight interface separating two Kelvin–Voigt materials.
- `inclusion_kelvin_voigt_projected3d.json` — circular inclusion, with local phase speed and attenuation.

Use `medium.viscoelastic` for the background and `medium.objects[i].viscoelastic` for each inclusion. Each constitutive specification provides `model` (`elastic` or `kelvin_voigt`), `density_kg_m3`, `mu_pa`, and Kelvin–Voigt `eta_pa_s`. For this heterogeneous mode use `propagation.phase_method="eikonal"` and `propagation.attenuation={"enabled":true}` (without a global `constitutive` field).

At each frequency the code constructs spatial phase-speed and attenuation maps from local constitutive parameters, solves Eikonal with the **phase speed**, backtraces the in-plane phase-gradient characteristic for each pixel, and multiplies each individual plane-wave contribution by `exp(-integral(alpha ds))` **before coherent accumulation**. The baseline speed maps in `medium.cs_m_s` and object `cs_m_s` remain required for legacy configuration compatibility but are not the physical phase-speed maps of the Kelvin–Voigt run.

**Current limitations:** only `projected3d`, plane waves with **direction_y=0**, and sharp overlay boundaries are supported for heterogeneous intrinsic loss. The ray approximation computes direct-phase amplitude loss, **not** reflection/transmission coefficients, ray-tube focusing, mode conversion, multiple scattering or full-wave behavior. It uses a numerical backtracking step of half the grid spacing and stops at the computation domain boundary. This is not yet an experimentally validated attenuation model.

```matlab
setup_simulation_framework
results=runtests('tests/unit/test_swsynth_heterogeneous_attenuation_v2.m');
assertSuccess(results)
b=run_simulation("examples/swsynth/v2/08_shear_attenuation/bilayer_kelvin_voigt_projected3d.json",PlotFigures=true);
i=run_simulation("examples/swsynth/v2/08_shear_attenuation/inclusion_kelvin_voigt_projected3d.json",PlotFigures=true);
```

## Stage 2b — Internal physical point source in a heterogeneous medium

`point_source_bilayer_kelvin_voigt_projected3d.json` uses a physical point force at (6, 0, 12) mm, **inside** the 24 × 24 mm x-z computational FOV. The point source is on the measurement plane. Each local Kelvin–Voigt constituent provides phase speed and attenuation. A first-arrival Eikonal field is initialized at the source's closest grid node; phase-gradient ray backtracking accumulates intrinsic attenuation towards a finite source neighborhood.

```matlab
setup_simulation_framework
results=runtests('tests/unit/test_swsynth_point_source_heterogeneous_attenuation_v2.m');
assertSuccess(results)
out=run_simulation("examples/swsynth/v2/08_shear_attenuation/point_source_bilayer_kelvin_voigt_projected3d.json",PlotFigures=true);
```

**Scope:** first-arrival 2D ray approximation only, for physical point sources inside the FOV and at y=0. Off-plane or external sources, coherent multi-node apertures and volumetric3d source Eikonal are not supported yet. The exact mathematical source singularity is not resolved: the Eikonal source is discretized to the nearest grid node and the loss integral stops in a neighborhood of radius ~1.5 grid diagonals. This introduces discretization errors near the source. In the internal-source Eikonal branch, cells within this unresolved near-source radius are explicitly set to zero in the synthesized far-field shear contribution; zero here means **masked/unresolved**, not a physical prediction of zero displacement. The global wavefield sample currently does not include a separate near-source validity mask, so analyses must exclude these cells explicitly. The example sets `geometric_decay_exponent=0` to isolate intrinsic attenuation; enabling the legacy `r^-1` factor is an empirical homogeneous spreading approximation, **not** a heterogeneous ray-tube transport calculation. No reflected wavefield, refracted-mode conversion, or interface transmission coefficients are synthesized.

## Stage 2c — External and out-of-plane point sources

Two more examples in this existing set:

- `point_source_external_bilayer_kelvin_voigt_projected3d.json`: source (-6,0,12) mm, outside the observed 24 mm square
- `point_source_offplane_bilayer_kelvin_voigt_projected3d.json`: source (-5,8,12) mm, external and 8 mm away from the x-z observation plane

Both examples use `propagation.phase_method="eikonal"`, `propagation.attenuation.enabled=true`, and explicit numerical options `GridSpacingM=0.0012` and `MaxGridCells=200000` to limit the expense of the **3D** Eikonal solver.

The internal on-plane source path remains unchanged. External or out-of-plane sources instead use a 3D computational domain including both the source and the observed x-z region; the solver computes first-arrival times and integrates local intrinsic attenuation along 3D phase-gradient paths, then resamples on the observation plane. The assumed mechanical property maps are **constant in y**, with values outside the observed x-z rectangle equal to the **nearest boundary material**. This extrapolation is explicit but not a measured material description; source-to-FOV travel times and attenuation depend on this assumption.

The local 3D Eikonal model does not calculate reflected waves, mode conversion, diffraction, coherent multipathing or ray-tube geometrical focusing. `geometric_decay_exponent=1` retains the existing straight-line `1/r` amplitude model as an approximation. These numerical results require validation in MATLAB; a denser extended grid improves resolution but substantially increases computation.

```matlab
setup_simulation_framework
results=runtests('tests/unit/test_swsynth_external_offplane_source_v2.m');
assertSuccess(results)
ext=run_simulation("examples/swsynth/v2/08_shear_attenuation/point_source_external_bilayer_kelvin_voigt_projected3d.json",PlotFigures=true);
off=run_simulation("examples/swsynth/v2/08_shear_attenuation/point_source_offplane_bilayer_kelvin_voigt_projected3d.json",PlotFigures=true);
```
