#!/usr/bin/env bash
# Public note:
# This script is kept as a public automation reference.
# Local endpoints, user names, tokens, and entity IDs should be supplied through a private environment file.
set -Eeuo pipefail

# ============================================================
# CPS-aligned pilot run script v3
# Purpose:
#   One command runs baseline -> cutoff -> recovery,
#   controls the HA forwarding gate, collects logs/snapshots,
#   and archives all evidence under the repo.
#
# Main fix from v1:
#   Summary generation no longer uses Markdown backticks inside an
#   expanding heredoc, so the shell will not accidentally treat them
#   as command substitutions.
# ============================================================

# ---------- User/environment configuration ----------
PROJECT_ROOT="${PROJECT_ROOT:-$HOME/edge-cps-recovery-testbed}"

HA_URL="${HA_URL:-http://homeassistant.local:8123}"
HA_TOKEN="${HA_TOKEN:-}"
GATE_ENTITY_ID="${GATE_ENTITY_ID:-switch.forwarding_gate_example}"

PI_USER="${PI_USER:-pi_user}"
PI_HOST="${PI_HOST:-homeassistant.local}"

ESPHOME_CONFIG_DIR="${ESPHOME_CONFIG_DIR:-$HOME/esphome_config}"
GATEWAY_YAML="${GATEWAY_YAML:-tortoise-gateway.yaml}"
ACTUATOR_YAML="${ACTUATOR_YAML:-tortoise-actuator-s3.yaml}"
ESPHOME_CONTAINER_NAME="${ESPHOME_CONTAINER_NAME:-}"

BASELINE_SEC="${BASELINE_SEC:-60}"
CUTOFF_SEC="${CUTOFF_SEC:-90}"
RECOVERY_SEC="${RECOVERY_SEC:-90}"
SAMPLE_INTERVAL_SEC="${SAMPLE_INTERVAL_SEC:-5}"

LOG_ALL_HA_STATES="${LOG_ALL_HA_STATES:-true}"
OBS_ENTITY_IDS="${OBS_ENTITY_IDS:-}"

RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)_cps_gate_pilot}"
RUN_ROOT="$PROJECT_ROOT/runs/cps_aligned_pilot/$RUN_ID"

META_DIR="$RUN_ROOT/metadata"
LOG_DIR="$RUN_ROOT/logs"
SNAPSHOT_DIR="$RUN_ROOT/snapshots"
SUMMARY_DIR="$RUN_ROOT/summary"

HOST_EVENTS="$LOG_DIR/host_events.log"
HA_SAMPLE_LOG="$LOG_DIR/ha_state_samples.jsonl"
HA_PHASE_SNAPSHOT_LOG="$LOG_DIR/ha_phase_snapshots.jsonl"
PING_PI_LOG="$LOG_DIR/ping_pi.log"
GATEWAY_ESPHOME_LOG="$LOG_DIR/gateway_esphome_logs.txt"
ACTUATOR_ESPHOME_LOG="$LOG_DIR/actuator_esphome_logs.txt"

BACKGROUND_PIDS=()
START_EPOCH="$(date +%s)"
TOTAL_PHASE_SEC=$((BASELINE_SEC + CUTOFF_SEC + RECOVERY_SEC))
TOTAL_LOG_SEC=$((TOTAL_PHASE_SEC + 90))
ERROR_TRAP_ACTIVE=0
EXIT_TRAP_ACTIVE=0

# ---------- Utility functions ----------
ts() {
  date -Is
}

