# Physics validation of swsynth V2

This directory records evidence of physical accuracy separately from unit and integration correctness. Source is estimator-independent.

- Source tests: `tests/physics/swsynth/`
- Executable examples: `examples/swsynth/v2/`
- Results and reports: `validation/reports/` (store generated artifacts from MATLAB here; large outputs should not be committed indiscriminately)

## Validation inventory

| Physics | Reference | Status |
| --- | --- | --- |
| Homogeneous plane-wave phase | Analytic harmonic plane wave | Pending systematic audit |
| Homogeneous point-source phase | `r / cs` | Diagnostic benchmark added; MATLAB verification pending |
| External/off-plane projected3d Eikonal | 3D `r / cs` | Diagnostic benchmark added; MATLAB verification pending |
| Point-source homogeneous intrinsic attenuation | Optical depth `alpha * r` | Diagnostic benchmark added; currently stops at unresolved source core |
| Kelvin–Voigt dispersion | Complex shear modulus analytic equation | Existing unit checks; physics audit pending |
| Heterogeneous Eikonal / refraction | Bilayer analytical/Snell and reference numerical solutions | Pending |
| Geometric spreading | Plane/cylindrical/spherical asymptotics | Pending |
| Shear polarization | Transversality/radiation pattern | Pending |
| Coherent source superposition | Linear sum | Pending |
| Shear noise | Statistics and spatial correlation | Pending |
| Interfaces | Shear-only transmission, energy balance | Not implemented |

Passing a numerical smoke test does not establish physical validation.

### First diagnostic benchmark

In MATLAB from the repository root:

```matlab
setup_simulation_framework
r = runtests('tests/physics/swsynth/propagation/test_extended_point_source_eikonal_homogeneous.m');
disp(table(r))
assertSuccess(r)
```

The test prints relative L2 errors in travel time and attenuation optical depth for three numerical grid resolutions. These diagnostic errors must be inspected for convergence before selecting acceptance criteria. The optical-depth integrator currently stops near the source: its output is not expected to equal `alpha*r` exactly at finite grid resolution. This should be corrected or explicitly characterized before relying on quantitatively accurate attenuation. The computation assumes edge-constant extension outside the FOV and y-invariant material properties.

## Workflow

1. Build physics modules with minimal analytical/unit checks.
2. Complete documented examples and freeze implementation scope.
3. Run physics benchmarks including convergence and independent reference comparisons.
4. Record measured tolerance and scope for each numerical model; only then promote a diagnostic into a regression acceptance test.

### Diagnose 3D Eikonal error sources

Run this after the baseline external/off-plane homogeneous benchmark:

```matlab
r = runtests('tests/physics/swsynth/propagation/test_extended_point_source_eikonal_error_decomposition.m');
disp(table(r)); assertSuccess(r)
```

The diagnostic prints `E3_all` (error at all solver volume nodes), `E3_far` (away from source), `E_slice_numeric` (numerical slice versus the **interpolated exact field**), `E_slice_interp` (interpolation of exact volume data onto observation pixels), and `E_obs` (total observed time error). They are L2-relative metrics and are **not additive**. To avoid large artifacts, the optional `ReturnVolumeDiagnostics=true` in `solveExtended` provides raw axes and travel times only when explicitly requested; the normal synthesis return remains unchanged. No target accuracy is claimed until MATLAB results are inspected.

### Optional second-order fast sweeping (experimental)

The 3D Eikonal kernel supports `SpatialOrder=1` (explicit legacy option) or
`SpatialOrder=2` (current default; causality-limited one-sided second-order differences,
with first-order fallback at boundaries or non-monotone stencils). The
extended point-source solver forwards this option from
`propagation.solver_options` in the example JSON.

Compare homogeneous external/off-plane sources against the same reference:

```matlab
r=runtests('tests/unit/test_eikonal_fast_sweeping_3d.m');
assertSuccess(r)
r=runtests('tests/physics/swsynth/propagation/test_eikonal_spatial_order_comparison.m');
assertSuccess(r)
```

