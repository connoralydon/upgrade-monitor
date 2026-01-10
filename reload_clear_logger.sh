#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/data"

if [ -d "$LOG_DIR" ]; then
  for f in "$LOG_DIR"/*.log "$LOG_DIR"/*.out "$LOG_DIR"/*.err; do
    [ -f "$f" ] && : > "$f"
  done
fi

"$SCRIPT_DIR/manage_logger.sh" reload
