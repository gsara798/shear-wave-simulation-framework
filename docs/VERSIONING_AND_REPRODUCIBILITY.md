# Versioning and reproducible simulations

## Protected historical references

- `main`: existing primary line (do not rewrite history).
- `stable/v1-main`: snapshot of `main` at commit `70ecfc7d63e432a15b508c6c971674bbe5ff956f` when the v2 work started.
- `v1.0.0`: **pre-existing** tag pointing to `4b6871ac3c846823f09e1b2de4ea562d3df09b84`. This is **not** the same commit as the `main` snapshot. Do not move the tag.
- `develop/v2`: active modular-framework development (currently `2.0.0-dev` in the swsynth CLI provenance).
- `integration/swsynth-point-force-aperture-v1`: historical integration line retained; future work should target `develop/v2`.

Tags and SHAs, not mutable branch names or marketing versions, identify reproducible source states. Before calling old datasets "v1", confirm the precise generating SHA from their manifests.

## Local macOS worktree setup (without deleting local changes)

From the existing working copy:

```bash
cd /Users/sara/local/shear-wave-simulation-framework
git status --short
git fetch origin --tags
git branch --show-current
```

If there are modified/untracked files, inspect and save them first. Do not run `git reset --hard`, `git clean`, or checkout over local edits.

Keep the existing directory as the v2 working directory once its changes are safe and switch to the development branch:

```bash
git switch --track origin/develop/v2
```

If the local branch already exists: `git switch develop/v2`.

Create a separate immutable historical worktree for the **main** snapshot:

```bash
git worktree add --detach ../shear-wave-simulation-framework-v1 origin/stable/v1-main
```

For the older pre-existing `v1.0.0` tag instead, use `git worktree add --detach ../shear-wave-simulation-framework-v1-tag v1.0.0` in a separately named directory. Do not assume that tag equals `main`.

In MATLAB, deliberately prioritize a single framework's `src` on the path. At the start of any run, inspect:

```matlab
which swsynth.run -all
which swsynth.run3D -all
```

Never add both framework versions to the MATLAB path in a single session. Consider `restoredefaultpath` only when appropriate for the current MATLAB session, and then `addpath(fullfile(repoRoot,'src'))` explicitly.

## Provenance for CLI runs

`swsynth.cli.runConfig` now writes `run_summary.json.framework` and manifest fields:

- `version` (`2.0.0-dev`), `git_commit`, `git_branch`, `git_tag`
- `git_dirty` (true if modified or untracked files are present)
- `matlab_version`, `captured_at`

The git information is resolved using the source module's own path, **not** the MATLAB current directory. A clean Git tree and immutable commit are necessary for exact code reproducibility. A dirty tree is a warning, not a complete diff: commit and rerun final production datasets.

This integration currently covers the 2D `swsynth.cli.runConfig` output path; direct MATLAB `swsynth.run`, direct `swsynth.run3D`, and other campaign backends may require propagation of these metadata fields before claiming full-framework provenance coverage.

## Validation commands

```matlab
cd('/Users/sara/local/shear-wave-simulation-framework')
addpath(fullfile(pwd,'src'))
r = runtests('tests/unit/test_swsynth_framework_provenance.m');
disp(table(r)); assertSuccess(r);
```

Then validate a small CLI example and inspect `run_summary.json` and `manifest.txt`. Full tests: `run('tests/run_all_tests.m')` or call `run_all_tests` after adding `tests` to the path.
