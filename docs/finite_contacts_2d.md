# Finite-contacts 2D benchmark

This benchmark adds a finite-contact alternative without removing the validated
point-contact model. Select it with:

```matlab
cfg = kwsim_benchmarks.finite_contacts_2d.config("directional");
```

In two dimensions these sources generate circular or cylindrical wavefronts.
A truly spherical wave requires the future 3D implementation.

## Physical vibrator versus solver channels

One physical vibrator is a segment tangent to the nearest domain boundary.
Its nodes share frequency, phase, propagation direction, and transverse
polarization. Each active node nevertheless receives a separate monotonically
labelled k-Wave channel so its peak velocity can follow a spatial taper.

The result stores both identities:

- `vibrator_id_mask_*`: physical actuator membership;
- `label_mask_*`: solver-channel labels;
- `vibrators`: contact geometry, profile, direction, phase, and drive share;
- `solver_channels`: node position, physical-vibrator ID, spatial weight, and
  realized peak velocity.

Total prescribed RMS-squared velocity is normalized using the actual squared
profile weights. It therefore remains constant when vibrator or node counts
change. It is not called mechanical power because contact stress is unknown.

## Validated reference envelope

The current 0.5 mm reference grid uses:

- 4 mm total contact span (`contact_radius_m = 2 mm`);
- three active nodes per contact;
- 2 mm separation between active nodes (four grid points);
- symmetric raised-cosine weights `[0.5, 1, 0.5]`;
- 8 directional vibrators, or 16 for partial/diffuse regimes;
- six settling cycles for the finite diffuse benchmark.

This spacing is a numerical reliability condition, not a claim about a
particular experimental transducer. Compact sweeps showed:

- 2 mm node separation: all three regimes passed stationarity;
- 1.5 mm node separation: the diffuse field became non-stationary;
- 1 mm node separation: all finite-contact regimes failed convergence.

Strict preflight therefore rejects finite contacts below four grid points of
node separation, asymmetric sampling, adjacent Dirichlet constraints, or a
contact with fewer than three active nodes. This deliberately does **not**
claim stability under arbitrary contact discretizations.

## Diagnostics

Every finite-contact run reports:

- requested and realized contact span;
- physical-vibrator and solver-channel counts;
- node spacing and profile symmetry;
- profile center alignment and effective node count;
- contribution of every vibrator to the prescribed drive;
- temporal source purity and final-cycle field convergence;
- P/S content, angular concentration, angular entropy, and spatial coherence.

`kwsim_benchmarks.finite_contacts_2d.compareModels` compares saved point and finite
results over their exact common physical ROI, including complex correlation
and shape error after optimal complex scaling.

`kwsim_benchmarks.finite_contacts_2d.runSizeSweep` provides the compact point-limit
diagnostic. In the reference sweep, field correlation to the point model was
0.916 for a 4 mm segment and 0.253 for an 8 mm segment; optimal-scaled shape
errors were 0.401 and 0.967. Thus the smaller validated contact moves clearly
toward the point-source field, while contact size remains physically
consequential rather than a cosmetic parameter.

## Validation and output

```matlab
validation = kwsim_benchmarks.finite_contacts_2d.run();
kwsim_benchmarks.finite_contacts_2d.saveResults( ...
    validation, 'outputs/finite_contacts_2d');
```

The acceptance suite uses the same angular and reproducibility gates as
the point-contact field-regimes benchmark. The readable summary also includes every single-run contact and
stationarity check.