log_host() {
  local action="$1"
  local result="$2"
  local note="${3:-}"
  if [ -n "${HOST_EVENTS:-}" ] && [ -d "$(dirname "$HOST_EVENTS")" ]; then
    printf 'ts=%s component=host action=%s result=%s note=%s\n' "$(ts)" "$action" "$result" "$note" | tee -a "$HOST_EVENTS"
  else
    printf 'ts=%s component=host action=%s result=%s note=%s\n' "$(ts)" "$action" "$result" "$note"
  fi
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

cleanup_background() {
  for pid in "${BACKGROUND_PIDS[@]:-}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
    fi
  done
}

on_error() {
  local exit_code=$?
  local line_no="${BASH_LINENO[0]:-unknown}"

  if [ "${ERROR_TRAP_ACTIVE:-0}" -eq 1 ]; then
    exit "$exit_code"
  fi

  ERROR_TRAP_ACTIVE=1
  trap - ERR
  log_host "script_exit" "failed" "exit_code=$exit_code line=$line_no" || true
  cleanup_background || true
  exit "$exit_code"
}

on_exit() {
  local exit_code=$?

  if [ "${EXIT_TRAP_ACTIVE:-0}" -eq 1 ]; then
    exit "$exit_code"
  fi

  EXIT_TRAP_ACTIVE=1
  trap - ERR
  trap - EXIT

  cleanup_background || true

  if [ "$exit_code" -eq 0 ]; then
    log_host "script_exit" "success" "run_root=$RUN_ROOT" || true
  fi

  exit "$exit_code"
}

trap 'on_error' ERR
trap 'on_exit' EXIT

# ---------- HA API functions ----------
ha_api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"

  if [ -n "$data" ]; then
    curl -sS -X "$method" \
      -H "Authorization: Bearer $HA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data" \
      "$HA_URL$path"
  else
    curl -sS -X "$method" \
      -H "Authorization: Bearer $HA_TOKEN" \
      -H "Content-Type: application/json" \
      "$HA_URL$path"
  fi
}

ha_check_api() {
  ha_api GET "/api/" | tee "$META_DIR/ha_api_check.json" >/dev/null
}

ha_get_entity_state() {
  local entity_id="$1"
  ha_api GET "/api/states/$entity_id"
}

ha_snapshot_all_states() {
  local phase="$1"
  local event="$2"
  local body
  body="$(ha_api GET "/api/states" || true)"
  printf '{"ts":"%s","phase":"%s","event":"%s","states":%s}\n' "$(ts)" "$phase" "$event" "$body" >> "$HA_PHASE_SNAPSHOT_LOG"
}

ha_switch_gate() {
  local desired="$1"
  local service

  if [ "$desired" = "on" ]; then
    service="turn_on"
  elif [ "$desired" = "off" ]; then
    service="turn_off"
  else
    echo "Invalid gate state: $desired" >&2
    exit 1
  fi

  log_host "set_forwarding_gate_$desired" "requesting" "entity_id=$GATE_ENTITY_ID"
  ha_api POST "/api/services/switch/$service" "{\"entity_id\":\"$GATE_ENTITY_ID\"}" \
    | tee -a "$LOG_DIR/ha_service_responses.jsonl" >/dev/null

  sleep 2
  ha_get_entity_state "$GATE_ENTITY_ID" > "$LOG_DIR/gate_state_after_${desired}_$(date +%H%M%S).json" || true
  log_host "set_forwarding_gate_$desired" "applied" "entity_id=$GATE_ENTITY_ID"
}

sample_focused_entities_once() {
  local phase="$1"
  local event="$2"
  local gate_json

  gate_json="$(ha_get_entity_state "$GATE_ENTITY_ID" || echo '{}')"
  printf '{"ts":"%s","phase":"%s","event":"%s","entity_id":"%s","state":%s}\n' \
    "$(ts)" "$phase" "$event" "$GATE_ENTITY_ID" "$gate_json" >> "$HA_SAMPLE_LOG"

  if [ -n "$OBS_ENTITY_IDS" ]; then
    IFS=',' read -ra ids <<< "$OBS_ENTITY_IDS"
    for entity_id in "${ids[@]}"; do
      entity_id="$(echo "$entity_id" | xargs)"
      [ -z "$entity_id" ] && continue
      local entity_json
      entity_json="$(ha_get_entity_state "$entity_id" || echo '{}')"
      printf '{"ts":"%s","phase":"%s","event":"%s","entity_id":"%s","state":%s}\n' \
        "$(ts)" "$phase" "$event" "$entity_id" "$entity_json" >> "$HA_SAMPLE_LOG"
    done
  fi

  if [ "$LOG_ALL_HA_STATES" = "true" ]; then
    ha_snapshot_all_states "$phase" "$event"
  fi
}