The benchmark reports the relative L2 timing error and runtime for both
orders. Order 2 was selected as the default after homogeneous source-alignment and
normal-incidence bilayer comparisons in October 2026. General oblique
refraction and heterogeneous attenuation still require validation.

### Source alignment and bilayer checks before adopting second order

```matlab
setup_simulation_framework
r1=runtests('tests/physics/swsynth/propagation/test_eikonal_second_order_source_alignment.m');
disp(table(r1)); assertSuccess(r1)
r2=runtests('tests/physics/swsynth/propagation/test_eikonal_second_order_bilayer.m');
disp(table(r2)); assertSuccess(r2)
```

The alignment diagnostic compares orders 1 and 2 at four grid spacings and prints actual source-to-grid offsets. Offsets matter: the extended solver constructs uniform axes using `linspace`, so the requested `GridSpacingM` is a target upper bound, not necessarily the realized spacing. This diagnostic does not assert a convergence order.

The bilayer benchmark uses a normal-incidence axial first-arrival reference for a two-speed material; it also checks time monotonicity along this line and a bound against an everywhere-fast reference. This is a **limited physical sanity check**, not a general proof of interface refraction, Snell's law, or correct transmitted/reflected amplitudes. In particular, first-arrival Eikonal does not synthesize reflected waves. If a test fails, inspect the solver and geometry assumptions rather than loosening tolerances automatically.

### Attenuation scope

The Kelvin-Voigt constitutive law produces both phase velocity and intrinsic
attenuation (Np/m) from the same complex wavenumber. The 3D fast-sweeping
spatial order controls travel-time solution only; heterogeneous optical depth
is integrated separately along characteristics estimated from the travel-time
gradient. Uniform-speed, uniform-loss fields use exact `alpha*r` in the
extended solver. The internal 2D source path uses a different integrator.
Neither interface transmission/reflection nor heterogeneous loss integration
is validated by the spatial-order benchmarks.

### Exact planar-interface optical depth (projected3d external sources)

For a **single sharp bilayer** in a projected3d spherical-source Eikonal
simulation, synthesis now forwards the material geometry to the extended
solver automatically. The coefficients on each side come from the same
local constitutive law used for the velocity and loss maps. Each numerical
ray segment is partitioned geometrically at the known plane, giving
`alpha_negative*L_negative + alpha_positive*L_positive` without
interpolating across the discontinuity. At constant speed, the full straight
ray is evaluated exactly. If speed changes, Eikonal characteristic tracing
remains approximate, but each segment's attenuation integral is exact for
its piecewise-constant materials.

**Scope:** external/off-plane sources that enter the extended 3D solver;
a single unblurred bilayer, overlay composition. Other geometries and
internal-source 2D integration retain their previous methods. This is
intrinsic absorption only: it does not add interface transmission or
reflected fields. It does not modify the 3D Eikonal solver itself.

```matlab
r=runtests('tests/physics/swsynth/propagation/test_planar_interface_attenuation.m');
disp(table(r)); assertSuccess(r)
```

### Oblique Snell refraction and attenuation (diagnostic)

Run `tests/physics/swsynth/propagation/test_eikonal_oblique_snell_attenuation.m`
for external-source `projected3d` rays crossing a sharp interface obliquely.
The independent reference minimizes the two-segment travel time over the
interface crossing coordinate with `fminbnd`; Snell's relation is checked
on that reference. Eikonal observation arrival times and geometrically
integrated attenuation are then compared with the optimal Fermat path at
multiple grid spacings. Outputs are diagnostic until numerical error
thresholds have been chosen based on observed behavior. No transmitted
amplitude coefficient or reflected wave is included.

```matlab
r=runtests('tests/physics/swsynth/propagation/test_eikonal_oblique_snell_attenuation.m');
disp(table(r)); assertSuccess(r)
```

### Geometric speed sampling for explicit bilayers

