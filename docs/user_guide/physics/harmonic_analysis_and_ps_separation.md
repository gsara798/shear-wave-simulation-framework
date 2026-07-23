# Harmonic Analysis and P/S Separation

This document explains how the framework converts time-domain elastic
simulations into complex harmonic fields and how it evaluates shear-wave
dominance relative to compressional contamination.

## 1. Time-domain simulation

The elastic solver produces particle-motion fields as functions of space and
time.

Conceptually:

```text
u(x,y,z,t)
v(x,y,z,t)
```

where the recorded quantity may be displacement, velocity, or another
solver-supported field.

The source oscillates at a prescribed frequency:

```text
f0
```

but the simulated time series can also contain:

- startup transients;
- broadband ramp content;
- reflections;
- compressional components;
- shear components;
- numerical noise;
- a DC offset;
- late-time interference.

For this reason, the saved harmonic field is not obtained by taking one
arbitrary time frame.

## 2. Settling and analysis intervals

The simulation timing separates field development from harmonic estimation.

Typical parameters are:

```json
"time": {
  "settling_cycles": 2,
  "analysis_cycles": 8
}
```

### Settling cycles

The settling interval allows:

- the source ramp to progress;
- waves to reach the region of interest;
- startup transients to decrease;
- the field to approach periodic behavior.

### Analysis cycles

The analysis interval provides the samples used to estimate the complex field at
`f0`.

More analysis cycles can improve frequency selectivity and estimation
robustness, but they increase simulation time and stored data requirements.

## 3. Harmonic representation

At one spatial location, an approximately harmonic signal can be written as:

```text
s(t) = a cos(2*pi*f0*t) + b sin(2*pi*f0*t) + c
```

where:

```text
a, b = harmonic coefficients
c    = temporal mean or DC component
```

The same signal can be represented by a complex phasor:

```text
S = a - i b
```

under the convention:

```text
s(t) = real(S * exp(i*2*pi*f0*t)) + c
```

The phasor contains:

```text
amplitude = abs(S)
phase     = angle(S)
```

A spatial collection of phasors forms the complex harmonic field.

## 4. Least-squares harmonic extraction

The current 3D configuration defaults include:

```json
"analysis": {
  "harmonic_method": "least_squares",
  "temporal_window": "none",
  "remove_mean": true
}
```

With least-squares extraction, each temporal signal is fitted to basis
functions at the known source frequency.

Conceptually, the fit uses:

```text
cos(2*pi*f0*t)
sin(2*pi*f0*t)
optional constant term
```

Advantages include:

- direct estimation at the known excitation frequency;
- use of all selected temporal samples;
- explicit treatment of the temporal mean;
- no requirement that the analysis interval contain an exact FFT bin;
- natural production of a complex phasor.

The result represents only the component at `f0`, not the complete temporal
signal.

## 5. Mean removal

A configuration may use:

```json
"remove_mean": true
```

This removes or fits the temporal DC component before estimating the harmonic
field.

Mean removal helps prevent static offsets from contaminating the estimate at the
source frequency.

It does not remove unrelated oscillatory frequencies.

## 6. Temporal window

The temporal-window setting controls whether samples receive equal or varying
weights during harmonic estimation.

The current baseline uses:

```json
"temporal_window": "none"
```

This means the selected analysis samples are not additionally tapered.

A temporal window can reduce edge discontinuities, but it also changes the
effective weighting and amplitude calibration.

Alternative windows should be documented only after being validated in the
executable workflow.

## 7. Complex field interpretation

For a complex field `U`:

```text
abs(U)
```

is the harmonic amplitude.

```text
angle(U)
```

is the wrapped harmonic phase.

The real part:

```text
real(U)
```

corresponds to one phase reference of the oscillation.

A time frame can be reconstructed approximately as:

```text
u(t) = real(U * exp(i*2*pi*f0*t))
```

up to any separately stored mean component and the exact convention used by the
analysis routine.

## 8. Phase and propagation

For an approximately traveling wave:

```text
U(r) = A(r) exp(-i k dot r)
```

The spatial phase gradient contains wavenumber information.

In a simple homogeneous directional field:

```text
|k| = 2*pi / lambda
cs  = 2*pi*f0 / |k|
```

In multi-directional or heterogeneous fields, one local phase gradient may not
represent all contributing waves.

This is one reason spectral estimators such as REQ are useful.

## 9. Harmonic amplitude

The phasor magnitude reflects the component of motion at `f0`.

Amplitude depends on:

- source amplitude;
- source distance;
- material properties;
- geometric spreading;
- reflection and transmission;
- interference;
- attenuation when enabled;
- measured motion component.

Amplitude should not be interpreted as a direct experimental displacement
prediction unless actuator coupling and measurement physics are also modeled.

