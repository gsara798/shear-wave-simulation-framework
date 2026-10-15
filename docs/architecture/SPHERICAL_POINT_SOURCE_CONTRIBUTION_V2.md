# Spherical point-force shear contribution V2

**Status:** implemented as an additive standalone MATLAB API on `develop/v2`; MATLAB tests to be executed locally. The old syntheses and RNG sequences are not replaced.

## Purpose and physics

`swsynth.propagation.spherical.point_source.computeContribution(request)` computes the complex **vector** shear far-field from **one physical source** (parent source ID), including all of its *coherent* point or line aperture elements.

For node `j` of source `s`, with position `r_j`, force unit vector `F_s`, aperture weight `w_j`, scalar relative amplitude `A_s`, shared source phase `phi_s`, and `n_j=(r-r_j)/|r-r_j|`:

```text
p_j(r) = F_s - n_j * dot(n_j,F_s)
T_j(r) = |r-r_j| / c_s
U_s(r) = A_s * exp(i*phi_s) * sum_j [
    w_j * p_j(r) * |r-r_j|^(-gamma) * exp(+i*omega*T_j(r))
]
```

The angular radiation *magnitude* of `p_j` is retained. The scalar `gamma=geometric_decay_exponent` is 0 by default (historical synthetic convention) and may be set to 1 for 3D spherical far-field `1/r` spreading. When `gamma>0`, `r` is in metres and the amplitude units implicitly absorb `m^gamma`; no calibrated absolute-force Green function is implemented.

The **2d** geometry is an **in-plane x-z observation of a three-dimensional point-force far field**, *not* the 2D cylindrical Green function of a line force. `projected3d` permits off-plane physical source positions and force directions but observes the x-z grid at `observation_y_m`, defaulting to the bundle observation y (usually zero). `volumetric3d` computes a 3D output grid.

## API

First construct sources with `swsynth.sources.prepare`:

```matlab
sourceRequest=struct();
sourceRequest.geometry="projected3d";
sourceRequest.count=2;
sourceRequest.positions=struct("method","explicit", ...
    "position_xyz_m",[0 .025 0;.02 -.025 0]);
sourceRequest.excitation=struct( ...
    "force_direction_xyz",[1 0 0;0 0 1], ...
    "relative_amplitude",[1;1], ...
    "phase_rad",[0;pi]);
bundle=swsynth.sources.prepare(sourceRequest);

req=struct();
req.source_bundle=bundle;
req.source_id=1;                    % required if bundle has multiple sources
req.frequency_hz=500;
req.phase=struct("method","analytical", ...
    "reference_cs_m_s",2);
req.x_m=0.005:.001:.04;
req.z_m=0.005:.001:.04;
req.observation_y_m=0;              % optional for slice observations
req.geometric_decay_exponent=1;    % optional; default 0
component=swsynth.propagation.spherical.point_source.computeContribution(req);
```

Omitting `request.source_id` is allowed only for a one-source bundle. Each source can have `point` or `line_segment` aperture; every node inherits the physical parent's force, relative amplitude, and initial phase. Each parent has normalized node weights (sum 1); the function does *not* draw independent phases per node. A singular observation exactly at an aperture node is rejected, rather than silently clamping distance.

**Supported phase:** homogeneous analytical spherical travel time `T=r/c_s`, routed through the shared `swsynth.phase.compute` and `swsynth.phase.analytical.spherical.computeTravelTime`. Eikonal, heterogeneous straight rays and viscoelastic attenuation are not yet supported in this new function. Requests for other phase methods fail explicitly. The legacy phase module's plane-wave routing is unchanged.

**Supported polarization:** `swsynth.polarization.compute(model="point_force_shear_far_field")`. It gives the transverse *unnormalized* radiation vector, not actuator force itself and not a constant scalar measured-axis weight.

## Output

```matlab
component.model="spherical_wave"
component.radiation_model="point_force_shear_far_field"
component.U_xyz                   % complex [Nz,Nx,3] or [Nz,Ny,Nx,3]
component.geometry                % 2d, projected3d, volumetric3d
component.x_m, component.z_m      % grid axes, metres
component.y_m                     % volumetric3d only
component.observation_y_m         % 2d/projected3d only
component.frequency_hz
component.phase_sign=1
component.source_id
component.source_xyz_m
component.force_direction_xyz
component.amplitude
component.phase_rad
component.reference_cs_m_s
component.geometric_decay_exponent
component.aperture_node_count
component.output_convention
```

A single parent source is **one contribution**, regardless of how many coherent aperture nodes represent it. Its components can be coherently summed with `swsynth.propagation.accumulate`, using `normalization="none"` or an explicitly requested `1/sqrt(N_sources)` convention. Do not normalize by number of aperture nodes: their weights already sum to one.

```matlab
req.source_id=1;
a=swsynth.propagation.spherical.point_source.computeContribution(req);
req.source_id=2;
b=swsynth.propagation.spherical.point_source.computeContribution(req);
wavefield=swsynth.propagation.accumulate({a,b});
uz=swsynth.observation.projectComponent(wavefield.U_xyz,[0 0 1]);
```

`accumulate` now supports mixed spherical and plane-wave contributions with compatible geometry, spatial axes, observation plane, frequency and spatial-phase sign; the user remains responsible for consistent displacement/velocity units and physical amplitude scale. No receiver projection, measurement effects, noise, longitudinal waves, near-field terms, reflection or calibrated elastodynamic Green tensor is included.

## Tests

`tests/unit/test_swsynth_spherical_point_source_contribution_v2.m` verifies field vector geometry, homogeneous spherical delay, legacy signed radiation projection, coherent line aperture versus manual node sum, phase inheritance, explicit multi-source mapping, cumulative sums, zero-amplitude complex output and incompatible parameter rejection. Run alongside `test_swsynth_propagation_accumulate_v2.m` and existing V2 source/polarization tests.
