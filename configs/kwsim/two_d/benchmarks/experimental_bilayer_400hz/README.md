# Controlled 400 Hz experimental-bilayer benchmark

These three lossless 2D k-Wave configurations isolate homogeneous estimator
performance from physical interface effects. They use the same 38.00 x 35.86 mm
physical domain, 0.2375 mm isotropic grid, seed, 400 Hz finite contact, sensor
coverage, PML, 57 ms duration, density, and fixed reduced compressional speed.
Only shear speed and the bilayer rectangle differ.

The numerical `cp=9.15 m/s` is held identical across cases and is three times
the maximum shear speed. It is not a tissue compressional-speed model. This
keeps the elastic time step and solver treatment controlled while satisfying
the positive-bulk-modulus guard. Attenuation and noise are disabled.

The requested interface is `z=19 mm`; rasterization includes grid nodes at and
below that coordinate in the stiff material. Use `kwsim.cli.runConfig` with
`DryRun=true` before any solver execution.

The originally requested 0.20 mm grid passed mathematical preflight but
required about 1.5 GiB for recorded split fields alone and its smoke process
ended before producing output. The realized 0.2375 mm grid is the closest
resource-safe grid that keeps the 19 mm interface exactly on a grid node; it
retains 18.32 PPW in the soft material and 32.11 PPW in the stiff material.
