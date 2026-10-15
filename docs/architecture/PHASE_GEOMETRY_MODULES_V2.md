# Phase geometry packages — V2 transition

The public phase contract is `swsynth.phase.compute(request)`. Methods route by geometry to methods named `computeTravelTime`:

- `+analytical/+planar2d`, `+analytical/+projected3d`, `+analytical/+volumetric3d`: homogeneous directional travel-time fields.
- `+eikonal/+projected3d`, `+eikonal/+volumetric3d`: directional Eikonal solvers and their incident boundary/slowness helpers.
- `+straight_ray/+planar2d`, `+straight_ray/+projected3d`: source-target straight-ray integration. Both share the same preexisting y-invariant 2.5D numerical integrator. Planar2d requires source and targets to lie on the same constant-y slice. Projected3d allows oblique 3D source-to-plane paths in an extruded medium.

MATLAB packages cannot start with a number, therefore `+planar2d` is used rather than `+2d`.

The root `swsynth.integrateStraightRayTravelTime` is now a compatibility forwarding wrapper, not a duplicate implementation. The existing spherical numerical synthesis calls the new phase location. The analytical planar superposition kernel `synthesizeHomogeneousFieldXZ` **still belongs to synthesis** (it computes the weighted superposition as well as phase) and has not been moved or deleted. Likewise, the root volumetric analytic synthesizer is not a standalone phase solver; its phase-only counterpart is in `+phase/+analytical`.

All phase-module outputs measure propagation **travel time in seconds**; excitation, polarization, coherent summation and noise remain in propagation. Numerical equivalence must be verified in MATLAB before removing legacy APIs.
