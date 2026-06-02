# Repository index

This repository is a public evidence package for an initial edge CPS fallback and recovery pilot discussion.

## Start here

- [`README.md`](README.md): main overview of the testbed, current status, accepted runs, and public boundary.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): system architecture and control / observation flow.
- [`docs/DEFINITIONS.md`](docs/DEFINITIONS.md): definitions for key terms used in the pilot.
- [`docs/EVIDENCE_SUMMARY.md`](docs/EVIDENCE_SUMMARY.md): evidence summary and state-transition interpretation.
- [`docs/RUNS.md`](docs/RUNS.md): accepted run index.

## Main public evidence

- `runs/cps_aligned_pilot/20260429_101454_minimum_gate_pilot_01/`
- `runs/cps_aligned_pilot/20260429_130045_control_fallback_pilot_02/`

Each accepted run keeps:

- `run_note.md`
- `RUN_STATUS.txt`
- `PUBLIC_ARTIFACT_SCOPE.md`
- `summary/run_summary.md`
- selected files under `evidence_extracts/`

## Script

- `scripts/cps_pilot_gate_run_v3.sh`: public-template version of the pilot script.

Local endpoints, entity IDs, SSH targets, and environment-specific configuration are not included in the public repository.

## Boundary

The current public materials support a limited claim: a host-side script can coordinate a baseline → cutoff → recovery sequence, control a gateway-to-actuator forwarding gate, and keep selected observations together for review.

The repository does not present claims about long-term stability, physical heating effects, recovery-strategy comparison, middleware completeness, or security design.
