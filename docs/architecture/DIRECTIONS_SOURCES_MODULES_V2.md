# Directions and sources — incremental V2 modularization

`swsynth.directions.generate(cfg)` is the new modular entry point for angular sampling. It delegates to the already mature `swsynth.generateDirections(cfg)`; it does not alter random/fibonacci/explicit sampling, angular support, or RNG behavior.

`swsynth.sources.prepare(cfg,directions)` is a separate preparation stage for the **existing planar 2D / projected3D legacy positioning convention**. It calculates parent XYZ positions from direction and radius, supports explicit source positions, and expands a coherent aperture through the existing `swsynth.sources.buildCoherentAperture`. It does **not** choose wave directions, excitation, forces, phase, polarization, or noise.

For reproducibility, **generate directions first**, then call `sources.prepare` without reseeding the RNG between calls. `sources.prepare` consumes the historical single-precision radius draw even with explicit positions. This legacy behavior will need an explicit reproducibility policy before changing source placement semantics.

Physical caveat: parent positions are source geometry used by spherical/point-source models. A plane-wave component is defined by incidence direction and need not have a finite point-source location; the new general synthesizer should not require `sources.prepare` for ideal plane waves merely because the old planar RNG path drew positions. The volumetric source configuration and independent 3D source placement will be addressed after testing the interface and reviewing its separate numerical conventions.

Existing synthesizers remain unchanged and are still the regression reference. Do not remove `generateDirections` or insert additional random draws into the current synthesis route until wavefield/RNG-equivalence tests pass.
