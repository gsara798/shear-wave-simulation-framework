# Sources and positions — incremental V2 implementation

Status: new position contract is **additive**, not connected to production wavefield synthesis.

## Geometry boundary
- `swsynth.sources.positions.generate(request)` resolves explicit or sampled XYZ positions. Request fields: `geometry`, `count`; for explicit use `position_xyz_m`; for sampled use `direction_xyz`, `center_xyz_m`, `radius_range_m`. `observation_y_m` is relevant to `planar2d`. Optional `stream` is a MATLAB RandStream object (not silently reseeded).
- `swsynth.sources.positions.validate(positions,geometry,count,observationY)` centrally enforces finite coordinates, count, and in-plane positioning for `planar2d`.
- Geometry-specific facades `positions.planar2d.validate`, `positions.projected3d.validate`, `positions.volumetric3d.validate` currently differ only in policy. Avoid duplicating algorithms unless geometries diverge in physics.
- MATLAB package name for 2D is `+planar2d`, not `+2d`.

The uniform radial sampling is area-uniform (2D) or volume-uniform (3D). This is a **new contract**; it is not intended to reproduce the single-precision RNG sequence of legacy `sources.prepare`, whose behavior is kept unchanged.

## Source relationships
`swsynth.sources.validate(bundle,geometry)` requires `bundle.components.direction_xyz` and `bundle.sources`; optional `sources.position_xyz_m` and `components.source_id` map components to finite sources (more than one component per source is valid). For plane-wave components, no finite position or source mapping is required. This contract is currently limited to direction-based components; more general spherical radiation will require a separate component description.

## Next stage
Create `sources.directions` and `sources.excitation` contracts, then deterministic independently seeded RandStream factory. Do not change the RNG behavior of legacy synthesis until a new modular end-to-end pipeline is tested. The existing experimental `swsynth.sources.prepare(cfg,directions)` remains legacy-oriented; it is **not** the new canonical source contract yet.
