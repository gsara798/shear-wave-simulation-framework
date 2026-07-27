# Simulation campaign configuration contract v1.1

Contract v1.1 makes the simulation backend explicit while preserving campaign
schema v1.0.

Supported backends:

- `kwsim`
- `swsynth`

Schema v1.0 remains valid and implies `backend = "kwsim"`.

Schema v1.1 requires:

```json
{
  "schema_version": "1.1",
  "backend": "swsynth",
  "campaign_name": "example",
  "base_config": "configs/swsynth/example.json",
  "sweep": [
    {
      "path": "medium.background_cs_m_s",
      "values": [2.0, 3.0]
    }
  ]
}
```

Run identity includes both the backend and the resolved single-run
configuration. This prevents two different simulation backends from sharing a
hash accidentally.

The first implementation phase covers backend-neutral loading and deterministic
Cartesian expansion. Backend-neutral validation, execution, resume, and CSV
publication are added in the next phase.