sample_phase() {
  local phase="$1"
  local duration="$2"
  local end_epoch=$(( $(date +%s) + duration ))

  log_host "phase_${phase}_start" "started" "duration_sec=$duration"
  sample_focused_entities_once "$phase" "phase_start"

  while [ "$(date +%s)" -lt "$end_epoch" ]; do
    sample_focused_entities_once "$phase" "periodic_sample"
    sleep "$SAMPLE_INTERVAL_SEC"
  done

  sample_focused_entities_once "$phase" "phase_end"
  log_host "phase_${phase}_end" "completed" "duration_sec=$duration"
}

# ---------- ESPHome log collection ----------
autodetect_esphome_container() {
  if [ -n "$ESPHOME_CONTAINER_NAME" ]; then
    echo "$ESPHOME_CONTAINER_NAME"
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    docker ps --format '{{.Names}}' | grep -Ei '(^|[-_])esphome($|[-_])|esphome' | head -n 1 || true
  fi
}

start_esphome_logs() {
  local yaml_file="$1"
  local output_file="$2"
  local label="$3"

  : > "$output_file"

  if command -v esphome >/dev/null 2>&1; then
    log_host "start_${label}_esphome_log" "started" "method=local_esphome yaml=$ESPHOME_CONFIG_DIR/$yaml_file"
    timeout "$TOTAL_LOG_SEC" esphome logs "$ESPHOME_CONFIG_DIR/$yaml_file" > "$output_file" 2>&1 &
    BACKGROUND_PIDS+=("$!")
    return 0
  fi

  local container_name
  container_name="$(autodetect_esphome_container)"
  if [ -n "$container_name" ]; then
    echo "$container_name" > "$META_DIR/esphome_container_name.txt"
    log_host "start_${label}_esphome_log" "started" "method=docker_exec container=$container_name yaml=/config/$yaml_file"
    timeout "$TOTAL_LOG_SEC" docker exec "$container_name" esphome logs "/config/$yaml_file" > "$output_file" 2>&1 &
    BACKGROUND_PIDS+=("$!")
    return 0
  fi

  log_host "start_${label}_esphome_log" "skipped" "reason=no_esphome_command_or_container_detected"
  echo "ESPHome log collection skipped: no local esphome command and no ESPHome Docker container detected." > "$output_file"
}

# ---------- Pi / HA log collection ----------
ssh_pi() {
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$PI_USER@$PI_HOST" "$@"
}

detect_pi_ha_log() {
  ssh_pi 'bash -s' <<'REMOTE'
set -u
candidates=(
  "$HOME/homeassistant/config/home-assistant.log"
  "$HOME/homeassistant/home-assistant.log"
  "$HOME/.homeassistant/home-assistant.log"
  "$HOME/ha/config/home-assistant.log"
  "$HOME/home-assistant/config/home-assistant.log"
)

for p in "${candidates[@]}"; do
  if [ -f "$p" ]; then
    echo "file:$p"
    exit 0
  fi
done

if command -v docker >/dev/null 2>&1; then
  container="$(docker ps --format '{{.Names}}' | grep -Ei 'homeassistant|home-assistant|^ha$' | head -n 1 || true)"
  if [ -n "$container" ]; then
    if docker exec "$container" test -f /config/home-assistant.log >/dev/null 2>&1; then
      echo "docker:$container:/config/home-assistant.log"
      exit 0
    fi
  fi
fi

echo "not_found"
REMOTE
}

