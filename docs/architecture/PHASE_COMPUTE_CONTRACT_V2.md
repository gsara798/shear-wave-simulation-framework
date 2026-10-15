# Phase travel-time API (V2, additive experimental contract)

`swsynth.phase.compute(request)` computes a **single contribution's travel-time field**, not a synthesized wavefield. It returns `travel_time_s`, `solver`, `method`, `geometry`, `model`, `diagnostics`. To obtain propagation phase in radians use `2*pi*frequency_hz*travel_time_s`. Initial excitation phases, polarizations, amplitudes, summation and noise remain with the synthesizer.

Input is one struct with `model`, `method`, `geometry`. For plane waves provide `direction_xyz`, `reference_cs_m_s` and spatial axes. Use `cs_map_zx` for 2D/projected3d and `cs_map_zyx` plus `y_m` for volumetric3d. The analytical backend checks medium uniformity **when a cs map is supplied**: callers should supply the map when available. `solver_options` is forwarded to eikonal numerical solvers.

- `analytical` (or historical `homogeneous_analytic`): plane waves in 2d, projected3d and volumetric3d; homogeneous only.
- `eikonal`: projected3d (y-invariant medium with conserved transverse slowness), volumetric3d (full 3D). Reuses existing numerical routines and boundary-condition references; **no physical 2D eikonal route yet**.
- `straight_ray_numerical`: spherical source to target points for planar 2.5D media; requires `cfg`, `source_xyz_m`, `target_xyz_m`; delegates to the existing integration function. It does not handle volumetric3d media.

The travel-time **phase reference** is determined by each solver and need not be identical between analytical and eikonal models; preserve this when comparing raw complex fields. Individual travel-time maps do not provide transport amplitudes or vector polarization.

This commit adds a separately testable interface. Existing synthesis functions **are intentionally untouched**. Once physics, precision, RNG and phasor conventions are checked, we can progressively reroute synthesis to this interface and remove redundant complete synthesizers. No legacy wrappers have been removed.