In projected3d spherical-source Eikonal synthesis with enabled viscoelastic
attenuation, a **single sharp bilayer** now automatically forwards its
normal, offset and both constitutive phase speeds to the extended 3D
solver. Extended-grid nodes are classified directly by that plane rather
than resampling the observation grid's material labels. General map-based
and other geometries remain on nearest-neighbor sampling.

For comparison, set `propagation.solver_options.SpeedSampling` to
`"nearest_map"` to opt out of geometric sampling for this case. Direct
calls to `solveExtended` can pass `SpeedInterfacePlane` to opt in.
Neither method analytically enforces interface jump conditions inside
Fast Sweeping; both still approximate first-arrival Eikonal on a grid.

Tests (MATLAB):
```matlab
r=runtests('tests/physics/swsynth/propagation/test_eikonal_geometric_bilayer_orientation.m');
disp(table(r)); assertSuccess(r)
```

These regressions include an inclined plane with a truly off-plane source,
an analytically exact optical-depth case, and a refracted-ray Fermat
reference (diagnostic errors printed; no arbitrary error threshold yet).

### Elastic SH reflection/transmission at a welded planar interface

The independent function
`swsynth.propagation.interface.shCoefficients(request)` computes
complex displacement reflection/transmission coefficients for a
**monochromatic elastic SH plane wave** incident on a welded plane separating
two homogeneous isotropic elastic half-spaces. The boundary conditions are
continuous tangential displacement and continuous tangential traction.
Tangential wavenumber is conserved (Snell refraction). The outgoing normal
wavenumber is chosen with nonnegative imaginary part, allowing an evanescent
transmitted wave above the critical angle.

Input properties are `frequency_hz`, `incidence_angle_rad`,
`mu1_pa`, `rho1_kg_m3`, `mu2_pa`, and `rho2_kg_m3`.
Reported fractions of incident *normal energy flux* satisfy
`reflection_energy_fraction + transmission_energy_fraction = 1`
for lossless elastic media, including total internal reflection.

This first-stage component is **not yet wired into spherical-source synthesis
or 3D polarization**, and does not simulate reflected wavefields.
It does **not** model SV/P conversion, Kelvin-Voigt complex viscoelastic
interface impedance, imperfect bonding, or arbitrary curved interfaces.
Existing Eikonal/attenuation wavefield behavior is unchanged.

```matlab
r=runtests('tests/physics/swsynth/propagation/test_sh_interface_coefficients.m');
disp(table(r)); assertSuccess(r)
```

### Kelvin-Voigt SH interface coefficients (isolated analytical module)

`swsynth.propagation.interface.shViscoelasticCoefficients` computes
complex displacement reflection/transmission for welded, isotropic,
homogeneous Kelvin-Voigt half-spaces and a plane SH wave. It uses the
`exp(i*(k.r-omega*t))` convention, so the dynamic modulus in traction
is `mu - i*omega*eta`, conjugate to the commonly written
`mu + i*omega*eta` for a `exp(+i*omega*t)` time convention.
Its complex wavenumbers decay along outgoing propagation directions.

For oblique lossy incidence, the tangential wavenumber is complex and
continuous across the plane. The input real incidence angle defines a
homogeneous complex incident plane wave. In attenuating media, there is
no general `R_energy + T_energy = 1` identity for separately interpreted
incident/reflected normal energy fluxes, so this function deliberately
does not report energy fractions. Its checks instead enforce complex
displacement and traction continuity. The elastic limit must match
`shCoefficients`, including an evanescent transmitted field above
critical incidence. Not integrated with spherical-source synthesis.

```matlab
r=runtests('tests/physics/swsynth/propagation/test_sh_viscoelastic_interface_coefficients.m');
disp(table(r)); assertSuccess(r)
```

### Controlled SH Kelvin-Voigt incident/reflected/transmitted fields

