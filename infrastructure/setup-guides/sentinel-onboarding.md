# Setup Guide: Microsoft Sentinel Onboarding

**Date Completed:** March 2026  
**Status:** ✅ Operational  
**Monthly Budget:** $150 (Microsoft Student Ambassador credits)

---

## Overview

This guide documents how logs flow from the on-premise Proxmox cluster to Microsoft Sentinel in Azure. The design goal was security-first: **no open ports on the home network**. All log traffic travels through an encrypted WireGuard tunnel.

```
Proxmox Node (Syslog)
        ↓
   WireGuard Tunnel (encrypted)
        ↓
   Azure SOC-Gateway VM
   (Syslog listener on port 514)
        ↓
   Azure Monitor Agent (AMA)
   (/etc/opt/microsoft/.../10-azuremonitoragent.conf)
        ↓
   Log Analytics Workspace
        ↓
   Microsoft Sentinel
```

---

## Prerequisites

- Azure subscription with Sentinel enabled
- Log Analytics Workspace created
- Azure VM (SOC-Gateway) — Ubuntu 22.04 recommended, Standard B2s or smaller to save credits
- WireGuard configured (see wireguard-tunnel.md)

---

## Step 1 — Deploy the SOC-Gateway VM

Deploy a small Ubuntu VM in Azure. This is your syslog collector — it does not need to be large.

Recommended size: **Standard B2s** (2 vCPU, 4GB RAM) — cheap and sufficient.

Key configuration:
- Place in same region as your Log Analytics Workspace
- No public inbound ports required (WireGuard handles connectivity)
- Assign a static private IP

---

## Step 2 — Install Azure Monitor Agent

```bash
# Install AMA on the SOC-Gateway VM
wget https://raw.githubusercontent.com/microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh
sudo sh onboard_agent.sh -w <WORKSPACE_ID> -s <PRIMARY_KEY>
```

Verify it's running:
```bash
systemctl status azuremonitoragent
```

---

## Step 3 — Configure the Log Forwarding Bridge

This is the critical config file that tells AMA where to pick up syslog data.

**File location:**
```
/etc/opt/microsoft/azuremonitoragent/config-cache/configchunks/10-azuremonitoragent.conf
```

**What to verify:**
- File exists and is not empty
- Syslog facility targets match what your nodes are sending (auth, syslog, kern, etc.)
- AMA service restarts cleanly after any edits: `sudo systemctl restart azuremonitoragent`

> **Note:** This file was the source of the first major troubleshooting session. AMA was running but logs were not appearing in Sentinel. The fix was ensuring this config file correctly pointed AMA to the rsyslog socket. Always verify this file after any AMA reinstall.

---

## Step 4 — Configure Nodes to Forward Syslog

On each Proxmox node or VM, configure rsyslog to forward to the SOC-Gateway VM's WireGuard IP:

```bash
# /etc/rsyslog.d/10-sentinel.conf
*.* @<WIREGUARD_GATEWAY_IP>:514
```

Restart rsyslog:
```bash
sudo systemctl restart rsyslog
```

---

## Step 5 — Validate Logs in Sentinel

In Microsoft Sentinel → Log Analytics → run:

```kql
Syslog
| where TimeGenerated > ago(15m)
| summarize count() by Computer
```

If your node hostnames appear — you're live.

---

## Budget Notes

To stay within the $150/month Ambassador credit:

- Use **Basic Logs** tier where possible for high-volume, low-value logs
- Use **Commitment Tiers** if ingestion is consistent
- Write KQL exclusion rules to drop noisy, low-value events before ingestion
- Monitor daily ingestion in: Sentinel → Settings → Workspace Settings → Usage

> In the first session, 6,000+ noisy events were identified and filtered. This alone extended the budget runway significantly.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Logs not in Sentinel | AMA bridge config missing/broken | Check `10-azuremonitoragent.conf` exists and is valid |
| AMA running but no data | rsyslog not forwarding | Check `/etc/rsyslog.d/` for forwarding rule |
| WireGuard connected but no logs | Firewall blocking UDP 514 | Check Azure NSG rules and local firewall |
| Budget spike | High-volume noisy logs ingested | Write KQL exclusion rules or filter at rsyslog level |
