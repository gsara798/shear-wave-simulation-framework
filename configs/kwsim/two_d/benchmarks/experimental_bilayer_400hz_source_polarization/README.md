# 400 Hz source-polarization bilayer benchmark

These six lossless 2D k-Wave configurations extend, but do not overwrite, the
frozen `experimental_bilayer_400hz` baseline. They cross three exact media
(homogeneous 1.74 m/s, homogeneous 3.05 m/s, and a horizontal 1.74/3.05 m/s
bilayer at `z=19 mm`) with two prescribed source-motion directions.

- `source_z_*` uses physical polarization `[Ux,Uz]=[0,1]`, the frozen control.
- `source_x_*` uses physical polarization `[Ux,Uz]=[1,0]`, matching the
  actuator-motion direction under study.

Only polarization and material geometry vary. All cases use the same 213 x
152 grid at 0.2375 mm, 400 Hz contact, seed, 65 ms duration, medium density,
reduced numerical compressional speed, exterior 20-point PML, and fixed
analysis FOV `[11.4,49.4] x [0,35.8625] mm`. The source contact center is at
`x=1.1875 mm`, giving a realized 10.2125 mm center-to-FOV gap for the requested
10 mm separation. The exterior PML is not part of the public coordinate grid.

Run `kwsim_benchmarks.experimental_bilayer_source_polarization_2d.auditGeometry`
before any solver execution. Generated outputs belong under
`outputs/benchmarks/experimental_bilayer_400hz_source_polarization` and are
ignored by Git.
