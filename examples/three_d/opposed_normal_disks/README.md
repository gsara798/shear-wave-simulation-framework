# Opposed normal disks: 3D k-Wave pilot

This feature branch extends the existing **framework** 3D `vibrator_bank` source layout with the `opposed_normal_disks` bank. Two sparse finite disk contacts sit at the x-min and x-max faces, centered in y,z. Both are driven coherently in laboratory +x with the same phase and amplitude, despite their nominal inward directions being opposite. This is **normal excitation**, not transverse shear drive. Finite-disk geometry, wave physics, temporal harmonic extraction, coordinates, sample export, and MAT persistence are all delegated to the existing framework. No alternate `kWaveGrid` or direct `pstdElastic3D` invocation occurs in the example.

Run from MATLAB after checking your k-Wave installation:

```matlab
framework_root="/Users/sara/local/shear-wave-simulation-framework";
addpath(fullfile(framework_root,"src"));
which kWaveGrid
run(fullfile(framework_root,"examples","three_d","opposed_normal_disks","run_preview.m"));
```

`which kWaveGrid` is diagnostic; the framework's `kwsim.io.locateKWave` during `kwsim.three_d.run` is responsible for locating the toolbox. If the installation is absent, configure the supported `solver.kwave_path` in base_config.json.

The JSON is framework-native schema v3.0 and is loaded with `kwsim.io.loadConfigJson`. The MATLAB entrypoint calls `kwsim.three_d.validateConfig`, `kwsim.three_d.run`, `kwsim.io.saveSimulationResult`, and `kwsim.samples.buildWavefieldSample`. A 3D solver operates over the full domain, and the sensor records the central acquisition y-plane. The pilot plots amplitude and phase of axial total displacement, axial shear and compression, and lateral total, using the public [z,y,x] result. Both `result.mat` and `wavefield_sample.mat` are saved via framework IO.

Default parameters are **numerical pilot** values: 500 Hz, cs=2 m/s, cp=20 m/s via reduced ratio 10, isotropic dx=0.5 mm, approximately 65x24x55 mm domain, disk radius 3 mm, boundary inset 2 mm, disk sparse sampling 3 pixels, in-phase contact x-velocity. No attenuation or simulated ultrasound tracking. The recorded sensor has a framework-generated source-free ROI; comparisons with the 38.3x38.4 mm Verasonics FOV should use a separate centered crop rather than assuming the entire sensor ROI equals the acquisition FOV. Check RAM and runtime before execution.

Existing framework physical validation cases assume transverse shear excitation. This case currently uses the standalone exploratory path through `kwsim.three_d.run`, not `kwsim.cli.runConfig` or `simrunner.runConfig`, whose standard validators do not characterize normally driven contact compression/shear mixing. Do not interpret absence of an error as full physical validation. Follow-up work should add a dedicated mixed-mode validation classification before integrating this into general campaigns.

**Important physical point:** x-normal disk motion is expected to generate strong longitudinal components. A weak axial shear field along the disk axis is plausible, but whether this produces a bottom-of-FOV attenuation-looking pattern is an experimental question. Look first at the saved z-shear/z-compression decomposition.