Standalone demonstrator:
`swsynth.propagation.interface.simulateSHPlaneInterface(request)`.
For a plane interface `x=interface_x_m`, it returns complex harmonic SH
displacement maps `incident_uy_zx`, `reflected_uy_zx`,
`transmitted_uy_zx`, and `total_uy_zx`, each on `z_m` by `x_m`.
With `interface_enabled=true`, the incident and reflected contributions
exist on the incident side and the transmitted contribution on the other
side. With `interface_enabled=false` (default), the incident medium-1
wave continues through the entire grid without any interface: this is a
**no-interface reference**, not a model of physical transmission through
material 2 with the reflection suppressed.

This is an independently callable *plane SH* example, not a new field
inside the general scenario JSON schema. Existing simulation scenarios
retain their prior behavior and do not automatically emit reflected waves.
Attenuating plane-wave amplitudes are referenced at the interface and
should not be read as a finite-distance point-source excitation.
See:
`examples/swsynth/v2/08_shear_attenuation/demo_controlled_sh_interface.m`.

```matlab
r=runtests('tests/physics/swsynth/propagation/test_controlled_sh_plane_interface.m');
disp(table(r)); assertSuccess(r)
run('examples/swsynth/v2/08_shear_attenuation/demo_controlled_sh_interface.m')
```

### Opt-in SH plane interface in V2 synthesis

The main `swsynth.propagation.synthesize` now accepts
`propagation.interface.enabled=true` for a **single projected3d plane
SH wave**, positive x incidence, explicit [0,1,0] polarization,
a single sharp x-normal bilayer, and Kelvin-Voigt constituents with
their `mu_pa`, `eta_pa_s`, `density_kg_m3` specified. A dedicated
controlled analytical route produces the full vector `U_xyz`, and
`result.interface_components` contains incident, reflected, transmitted
and total complex scalar SH maps. Unsupported geometries and
polarizations are rejected rather than processed with SH coefficients.

Omitting `propagation.interface`, or setting
`propagation.interface.enabled=false`, preserves the **existing
general synthesis route**. In that route, a heterogeneous Eikonal
simulation can refract and attenuate, but does not generate reflected
waves or apply SH boundary transmission factors. Switching to false
does NOT implicitly convert a heterogeneous scenario into a uniform
no-interface reference; that reference is available separately in
`simulateSHPlaneInterface`.

When enabled, `propagation.interface.reference_x_m` and
`reference_z_m` are optional. `reference_x_m` must be upstream of
the interface. The incident amplitude is referenced there, with
`incidence.relative_amplitude` as the magnitude; default reference
is at the interface. The phasor phase is then shifted by
`incidence.phase_rad`. This is a plane-wave reference, not a finite
aperture or point-source radiation model.

Example:
`examples/swsynth/v2/08_shear_attenuation/plane_sh_kelvin_voigt_interface_optin.json`.
Validation:
```matlab
r=runtests('tests/physics/swsynth/propagation/test_sh_synthesis_interface_optin.m');
disp(table(r)); assertSuccess(r)
```

### Elastic P-SV mode conversion (isolated coefficients)

`swsynth.propagation.interface.psvElasticCoefficients` solves four
continuity equations (x/z displacement and normal/shear traction)
for **SV incidence on a welded x-normal plane** in isotropic elastic
half-spaces. It returns reflected/transmitted **P and SV displacement
amplitudes**, boundary residual, and normal energy-flux fractions.
Inputs include both P and S velocities, densities, frequency and incidence
angle. Complex normal wavenumbers allow evanescent converted P branches.

This model must **not** be inferred from shear velocity or Kelvin-Voigt
shear modulus alone: P-wave properties (bulk response) are also needed.
The implementation is deliberately *not* integrated into the generic
synthesis pipeline, which remains SH-only for active interface amplitudes.
It does not simulate finite sources, P/SV vector fields, curved surfaces,
or viscoelastic P-SV interactions.

```matlab
r=runtests('tests/physics/swsynth/propagation/test_psv_elastic_interface_coefficients.m');
disp(table(r)); assertSuccess(r)
```
