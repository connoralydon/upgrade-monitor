#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/data"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-60}"

mkdir -p "$LOG_DIR"

while true; do
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  cpu_total="$(ps -A -o %cpu= | awk '{sum+=$1} END {printf "%.1f", sum}')"
  cpu_cores="$(sysctl -n hw.ncpu)"
  cpu_normalized="$(awk -v total="$cpu_total" -v cores="$cpu_cores" 'BEGIN {printf "%.1f", total/cores}')"
  cpu_line="total=${cpu_total}% normalized=${cpu_normalized}% cores=${cpu_cores}"

  pagesize="$(sysctl -n hw.pagesize)"
  mem_total_bytes="$(sysctl -n hw.memsize)"
  vm_stat_output="$(vm_stat)"
  pages_active="$(printf "%s" "$vm_stat_output" | awk '/Pages active/ {gsub("\\.","",$3); print $3}')"
  pages_inactive="$(printf "%s" "$vm_stat_output" | awk '/Pages inactive/ {gsub("\\.","",$3); print $3}')"
  pages_speculative="$(printf "%s" "$vm_stat_output" | awk '/Pages speculative/ {gsub("\\.","",$3); print $3}')"
  pages_wired="$(printf "%s" "$vm_stat_output" | awk '/Pages wired down/ {gsub("\\.","",$4); print $4}')"
  pages_compressed="$(printf "%s" "$vm_stat_output" | awk '/Pages occupied by compressor/ {gsub("\\.","",$5); print $5}')"
  pages_compressed="${pages_compressed:-0}"
  mem_used_pages="$((pages_active + pages_inactive + pages_speculative + pages_wired + pages_compressed))"
  mem_used_bytes="$((mem_used_pages * pagesize))"
  mem_used_gb="$(awk -v b="$mem_used_bytes" 'BEGIN {printf "%.2f", b/1024/1024/1024}')"
  mem_total_gb="$(awk -v b="$mem_total_bytes" 'BEGIN {printf "%.2f", b/1024/1024/1024}')"
  mem_used_pct="$(awk -v used="$mem_used_bytes" -v total="$mem_total_bytes" 'BEGIN {printf "%.1f", used/total*100}')"
  mem_line="used=${mem_used_gb}GB/${mem_total_gb}GB (${mem_used_pct}%)"

  disk_info="$(diskutil info / | awk -F'[()]' '/Disk Size:/ || /Total Size:/ {total=$2; gsub(/[^0-9]/, "", total)} /Container Free Space:/ {free=$2; gsub(/[^0-9]/, "", free)} /Volume Free Space:/ {free=$2; gsub(/[^0-9]/, "", free)} END {if (total=="" || free=="") {printf "0 0 0"; exit} used=total-free; pct=(total>0)?(used/total*100):0; printf "%.2f %.2f %.1f", used/1024/1024/1024, total/1024/1024/1024, pct}')"
  disk_used_gb="$(echo "$disk_info" | awk '{print $1}')"
  disk_total_gb="$(echo "$disk_info" | awk '{print $2}')"
  disk_used_pct="$(echo "$disk_info" | awk '{print $3}')"

  printf "{\"timestamp\": \"%s\", \"total_percent\": %s, \"normalized_percent\": %s, \"cores\": %s}\n" "$timestamp" "$cpu_total" "$cpu_normalized" "$cpu_cores" >> "$LOG_DIR/cpu.jsonl"
  printf "{\"timestamp\": \"%s\", \"used_gb\": %s, \"total_gb\": %s, \"used_percent\": %s}\n" "$timestamp" "$mem_used_gb" "$mem_total_gb" "$mem_used_pct" >> "$LOG_DIR/memory.jsonl"
  printf "{\"timestamp\": \"%s\", \"used_gb\": %s, \"total_gb\": %s, \"used_percent\": %s}\n" "$timestamp" "$disk_used_gb" "$disk_total_gb" "$disk_used_pct" >> "$LOG_DIR/disk.jsonl"

  sleep "$INTERVAL_SECONDS"
done
