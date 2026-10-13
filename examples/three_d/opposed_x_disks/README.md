# Pilot: opposed 3D disks with x-directed motion

Physical motivation: two facing disk-shaped actuators on the left/right (x) sides of a larger homogeneous phantom, driven in phase with prescribed lateral (x) velocity. The acquisition is the central x-z plane in a ~38.3 x 38.4 mm ROI. This is a **true 3D elastic k-Wave** simulation, not a 2D slice with disk-shaped source regions.

IMPORTANT physics: disks normal to x driven in x impose **longitudinal/normal velocity**, so on-axis waves may be predominantly **compressional**, not shear. The result therefore saves separately total axial Uz, shear axial Uz, compression axial Uz, and lateral shear/total Ux. Inspect these before considering REQ. Matching experimental shear waves is not guaranteed.

The pilot uses `pstdElastic3D` directly and reuses the simulation framework's `kwsim.three_d.makeSparseDiskMaskOnFace` and `kwsim.three_d.extractHarmonicSensorData`. The existing framework vibrator-bank *validator* deliberately enforces transverse polarization; the custom pilot bypasses that bank configuration rather than silently changing the requested x motion. It has its own explicit JSON; it is not a general `kwsim.cli.runConfig` schema. The result is a self-contained `run.mat`, matching [z,x] public plane orientation. It does not replace any framework production APIs.

## Run

From MATLAB:

```matlab
framework_root="/Users/sara/local/shear-wave-simulation-framework";
addpath(genpath(fullfile(framework_root,"src")))
addpath(fullfile(framework_root,"examples","three_d","opposed_x_disks"))
cfg=fullfile(framework_root,"examples","three_d","opposed_x_disks","config.json");
out=run_opposed_x_disks_3d(cfg);
```

Change `framework_root` to your actual clone. `output_dir` in the JSON is relative to your current MATLAB directory; replace with an absolute path if desired.

Pilot defaults: 500 Hz, cs 2 m/s, reduced cp=20 m/s to limit runtime (not realistic tissue compressional speed); no material attenuation/no tracking/no IQ. Domain 65 x 24 x 55 mm (x, y, z), isotropic 0.5 mm; x-z FOV 38.3 x 38.4 mm. Finite 3 mm radius sparse disks near opposite x faces. Two disks in phase, x-driven. Saving center y plane only to control memory, but simulation propagates in full 3D volume. A 3D simulation at these sizes may require substantial RAM/time; check resources before running. No assistant-side MATLAB execution has been performed.

Outputs: `run.mat`, `resolved_input.json`, `central_xz_plane.png`. Inspect field amplitudes, phase, shear/compressional separation, and whether the observed lower-FOV low amplitude pattern occurs *without* attenuation. If absent, introduce controlled changes one at a time later, not in the pilot.

## Important distinction
In the analytical Step 1, we previously studied transverse z polarization with x propagation. This pilot is a **different physical excitation** (x polarization on x-normal disk). A lower-amplitude zone in Uz may arise from geometric projection, weak mode conversion, or wave interference; it does not itself prove shear attenuation.
