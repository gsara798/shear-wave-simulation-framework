# Three-dimensional data contract

## Coordinates

The public physical coordinate convention is:

- `x`: lateral;
- `y`: elevational or out-of-plane;
- `z`: axial or depth.

All physical values use SI units.

## Array orientation

k-Wave solver arrays are stored internally as `[Nx, Ny, Nz]`.

Public spatial arrays returned by `kwsim.three_d` are stored as `[Nz, Ny, Nx]`
and carry the suffix `_zyx`.

The solver adapter performs the conversion with:

    public_zyx = permute(internal_xyz, [3, 2, 1]);

Internal solver-order arrays must not escape the adapter unless their names
explicitly include the suffix `_xyz_internal`.

## Vector fields

Vector components are named explicitly:

- `x_shear_zyx`
- `y_shear_zyx`
- `z_shear_zyx`
- `x_compression_zyx`
- `y_compression_zyx`
- `z_compression_zyx`

The initial directional benchmark uses principal propagation along `+x` and
polarization along `+z`.

## Geometry

Geometry constructors use physical coordinates.

A spherical object uses:

- `center_m_xyz = [x, y, z]`
- `radius_m`

Rasterization into solver-order arrays is performed only by
`kwsim.three_d.buildGeometry`.

## Result fields

The public result contract includes:

- `result.axes.x_m`
- `result.axes.y_m`
- `result.axes.z_m`
- `result.truth.cs_m_s_zyx`
- `result.truth.cp_m_s_zyx`
- `result.truth.rho_kg_m3_zyx`
- `result.truth.material_id_zyx`
- `result.fields.velocity`
- `result.fields.displacement`

All spatial truth and field arrays use public orientation `[Nz, Ny, Nx]`.

## Source convention

The baseline source is located on the left `x` boundary and launches primarily
toward `+x`.

Its prescribed motion is polarized along `+z`, making the intended motion
transverse to the principal propagation direction.

Both vectors are stored explicitly:

- `source.target_direction_xyz`
- `source.polarization_xyz`

They must be nonzero, normalized during validation, and mutually orthogonal for
the baseline shear-wave configuration.

## Multi-source bank convention

A resolved vibrator bank stores one structure per physical contact under:

```matlab
result.config_resolved.source.vibrators
```

Each vibrator contains:

```text
node_linear_indices
center_index_xyz
center_m_xyz
nominal_propagation_xyz
polarization_xyz
phase_rad
velocity_amplitude_m_s
contact_node_count
```

All solver-source component matrices use shape:

```text
[NsourcePoints, Nt]
```

Their row order corresponds exactly to the column-major ordering returned by:

```matlab
find(source.u_mask)
```

This correspondence must remain valid for `ux`, `uy`, and `uz`.

The current bank policies are:

```text
phase_policy        = random_uniform
amplitude_policy    = equal_total_rms
polarization_policy = project_axial_transverse
```

`equal_total_rms` normalizes the node-weighted RMS-squared prescribed velocity
of the complete bank to the single-contact reference. It is a controlled drive
quantity and is not interpreted as mechanical power because source stress is
not prescribed.

The acquisition plane is a central `x-z` plane at a resolved `y` index. The REQ
export contains this two-dimensional plane, while the solver and harmonic fields
remain fully three-dimensional.

The implemented `partial_diffuse_8` bank is a single-face development geometry.
Its eight contacts lie on the left `x` face and point toward the domain
interior. Multi-face partially diffuse and diffuse geometries are future
source-bank configurations.

See
[`three_d_wavefield_regimes.md`](three_d_wavefield_regimes.md)
for the planned directional-to-diffuse field taxonomy.

## Grid resolution

The shear wavelength is

    lambda_s = cs / f0

The points per wavelength are evaluated independently along every axis:

    ppw_x = lambda_s / dx
    ppw_y = lambda_s / dy
    ppw_z = lambda_s / dz

All three values must satisfy `grid.minimum_shear_ppw`.

## Memory preflight

Every 3D configuration undergoes a memory preflight before invoking k-Wave.

The estimate is intentionally conservative and is used to reject configurations
that clearly exceed the configured memory limit. It is not interpreted as an
exact prediction of peak CPU or GPU memory use.

## Solver boundary

The following implementation details remain confined to
`kwsim.three_d.run` and its builders:

- k-Wave array orientation;
- solver-specific component names;
- CPU or GPU data representation;
- sensor-vector reshaping;
- conversion from `[Nx, Ny, Nz]` to `[Nz, Ny, Nx]`.

Benchmark and analysis code must consume only the public result contract.