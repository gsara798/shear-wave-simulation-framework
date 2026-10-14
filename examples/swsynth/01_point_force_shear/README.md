# 01 — Point-force shear radiation (far field)

From MATLAB: `run("examples/swsynth/01_point_force_shear/run_example.m")`.

Uses the framework's `swsynth.validateConfig` and `swsynth.run` with the versioned validation configurations `source_x_uz.json` and `source_z_uz.json`. Exports an axial real-displacement comparison on a **common color scale** under `outputs/`. No standalone propagation implementation or REQ-ML code.

Expected: force-x, measured z, has an antisymmetric nodal line through the source axis; force-z is symmetric. Only the **far-field shear projector** is modeled: there is no P wave, full Green tensor, or near-field physics.

Tests: `runtests("tests/unit/test_swsynth_point_force_radiation.m")` after adding framework `src` to MATLAB path. Regression tests check legacy default mode.
