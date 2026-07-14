# Stage 1 MAT data contract

`kwsim.two_d.run` returns `result` and `report`. `saveRun` stores both without
renaming fields.

Important result groups:

- `config_requested`: caller input before resolution.
- `config_resolved`: actual `cp`, grid indices, timing, ROI, and memory values.
- `axes`: SI coordinate vectors and explicit `[Nz,Nx]` orientation.
- `truth`: homogeneous `cp`, `cs`, density, material ID, and zero attenuation.
- `source`: mask, waveform, location, polarization, phase, and spectrum.
- `fields.velocity`: complex axial/lateral P/S/total phasors in m/s.
- `fields.displacement`: complex axial/lateral P/S/total phasors in m.
- `diagnostics`: thresholds, values, pass/fail state, and speed-fit details.
- `provenance`: MATLAB, k-Wave, backend, schema, time, and seed.

The stable future integration point for adaptive REQ is the public axial
phasor plus `x_m`, `z_m`, `dx_m`, `dz_m`, and `f0_hz`. No dependency on
adaptive REQ is introduced in this repository.
