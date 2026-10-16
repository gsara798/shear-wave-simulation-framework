# swsynth V2 — shear attenuation, stage 1

This folder compares homogeneous elastic and Kelvin–Voigt shear propagation. This initial stage is opt-in and independent of mechanical noise and ultrasound observation noise.

## Physics

The constitutive law is defined in `+swsynth/+medium/+viscoelastic/dispersion.m`:

- Elastic: `G*=mu`
- Kelvin–Voigt: `G*=mu+i*omega*eta`
- The real phase wavenumber and positive attenuation coefficient are obtained consistently from the same complex modulus, density and frequency. The existing spatial phasor convention is `exp(+i*k*r)`.

The plane-wave contribution uses phase speed from the constitutive law and multiplies the amplitude by `exp(-alpha*d)`. Here `d` is distance from the first wavefront intersecting the field of view, projected along propagation direction. This is a finite-FOV convention, not an absolute physical source location.

The spherical point-force contribution uses `exp(-alpha*r)`, where `r` is distance to each aperture node, in addition to the already-existing `geometric_decay_exponent` spreading factor. The current geometric spreading exponent preserves existing legacy behavior; the standalone `+propagation/+spreading/factor.m` function provides a regularized reference-distance implementation for future explicit normalization, but has **not** replaced the existing spherical calculation.

This implementation supports **only homogeneous media and analytical propagation**, and rejects heterogeneous/Eikonal attenuation. It does not model interface transmission, multiple scattering, shear-to-compressional mode conversion or ultrasound noise.

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

The next planned stages are integration of locally varying attenuation along Eikonal trajectories, followed by separate empirical-shadow and impedance-transmission approximations for interfaces. Reflections are **not** implemented by an amplitude-only transmission approximation.
