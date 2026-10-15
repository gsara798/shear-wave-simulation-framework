# Coherent propagation accumulator V2

**Status:** new additive API implemented; MATLAB tests to be run locally. Existing synthesizers are unchanged.

Entrypoint: `wavefield = swsynth.propagation.accumulate(contributions,options)`.

## Purpose

The accumulator adds already-computed **complex vector wave contributions**:
`U_total(r) = normalization_factor * sum_n U_n(r)`.

It does not compute phase, polarization, amplitude, source positions, source radiation, material attenuation, acquisition effects, random noise, or measurement projection. Each `plane_wave.computeContribution` output already includes its amplitude, phase, and polarization. Applying them again during accumulation would be a physics error.

### Inputs

- `contributions`: nonempty 1-by-N / N-by-1 struct array or cell array of scalar structs from `swsynth.propagation.plane_wave.computeContribution`. Cell arrays are useful when constructing independent contributions in loops.
- `options`: optional scalar struct with `normalization="none"` (default) or `"sqrt_count"`. The latter applies `1/sqrt(N)` **to the entire coherent sum**. It is useful for the historical unit-amplitude incoherent-ensemble convention, but does **not** guarantee equal power for coherent fields, correlated amplitudes, or different polarizations.

The accumulator rejects mixed `geometry`, mixed `frequency_hz`, mixed `phase_sign`, incompatible array dimensions, or **different coordinate axes even when shapes match**. Axes are carried by each contribution as `x_m`, `z_m`, optionally `y_m`, avoiding ambiguous overlap between shifted fields. Frequency/coordinate consistency is exact; the caller should generate all contributions on one shared grid.

The supported contributions are currently `model="plane_wave"` with spatial geometry `2d`/`planar2d`, `projected3d`, or `volumetric3d`. A future spherical component requires a compatible vector-field contract but should not be mixed with plane waves implicitly until the synthesis adapter defines common phase and normalization semantics.

### Example: two coherent planar waves

```matlab
req=struct();
req.geometry="2d";
req.direction_xyz=[1 0 0];
req.frequency_hz=500;
req.phase=struct("method","analytical", ...
    "reference_cs_m_s",2, ...
    "x_m",0:0.0005:0.01, "z_m",0:0.0005:0.01);
req.polarization=struct("policy","in_plane_sv");

req.phase_rad=0;
a=swsynth.propagation.plane_wave.computeContribution(req);
req.phase_rad=pi/2;
b=swsynth.propagation.plane_wave.computeContribution(req);

wavefield=swsynth.propagation.accumulate({a,b}, ...
    struct("normalization","sqrt_count"));
observedZ=swsynth.observation.projectComponent(wavefield.U_xyz,[0 0 1]);
```

### Output

```matlab
wavefield.U_xyz                   % complex [Nz,Nx,3] or [Nz,Ny,Nx,3]
wavefield.component_count
wavefield.geometry
wavefield.frequency_hz
wavefield.phase_sign
wavefield.normalization            % none / sqrt_count
wavefield.normalization_factor     % 1 or 1/sqrt(N)
wavefield.x_m
wavefield.z_m
wavefield.y_m                      % volumetric3d only
wavefield.output_convention
```

No scalar field `U_zx` is generated inside `accumulate`. Projection along an observation sensitivity axis belongs to `swsynth.observation.projectComponent`. In general the sum of differently polarized vector waves cannot be represented by one common scalar polarization factor.

## Reproducibility, scope and numerical conventions

- Accumulation is deterministic, preserves order of addition, performs the sum in double precision, and generates no random draws. Different summation orders can differ slightly from floating-point rounding; a later large-N implementation could consider compensated summation if needed.
- No hidden `1/sqrt(N)` factor: the caller explicitly opts in. Each individual wave's amplitude is already included.
- Uses the same `phase_sign=+1` spatial phasor convention as the existing single-wave V2 function. Frequency and phase convention must match to coherently sum monochromatic phasors.
- Input validation is strict and one mismatching component fails the whole call; no interpolation, resampling, mode conversion or silent coordinate alignment.
- The result is a wavefield-level **vector phasor**, not yet a time series, displacement/velocity-specific quantity or ultrasound readout. Input amplitudes must refer to the same physical quantity and units; unit annotations can be added to a future full synthesis contract.

MATLAB tests: `tests/unit/test_swsynth_propagation_accumulate_v2.m`, plus `test_swsynth_plane_wave_contribution_v2.m`. No production synthesizer is switched to this new path yet.
