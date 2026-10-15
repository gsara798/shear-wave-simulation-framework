# Source orientation and excitation (V2, additive)

**Source force direction** specifies actuator forcing; it is not a propagation direction or tissue displacement polarization.

`swsynth.sources.excitation.generate(request)` prepares source-level orientations, amplitudes, and phases independently of positions and synthesis. Required `count`. Optional `geometry`: `"2d"` (alias `"planar2d"`), `"projected3d"`, or `"volumetric3d"`. Omitting geometry retains the earlier unrestricted XYZ-only excitation contract for transitional callers.

## Force direction inputs

For a physically **in-plane 2D x-z** model:
- `force_policy="fixed"` and `force_direction_xz=[Fx Fz]` (1-by-2 replicated, or N-by-2); output is always normalized N-by-3 `force_direction_xyz=[Fx 0 Fz]`.
- Alternatively `force_direction_xyz=[Fx 0 Fz]` (1-by-3 replicated, or N-by-3) is valid. Nonzero force-y is rejected with `swsynth:PlanarForceOutsidePlane`. Providing both inputs is an error.
- `force_policy="random_circle"` creates uniform random force orientations in the x-z plane; `random_sphere` is rejected for planar2d.

For projected3d/volumetric3d, `force_direction_xyz` accepts any nonzero 3D direction, and `force_policy="random_sphere"` samples uniformly over the full sphere. The 2D shorthand `force_direction_xz` is deliberately disallowed in 3D to avoid conflating spatial/physical assumptions. The 3D sample distribution is unchanged.

The 2D in-plane restriction is a property of the **currently defined planar model**, not a universal ban on out-of-plane SH waves; such a model would need its own explicit physical contract. `projected3d` supports true 3D force orientations for a planar observation.

## Amplitude and phase

- `amplitude_policy="fixed"` with optional `relative_amplitude` (defaults to ones), or `"random_normal"` with optional `amplitude_jitter_fraction`. Generated negative values are truncated to zero (not the legacy generator's exact distribution).
- `phase_policy="fixed"` with optional `phase_rad` (defaults zero), or `"random_uniform"` in [0,2*pi).
- `relative_amplitude` is a nonnegative multiplier; values greater than one are physically valid relative to the chosen normalization.
- Optional `stream` is a MATLAB RandStream. The excitation generator never reseeds global RNG. The current API consumes one stream sequentially for force, amplitude, phase; independent labeled substreams are an upcoming orchestration task.

Example in-plane forces:
```matlab
request=struct("geometry","2d","count",2, ...
    "force_policy","fixed", ...
    "force_direction_xz",[1 0; 0 1], ...
    "amplitude_policy","fixed", ...
    "relative_amplitude",[1;1], ...
    "phase_policy","fixed","phase_rad",[0;pi]);
excitation=swsynth.sources.excitation.generate(request);
% excitation.force_direction_xyz = [1 0 0; 0 0 1]
```

Example random 2D orientation:
```matlab
request=struct("geometry","2d","count",30, ...
    "force_policy","random_circle", ...
    "phase_policy","random_uniform", ...
    "stream",RandStream("mt19937ar","Seed",53053));
excitation=swsynth.sources.excitation.generate(request);
```

## Scope and migration

`+excitation/+planar2d/sampleForceDirections.m` implements the 2D orientation sampler. Geometry-independent amplitude/phase validation remains shared in `+excitation`.

This module is **not yet wired into the existing wavefield synthesizers**, which still use legacy `swsynth.generateDirectionalExcitation` or their own routines. Do not assume changing `request.force_direction_xz` changes a call to `swsynth.run(cfg)` until the new preparation pipeline is connected and regression-tested.