copy_pi_ha_log_snapshot() {
  local tag="$1"
  local detected="$2"
  local out="$LOG_DIR/ha_log_${tag}.txt"

  if [[ "$detected" == file:* ]]; then
    local path="${detected#file:}"
    log_host "copy_pi_ha_log_$tag" "started" "method=scp path=$path"
    scp -q "$PI_USER@$PI_HOST:$path" "$out" || {
      log_host "copy_pi_ha_log_$tag" "failed" "method=scp path=$path"
      return 0
    }
    log_host "copy_pi_ha_log_$tag" "completed" "method=scp path=$path"
  elif [[ "$detected" == docker:* ]]; then
    local rest="${detected#docker:}"
    local container="${rest%%:*}"
    local path="${rest#*:}"
    log_host "copy_pi_ha_log_$tag" "started" "method=ssh_docker_exec container=$container path=$path"
    ssh_pi "docker exec '$container' cat '$path'" > "$out" || {
      log_host "copy_pi_ha_log_$tag" "failed" "method=ssh_docker_exec container=$container path=$path"
      return 0
    }
    log_host "copy_pi_ha_log_$tag" "completed" "method=ssh_docker_exec container=$container path=$path"
  else
    log_host "copy_pi_ha_log_$tag" "skipped" "reason=ha_log_not_found"
    echo "HA log not found automatically on Pi." > "$out"
  fi
}

start_ping_pi() {
  log_host "start_ping_pi" "started" "target=$PI_HOST"
  ping "$PI_HOST" > "$PING_PI_LOG" 2>&1 &
  BACKGROUND_PIDS+=("$!")
}

# ---------- Archival / metadata ----------
write_run_config() {
  PRIVATE_RUNTIME_META_DIR="${PRIVATE_RUNTIME_META_DIR:-$HOME/edge-cps-recovery-testbed/.private/runtime_metadata/$RUN_ID}"
  mkdir -p "$PRIVATE_RUNTIME_META_DIR"
  cat > "$PRIVATE_RUNTIME_META_DIR/local_run_config.txt" <<CONFIG
RUN_ID=$RUN_ID
PROJECT_ROOT=$PROJECT_ROOT
HA_URL=$HA_URL
GATE_ENTITY_ID=$GATE_ENTITY_ID
PI_USER=$PI_USER
PI_HOST=$PI_HOST
ESPHOME_CONFIG_DIR=$ESPHOME_CONFIG_DIR
GATEWAY_YAML=$GATEWAY_YAML
ACTUATOR_YAML=$ACTUATOR_YAML
BASELINE_SEC=$BASELINE_SEC
CUTOFF_SEC=$CUTOFF_SEC
RECOVERY_SEC=$RECOVERY_SEC
SAMPLE_INTERVAL_SEC=$SAMPLE_INTERVAL_SEC
LOG_ALL_HA_STATES=$LOG_ALL_HA_STATES
OBS_ENTITY_IDS=$OBS_ENTITY_IDS
CONFIG
}

save_metadata() {
  date -Is > "$META_DIR/run_started_at.txt"
  uname -a > "$META_DIR/ubuntu_uname.txt" || true
  hostnamectl > "$META_DIR/ubuntu_hostnamectl.txt" 2>&1 || true
  ip addr > "$META_DIR/ubuntu_ip_addr.txt" 2>&1 || true
  docker ps > "$META_DIR/ubuntu_docker_ps.txt" 2>&1 || true
  ssh_pi 'hostnamectl; echo "---"; ip addr; echo "---"; docker ps 2>/dev/null || true' > "$META_DIR/pi_system_snapshot.txt" 2>&1 || true
}

