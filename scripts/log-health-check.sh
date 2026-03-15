#!/bin/bash
# ============================================================
# Script: log-health-check.sh
# Purpose: Verify all nodes are actively sending logs to Sentinel
# Author: Emilio Burgohy
# Usage: Run on the Azure SOC-Gateway VM or any node
# ============================================================

echo "======================================"
echo "  SOC Log Pipeline Health Check"
echo "  $(date)"
echo "======================================"

# Check AMA agent status
echo ""
echo "[1] Azure Monitor Agent Status:"
systemctl is-active azuremonitoragent && echo "  ✅ AMA Agent: RUNNING" || echo "  ❌ AMA Agent: STOPPED"

# Check rsyslog / syslog-ng forwarding
echo ""
echo "[2] Syslog Forwarder Status:"
systemctl is-active rsyslog && echo "  ✅ rsyslog: RUNNING" || echo "  ❌ rsyslog: STOPPED"

# Check WireGuard tunnel
echo ""
echo "[3] WireGuard Tunnel:"
wg show | grep -q "latest handshake" && echo "  ✅ WireGuard: CONNECTED" || echo "  ❌ WireGuard: NO RECENT HANDSHAKE"

# Check log volume (last 5 min)
echo ""
echo "[4] Recent Log Activity (last 5 min):"
LOG_COUNT=$(journalctl --since "5 minutes ago" | wc -l)
echo "  📊 Lines generated: $LOG_COUNT"

if [ "$LOG_COUNT" -lt 10 ]; then
  echo "  ⚠️  WARNING: Low log volume — check agent and syslog config"
fi

# Check AMA config file
echo ""
echo "[5] AMA Forwarding Config:"
CONFIG_FILE="/etc/opt/microsoft/azuremonitoragent/config-cache/configchunks/10-azuremonitoragent.conf"
if [ -f "$CONFIG_FILE" ]; then
  echo "  ✅ Config file exists: $CONFIG_FILE"
else
  echo "  ❌ Config file MISSING — AMA may not be forwarding logs"
fi

echo ""
echo "======================================"
echo "  Health check complete."
echo "======================================"
