#!/usr/bin/env python3
import json
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR / "data"
OUTPUT = SCRIPT_DIR / "dashboard.html"


def load_jsonl(path):
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


cpu = load_jsonl(DATA_DIR / "cpu.jsonl")
memory = load_jsonl(DATA_DIR / "memory.jsonl")
disk = load_jsonl(DATA_DIR / "disk.jsonl")

last_timestamp = max(
    entry["timestamp"] for dataset in (cpu, memory, disk) for entry in dataset
)

html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Resource Monitor Dashboard</title>

  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    html, body {{
      height: 100%;
      overflow: hidden;
    }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #1a1a2e;
      color: #eee;
      padding: 16px;
      display: flex;
      flex-direction: column;
    }}
    h1 {{
      text-align: center;
      margin-bottom: 12px;
      color: #00d4ff;
      font-size: 1.4rem;
      flex-shrink: 0;
    }}
    .last-updated {{
      text-align: center;
      margin-bottom: 16px;
      color: #aaa;
      font-size: 0.9rem;
      flex-shrink: 0;
    }}
    .dashboard {{

      display: grid;
      grid-template-columns: 1fr 1fr;
      grid-template-rows: auto 1fr;
      gap: 12px;
      flex: 1;
      min-height: 0;
    }}
    .card {{
      background: #16213e;
      border-radius: 10px;
      padding: 12px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
      display: flex;
      flex-direction: column;
      min-height: 0;
    }}
    .card h2 {{
      margin-bottom: 8px;
      color: #00d4ff;
      font-size: 1rem;
      flex-shrink: 0;
    }}
    .disk-card {{
      grid-column: span 2;
    }}


    .stats-table {{
      width: 100%;
      border-collapse: collapse;
      margin-top: 8px;
      flex-shrink: 0;
    }}
    .stats-table th, .stats-table td {{
      padding: 4px 8px;
      text-align: right;
      border-bottom: 1px solid #2a3f5f;
      font-size: 0.85rem;
    }}
    .stats-table th {{ color: #888; font-weight: normal; text-align: left; }}
    .stats-table td {{ font-family: monospace; color: #00ff88; }}
  </style>
</head>
<body>
  <h1>Resource Monitor Dashboard</h1>
  <div class="last-updated">Last update: {last_timestamp}</div>
  <div class="dashboard">
    <div class="card">
      <h2>CPU Percentiles</h2>
      <table class="stats-table" id="cpu-stats"></table>
    </div>
    <div class="card">
      <h2>Memory Percentiles</h2>
      <table class="stats-table" id="memory-stats"></table>
    </div>
    <div class="card disk-card">
      <h2>Disk Usage</h2>
      <table class="stats-table" id="disk-stats"></table>
    </div>
  </div>

  <script>
    const cpuData = {json.dumps(cpu)};
    const memoryData = {json.dumps(memory)};
    const diskData = {json.dumps(disk)};
    const lastTimestamp = "{last_timestamp}";

    function percentile(arr, p) {{
      const sorted = [...arr].sort((a, b) => a - b);
      const idx = (p / 100) * (sorted.length - 1);
      const lower = Math.floor(idx);
      const upper = Math.ceil(idx);
      if (lower === upper) return sorted[lower];
      return sorted[lower] + (sorted[upper] - sorted[lower]) * (idx - lower);
    }}

    function computePercentiles(values) {{
      return {{
        p50: percentile(values, 50),
        p75: percentile(values, 75),
        p90: percentile(values, 90),
        p99: percentile(values, 99),
        p999: percentile(values, 99.9)
      }};
    }}

    function renderStatsTable(elementId, stats) {{
      document.getElementById(elementId).innerHTML = `
        <tr><th>Percentile</th><th>P50</th><th>P75</th><th>P90</th><th>P99</th><th>P99.9</th></tr>
        <tr>
          <td></td>
          <td>${{stats.p50.toFixed(1)}}%</td>
          <td>${{stats.p75.toFixed(1)}}%</td>
          <td>${{stats.p90.toFixed(1)}}%</td>
          <td>${{stats.p99.toFixed(1)}}%</td>
          <td>${{stats.p999.toFixed(1)}}%</td>
        </tr>
      `;
    }}

    function renderDiskTable(latest) {{
      document.getElementById('disk-stats').innerHTML = `
        <tr><th>Used</th><th>Total</th><th>Usage</th></tr>
        <tr>
          <td>${{latest.used_gb.toFixed(1)}} GB</td>
          <td>${{latest.total_gb.toFixed(1)}} GB</td>
          <td>${{latest.used_percent.toFixed(1)}}%</td>
        </tr>
      `;
    }}

    const cpuValues = cpuData.map(d => d.normalized_percent);
    const cpuStats = computePercentiles(cpuValues);
    renderStatsTable('cpu-stats', cpuStats);

    const memValues = memoryData.map(d => d.used_percent);
    const memStats = computePercentiles(memValues);
    renderStatsTable('memory-stats', memStats);

    const latestDisk = diskData[diskData.length - 1];
    renderDiskTable(latestDisk);
  </script>
</body>
</html>
"""

OUTPUT.write_text(html)
print(f"Dashboard generated: {OUTPUT}")
print(f"Open in browser: file://{OUTPUT}")