capture_time_sources() {
  local label="$1"
  local out="$META_DIR/time_sources_${label}.txt"

  log_host "capture_time_sources_${label}" "started" "path=$out" || true

  # Best-effort evidence metadata. SSH/API checks here must not create
  # a false failed run after the experiment itself has already completed.
  set +e
  {
    echo "[ubuntu]"
    echo "hostname=$(hostname 2>/dev/null)"
    echo "date_is=$(date -Is 2>/dev/null)"
    echo "date_utc=$(date -u -Is 2>/dev/null)"
    echo "unix_epoch=$(date +%s 2>/dev/null)"
    echo
    echo "[pi]"
    ssh_pi 'echo "hostname=$(hostname)"; echo "date_is=$(date -Is)"; echo "date_utc=$(date -u -Is)"; echo "unix_epoch=$(date +%s)"'
    echo "pi_ssh_exit_code=$?"
    echo
    echo "[home_assistant_gate_state]"
    ha_get_entity_state "$GATE_ENTITY_ID"
    echo
    echo "ha_api_exit_code=$?"
  } > "$out" 2>&1
  local capture_rc=$?
  set -e

  if [ "$capture_rc" -eq 0 ]; then
    log_host "capture_time_sources_${label}" "completed" "path=$out" || true
  else
    log_host "capture_time_sources_${label}" "completed_with_warning" "path=$out exit_code=$capture_rc" || true
  fi

  return 0
}

save_yaml_snapshots() {
  if [ -f "$ESPHOME_CONFIG_DIR/$GATEWAY_YAML" ]; then
    cp "$ESPHOME_CONFIG_DIR/$GATEWAY_YAML" "$SNAPSHOT_DIR/gateway_yaml_snapshot.yaml"
  else
    echo "Gateway YAML not found at $ESPHOME_CONFIG_DIR/$GATEWAY_YAML" > "$SNAPSHOT_DIR/gateway_yaml_snapshot_missing.txt"
  fi

  if [ -f "$ESPHOME_CONFIG_DIR/$ACTUATOR_YAML" ]; then
    cp "$ESPHOME_CONFIG_DIR/$ACTUATOR_YAML" "$SNAPSHOT_DIR/actuator_yaml_snapshot.yaml"
  else
    echo "Actuator YAML not found at $ESPHOME_CONFIG_DIR/$ACTUATOR_YAML" > "$SNAPSHOT_DIR/actuator_yaml_snapshot_missing.txt"
  fi
}

generate_summary() {
  local end_epoch
  end_epoch="$(date +%s)"
  local elapsed=$((end_epoch - START_EPOCH))
  local summary_file="$SUMMARY_DIR/run_summary.md"

  {
    echo "# CPS-aligned gate pilot run summary"
    echo
    echo "## Run identity"
    echo
    echo "- Run ID: \`${RUN_ID}\`"
    echo "- Run root: retained in the local archive"
    echo "- Started at: $(cat "$META_DIR/run_started_at.txt" 2>/dev/null || true)"
    echo "- Finished at: $(ts)"
    echo "- Elapsed seconds: ${elapsed}"
    echo
    echo "## Purpose"
    echo
    echo "This run records a CPS-aligned pilot using a Home Assistant controlled forwarding gate."
    echo
    echo "The purpose of this run is to check whether the host script can coordinate a baseline → cutoff → recovery sequence and collect observations around the gateway-to-actuator forwarding path."
    echo
    echo "## Phase settings"
    echo
    echo "- Baseline seconds: ${BASELINE_SEC}"
    echo "- Cutoff seconds: ${CUTOFF_SEC}"
    echo "- Recovery seconds: ${RECOVERY_SEC}"
    echo "- Sampling interval seconds: ${SAMPLE_INTERVAL_SEC}"
    echo
    echo "## Public configuration boundary"
    echo
    echo "The following local configuration details were used during the run and are retained in the local archive rather than included in the public repository:"
    echo
    echo "- Home Assistant endpoint"
    echo "- Forwarding gate entity"
    echo "- Pi SSH target"
    echo "- Gateway ESPHome configuration"
    echo "- Actuator ESPHome configuration"
    echo
    echo "This keeps the public repository focused on the pilot structure, selected evidence, and interpretation without exposing local home-automation details."
    echo
    echo "## Main public evidence files"
    echo
    echo "- \`run_note.md\`: concise interpretation of the run and its current evidence boundary."
    echo "- \`RUN_STATUS.txt\`: public status marker for an accepted run."
    echo "- \`PUBLIC_ARTIFACT_SCOPE.md\`: note explaining what is included in the public copy and what remains local."
    echo "- \`summary/run_summary.md\`: this public summary."
    echo "- \`evidence_extracts/host_events_key_lines.txt\`: selected host-side phase and gate-control events."
    echo "- \`evidence_extracts/gateway_key_lines.txt\`: selected gateway-side forwarding evidence."
    echo "- \`evidence_extracts/actuator_key_lines.txt\`: selected actuator-side observation evidence."
    echo
    echo "## Local archive note"
    echo
    echo "The full runtime captures generated by this script, including raw runtime captures, local metadata, Home Assistant state snapshots, and configuration snapshots, are retained in the local archive. They should be sanitized into selected evidence extracts before public release."
    echo
    echo "## Current interpretation"
    echo
    echo "This run supports a limited claim: the host-side automation can run a baseline → cutoff → recovery sequence and collect selected evidence around the forwarding-gate change."
    echo
    echo "It should not be described as evidence of long-term stability, final physical-control validation, recovery-strategy comparison, or a completed middleware result."
  } > "$summary_file"

  log_host "generate_summary" "completed" "path=$summary_file"
}

