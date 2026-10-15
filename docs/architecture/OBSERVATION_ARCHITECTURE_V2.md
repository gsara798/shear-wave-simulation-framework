# Observation architecture — generic projection implemented; ultrasound planned

## Separation from mechanical wavefield physics

The mechanical simulation should be capable of returning physical vector displacement/velocity `U_xyz(r,t)` or phasors. **Observation** converts that physical field into what a measurement modality can detect, while preserving provenance and units.

Proposed packages:

```text
+swsynth/
    +observation/
        projectComponent.m        % IMPLEMENTED: generic sensitivity-axis projection
        sampleSpaceTime.m         % generic finite FOV, grid and temporal sampling
        validate.m               % common observation contract
        +ultrasound/
            simulate.m            % future orchestrator
            +acoustics/
                attenuation.m    % MHz ultrasound, pulse-echo propagation
                beamProfile.m    % PSF, focus, aperture
            +signal/
                simulateIQ.m     % RF/IQ scatterer motion, PRF, clutter, noise
            +displacement/
                estimate.m       % Loupas / phase-shift or other readout
            +artifacts/
                motion.m         % probe/body motion, optional
        +oct/
        +mre/
```

Do **not** implement arbitrary ultrasound attenuation as a scalar damping applied to the mechanical displacement field. **Shear-wave mechanical attenuation** belongs to `propagation` / the viscoelastic medium and changes the actual wavefield. **Ultrasound acoustic attenuation** operates at MHz on transmit/receive echoes (depth/path/frequency-dependent acoustic pressure, usually two-way in pulse-echo), affecting RF/IQ signal amplitude, SNR and the performance of motion estimation. An idealized model without RF/IQ should document an evidence-based depth/quality-dependent measurement noise/bias assumption, not silently rescale true tissue motion.

Recommended incremental implementation:
1. **Implemented:** `observation.projectComponent(vectorXYZ,axisXYZ)` returns the signed scalar component of N-by-3 or spatial arrays with xyz in the last dimension. Preserves complex phasors and units. Tests: `test_swsynth_observation_projection_v2.m`.
2. Define ideal observation and ROI/FOV/time sampling with explicit output units.
3. Next, add `observation.ultrasound` as an **ideal ultrasound axial velocity/displacement readout** using the shared projection and explicit probe orientation, PRF and spatial sampling, with no fictitious attenuation. **No `+ultrasound` implementation has been added yet.**
4. Only after defining an RF/IQ model, introduce MHz acoustic attenuation, scatterer density, transmit/receive beam, TGC, receive noise, PRF, clutter and tracking estimator. Validate against experiments where possible.

Future data flow: `sources` + `medium` -> `propagation` (+ `phase` + `polarization`) -> **true vector motion** -> `observation` (projection and ultrasound acquisition/reconstruction) -> **observed displacement/velocity** -> REQ/REQ-ML.

Measured motion depends on both transducer beam sensitivity and displacement estimator; a nominal projection only represents ideal motion sensitivity and is not a full ultrasound measurement.
