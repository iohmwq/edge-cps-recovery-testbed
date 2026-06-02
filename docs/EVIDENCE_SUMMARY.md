# Evidence summary

## Purpose

This document summarises the public evidence retained for the current initial-discussion version of the pilot.

The public evidence is meant to show that the project has a small, runnable CPS-aligned pilot and a clear observation path for gateway-to-actuator forwarding interruption.

## Accepted runs

| Run ID | Role | Public use |
|---|---|---|
| `20260429_101454_minimum_gate_pilot_01` | Minimum gate / minimum signal fallback pilot | Shows the automated baseline → cutoff → recovery procedure and host-controlled forwarding gate. |
| `20260429_130045_control_fallback_pilot_02` | Control fallback pilot | Shows actuator-side fallback and recovery-related observation under a longer controlled forwarding interruption. |

## Evidence locations

| Evidence type | Path |
|---|---|
| Minimum run note | `runs/cps_aligned_pilot/20260429_101454_minimum_gate_pilot_01/run_note.md` |
| Minimum run summary | `runs/cps_aligned_pilot/20260429_101454_minimum_gate_pilot_01/summary/run_summary.md` |
| Control fallback run note | `runs/cps_aligned_pilot/20260429_130045_control_fallback_pilot_02/run_note.md` |
| Control fallback run summary | `runs/cps_aligned_pilot/20260429_130045_control_fallback_pilot_02/summary/run_summary.md` |

## State-transition view

The accepted runs can be interpreted through a simple state-transition view:

| Phase | Gateway-side expectation | Actuator-side expectation | Meaning |
|---|---|---|---|
| Baseline | Forwarding gate enabled | Normal or signal-present state | CPS path is operating before interruption. |
| Forwarding cutoff | Forwarding gate disabled | Fallback-related or signal-loss-related cue | Controlled interruption is injected. |
| Recovery observation | Forwarding gate re-enabled | Recovery-related or signal-restored cue | CPS path returns from interruption. |

## Current interpretation

The accepted runs support the following limited interpretation:

- the host-side script can coordinate a baseline → cutoff → recovery sequence
- Home Assistant can be used to control the gateway-side forwarding gate
- selected host, gateway, actuator, and Home Assistant observations can be retained together
- actuator-side observations can be checked for fallback and recovery-related cues

## Boundary

This evidence does not claim physical heating effect validation, long-term stability, recovery-strategy comparison, or a completed middleware result.

Raw runtime captures, local machine metadata, Home Assistant state snapshots, device identifiers, and environment-specific configuration are retained only in the local archive.