## 10. Vector elastic field

An elastic 3D simulation may contain three particle-motion components:

```text
Ux
Uy
Uz
```

These are vector components of one physical field.

A field component should not automatically be identified as a P wave or S wave.

For example:

```text
Uz != shear component in every geometry
Ux != compressional component in every geometry
```

P/S classification depends on the relationship between motion and spatial
propagation, not only on coordinate labels.

## 11. P and S waves

### Compressional wave

For a P wave, particle motion is predominantly parallel to the propagation
direction.

### Shear wave

For an S wave, particle motion is predominantly perpendicular to the
propagation direction.

In a general 3D wavefield, multiple propagation directions may coexist at the
same location.

Therefore P/S separation is naturally a vector-field decomposition problem.

## 12. Helmholtz decomposition

A vector field can conceptually be separated into:

```text
irrotational component
solenoidal component
```

The irrotational component is associated with compressional motion.

The solenoidal component is associated with shear motion.

For displacement field `u`:

```text
P-related content  <-> divergence(u)
S-related content  <-> curl(u)
```

More formally:

```text
u = grad(phi) + curl(Psi)
```

subject to boundary conditions and decomposition assumptions.

This relationship motivates P/S energy diagnostics.

## 13. Spectral P/S projection

In spatial Fourier space, let:

```text
U(k)
```

be the vector-field spectrum and:

```text
k_hat = k / |k|
```

the unit wavevector.

The longitudinal projection is:

```text
U_P = k_hat * (k_hat dot U)
```

The transverse projection is:

```text
U_S = U - U_P
```

This separates each nonzero spatial-frequency component according to whether
motion is parallel or perpendicular to its wavevector.

At `k = 0`, the direction is undefined and must be handled separately.

## 14. P/S energy ratio

A P/S energy diagnostic compares compressional and shear content.

Conceptually:

```text
E_P = sum |U_P|^2
E_S = sum |U_S|^2
P/S ratio = E_P / E_S
```

A smaller ratio indicates a more shear-dominant field.

For the verified homogeneous 2D directional run:

```text
P/S energy ratio = 0.0004974
```

with a configured maximum threshold of:

```text
0.05
```

The run passed this check.

The exact calculation region, spectral handling, and threshold are part of the
validation implementation and case definition.

## 15. Why P/S contamination is not zero

Even a source designed to launch transverse motion can generate nonzero
compressional content because of:

- finite source aperture;
- boundary constraints;
- near-field structure;
- source discretization;
- heterogeneous interfaces;
- reflections;
- oblique incidence;
- mode conversion;
- numerical approximation.

The correct approach is to measure contamination rather than assume ideal
purity.

## 16. Source fundamental fraction

The source waveform itself is checked for frequency purity.

A typical diagnostic is:

```text
source fundamental fraction
```

Conceptually:

```text
energy at f0 / relevant source-signal energy
```

A value near one indicates that the stationary source is dominated by the
intended harmonic frequency.

The verified 2D reference run reported:

```text
source fundamental = 1.000000
```

This check concerns the source waveform, not the full propagated wavefield.

## 17. Steady-state change

The framework evaluates whether the late-time harmonic field is stable.

Conceptually, the analysis interval can be divided into late-time groups and
their harmonic estimates compared.

A relative-change metric can be written schematically as:

```text
||U_late_2 - U_late_1|| / ||U_late_1||
```

A small value indicates that the estimated harmonic field is no longer changing
substantially over successive late-time intervals.

The verified 2D reference run reported:

```text
steady-state change = 2.014e-05
```

with a threshold of:

```text
0.01
```

The run passed this check.

## 18. Finite-field validation

Before interpreting amplitude, phase, or spectra, the framework checks that
harmonic fields are finite.

The check rejects fields containing:

```text
NaN
Inf
```

A finite field is necessary but not sufficient for physical validity.

## 19. Shear-speed validation in a directional field

For the homogeneous directional benchmark, a phase-gradient estimate provides a
simple independent speed check.

The verified case used:

```text
truth cs = 2.0000 m/s
estimated cs = 2.0043 m/s
relative error = 0.214%
```

This validation is appropriate because the field is homogeneous and strongly
directional.

The same phase-gradient method should not automatically be treated as ground
truth for a broad angular or mixed heterogeneous field.

## 20. Cross-polarization and longitudinal leakage

A source has an intended polarization and propagation direction.

Diagnostics may evaluate:

```text
cross-polarization ratio
longitudinal leakage ratio
```

Cross-polarization measures motion outside the intended transverse polarization.

Longitudinal leakage measures motion aligned with the intended propagation
direction.

These are useful source-specific diagnostics, while full P/S separation
evaluates the total vector field more generally.

## 21. Central-plane analysis

