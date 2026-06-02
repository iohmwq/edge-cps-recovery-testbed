# Definitions for the Initial-Discussion Pilot

This document defines the terms used in the current initial-discussion version of the CPS pilot.

## Edge CPS

In this repository, edge CPS refers to a small cyber-physical system in which sensing, communication, logging, and actuator-side response are distributed across local devices.

The current pilot uses an Ubuntu host, a Raspberry Pi running Home Assistant, an ESP32 gateway, and an ESP32-S3 actuator node.

## Gateway

The gateway is the ESP32 node that provides the forwarding path toward the actuator. In the current pilot, the gateway exposes a forwarding gate through Home Assistant.

## Actuator node

The actuator node is the ESP32-S3 node placed on the enclosure side. It is the main observation point in this pilot because fallback and recovery signs are checked from the actuator-side observations.

## Forwarding gate

The forwarding gate is a logical switch exposed through Home Assistant. It allows the host script to turn forwarding from the gateway to the actuator off and back on without manually reflashing the device during the run.

## Baseline

Baseline is the period in which the forwarding gate is open. It provides the normal reference condition for the run.

## Forwarding cutoff

Forwarding cutoff is the period in which the forwarding gate is turned off. It is used to create a controlled interruption between the gateway and actuator.

## Recovery

Recovery is the period after forwarding is turned back on. The actuator logs are checked to see how the system behaves after forwarding is restored.

## Fallback sign

A fallback sign is a log-level cue suggesting that the actuator side has entered, or is approaching, a local fallback-related state during the cutoff period.

The current pilot treats fallback signs as selected log-based evidence only. It does not claim physical heating behaviour.

## Recovery cue

A recovery cue is a log-level cue suggesting that the actuator side changes state after forwarding is restored.

The current pilot does not claim that a recovery strategy has been settled as a final result. It only checks whether recovery-related behaviour can be followed in the logs.

## Evidence boundary

The current evidence boundary is log-based. The accepted runs support host-controlled forwarding interruption and archived logs for later checking.

The current pilot does not claim long-term stability, physical heating performance, or comparison between recovery designs.
