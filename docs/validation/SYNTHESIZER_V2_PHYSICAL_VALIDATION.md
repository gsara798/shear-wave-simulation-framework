# V2 synthesizer: physical and spectral validation campaign

**Status:** analysis script and independent automated physics tests implemented on `develop/v2`; **MATLAB execution and visual inspection remain pending**. This is an additive diagnostic: it does not modify the legacy synthesizers or generate REQ-ML training data.

## Purpose

A unit-test pass confirms software contract behavior, not that a synthetic wavefield has the physical spatial and spectral structure required by REQ-ML. This validation checks wave number, constructive/destructive coherence, and controlled directional spreading in the **observed axial projection**.

Run from repository root:

```matlab
!git pull --ff-only
addpath(fullfile(pwd,"src"));
addpath(fullfile(pwd,"analysis","synthesizer_v2"));
report=validate_wavefields_v2();
```

The script writes three PNG panels, `validation_report.mat`, and `metrics_summary.csv` into `results/synthesizer_v2_validation`. Figures are created invisible and closed after exporting. To disable all files and figures (e.g. in CI/tests):

```matlab
report=validate_wavefields_v2( ...
    struct("MakeFigures",false,"SaveResults",false));
```

To save elsewhere, supply `options.OutputDir`. The report includes each original scenario, full synthesized vector field, observed axial phasor `Uz`, its complex-FFT diagnostics, the scenario summary table, and physical comparison metrics.

Automated test:

```matlab
results=runtests("tests/unit/test_swsynth_synthesis_physics_v2.m");
disp(table(results))
assertSuccess(results)
```

## Three controlled cases

All cases: homogeneous isotropic elastic `cs=2 m/s`, `f=500 Hz`, `lambda=cs/f=4 mm`, `k0=2*pi*f/cs=1570.796 rad/m`, sample spacing `dx=dz=0.2 mm`, `120 x 120` grid with 20 pixels per wavelength. Spatial axes are `0 : 0.2 mm : 23.8 mm`. The 24-mm *sampling period* (`120*dx`) contains exactly six wavelength cycles for a purely +x plane wave; using 120 samples avoids a Fourier leakage artefact in the key single-wave test.

**A. Directional single plane wave:** one +x incident wave; in-plane SV polarization yields axial `Uz=-exp(+i*k0*x)`. Expect one sharp positive-`kx` peak of the **complex** FFT, `k_peak=k0`, `cs_from_peak=2 m/s`, and annular angular resultant nearly one. This is an algebraic *spatial phasor* under the current positive spatial phase convention.

**B. Two coherent spherical point-force sources:** projected3d x-z observation plane at `y=0`, source positions `[-12,0,12]` mm and `[36,0,12]` mm, axial unit force `[0,0,1]` for both, equal amplitudes, phases `[0,pi]`. Each contribution follows the 3D shear far-field angular radiation pattern. At `[x,z]=[12,12]` mm, the distances and radiation weights match while the phases differ by pi, so **axial motion cancels** up to floating-point precision. Away from that symmetric point, wavefront curvature and interference produce spatial structure. The geometric decay exponent is 0 for consistency with the historical relative-amplitude synthetic model, **not** a calibrated 3D Green-function amplitude. This is **not** cylindrical 2D radiation.

**C. Partially angular multi-plane-wave ensemble:** thirty independent 2D plane waves with propagation angles uniformly distributed from -80 to +80 degrees around +x, equal input amplitudes, reproducibly drawn phases from local `RandStream("mt19937ar","Seed",53053)`, `normalization="sqrt_count"`. This is **partially angular/directional** propagation, *not* completely diffuse isotropic 2D/3D motion. Its axial observed spectrum should have a lower annular angular resultant than case A and remain clustered near the expected k ring. Source phases consume only the local stream, not MATLAB's global RNG.

## Diagnostic definition and interpretation

`swsynth.diagnostics.analyzeSpectrum2D(Uz,x_m,z_m,f,cs)` computes the unwindowed **complex** 2D FFT power (no zero-padding, Hann window, radial smoothing, radial interpolation or RF/IQ simulation). Radial/angular positions are physical rad/m from the uniform grid. It returns:

- `expected_wavenumber_rad_m` and `expected_wavelength_m`
- annular peak `peak_wavenumber_rad_m` and implied `sws_from_peak_m_s`
- `annular_energy_fraction`: fraction of total 2D power with `0.8*k0 <= |k| <= 1.2*k0`
- `angular_resultant`: `|sum(E_j * exp(i*theta_j))| / sum(E_j)`, for FFT bins in that annulus. It is near 1 for a concentrated **single signed propagation direction** and smaller for energy distributed around the circle.
- `radial_energy_fraction`: power **per radial bin** normalized by total FFT energy, without dividing by the annulus area. It should not be treated as radial density or directly as a REQ radial CDF.
- `axial_rms`, `axial_peak_amplitude`, complex power spectrum and wavenumber axes.

The `k_peak` metric is a direct diagnostic for a single plane wave. In coherent multi-source or partially angular fields the peak is not an unbiased universal SWS estimator; quantify ring support, angular distribution, cross-phase interference and spatial variation instead. Angular resultant is affected by the **measurement projection** and the finite FOV: it is not automatically an estimate of the underlying 3D diffusivity.

All images: real part of spatial axial **phasor** at the chosen phase reference (not a calibrated motion snapshot without a temporal sign convention); magnitude; log complex FFT power, with expected shear-wave ring; and radial-bin energy. The complex FFT has a *signed* propagation peak. Taking FFT of the real part would produce conjugate ±k peaks: **do not confuse that display effect with true two-direction incidence**.

## Required physical checks and what remains

Automated tests verify the analytically exact single-plane-wave `k0` and phasor phase gradient, point-source cancellation at the symmetry pixel, broadened angular support for the finite-aperture directional ensemble, FFT energy normalization, deterministic random phases, and invalid-grid/zero-spectrum handling.

These checks do **not** yet establish:
- equivalence with all legacy wavefields, especially at fixed source RNG seeds;
- validity of simulated viscoelastic shear attenuation, scattering, reflection, mode conversion, anisotropy, heterogeneous spherical Eikonal, or acoustic ultrasound measurement effects;
- correct partial/diffuse **projected 3D** radiation statistics; current ensemble is planar2d;
- spatially resolved ground-truth `q_oracle` or REQ-ML prediction performance;
- calibration of actuator force to physical displacement/velocity units;
- throughput/memory safety for production 3D datasets.

**Before generating REQ-ML datasets**, inspect the three figures, run the entire V2 unit suite, compare a few fields directly with known analytic/legacy cases under matched physics, and define broader angular/source geometry campaigns and stable output metadata. A subsequent validation should include counterpropagating pairs, near-isotropic planar and projected3d fields, heterogeneous media with supported solvers, interfaces and SNR perturbations.