# ---------- Main execution ----------
main() {
  if [ -z "$HA_TOKEN" ]; then
    echo "HA_TOKEN is empty. Run this first or source your private ha.env file:" >&2
    echo "Create .private/ha.env with HA_URL and your Home Assistant long-lived access token before running this script." >&2
    exit 1
  fi

  require_command curl
  require_command ssh
  require_command scp
  require_command ping
  require_command timeout
  require_command python3

  mkdir -p "$META_DIR" "$LOG_DIR" "$SNAPSHOT_DIR" "$SUMMARY_DIR"
  : > "$HOST_EVENTS"
  : > "$HA_SAMPLE_LOG"
  : > "$HA_PHASE_SNAPSHOT_LOG"

  log_host "run_prepare" "started" "run_root=$RUN_ROOT"
  write_run_config
  save_metadata
  save_yaml_snapshots

  log_host "ha_api_check" "started" "url=$HA_URL"
  ha_check_api
  log_host "ha_api_check" "completed" "url=$HA_URL"

  log_host "pi_ssh_check" "started" "target=$PI_USER@$PI_HOST"
  ssh_pi 'echo ok' > "$META_DIR/pi_ssh_check.txt"
  log_host "pi_ssh_check" "completed" "target=$PI_USER@$PI_HOST"

  capture_time_sources "start"

  local detected_ha_log
  detected_ha_log="$(detect_pi_ha_log || echo not_found)"
  echo "$detected_ha_log" > "$META_DIR/pi_ha_log_detected.txt"

  copy_pi_ha_log_snapshot "before" "$detected_ha_log"

  start_ping_pi
  start_esphome_logs "$GATEWAY_YAML" "$GATEWAY_ESPHOME_LOG" "gateway"
  start_esphome_logs "$ACTUATOR_YAML" "$ACTUATOR_ESPHOME_LOG" "actuator"

  ha_switch_gate on
  ha_snapshot_all_states "pre_baseline" "after_gate_on"
  sample_phase "baseline" "$BASELINE_SEC"

  ha_switch_gate off
  log_host "host_cut_applied" "applied" "gateway_to_actuator_forwarding_gate_off"
  ha_snapshot_all_states "cutoff" "after_gate_off"
  sample_phase "cutoff" "$CUTOFF_SEC"

  ha_switch_gate on
  log_host "host_recover_applied" "applied" "gateway_to_actuator_forwarding_gate_on"
  ha_snapshot_all_states "recovery" "after_gate_on"
  sample_phase "recovery" "$RECOVERY_SEC"

  capture_time_sources "end"
  copy_pi_ha_log_snapshot "after" "$detected_ha_log"
  generate_summary

  log_host "run_archive" "completed" "run_root=$RUN_ROOT"
  echo
  echo "Completed. Evidence archived at:"
  echo "$RUN_ROOT"
}

main "$@"
