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

The 3D Eikonal kernel supports `SpatialOrder=1` (unchanged default) or
`SpatialOrder=2` (causality-limited one-sided second-order differences,
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
orders. Order 2 is experimental: neither improved accuracy nor convergence
has been established until this comparison is run. Do not change the
default based only on solver convergence.
