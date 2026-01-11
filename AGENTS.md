# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-10 14:07 PST
**Commit:** 976041e
**Branch:** cly/web-pane

## OVERVIEW
macOS system resource monitoring daemon. Logs CPU, memory, disk metrics at intervals.

## STRUCTURE
```
upgrade-monitor/
├── resource_logger.sh          # Main monitoring script
├── manage_logger.sh           # LaunchAgent control (load/reload/stop)
├── reload_clear_logger.sh     # Quick reload + clear logs
├── com.upgrade-monitor.resource-logger.plist  # LaunchAgent config
└── data/                      # Output directory
    ├── *.jsonl               # JSON logs (cpu/memory/disk)
    └── launchd.out/err       # Daemon stdout/stderr
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Metric collection logic | resource_logger.sh | Uses ps, vm_stat, diskutil |
| Daemon lifecycle | manage_logger.sh | launchctl wrapper |
| Log format | resource_logger.sh lines 39-41 | JSONL with timestamp |
| Configuration | .plist | INTERVAL_SECONDS env var |

## CONVENTIONS
- All shell scripts use `set -euo pipefail`
- JSONL format for structured logs (not plain text)
- Metrics in human-readable units (GB, %)
- 60-second default interval via env var

## ANTI-PATTERNS (THIS PROJECT)
- Direct launchctl commands (use manage_logger.sh)
- Modifying logs while daemon runs
- Paths outside SCRIPT_DIR

## UNIQUE STYLES
- CPU normalization by core count
- Disk space via diskutil (not df)
- Memory from vm_stat pages * pagesize

## COMMANDS
```bash
# Install/start daemon
./manage_logger.sh load

# Restart + clear logs
./reload_clear_logger.sh

# Stop daemon
./manage_logger.sh stop
```

## NOTES
- Requires macOS (uses vm_stat, diskutil, launchctl)
- Logs grow unbounded - needs rotation strategy
- CPU total can exceed 100% (multi-core)