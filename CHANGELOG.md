# Changelog

This file is the running journal of the lab. Every meaningful change, fix, win, or lesson learned gets logged here. This is what makes the repo a living document rather than a static portfolio piece.

Format: `[Date] — What happened and why it matters`

---

## March 2026

### 2026-03-14
**Microsoft Sentinel Onboarding**
- Connected home lab to Microsoft Sentinel via Azure Log Analytics Workspace
- Deployed Azure SOC-Gateway VM to act as syslog collector
- Built WireGuard tunnel from Proxmox cluster to Azure — zero open ports to internet
- Fixed AMA forwarding bridge (`10-azuremonitoragent.conf`) — logs now flowing end to end
- Filtered 6,000+ noisy events to keep within Microsoft Ambassador $150/month credit budget
- Node 2 confirmed: auth logs reaching Sentinel ✅

**First KQL Queries Written**
- Drafted brute force detection rule (T1110)
- Drafted sudo abuse detection rule (T1548.003)
- Both rules pending promotion to Analytics Rules (auto-incident generation)

**Repo Initialized**
- Created `hybrid-soc-lab` repository
- Established folder structure: infrastructure, detections, runbooks, threat-simulations, findings, scripts

---

### 2026-03-[TBD]
**Node 3 Onboarding** *(Planned)*
- Apply same repo fix and sudo install as Node 2
- Verify DC01 and Win11 VM logs reaching Sentinel
- Full 320GB cluster visible in Sentinel

---

### 2026-03-[TBD]
**Analytics Rules Activation** *(Planned)*
- Promote KQL queries to Sentinel Analytics Rules
- Validate that rules auto-generate Incidents in the Incident queue
- Document first real Sentinel Incident

---

## Upcoming Milestones

- [ ] First documented threat simulation (SSH brute force against Node 3 victim VM)
- [ ] Wazuh MITRE ATT&CK dashboard screenshot + write-up
- [ ] OpenVAS scan findings documented
- [ ] Security Onion Zeek/Suricata logs integrated with overall SOC picture
- [ ] First real finding write-up in `/findings`

---

> *"You can't improve what you don't measure. You can't show what you don't document."*
