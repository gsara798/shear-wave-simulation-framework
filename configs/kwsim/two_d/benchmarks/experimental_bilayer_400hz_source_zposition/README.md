# SOURCE-X bilayer source-z-position control

These two configurations change only the requested axial center of the finite SOURCE-X contact. The completed source-polarization bilayer result is reused as `NEAR_INTERFACE`; homogeneous simulations are not repeated.

- `SOURCE_IN_SOFT`: requested z = 11.5 mm, expected material 1.
- `SOURCE_IN_STIFF`: requested z = 26.5 mm, expected material 2.

Finite-contact centers are quantized to the nearest symmetric half-grid position. Preflight must demonstrate identical contact offsets, node count, x position, FOV, waveform, and solver configuration.
