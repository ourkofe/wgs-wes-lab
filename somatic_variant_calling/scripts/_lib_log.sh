#!/usr/bin/env bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"

log_run() {
  local step_name="$1"
  shift
  local cmd="$*"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  local logfile="$LOG_DIR/${step_name}.log"

  {
    echo "=== $ts | STEP: $step_name ==="
    echo "CMD: $cmd"
  } >> "$logfile"

  eval "$cmd" 2>&1 | tee -a "$logfile"

  echo "=== $(date '+%Y-%m-%d %H:%M:%S') | END: $step_name (exit=$?) ===" >> "$logfile"
}

log_docker_digest() {
  local image="$1"
  local digest
  digest="$(docker inspect --format='{{index .RepoDigests 0}}' "$image" 2>/dev/null || echo "unknown")"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $image -> $digest" >> "$LOG_DIR/image_digests.txt"
}
