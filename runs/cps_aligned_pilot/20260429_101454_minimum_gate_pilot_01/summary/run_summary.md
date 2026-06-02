# CPS-aligned gate pilot run summary

## Run identity

- Run ID: `20260429_101454_minimum_gate_pilot_01`
- Public role: accepted minimum gate / minimum signal fallback pilot
- Started at: 2026-04-29T10:14:54+00:00
- Finished at: 2026-04-29T10:19:44+00:00
- Elapsed seconds: 290

## Purpose

This run records a minimum CPS-aligned pilot using a Home Assistant controlled forwarding gate.

The purpose of this run is to check whether the host script can control a gateway-to-actuator forwarding interruption and collect selected observations across the host, gateway, actuator, and Home Assistant side.

## Phase settings

- Baseline seconds: 60
- Cutoff seconds: 90
- Recovery seconds: 90
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

This run supports a limited claim: the host-side automation could run a baseline → cutoff → recovery sequence and collect selected evidence around the forwarding-gate change.

It should be treated as a minimum pilot run, not as a complete CPS recovery comparison study.

## Notes

The public repository keeps selected evidence extracts, run notes, run status files, and summary pages.

Raw runtime captures, local machine metadata, Home Assistant state snapshots, device identifiers, and environment-specific configuration are retained only in the local archive.
