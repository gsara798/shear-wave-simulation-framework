# 02 — Finite coherent line aperture

From MATLAB: `run("examples/swsynth/02_finite_line_aperture/run_example.m")`.

Uses standard `swsynth.validateConfig` / `swsynth.run` with point, 4-mm and 8-mm **line** apertures. Figure uses the same absolute reference for all fields, making radiative pattern changes visible. The source consists of uniformly weighted coherent point-force elements; it does not enforce a rigid displacement boundary, nor is it a circular disk. This is a stepping stone toward a Green-tensor finite-contact approximation.

Tests: `runtests("tests/unit/test_swsynth_finite_aperture.m")`.
