# Physical source positions — V2 independent contract

Status: **implemented as an additive, standalone source-position generator**. Not yet wired into legacy wavefield synthesis.

## Concept

`swsynth.sources.positions.generate(request)` returns N-by-3 **physical source coordinates in metres**. These are not propagation-direction vectors and are unrelated to actuator force direction. An ideal plane wave does not require source positions. A spherical/point source does.

Required:
- `geometry`: `"2d"` (or `"planar2d"`), `"projected3d"`, or `"volumetric3d"`. `"2d"` is the public alias normalized to the MATLAB package name `+planar2d`.
- `count`: number of physical sources
- `method`: `"fibonacci"`, `"random"`, or `"explicit"` (omitted method is inferred as `explicit` only if `position_xyz_m` is supplied).

For `fibonacci` / `random`:
- `center_xyz_m`: XYZ centre, metres.
- `radius_range_m`: [min max] in metres. Equal bounds put every source **on the same circle/sphere**, e.g. `[0.025 0.025]`.
- Optional `support`: `struct("type","full_circle")` in planar2d, `struct("type","full_sphere")` in either 3D geometry, or `struct("type","cone","axis_xyz",[...],"half_angle_deg",...)`. Default is full circle/sphere.
- Optional `stream`: MATLAB `RandStream`, for reproducible random sampling without touching global RNG.
- Optional `observation_y_m`: physical y coordinate of planar2d plane (default 0). Planar source centre must lie on this plane.

For `explicit`:
- `position_xyz_m`: N-by-3 finite coordinates in metres; strictly checked against `count` and planar observation y. Explicit coordinates are not altered and consume **no RNG**.

## What the sampling actually does

- **planar2d**: positions on a circle or annulus in the x-z plane; `random` angles are uniform in angle and radii are uniform in **area**, `fibonacci` is deterministic **equally spaced** angles (the 2D counterpart of Fibonacci sphere), and radial shells use area-quantile midpoints.
- **projected3d**: physical XYZ positions on spherical surfaces or inside a spherical shell, even when the observation is 2D (x-z).
- **volumetric3d**: physical XYZ positions, using the same 3D sampling equations as projected3d. In 3D, `random` angles are isotropic, radius samples are uniform in **volume**; `fibonacci` uses golden-angle sphere angular placement and deterministic radial quantile midpoints.
- `cone`: random uniform angular support or Fibonacci-like deterministic coverage of the circular/spherical cap. This concerns **where sources are placed**, not their force or propagation direction.
- Neither `fibonacci` nor `random` guarantees a minimum separation of sources; no collision-rejection algorithm is implied.

## Examples

```matlab
r=struct("geometry","projected3d","count",30, ...
    "method","fibonacci","center_xyz_m",[.025 0 .025], ...
    "radius_range_m",[.025 .025], ...
    "support",struct("type","full_sphere"));
xyz=swsynth.sources.positions.generate(r);

r.method="random";
r.stream=RandStream("mt19937ar","Seed",53053);
xyzRandom=swsynth.sources.positions.generate(r);

r=struct("geometry","planar2d","count",1,"method","explicit", ...
    "observation_y_m",0,"position_xyz_m",[.01 0 .02]);
xyzExact=swsynth.sources.positions.generate(r);
```

## Module ownership

`+positions/generate.m`: contract dispatcher and explicit passthrough.
`+positions/validateRequest.m`: validates method, units, supports and combinations.
`+positions/+planar2d/generate.m`: circle/annulus and planar cones.
`+positions/+projected3d/generate.m`: 3D spherical placement for slice observations.
`+positions/+volumetric3d/generate.m`: 3D spherical placement for volumetric observations.
`+positions/sampleUnitSphere.m` and `sampleRadii.m`: reusable **position** mathematics, not a call to propagation-direction generation.

`swsynth.sources.validate(bundle,geometry)` validates physical source positions independently of incident propagation directions; optional `components.source_id` maps multiple contributions to one physical source.

## Reproducibility and migration

These new methods use double precision and a caller-provided stream when supplied; they do **not** call `rng` or reset the global random state. Without an explicit stream, `random` uses MATLAB's current global random stream. Fibonacci and explicit positioning do not consume RNG.

The existing `swsynth.sources.prepare(cfg,directions)` remains a **legacy compatibility preparation routine** using the old single-precision draw order; it is not the new positions contract. All existing synthesizers remain unchanged. We will only migrate them after end-to-end RNG and field regression tests.
