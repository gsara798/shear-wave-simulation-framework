# Stage 4: monofrequency power-law attenuation

Stage 4 reproduces a requested attenuation law across independent elastic
simulations:

\[
\alpha(f)=\alpha_\mathrm{ref}(f/f_\mathrm{ref})^y.
\]

Every k-Wave run still contains one excitation frequency. The implementation
does not claim that `pstdElastic2D` supports an arbitrary power law within one
time-domain field. k-Wave 1.4.1 uses Kelvin–Voigt absorption, whose frequency
dependence is quadratic. At each requested `f0_hz`, `kwsim` therefore computes

\[
\alpha_\mathrm{KV}=\frac{\alpha(f_0)}{(f_0/10^6)^2}
\quad [\mathrm{dB/(MHz^2\,cm)}].
\]

This makes the requested and solver attenuation identical at `f0_hz`; onset
transients and any harmonics continue to follow the Kelvin–Voigt model.

## Configuration and units

```matlab
cfg = kwsim.two_d.stage4Config();
cfg.attenuation.materials = kwsim.materials.makeAttenuationMaterial(1, ...
    ShearAlphaRefDbCm=1.0, ShearReferenceFrequencyHz=500, ...
    ShearPowerY=1.2, CompressionAlphaRefDbCm=0.1, ...
    CompressionReferenceFrequencyHz=500, CompressionPowerY=1.2);
```

Each rasterized material ID must have exactly one definition when attenuation
is enabled. P and S laws are separate because `pstdElastic2D` requires both
`alpha_coeff_compression` and `alpha_coeff_shear`. The resolved result stores
target maps in dB/cm, solver maps in dB/(MHz² cm), and the effective `eta` and
`chi` viscosity maps in Pa s.

The preflight rejects missing or duplicate material IDs, negative laws,
non-finite conversions, and combinations that yield negative viscosity. An
enabled map must be strictly positive. Use `attenuation.enabled=false` for a
genuinely lossless simulation; in that mode no absorption fields are passed to
k-Wave.

The reference compression coefficient is deliberately smaller than the shear
coefficient. With `reduced_cp/cs = 10`, 0.1 dB/cm at 500 Hz damps weak
compressional contamination without the excessive volumetric stiffness of
using the 1 dB/cm shear value. It is a numerical benchmark choice, not a
tissue compressional-attenuation claim.

## Viscous stability

Kelvin–Voigt terms introduce a stricter explicit stability restriction than
the lossless wave CFL. The validated Stage 4 implementation requires
`grid.cfl <= 0.025`. A compact experiment at the lossless default `CFL=0.2`
produced non-finite fields and was correctly rejected. At `CFL=0.025`, the
same 500 Hz test was stationary and finite.

The reference attenuation grid is 64 by 48 points at 0.5 mm spacing. This is
a deliberate memory choice: eight recorded cycles at `CFL=0.025` on the
96-by-96 directional homogeneous sensor exceed the strict 2 GiB preflight limit, whereas the
32-by-24 mm Stage 4 domain retains enough propagation distance for the fit.

## Matched attenuation measurement

For every frequency, `runFrequencySweep` runs an attenuated and a lossless
case with identical grid, duration, seed, source realization, sensor ROI, and
PML. The diagnostic computes

\[
L(x)=20\log_{10}\left(A_0(x)/A_\alpha(x)\right),
\]

so matched geometric spreading cancels. The full vector-shear magnitude is
RMS-averaged in a narrow strip around the source depth and fitted against
lateral propagation distance in cm. The axial-only fit is saved as a
secondary ultrasound-like measurement. Low-amplitude points and the source
region are excluded. The last 1.5 shear wavelengths before the downstream
edge are also excluded so small phase-dependent PML reflections do not bias
the fitted attenuation slope.

The acceptance benchmark is deliberately homogeneous and directional.
Interference in diffuse fields can invalidate a simple spatial attenuation
slope even when the solver attenuation itself is correct.

The reference uses one prescribed-velocity contact node. This avoids the
known late-time coupling between multiple Dirichlet nodes during the longer
low-frequency runs. Its cylindrical spreading is not mistaken for attenuation
because every measurement is divided by the exactly matched lossless field.

## Sweep and outputs

```matlab
cfg = kwsim.two_d.stage4Config();
sweep = kwsim.two_d.runFrequencySweep( ...
    cfg, [300, 400, 500], 'outputs/stage4_power_law');
```

Each frequency directory contains independent attenuated and lossless MAT
files plus the standard field diagnostics. `attenuation_diagnostics.png`
shows the requested map, Kelvin–Voigt coefficient, axial amplitude and phase,
matched loss map, and spatial fit. The sweep root contains `sweep_index.mat`,
`stage4_summary.txt`, and `stage4_power_law.png`.

The strict acceptance gates are:

- attenuation error at every `f0_hz` no greater than 5%;
- absolute recovered-exponent error no greater than 0.05;
- shear phase-speed change relative to lossless no greater than 2%;
- spatial attenuation-fit `R²` at least 0.98;
- all normal source, PPW, finite-field, and stationarity checks pass.
