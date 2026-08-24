#!/usr/bin/env bash

set -euo pipefail

root=${FAKE_PCT_ROOT:?FAKE_PCT_ROOT is required}
log=${FAKE_PCT_LOG:?FAKE_PCT_LOG is required}
command=${1:?missing pct command}
shift

case "$command" in
  config)
    cat "$root/$1.conf"
    ;;
  status)
    cat "$root/$1.status"
    ;;
  exec)
    printf 'exec %s\n' "$*" >> "$log"
    ;;
  stop)
    printf 'stop %s\n' "$*" >> "$log"
    ;;
  destroy)
    vmid=$1
    printf 'destroy %s\n' "$*" >> "$log"
    rm -f "$root/$vmid.conf" "$root/$vmid.status"
    ;;
  *)
    printf 'unexpected fake pct command: %s %s\n' "$command" "$*" >&2
    exit 2
    ;;
esac
