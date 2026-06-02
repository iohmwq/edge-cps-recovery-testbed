# Run Note: 20260429_101454_minimum_gate_pilot_01

## Role in the initial-discussion evidence package

This run is used as the minimum gate / minimum signal fallback pilot.

Its purpose is to check the automated baseline → forwarding cutoff → recovery procedure and to confirm that the host-side script can control the gateway forwarding gate through Home Assistant.

## Setup under test

The pilot uses an Ubuntu host, a Raspberry Pi running Home Assistant, an ESP32 gateway, and an ESP32-S3 actuator node.

In this run, the main object under test is the gateway-to-actuator forwarding path.

## Procedure

The run follows this order:

```text
baseline → forwarding cutoff → recovery
```

The host script first keeps the forwarding gate open during baseline, turns it off during cutoff, and turns it back on during recovery.

Selected observations are collected from the host, gateway, actuator, and Home Assistant side.

## What this run supports

This run supports a limited but concrete claim: the host script can control the forwarding gate and complete the baseline → cutoff → recovery flow.

It also shows that selected observations from the relevant components can be kept together in the run folder for later checking.

## What this run does not claim

This run does not claim long-term stability, physical heating performance, or comparison between recovery designs.

It should be treated as minimum CPS-aligned pilot evidence, not as a completed recovery study.

## Evidence to check

- `RUN_STATUS.txt`
- `summary/run_summary.md`
- `PUBLIC_ARTIFACT_SCOPE.md`
- `evidence_extracts/host_events_key_lines.txt`
- `evidence_extracts/gateway_key_lines.txt`
- `evidence_extracts/actuator_key_lines.txt`

## External wording

A minimum pilot showing host-controlled forwarding-gate operation and the baseline → cutoff → recovery procedure.
