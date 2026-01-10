#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.upgrade-monitor.resource-logger.plist"
LABEL="com.upgrade-monitor.resource-logger"
SOURCE_PLIST="$SCRIPT_DIR/$PLIST_NAME"
TARGET_PLIST="$HOME/Library/LaunchAgents/$PLIST_NAME"
USER_DOMAIN="gui/$(id -u)"

usage() {
  printf "Usage: %s {load|reload|stop}\n" "$(basename "$0")"
}

load_agent() {
  mkdir -p "$HOME/Library/LaunchAgents"
  cp "$SOURCE_PLIST" "$TARGET_PLIST"

  launchctl bootout "$USER_DOMAIN" "$TARGET_PLIST" >/dev/null 2>&1 || true
  launchctl bootstrap "$USER_DOMAIN" "$TARGET_PLIST"
  launchctl enable "$USER_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  launchctl kickstart -k "$USER_DOMAIN/$LABEL" >/dev/null 2>&1 || true
}

stop_agent() {
  launchctl bootout "$USER_DOMAIN" "$TARGET_PLIST" >/dev/null 2>&1 || true
  launchctl unload "$TARGET_PLIST" >/dev/null 2>&1 || true
}

case "${1:-}" in
  load)
    load_agent
    ;;
  reload)
    stop_agent
    load_agent
    ;;
  stop)
    stop_agent
    ;;
  *)
    usage
    exit 1
    ;;
esac