A 3D simulation may export a central x-z plane.

The plane contains only a subset of the full volumetric field.

Consequences:

- out-of-plane gradients are not directly represented;
- volumetric P/S separation cannot always be reconstructed from one plane;
- a projected component may mix contributions from several 3D directions;
- central-plane angular statistics can differ from full-volume statistics.

A 2D exported field should therefore be described as a plane or projection of
the 3D field, not as the complete 3D wavefield.

## 22. Measured component versus full vector field

Ultrasound elastography often emphasizes one measured displacement component,
commonly axial motion.

The simulation may provide:

```text
full vector field
one selected component
central-plane component
```

These serve different purposes.

The full vector field is needed for the most complete P/S analysis.

A single component can be appropriate for emulating a measurement or for
external REQ processing, but it does not contain all vector information.

## 23. Displacement and velocity phasors

If velocity phasor `V` and displacement phasor `U` use the same harmonic
convention, they are related by:

```text
V = i*omega*U
```

or equivalently:

```text
U = V / (i*omega)
```

where:

```text
omega = 2*pi*f0
```

The sign depends on the adopted complex-exponential convention.

Conversions must preserve the convention used by the implementation.

## 24. Harmonic field for REQ

REQ operates on a spatial complex field at one temporal frequency.

The exported sample therefore needs:

- complex field values;
- known `f0`;
- known spatial spacing;
- documented orientation;
- sufficient field dimensions;
- valid truth metadata when available.

The harmonic extraction stage separates the desired temporal frequency before
REQ analyzes spatial wavenumber content.

## 25. Why temporal and spatial Fourier analysis are different

Temporal harmonic extraction answers:

```text
What part of the signal oscillates at f0?
```

Spatial spectral analysis answers:

```text
Which spatial wavenumbers and directions are present at f0?
```

The workflow is:

```text
time-domain simulation
-> temporal extraction at f0
-> complex spatial field
-> spatial spectrum
-> wavenumber or REQ analysis
```

A temporal FFT alone does not estimate shear-wave speed.

## 26. Windowing in spatial analysis

Temporal windowing and spatial windowing are different.

Temporal windowing weights samples across time during harmonic extraction.

Spatial windowing weights samples across the local analysis region before
computing a spatial spectrum.

Both can affect spectral leakage, but they operate in different domains.

## 27. Harmonic extraction limitations

A single-frequency phasor does not preserve:

- transient evolution;
- broadband content;
- source ramp history;
- arrival times;
- separate source contributions;
- nonlinear harmonics;
- frequency-dependent behavior outside `f0`.

Save time series when these quantities are required.

## 28. P/S separation limitations

P/S decomposition can be affected by:

- finite ROI;
- window boundaries;
- spatial sampling;
- missing vector components;
- heterogeneous material gradients;
- PML proximity;
- spectral leakage;
- zero-wavenumber handling;
- reflected and evanescent fields.

The reported P/S ratio should be treated as an operational diagnostic defined by
the implemented analysis, not as an exact universal invariant.

## 29. Recommended validation sequence

For a harmonic result:

```text
1. Confirm preflight passed.
2. Confirm source fundamental fraction passed.
3. Confirm all harmonic fields are finite.
4. Confirm steady-state change passed.
5. Inspect P/S or leakage metrics.
6. Inspect amplitude and phase figures.
7. Inspect speed validation when the case supports it.
8. Inspect the resolved configuration.
9. Preserve the validation report.
```

## 30. Recommended reporting

For harmonic-field results, report:

```text
source frequency
source ramp cycles
settling cycles
analysis cycles
harmonic extraction method
temporal window
mean-removal setting
recorded physical quantity
vector component or full vector field
P/S diagnostic method
analysis ROI
steady-state metric
validation thresholds
```

## 31. What the analysis represents

The current harmonic workflow represents:

- temporal reduction at the known source frequency;
- complex amplitude and phase;
- late-time harmonic stability;
- shear-versus-compressional diagnostics;
- preparation of spatial fields for external wavenumber analysis.

## 32. What it does not automatically establish

A valid harmonic field does not automatically establish:

- experimental realism;
- perfect P/S separation;
- ideal diffusivity;
- accurate local SWS in mixed regions;
- accurate attenuation;
- correct ultrasound measurement physics;
- absence of discretization error.

These require separate validation.

## 33. Summary

The analysis pipeline is:

```text
run time-domain elastic simulation
-> exclude startup-dominated data
-> estimate complex field at f0
-> check frequency purity and steady state
-> separate or quantify P and S content
-> save amplitude, phase, and validation products
-> export selected field for spatial analysis
```

The key distinction is:

```text
temporal harmonic extraction identifies the field at f0
spatial analysis identifies the wavenumber content of that field
```
