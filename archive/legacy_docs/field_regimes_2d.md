# Field-regimes 2D benchmark

The field-regimes benchmark replaces the single left-side contact with a reproducible bank of
external vibrators. Every run remains monofrequency: all contacts in one
simulation operate at the same `f0_hz`.

## Source model

The public source geometry uses `[x,z]`, where `x` is lateral and `z` is
axial/depth. Each vibrator stores its boundary side, center, phase,
propagation direction, transverse polarization, peak velocity, and assigned
fraction of the prescribed drive. k-Wave receives a labelled `source.u_mask`:
label `j` is driven by row `j` of `source.ux` and `source.uy` with
`u_mode='dirichlet'`.

The field-regimes benchmark activates one resolved node per vibrator. `contact_radius_m` defines
placement clearance rather than a multi-node driven patch. Tests showed that
placing several Dirichlet constraints inside every member of a large bank
caused late-time non-stationarity in `pstdElastic2D`; the point-contact bank
passes the final-cycle convergence test. The separate single-contact benchmark retains its validated
sparse 2 mm contact.

The normalized drive is

```text
sum_j(n_j * A_j^2 / 2)  [m^2/s^2],
```

where `n_j` is the number of active nodes and `A_j` is peak particle velocity.
This is an imposed-velocity RMS-squared proxy, not mechanical power in watts,
because the contact stress is not prescribed. It remains constant when the
number of vibrators changes.

## Regimes

- `directional`: a coherent aperture on the perimeter is phased toward
  `target_angle_deg`. The 500 Hz reference fills the usable side with 12
  contacts; fewer contacts produced measurable grating lobes.
- `partially_diffuse`: half the prescribed drive belongs to the coherent
  aperture and half to seeded perimeter contacts with independent phases.
- `diffuse`: seeded contacts are distributed around the perimeter with
  independent phases and polarization transverse to their inward direction.
  The reference allows one additional settling cycle; this was selected from
  an explicitly measured monotonic cycle-to-cycle convergence sequence and
  still remains short enough to avoid the documented late-time constraint
  instability.

## Angular diagnostics

The diagnostic uses both vector shear phasors, not only the ultrasound-like
axial projection. A separable Hann taper is applied before a zero-padded 2D
FFT. Energy is integrated over an annulus centered on
`k_s = 2*pi*f0/cs`. With the stored `exp(+i*omega*t)` phasor convention,
propagation direction is the negative spatial-FFT wavevector.

Angles follow `[x,z]`: 0 degrees is `+x`, and +90 degrees is `+z`. Reported
metrics include angular energy, concentration within ±15 degrees of the
target, normalized angular entropy, dominant direction, spectral shear
speed, and polarization coherence.
The report also stores complex nearest-neighbor spatial coherence: it is one
for an ideal plane wave and decreases as adjacent vector phasors become less
coherent.

The reference suite requires directional concentration of at least 0.80,
diffuse entropy of at least 0.75, and a margin of at least 0.10 on both
concentration and entropy between adjacent regimes. It also enforces source
spectral purity, final-cycle phasor convergence, fixed total drive, and exact
source-bank reproducibility for a given seed.

## Running and saving

```matlab
validation = kwsim_benchmarks.field_regimes_2d.run();
kwsim_benchmarks.field_regimes_2d.saveResults(validation, ...
    'outputs/field_regimes_2d');
```

The saved MAT file contains the three full phasor results and reports. The
summary text exposes every threshold, and `field_regimes_comparison.png` compares
source geometry, measured axial-displacement amplitude, and vector-shear
angular spectra.
