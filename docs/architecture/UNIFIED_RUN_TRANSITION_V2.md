# V2 unified public run API — incremental transition

The public API is now `swsynth.run(cfg)` for both planar and volumetric observations. This is a **routing and compatibility** change, not a numerical-model rewrite.

## Existing configurations stay valid

- Existing 2D / projected observation configurations without `domain.Ly_m` continue to use the historical `swsynth.run` path and return `U_zx`.
- Existing volumetric configurations with `domain.Ly_m` are recognized by `swsynth.run` and use the original 3D validation, medium builder and synthesis path; return `U_zyx`.
- `swsynth.run3D(cfg)` remains a compatibility wrapper and calls `swsynth.run(cfg)`.
- Volumetric configs can optionally include `observation.geometry = 'volumetric3d'` and `observation.component = 'z'`; that optional metadata is stripped before validation by the existing volumetric schema. Only axial/z component is currently supported by the bridge.
- Mismatched 3D domain with 2D/projected geometry is rejected. A true normalized cross-geometry JSON schema is still future work.

## Source responsibilities

- `src/+swsynth/run.m`: public geometry selection and existing planar execution.
- `src/+swsynth/run3D.m`: legacy alias, no numerical code.
- `src/+swsynth/+internal/runVolumetric.m`: original volumetric execution implementation, kept isolated until common code is factored and validated.

The existing `validateConfig` and `validateConfig3D`, `defaultConfig` and `defaultConfig3D`, synth modules and sample schemas **remain separate** in this phase. We have **not yet unified** configuration validators, grid builders, or field packaging. For a clean new volumetric config, start from `swsynth.defaultConfig3D()`, not from `defaultConfig()`.

## MATLAB smoke/regression test

```matlab
cd('/Users/sara/local/shear-wave-simulation-framework')
addpath(fullfile(pwd,'src'))
r = runtests('tests/unit/test_swsynth_unified_run.m');
disp(table(r)); assertSuccess(r)

cfg = swsynth.defaultConfig3D();
cfg.domain.Lx_m = 0.006; cfg.domain.Ly_m = 0.004;
cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.002; cfg.domain.dy_m = 0.002;
cfg.domain.dz_m = 0.002;
cfg.directions.count = 1;
cfg.execution.use_parallel = false;
result = swsynth.run(cfg);
size(result.wavefield.U_zyx)
```

After these tests pass, run the full test suite and capture its results before refactoring the propagators themselves. The 3D results are presently numerically delegated without changes, but equivalence remains to be verified by MATLAB tests, not assumed.
