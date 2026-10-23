# 🛡️ Hybrid SOC Home Lab — Detection Engineering & Incident Response

**Built by Emilio Burgohy | Cybersecurity Analyst | USF MS Cybercrime & Digital Forensics**

[![Security+](https://img.shields.io/badge/CompTIA-Security%2B-red)](https://www.comptia.org/)
[![ISC2 CC](https://img.shields.io/badge/ISC2-CC-blue)](https://www.isc2.org/)
[![CySA+](https://img.shields.io/badge/CompTIA-CySA%2B-orange)](https://www.comptia.org/)
[![Microsoft Sentinel](https://img.shields.io/badge/Microsoft-Sentinel-blue)](https://azure.microsoft.com/en-us/products/microsoft-sentinel)
[![Wazuh](https://img.shields.io/badge/SIEM-Wazuh-brightgreen)](https://wazuh.com/)

---

## What this is

A **home lab** I built to practice the security operations lifecycle end to end: stand up
infrastructure, forward logs to a SIEM, write detections, attack my own environment, and document
what the detections caught (and what they missed). It is a learning project, not a production SOC —
the value is in the workflow, the detections that are backed by real evidence, and the lessons from
getting each piece working.

Everything shown below with a screenshot or a write-up actually ran in this environment. The
**Roadmap** section is honest about what is built versus what is still planned, and the **What I
learned** section captures the problems I had to solve along the way.

> Note on uptime: this is a lab, and the Azure side is deliberately deallocated when not in use to
> stay inside a student credit budget. The dashboards and incidents below are real captures from
> when the pipeline was running, not a claim that it runs 24/7.

---

## What actually works (evidenced)

- **3-node Proxmox cluster** (Minisforum MSA2 + 2× MS01, 320 GB RAM total) running Wazuh,
  OpenVAS, a Windows Server domain controller (DC01), and a Windows 11 victim VM.
- **Encrypted log pipeline to the cloud** — all nodes forward syslog to an Azure SOC-Gateway VM
  over a **WireGuard tunnel with zero open inbound ports**, then into Microsoft Sentinel via the
  Azure Monitor Agent. Confirmed with all four nodes reporting
  ([screenshot](screenshots/04-sentinel-all-nodes-reporting.png),
  [tunnel](screenshots/03-wireguard-tunnel-all-nodes-connected.png)).
- **5 Sentinel analytics rules** deployed and enabled, auto-generating incidents
  ([screenshot](screenshots/02-sentinel-analytics-rules-active.png)). Two of the custom KQL rules
  are published here: [brute force](detections/kql/brute-force-detection.kql) and
  [sudo abuse](detections/kql/sudo-abuse-detection.kql).
- **SSH brute-force detection, end to end** — Hydra attack from Kali → failed logins forwarded
  over WireGuard → KQL rule fires → Sentinel auto-creates a Medium incident, investigated with the
  entity graph and timeline. Full walkthrough with nine screenshots is in the
  [Threat Simulations](#️-threat-simulations) section below.
- **Two Active Directory attack simulations against DC01**, each with attacker commands, the Wazuh
  rules that fired, and the detection gap found:
  - [Password Spray (T1110.003)](threat-simulations/01-password-spray/01-password-spray.md) —
    CrackMapExec, domain Administrator compromised, Event ID 4625/4624 analysis.
  - [AS-REP Roasting (T1558.004)](threat-simulations/02-asrep-roasting/02-asrep-roasting.md) —
    Impacket + Hashcat, and the key finding that **default Windows audit policy does not log
    Kerberos AS events**, so the attack was invisible until auditing was manually enabled.
- **Incident response runbook** for brute force
  ([IRP-001](runbooks/IRP-001-brute-force.md)) with validation/scoping KQL, and a
  **log-pipeline health-check script** ([log-health-check.sh](scripts/log-health-check.sh)).
- **Two BSS engagement reports** (PDF) produced from this lab: an ASUS GT-AXE16000 router audit and
  a purple-team port-scan detection exercise — see [/findings](findings/).

---

## 🏗️ Infrastructure

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOME NETWORK                             │
│                     (Unifi Ecosystem)                           │
│   UDM Pro Max → USW Pro 48 PoE → 8-Port Agg → 24-Port Switch  │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼─────┐    ┌─────▼────┐    ┌─────▼────┐
   │  NODE 1  │    │  NODE 2  │    │  NODE 3  │
   │ MSA2 Mini│    │  MS01    │    │  MS01    │
   │ 128GB RAM│    │ 96GB RAM │    │ 96GB RAM │
   │  4TB NVMe│    │  2TB NVMe│    │  2TB NVMe│
   │          │    │          │    │          │
   │ [Wazuh]  │    │[OpenVAS] │    │  [DC01]  │
   │   SIEM   │    │  Vuln    │    │ Domain   │
   │          │    │  Scanner │    │Controller│
   │          │    │          │    │[Win11 VM]│
   │          │    │          │    │ Victim   │
   └──────────┘    └──────────┘    └──────────┘
        │                │                │
        └────────────────┼────────────────┘
                         │ Proxmox Cluster (All 3 Nodes)
                         │ 320GB RAM Total
                         │
                    ┌────▼────┐
                    │WireGuard│  ← Encrypted tunnel
                    │ Tunnel  │     (no open ports)
                    └────┬────┘
                         │
               ┌─────────▼──────────┐
               │    AZURE CLOUD      │
               │                    │
               │  [SOC-Gateway-VM]  │
               │   Ubuntu + AMA     │
               │   + rsyslog        │
               │        ↓           │
               │ [Microsoft Sentinel]│
               │   5 Analytics Rules│
               │   Incident Mgmt    │
               └────────────────────┘
```

### Hardware

| Device | Role | RAM | Storage |
|--------|------|-----|---------|
| Minisforum MSA2 (Node 1) | Proxmox / Wazuh SIEM | 128 GB | 4 TB NVMe |
| Minisforum MS01 (Node 2) | Proxmox / OpenVAS | 96 GB | 2 TB NVMe |
| Minisforum MS01 (Node 3) | Proxmox / DC01 + Win11 victim VM | 96 GB | 2 TB NVMe |
| GMKtec Mini PC | Security Onion (bare metal) | 32 GB | 1 TB HDD |
| Zimaboard 832 | Kali Linux attack platform | — | — |

**Network:** Unifi UDM Pro Max · USW Pro 48 PoE · 8-Port Aggregation · 24-Port Switch

### Security stack

| Tool | Category | Role in the lab |
|------|----------|-----------------|
| Microsoft Sentinel | Cloud SIEM | Central log analysis, KQL detections, incident management — **in use** |
| Wazuh | On-prem SIEM/XDR | Host IDS, FIM, MITRE ATT&CK mapping — **in use** (AD sims) |
| Azure Monitor Agent | Log forwarding | Syslog → Sentinel pipeline via SOC-Gateway — **in use** |
| WireGuard | Secure tunnel | Encrypted on-prem → Azure forwarding, no open ports — **in use** |
| Proxmox VE | Hypervisor | 3-node cluster — **in use** |
| Kali Linux | Threat simulation | Authorized attack simulation to validate detections — **in use** |
| OpenVAS | Vulnerability scanner | Deployed; scan findings **not yet documented here** |
| Security Onion | NSM / IDS | Bare-metal deploy; Sentinel integration **planned** |
| Unifi | Network | VLAN segmentation and firewalling |

---

## 📊 Sentinel Analytics Rules

Five rules enabled in Sentinel ([screenshot](screenshots/02-sentinel-analytics-rules-active.png)):

| Rule | Severity | Type | Tactic |
|------|----------|------|--------|
| SSH Brute Force Attempt | Medium | Scheduled (custom) | Credential Access, Initial Access |
| Successful Login After Multiple Failures | High | Scheduled (custom) | Initial Access |
| New Local User Account Created | Low | Scheduled (custom) | Persistence, Privilege Escalation |
| Privileged Command Execution (Sudo) — Proxmox | Medium | Scheduled (custom) | Privilege Escalation |
| Advanced Multistage Attack Detection | High | Fusion (built-in) | Multiple |

The brute-force and sudo-abuse KQL are published in [detections/kql/](detections/kql/). The other
three custom rules are enabled in the tenant but their KQL is not yet exported to this repo.

---

## ⚔️ Threat Simulations

### ✅ SSH Brute Force (March 2026)

**Attacker:** Kali Linux · **Target:** Node 3 · **Tool:** Hydra

```bash
hydra -l root -P /usr/share/wordlists/rockyou.txt -t 10 -s 22 <target> ssh
```

**Detection chain:**
```
Kali launches attack
    → Failed logins logged by Node 3 auth facility
    → rsyslog forwards via WireGuard tunnel to SOC-Gateway
    → Azure Monitor Agent ingests into Sentinel
    → KQL rule fires (5+ failures in 5 min threshold)
    → Incident auto-generated: "SSH Brute Force Attempt" (Medium)
    → Investigation graph maps attacker IP → target host
```

| # | Evidence |
|---|----------|
| 01 | [Live syslog: failed SSH attempts arriving from Kali](screenshots/01-sentinel-brute-force-syslog-detection.png) |
| 02 | [All 5 analytics rules active in Sentinel](screenshots/02-sentinel-analytics-rules-active.png) |
| 03 | [WireGuard tunnel: all nodes connected](screenshots/03-wireguard-tunnel-all-nodes-connected.png) |
| 04 | [All nodes reporting logs to Sentinel](screenshots/04-sentinel-all-nodes-reporting.png) |
| 05 | [Incident auto-generated (Medium)](screenshots/05-sentinel-ssh-brute-force-incident.png) |
| 06 | [Incident details panel](screenshots/06-sentinel-incident-details.png) |
| 07 | [Investigation graph: attacker IP → target](screenshots/07-sentinel-incident-investigation-graph.png) |
| 08 | [Incident timeline](screenshots/08-sentinel-incident-timeline.png) |
| 09 | [Entities extracted from the incident](screenshots/09-sentinel-incident-entities.png) |

### ✅ Password Spray against DC01 (April 2026)

CrackMapExec password spray against the `cyberlab.local` domain controller; domain Administrator and
a standard user compromised. Documents the exact Wazuh rules that fired (4625 logon failure, 4624
remote logon flagged as possible Pass-the-Hash, 4672 special privileges) and the key fields to triage
each. → [Full write-up](threat-simulations/01-password-spray/01-password-spray.md)

### ✅ AS-REP Roasting against DC01 (April 2026)

Impacket `GetNPUsers` to pull a Kerberos AS-REP hash for an account with pre-auth disabled, cracked
offline with Hashcat. **Key lesson: default Windows audit policy does not log Kerberos Authentication
Service events**, so the attack left no trace until Kerberos auditing was manually enabled on DC01 —
after which Event ID 4768 became visible to Wazuh. → [Full write-up](threat-simulations/02-asrep-roasting/02-asrep-roasting.md)

### ✅ ASUS GT-AXE16000 Router Audit (May 2026)

Authorized security audit of a factory-reset ASUS router on an isolated segment. Six findings
including a Critical authentication-bypass issue consistent with CVE-2024-3080 (CVSS 9.8), plaintext
HTTP admin interface, version disclosure, and UPnP exposure.
→ [Full report (PDF)](findings/Audit_ASUS_AXE16000_Factory_Reset.pdf)

---

## 💡 What I learned

The parts that taught me the most were the things that didn't work the first time:

- **Log pipelines fail silently.** The Azure Monitor Agent would show as "running" while no data
  reached Sentinel. The fix was the AMA bridge config (`10-azuremonitoragent.conf`) correctly
  pointing at the rsyslog socket. Lesson: "agent is up" is not "logs are flowing" — verify at the
  destination, which is why I wrote [log-health-check.sh](scripts/log-health-check.sh).
- **AppArmor silently blocked rsyslog forwarding**, and sysctl/iptables settings didn't survive
  reboots until I made them persistent — so a reboot would quietly break the pipeline.
- **Cloud costs force design discipline.** To stay inside a student credit budget I deallocate the
  Azure VM when idle and filter noisy events before ingestion. Deallocation drops the gateway's
  WireGuard IP, which was its own recurring lesson in why the health check matters.
- **Detections are only as good as the logging underneath them.** AS-REP roasting was completely
  invisible until I enabled Kerberos auditing on the DC. A missing audit setting is a blind spot no
  SIEM rule can cover.
- **Writing the runbook changed how I read the alert.** Building [IRP-001](runbooks/IRP-001-brute-force.md)
  forced me to define what "validate the alert" and "scope the attack" actually mean in KQL before
  an incident, not during one.

---

## 🗺️ Roadmap

Built and evidenced above. Still planned:

- [ ] Export the remaining three custom analytics rules' KQL into this repo
- [ ] Document OpenVAS scan findings
- [ ] Integrate Security Onion (Zeek/Suricata) network telemetry with the Sentinel picture
- [ ] Additional AD simulations: lateral movement, Kerberoasting, privilege escalation
- [ ] Automated response playbooks (Sentinel automation rules / Logic Apps)
- [ ] Fill in the per-folder READMEs with setup guides

---

## 📁 Repository Structure

```
hybrid-soc-lab/
├── README.md
├── CHANGELOG.md                 ← running journal of changes, fixes, and lessons
├── detections/
│   └── kql/
│       ├── brute-force-detection.kql
│       └── sudo-abuse-detection.kql
├── runbooks/
│   ├── IRP-001-brute-force.md
│   └── brute-force-response.md
├── threat-simulations/
│   ├── 01-password-spray/       ← write-up + Wazuh/Windows evidence
│   └── 02-asrep-roasting/       ← write-up + Impacket/Hashcat/Wazuh evidence
├── infrastructure/
│   └── setup-guides/
│       └── sentinel-onboarding.md
├── findings/                    ← BSS engagement reports (PDF)
├── scripts/
│   └── log-health-check.sh
└── screenshots/                 ← Sentinel incident + pipeline evidence
```

---

## 🎓 Certifications & Education

| Credential | Status |
|-----------|--------|
| CompTIA Security+ | ✅ Certified |
| ISC2 CC | ✅ Certified |
| CompTIA CySA+ | ✅ Certified |
| CompTIA PenTest+ | 🔄 In progress |
| BS Cybersecurity (SPC) | ✅ December 2025 |
| MS Cybercrime & Digital Forensics (USF) | 🎓 In progress — GPA 3.8 |
| US Army — 9 years, 25L Signal/Communications | ✅ Veteran |

---

## 📬 Connect

- **LinkedIn:** [linkedin.com/in/emilioburgohy1984](https://linkedin.com/in/emilioburgohy1984)
- **Email:** emilioburgohy@gmail.com
- **GitHub:** [github.com/ebuggy84](https://github.com/ebuggy84)

> *Building real SOC skills — one detection at a time.*
