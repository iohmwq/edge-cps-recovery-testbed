# Run Note: 20260429_130045_control_fallback_pilot_02

## Role in the initial-discussion evidence package

This run is used as the accepted control fallback pilot.

Its purpose is to check whether actuator-side fallback and recovery cues can be observed during a longer controlled forwarding interruption.

## Setup under test

The pilot uses an Ubuntu host, a Raspberry Pi running Home Assistant, an ESP32 gateway, and an ESP32-S3 actuator node.

The main path under observation is forwarding from the gateway to the actuator. The actuator side is the main observation point because the local CPS response appears there after the forwarding path changes.

## Procedure

The run follows this order:

```text
baseline → forwarding cutoff → recovery
```

The host script controls the forwarding gate through Home Assistant.

During cutoff, forwarding from the gateway to the actuator is interrupted for a longer period so that fallback-related actuator-side behaviour can be checked from selected observations.

During recovery, forwarding is restored and the actuator-side observations are checked again.

## What this run supports

This run supports the use of the same automated baseline → cutoff → recovery flow under a longer interruption.

It also supports the current evidence boundary: actuator-side fallback and recovery cues can be checked from selected evidence extracts, while the pilot remains limited to selected observation.

## What this run does not claim

This run does not claim long-term stability, physical heating performance, or comparisons between recovery designs.

It should not be described as a full recovery framework or a completed comparison study.

## Evidence to check

- `RUN_STATUS.txt`
- `summary/run_summary.md`
- `PUBLIC_ARTIFACT_SCOPE.md`
- `evidence_extracts/host_events_key_lines.txt`
- `evidence_extracts/gateway_key_lines.txt`
- `evidence_extracts/actuator_key_lines.txt`

## External wording

A CPS-aligned pilot showing fallback/recovery observation under a controlled forwarding interruption.
