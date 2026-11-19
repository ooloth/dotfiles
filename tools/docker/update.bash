#!/usr/bin/env bash
# Says when Docker could free more than 10 GB, and deletes nothing: a prune nobody watches can
# remove what another session is using, so `dp` and `dpa` (tools/docker/shell.zsh) are run by hand.
# Says nothing when Docker is missing, stopped or does not answer within 5 seconds, so `u` stays
# green and fast. Written for macOS's own bash 3.2, which has no `timeout`.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

threshold_bytes=10000000000
deadline_seconds=5

if ! have docker; then
  exit 0
fi

rows="$(mktemp)"
trap 'rm -f "${rows}"' EXIT

# One "Images<TAB>18.57GB (70%)" per kind of object: images, containers, volumes, build cache.
# The deadline is perl's alarm, which outlives its exec and leaves nothing running; a loop of `sleep 0.1` overruns
# by each sleep's start-up cost. bash reports a child killed by a signal, so the call runs in a
# subshell whose stderr is discarded, and the `exit` after it stops bash exec'ing the call in place
# of the subshell, which would hand that report back to this shell.
if ! (perl -e 'alarm shift; exec @ARGV' "${deadline_seconds}" \
  docker system df --format '{{.Type}}\t{{.Reclaimable}}' >"${rows}"; exit $?) 2>/dev/null; then
  exit 0
fi

# Volumes are left out, because neither dp nor dpa removes them. Docker prints decimal units (1 GB
# is 10^9 bytes). Prints "unknown <value>" for a size in a unit it doesn't know, rather than guess,
# the total in GB when it is over the threshold, or nothing.
verdict="$(awk -F '\t' -v threshold="${threshold_bytes}" '
  BEGIN { scale["B"] = 1; scale["kB"] = 1e3; scale["MB"] = 1e6; scale["GB"] = 1e9; scale["TB"] = 1e12; scale["PB"] = 1e15 }
  NF == 0 || $1 == "Local Volumes" { next }
  {
    split($2, parts, " ")
    size = parts[1]
    unit = size
    sub(/^[0-9.]+/, "", unit)
    if (unit == size || !(unit in scale)) { unknown = 1; print "unknown " size; exit }
    sum += substr(size, 1, length(size) - length(unit)) * scale[unit]
  }
  END { if (!unknown && sum > threshold) printf "%.1f\n", sum / 1e9 }
' "${rows}")"

if [[ "${verdict}" == unknown* ]]; then
  warn "⚠️ Docker printed a reclaimable size this script can't read: ${verdict#unknown }"
elif [[ -n "${verdict}" ]]; then
  info "🐳 Docker could free up to ${verdict} GB: run dp, or dpa to remove unused images as well"
fi
