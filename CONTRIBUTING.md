# Contributing

Contributions that improve numerical reliability, reproducibility,
documentation, portability, testing, and physical validation are welcome.

## Before contributing

For substantial methodological changes, open an issue first. Describe:

- the physical or numerical problem;
- the proposed change;
- the validation case;
- expected effects on runtime, stability, and reproducibility.

Bug reports should include:

- MATLAB version;
- k-Wave version;
- operating system;
- configuration used;
- smallest reproducible example;
- complete error message;
- expected and observed behavior.

Do not upload clinical, confidential, proprietary, or personally identifiable
data.

## Development workflow

1. Fork the repository.
2. Create a focused branch.
3. Add the repository source folder to the MATLAB path.
4. Implement one logically coherent change.
5. Add or update tests.
6. Run the relevant unit and integration tests.
7. Open a pull request against `main`.

Example:

```bash
git checkout -b fix/source-normalization
```

```matlab
addpath('src');
addpath('tests');
results = run_all_tests();
```

## Scientific expectations

Changes affecting simulated physics should be validated using one or more of:

- analytical or limiting-case behavior;
- homogeneous-medium benchmarks;
- grid-convergence checks;
- domain-size or PML sensitivity;
- P/S energy diagnostics;
- phasor convergence;
- phase-speed recovery;
- comparison with a frozen reference configuration.

A visually plausible wavefield is not sufficient evidence of correctness.

## Coding guidelines

- Use portable paths and `fullfile`.
- Document units and coordinate conventions.
- Keep public fields consistent with the `[Nz, Nx]` contract.
- Separate physical assumptions from solver-specific workarounds.
- Avoid silently changing default approximations.
- Preserve deterministic seeds for reproducibility tests.
- Do not commit generated outputs, large MAT files, or local caches.

## Scope

This software is intended for research and methodological development. It is
not a clinically validated simulator and must not be used for diagnosis or
medical decision-making.

## License

By submitting a contribution, you agree that it may be distributed under the
Apache License 2.0.
