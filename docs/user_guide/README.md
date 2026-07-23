# User Guide

This directory contains the user-facing documentation for the shear-wave
simulation framework.

The recommended reading order is:

```text
1. Quick Start
2. Configuration Guide
3. Terminology
4. Simulation Parameters
5. Outputs and Validation
6. Physics Guides
```

## 1. Quick Start

Start here to run a verified simulation through the command-line interface.

[Quick Start](quickstart.md)

This guide covers:

- checking the CLI;
- running a dry run;
- executing the verified 2D reference case;
- locating the output directory;
- reading the validation summary;
- verified 3D dry-run examples.

## 2. Configuration Guide

Use this guide when creating or modifying JSON configurations.

[Configuration Guide](configuration_guide.md)

This guide covers:

- choosing a verified base configuration;
- copying and editing JSON files;
- changing SWS, frequency, grid, timing, and outputs;
- comparing requested and resolved configurations;
- safe and high-risk parameter changes.

## 3. Terminology

Use this glossary when a term, abbreviation, naming convention, or test type is
unclear.

[Terminology](terminology.md)

This guide defines:

- dry run;
- preflight;
- validation;
- smoke, unit, and integration tests;
- REQ-ready;
- N8 P2, N32 P8, and N128 P8;
- public array orientation;
- source-bank and wavefield terminology.

## 4. Simulation Parameters

Use this reference when interpreting configuration fields.

[Simulation Parameters](simulation_parameters.md)

This guide explains:

- grid and spatial resolution;
- points per wavelength and CFL;
- material properties;
- geometry;
- finite-contact and angular source parameters;
- timing;
- sensor and solver settings;
- harmonic analysis;
- REQ export settings;
- output and validation controls.

## 5. Outputs and Validation

Use this guide after executing a simulation.

[Outputs and Validation](outputs_and_validation.md)

This guide explains:

- the run-directory structure;
- requested and resolved configurations;
- result, summary, and validation MAT files;
- the human-readable validation report;
- diagnostic figures;
- REQ validation samples;
- pure and mixed heterogeneous truth regions;
- what a valid run does and does not establish.

## 6. Physics Guides

The physics guides explain how the implemented simulation components should be
interpreted.

### Finite-contact sources

[Finite-Contact Sources](physics/finite_contact_sources.md)

Explains:

- finite segments in 2D;
- finite disks in 3D;
- prescribed boundary velocity;
- source motion and polarization;
- Dirichlet source interpretation;
- contact discretization;
- source ramp and settling;
- differences from a complete mechanical shaker model.

### Multiface and angular sources

[Multiface and Angular Sources](physics/multiface_and_angular_sources.md)

Explains:

- multiface source banks;
- direction-first angular generation;
- N and P nomenclature;
- in-plane and out-of-plane contributors;
- face mapping;
- phase, amplitude, and polarization policies;
- partial-3D versus diffuse fields;
- source- and field-level angular validation.

### Heterogeneous materials

[Heterogeneous Materials](physics/heterogeneous_materials.md)

Explains:

- background materials;
- spheres;
- finite cylinders;
- bilayers;
- combined geometry;
- geometry precedence;
- material IDs and truth maps;
- pure and mixed analysis windows;
- reduced compressional speed;
- voxelization and interface effects.

### Harmonic analysis and P/S separation

[Harmonic Analysis and P/S Separation](physics/harmonic_analysis_and_ps_separation.md)

Explains:

- time-domain simulation;
- settling and analysis intervals;
- least-squares harmonic extraction;
- complex phasors;
- amplitude and phase;
- longitudinal and transverse field components;
- P/S energy ratio;
- source-frequency purity;
- steady-state validation;
- connection to REQ.

## 7. Recommended workflow

For a new simulation:

```text
choose a verified configuration
-> read the parameter documentation
-> copy the JSON file
-> edit one parameter group
-> run a dry run
-> execute the solver
-> inspect validation
-> inspect figures and resolved configuration
-> begin downstream analysis
```

## 8. Documentation status

The current guide documents the verified configured workflow and the implemented
2D and 3D simulation components.

The documentation is intentionally incremental.

Before a new feature is described as supported, it should have:

```text
an executable configuration or example
a successful dry run
a successful solver run when practical
saved output inspection
documented limitations
```

## 9. Important interpretation rule

A completed solver run is not automatically a valid scientific result.

Always inspect:

```text
validation_summary.txt
resolved_config.json
diagnostic figures
truth maps
analysis-region composition
```

before making scientific claims.
