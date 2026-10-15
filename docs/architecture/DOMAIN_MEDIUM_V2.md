# Domain and medium V2 modules

**Status:** standalone modules implemented on `develop/v2`, additive, awaiting MATLAB test execution. The legacy `swsynth.buildMediumMaps`, `swsynth.buildMediumMaps3D`, and existing `swsynth.run` pipelines are **not** replaced or modified.

## Responsibilities and names

### `swsynth.domain.buildGrid(request)`

Creates a computational spatial grid, independently of the material, frequency, wave sources and measurement device.

- `geometry="2d"` (alias `"planar2d"`): 2D x-z spatial mesh. No y array; one `observation_y_m` scalar.
- `geometry="projected3d"`: same x-z output mesh at `observation_y_m`, but actual physical sources and propagation may be three-dimensional.
- `geometry="volumetric3d"`: x-y-z spatial mesh.

Choose exactly one input scheme:

**Physical lengths and requested steps:**

```matlab
grid=swsynth.domain.buildGrid(struct( ...
    "geometry","projected3d", ...
    "Lx_m",.05,"Lz_m",.04, ...
    "dx_m",.0002,"dz_m",.0002, ...
    "observation_y_m",0));
```

To preserve the legacy endpoint policy, a length `L` and requested spacing `d` produce `N=round(L/d)+1` nodes, coordinates `linspace(0,L,N)`. Therefore the **realized** `grid.dx_m` is `L/(N-1)`, which may differ from `grid.requested_dx_m`. The new grid reports both; legacy `cfg.domain.dx_m` remains unchanged in its own API. The optional `origin_xyz_m` offsets the length-defined coordinate axes without changing the observed y plane.

For a volume, also supply `Ly_m,dy_m`.

**Explicit coordinate vectors:**

```matlab
grid=swsynth.domain.buildGrid(struct( ...
    "geometry","volumetric3d", ...
    "x_m",-.025:.0002:.025, ...
    "y_m",-.01:.0002:.01, ...
    "z_m",0:.0002:.05));
```

Explicit axes must be finite, uniformly increasing and have at least two points. Explicit coordinate origins are already embedded in the axes; they cannot be mixed with lengths/spacings or `origin_xyz_m`.

Outputs: coordinate rows `x_m, z_m` (+ `y_m` for volumes), actual `dx_m,dz_m` (+ `dy_m`), realized physical extent, node counts, `spatial_size=[Nz,Nx]` or `[Nz,Ny,Nx]`, geometry and `output_convention`. Domain grid describes the **computational mesh**, not an ultrasound sensor FOV or its finite resolution.

### `swsynth.medium.buildMaps(grid,mediumSpec)`

Samples the elastic material specification on the **given grid**, without synthesizing any waves. The material defines shear speed `cs` (metres per second), spatially heterogeneous inclusions, labels and object coverage.

```matlab
material=struct();
material.background_cs_m_s=2;
material.combine_mode="overlay";
material.objects={struct( ...
    "type","circle", ...
    "center_xz_m",[.025 .02], ...
    "radius_m",.006, ...
    "cs_m_s",4, ...
    "edge_sigma_m",0)};
maps=swsynth.medium.buildMaps(grid,material);
```

For a homogeneous medium the alias `material.cs_m_s=2` is also accepted; specify **exactly one** of `cs_m_s` or `background_cs_m_s`.

- 2D and projected3d: `circle`, `bilayer`, `s_curve`, `custom(mask_zx)`, with `edge_sigma_m` sharp or optional Gaussian softened (requires Image Processing Toolbox as before); `combine_mode` options `overlay`, `blend`, `max`, `min`.
- Volumetric3d: `sphere`, `box`, `slab`, `custom(mask_zyx)`; currently `combine_mode="overlay"`. For `slab`, the normal is validated and normalized as in the 3D legacy validator.
- Material outputs: `cs_map_zx` / `cs_map_zyx`, `material_id_zx` / `material_id_zyx`, `object_alpha_zx` / `object_alpha_zyx`, spatial coordinate vectors, material model and output convention.
- Optional `density_kg_m3` is accepted as positive finite metadata; **it does not yet change wave radiation amplitudes or the prescribed `cs_map`**.

`medium.buildMaps` deliberately has **no** `frequency_hz` input and returns **no** `k_map`. Frequency is a property of the harmonic drive (`excitation.frequency_hz`, future unified configuration), not intrinsic to a constant elastic shear-speed map. Once a drive frequency `f` and a material map have been chosen, a compatible elastic approximation derives `k(r)=2*pi*f./cs_map(r)` in the propagation layer. Avoid interpreting this as a full viscoelastic complex wavenumber.

The implemented `projected3d` medium uses `cs(x,z)`, implicitly invariant in the unobserved y direction. For genuinely y-varying heterogeneity, use a volumetric medium solver and separately sample a slice.

## Numerical equivalence and scope

Existing `buildMediumMaps` and `buildMediumMaps3D` still include the legacy `k_map`, with frequency read from `cfg.wavefield.frequency_hz`. The new modules reproduce their **material-map logic** (2D sharp/smoothed geometries and combination rules, volumetric sharp overlays) without migrating existing code paths. Tests compare new `cs_map`, `material_id` and object-alpha maps against legacy outputs.

The current medium API is **isotropic elastic and speed-prescribed**, not a Kelvin–Voigt / Maxwell / fractional rheology implementation. Frequency-dependent shear attenuation, dispersion, anisotropy, density-sensitive amplitudes, and constitutive inversions should be modeled explicitly later, not silently inferred from `cs`.

## Test instructions

```matlab
cd('/Users/sara/local/shear-wave-simulation-framework')
!git pull --ff-only
clear functions
rehash
addpath(fullfile(pwd,'src'))

results=runtests({
    'tests/unit/test_swsynth_domain_build_grid_v2.m'
    'tests/unit/test_swsynth_medium_build_maps_v2.m'
    'tests/unit/test_swsynth_medium_maps.m'
    'tests/unit/test_swsynth_medium_maps_3d.m'
});
disp(table(results))
assertSuccess(results)
```

**Next stage:** freeze the shared harmonic-drive `frequency_hz` contract (with a legacy adapter from `cfg.wavefield.frequency_hz`), then implement `swsynth.propagation.synthesize` orchestration using domain and medium, prepared sources or directional incidence, phase/polarization, accumulation, observation projection and provenance.
