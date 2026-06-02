# Edge CPS fallback and recovery testbed

This repository documents a small CPS-aligned pilot for observing fallback and recovery-related behaviour when forwarding from a gateway to an actuator is interrupted and later restored.

The testbed began from a real temperature-control setup for a tortoise enclosure. In this public pilot, the scope is narrowed to one path: forwarding from the gateway to the actuator. The actuator side is treated as the main observation point because local response cues appear there after forwarding changes.

For the architecture overview, see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Current status

The current evidence is based on two accepted pilot runs:

1. `20260429_101454_minimum_gate_pilot_01`
2. `20260429_130045_control_fallback_pilot_02`

These runs support a limited but concrete claim: the host script can turn forwarding from the gateway to the actuator off and back on, and selected observations from the host, gateway, actuator, and Home Assistant side can be kept together for later checking.

The current pilot does not claim long-term stability, physical heating performance, or comparison between recovery designs.

## Testbed components

The current setup includes:

- Ubuntu host: runs the pilot script, controls the experiment, and archives run outputs.
- Raspberry Pi with Home Assistant: provides the Home Assistant API and device status interface.
- ESP32 gateway: exposes the forwarding gate used in the pilot.
- ESP32-S3 actuator node: receives the forwarded signal and provides actuator-side observations.
- Selected Home Assistant and ESPHome evidence extracts: provide public evidence for checking the run afterwards.

## Pilot flow

The pilot procedure is automated with a Bash script running on the Linux host. Home Assistant is used for gate control, while selected ESPHome and Home Assistant observations are kept for later checking.

Each accepted run follows the same structure:

```text
baseline → forwarding cutoff → recovery
```

During baseline, forwarding is kept open. During cutoff, forwarding is turned off through Home Assistant. During recovery, forwarding is restored.

## Repository guide

Useful entry points are:

- [`REPO_INDEX.md`](REPO_INDEX.md): concise map of the public repository.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): architecture overview and system flow.
- [`docs/DEFINITIONS.md`](docs/DEFINITIONS.md): definitions for key terms used in the pilot.
- [`docs/EVIDENCE_SUMMARY.md`](docs/EVIDENCE_SUMMARY.md): accepted evidence, interpretation, and state-transition view.
- [`docs/RUNS.md`](docs/RUNS.md): accepted run index.

The main run notes are located at:

- `runs/cps_aligned_pilot/20260429_101454_minimum_gate_pilot_01/run_note.md`
- `runs/cps_aligned_pilot/20260429_130045_control_fallback_pilot_02/run_note.md`

## Public repository boundary

This repository is prepared as an initial-discussion evidence package. It is not presented as a completed research result.

Raw runtime captures, local machine metadata, Home Assistant state snapshots, device identifiers, and environment-specific configuration are retained only in the local archive.
