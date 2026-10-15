# Source orientation and excitation (V2, additive)

The terminology is now fixed: **source force direction** = orientation of actuator forcing, while **wave propagation direction** = incidence / local ray direction. Neither should be called bare `directions` in the final public source schema.

`swsynth.sources.excitation.generate(request)` independently prepares one set of source-level force vectors, amplitudes and initial phases. Required `count`; policies:
- `force_policy="fixed"` with `force_direction_xyz` (single 1x3 vector broadcast or N-by-3), or `"random_sphere"`.
- `amplitude_policy="fixed"` with optional `relative_amplitude` (defaults to ones), or `"random_normal"` with optional `amplitude_jitter_fraction`. Random amplitudes are truncated at zero to enforce nonnegative magnitudes (this is **not** the same distribution as all legacy generators).
- `phase_policy="fixed"` with optional `phase_rad` (defaults zero), or `"random_uniform"` in [0,2*pi).

Optional `stream`: a MATLAB RandStream used for every draw; the module never calls `rng`. Callers wanting independent random outputs must provide separately seeded streams for force, amplitude and phase in a future orchestrated generator; **the current interface uses one stream for its own sequential draws**.

Returned `force_direction_xyz` is N-by-3 unit vectors, `relative_amplitude` and `phase_rad` are N-by-1. `relative_amplitude` is a nonnegative multiplier, so values > 1 are valid. For a force vector combining axes e.g. [1 0 1], normalization gives equal x and z components at fixed total force magnitude.

The code is **not connected to the existing synthesizers**. Existing `swsynth.generateDirectionalExcitation` still generates polarization as well as amplitude and phase, and uses legacy RNG resets; it remains untouched. Wave propagation directions will be renamed/migrated in a separate step rather than mechanically moved to source force orientation.

Geometry subfolders are only needed for excitation physics that actually varies with geometry. The current force vector math is shared, so it lives under `+sources/+excitation`.
