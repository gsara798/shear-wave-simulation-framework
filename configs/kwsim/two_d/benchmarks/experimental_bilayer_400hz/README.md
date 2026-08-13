# Controlled 400 Hz experimental-bilayer benchmark

These three lossless 2D k-Wave configurations isolate homogeneous estimator
performance from physical interface effects. They use the same 38 x 36 mm
physical domain, 0.20 mm isotropic grid, seed, 400 Hz finite contact, sensor
coverage, PML, 57 ms duration, density, and fixed reduced compressional speed.
Only shear speed and the bilayer rectangle differ.

The numerical `cp=9.15 m/s` is held identical across cases and is three times
the maximum shear speed. It is not a tissue compressional-speed model. This
keeps the elastic time step and solver treatment controlled while satisfying
the positive-bulk-modulus guard. Attenuation and noise are disabled.

The requested interface is `z=19 mm`; rasterization includes grid nodes at and
below that coordinate in the stiff material. Use `kwsim.cli.runConfig` with
`DryRun=true` before any solver execution.
