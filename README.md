# Reproducible k-Wave shear-wave simulations

This repository provides a documented MATLAB interface for reproducible
elastic-wave simulations using the pinned k-Wave 1.4.1 toolbox. The current
implementation includes **Stages 1, 2, and 3**: the validated homogeneous 2D
benchmark, a central circular material inclusion, and reproducible external
vibrator banks for directional, partially diffuse, and diffuse fields.

The historical scripts under `archive/` are retained as evidence and are not
used by the new implementation.

## Quick start

From MATLAB:

```matlab
addpath('/absolute/path/to/k-wave_simulations/src');

cfg = kwsim.two_d.defaultConfig();
[result, report] = kwsim.two_d.run(cfg);
disp(report.summary);
```

To save the self-contained MAT result and diagnostic figures:

```matlab
kwsim.common.saveRun(result, report, 'outputs/my_run');
```

To inspect the measured axial displacement field interactively, including
amplitude, phase, P/S separation, and the phase-speed fit:

```matlab
kwsim.diagnostics.plotAxialField(result, report);
```

Pass `Quantity="velocity"` as a name-value option to visualize axial particle
velocity instead of displacement.

Axial and lateral motion can be compared with shared amplitude scales using:

```matlab
kwsim.diagnostics.plotMotionComponents(result, report);
```

All diagnostic figures use the reusable template returned by
`kwsim.common.figureTemplate`: Times New Roman, 12 pt axes/labels/titles,
14 pt figure titles, and 300 dpi export. Apply it to a new completed figure
with `kwsim.common.applyFigureStyle(fig)`. The notation rules are documented
in `docs/figure_style.md`.

The complete reference example is
`examples/two_d/run_stage1_directional.m`. The compact cross-run reliability
suite is `examples/two_d/run_stage1_validation.m`.

The Stage 2 reference is `examples/two_d/run_stage2_circular_inclusion.m`.
It validates a contrast circle against homogeneous and zero-contrast runs
before saving material maps and field-comparison figures.

The Stage 3 reference is `examples/two_d/run_stage3_field_regimes.m`. It runs
the three source regimes independently, verifies angular concentration and
entropy, and saves a common field/source/spectrum comparison. Definitions and
source-model limitations are in `docs/stage3_field_regimes.md`.

Stage 3B adds validated finite perimeter contacts while retaining point
contacts. The reference uses a 4 mm raised-cosine segment sampled at three
non-adjacent nodes. Run `examples/two_d/run_stage3b_finite_contacts.m`; the
validated range and rejected dense discretizations are documented in
`docs/stage3b_finite_contacts.md`.

## Coordinate and field contract

- `x`: lateral coordinate, increasing across columns in public maps.
- `z`: axial/depth coordinate, increasing across rows in public maps.
- Public spatial fields are always `[Nz, Nx]` and carry a `_zx` suffix.
- k-Wave internally uses `[Nx, Ny]`; this internal second coordinate is
  interpreted as `z` and converted only inside `kwsim.two_d.run`.
- Velocity phasors use m/s; displacement phasors use m.
- The phasor convention is
  `signal(t) = real(phasor * exp(1i*2*pi*f0*t)) + dc`.

The result includes axial total, shear, and compression components. Axial
total is the closest numerical analogue of an ultrasound measurement; the
split components expose P-wave contamination rather than hiding it.

## Reduced compressional speed

The reference uses

```text
cp = 10 * cs
```

instead of tissue-like `cp ~= 1540 m/s`. This keeps the isotropic material
physically admissible while reducing the time-step cost. It is an explicit
development approximation, not a claim that tissue has a 20 m/s
compressional speed. A future fidelity stage must compare it against physical
`cp` before final scientific simulations.

Configurations with `cp/cs <= sqrt(4/3)` are rejected because they imply a
non-positive bulk modulus for the isotropic elastic model.

## External vibrator model

The vibrator imposes axial particle velocity with `source.u_mode='dirichlet'`
near the left boundary. Its main propagation is lateral, making the imposed
motion transverse and shear-dominant.

k-Wave 1.4.1 becomes unstable when identical Dirichlet velocity is imposed on
adjacent elastic grid points for a long continuous-wave run. Stage 1 therefore
represents the approximately 2 mm contact using nodes spaced by two grid
points. This is a
documented solver limitation and is guarded by finite-field, P/S, speed, and
stationarity diagnostics. The additive source used by the archive is not used.

Stage 3 uses labelled point contacts around the perimeter. Every contact has
its own phase and transverse vector polarization. Directional comparisons
hold the total prescribed RMS-squared velocity drive constant as contact count
changes; this quantity is not described as mechanical power because contact
stress is unknown.

For finite Stage 3B contacts, physical-vibrator IDs are stored separately from
solver-channel labels. This permits spatially weighted finite segments while
preserving the requested total drive. In 2D their outgoing wavefronts are
circular/cylindrical; spherical propagation requires 3D.

## Reliability checks

Every run performs:

- configuration, units, CFL, PPW, bulk-modulus, ROI, duration, and memory
  preflight;
- source fundamental-energy measurement after the ramp;
- finite-value and P/S-energy checks;
- phasor convergence between the final complete cycles, with the earlier
  four-cycle versus four-cycle change retained as a descriptive metric;
- shear-speed estimation from spatial phase.

The cross-run suite additionally checks exact repetition, a 25% finer grid,
and a physically larger downstream domain as the PML-reflection reference.
See `docs/stage1_reliability.md` for definitions and thresholds.

## Tests

```matlab
addpath('/absolute/path/to/k-wave_simulations/tests');
results = run_all_tests();
```

Unit tests are fast. Integration tests execute several compact k-Wave
simulations and take longer.

## Output policy

`run.mat` always stores resolved configuration, true material maps, source
metadata, axes, phasors, diagnostics, and environment provenance. The full
space-time field is disabled by default to prevent accidental multi-gigabyte
files. Enable it explicitly with:

```matlab
cfg.output.save_time_series = true;
```

New outputs belong under `outputs/`, which is excluded by `.gitignore`.
Large historical MAT files under `archive/` are also kept local; the archived
MATLAB scripts remain versioned as implementation evidence.
