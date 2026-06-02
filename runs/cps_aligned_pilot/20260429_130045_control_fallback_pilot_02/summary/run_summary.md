# CPS-aligned gate pilot run summary

## Run identity

- Run ID: `20260429_130045_control_fallback_pilot_02`
- Public role: accepted control fallback pilot
- Started at: 2026-04-29T13:00:45+00:00
- Finished at: 2026-04-29T13:14:28+00:00
- Elapsed seconds: 823

## Purpose

This run records a longer CPS-aligned control fallback pilot using a Home Assistant controlled forwarding gate.

The purpose of this run is to check whether a longer cutoff window can be used for observing actuator-side behaviour while the host script coordinates the baseline → cutoff → recovery sequence.

## Phase settings

- Baseline seconds: 90
- Cutoff seconds: 500
- Recovery seconds: 180
- Sampling interval seconds: 5

## Public configuration boundary

The following local configuration details were used during the run and are retained in the local archive rather than included in the public repository:

- Home Assistant endpoint
- Forwarding gate entity
- Pi SSH target
- Gateway ESPHome configuration
- Actuator ESPHome configuration

This keeps the public repository focused on the pilot structure, selected evidence, and interpretation without exposing local home-automation details.

## Main public evidence files

- `run_note.md`: concise interpretation of the run and its current evidence boundary.
- `RUN_STATUS.txt`: public status marker for this accepted run.
- `PUBLIC_ARTIFACT_SCOPE.md`: note explaining what is included in the public copy and what remains local.
- `summary/run_summary.md`: this public summary.
- `evidence_extracts/host_events_key_lines.txt`: selected host-side phase and gate-control events.
- `evidence_extracts/gateway_key_lines.txt`: selected gateway-side forwarding evidence.
- `evidence_extracts/actuator_key_lines.txt`: selected actuator-side observation evidence.

## Current interpretation

This run supports a limited claim: the host-side automation could run a longer cutoff sequence and collect selected evidence around the forwarding-gate change and actuator-side observation.

It should be treated as a control fallback pilot, not as evidence of long-term stability or final physical-control validation.

## Notes

The public repository keeps selected evidence extracts, run notes, run status files, and summary pages.

Raw runtime captures, local machine metadata, Home Assistant state snapshots, device identifiers, and environment-specific configuration are retained only in the local archive.
