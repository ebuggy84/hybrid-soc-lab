# 🛡️ Hybrid SOC Home Lab — Detection Engineering & Incident Response

**Built by Emilio Burgohy | Cybersecurity Analyst | USF MS Cybercrime & Digital Forensics**

[![Security+](https://img.shields.io/badge/CompTIA-Security%2B-red)](https://www.comptia.org/)
[![CySA+](https://img.shields.io/badge/CompTIA-CySA%2B-red)](https://www.comptia.org/)
[![Microsoft Sentinel](https://img.shields.io/badge/Microsoft-Sentinel-blue)](https://azure.microsoft.com/en-us/products/microsoft-sentinel)
[![Wazuh](https://img.shields.io/badge/SIEM-Wazuh-brightgreen)](https://wazuh.com/)

---

## 🎯 Mission

This lab simulates a **real-world Hybrid SOC** by connecting on-premise infrastructure to cloud-native security tooling. The goal is to practice the full security operations lifecycle:

- **Detection Engineering** — Writing rules that catch real attacker behavior
- **Incident Response** — Triaging, investigating, and documenting security events
- **Threat Simulation** — Attacking my own environment to validate detections
- **Cloud + On-Prem Integration** — Bridging local hardware to Microsoft Sentinel via secure tunnel

> This is not a theoretical lab. Every detection rule here was written in response to something observed in this environment.

---

## 🏗️ Infrastructure Overview

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
               │  AZURE CLOUD        │
               │                    │
               │  [SOC-Gateway-VM]  │
               │   Log Collector    │
               │   AMA Agent        │
               │        ↓           │
               │ [Microsoft Sentinel]│
               │   KQL Queries      │
               │   Analytics Rules  │
               │   Incident Mgmt    │
               └────────────────────┘
                         │
               ┌─────────▼──────────┐
               │  Security Onion    │  ← Bare metal (GMKtec 32GB)
               │  Network IDS/NSM   │
               └────────────────────┘
```

---

## 🖥️ Hardware Inventory

| Device | Role | RAM | Storage | Status |
|--------|------|-----|---------|--------|
| Minisforum MSA2 (Node 1) | Proxmox / Wazuh SIEM | 128GB | 4TB NVMe | 🟢 Online |
| Minisforum MS01 (Node 2) | Proxmox / OpenVAS | 96GB | 2TB NVMe | 🟢 Online |
| Minisforum MS01 (Node 3) | Proxmox / DC01 + Victim VM | 96GB | 2TB NVMe | 🟢 Online |
| GMKtec Mini PC | Security Onion (bare metal) | 32GB | 1TB HDD | 🟢 Online |
| Zimaboard 832 (x3) | Edge devices / Available | - | - | 🟡 Standby |
| Zimaboard 1664 (x2) | Edge devices / Available | - | - | 🟡 Standby |
| Kali Linux (Zimaboard) | Attack simulation platform | - | - | 🟢 Online |

**Network:** Unifi UDM Pro Max | USW Pro 48 PoE | 8-Port Aggregation | 24-Port Switch

---

## 🔧 Security Stack

| Tool | Category | Purpose |
|------|----------|---------|
| Microsoft Sentinel | Cloud SIEM | Central log analysis, KQL detections, incident management |
| Wazuh | On-Prem SIEM/XDR | Host-based IDS, FIM, MITRE ATT&CK mapping |
| Security Onion | NSM / IDS | Network traffic analysis, Zeek logs, Suricata alerts |
| OpenVAS | Vulnerability Scanner | Continuous vulnerability assessment of lab assets |
| WireGuard | Secure Tunnel | Encrypted on-prem to Azure log forwarding |
| Azure Monitor Agent | Log Forwarding | Syslog → Sentinel pipeline via SOC-Gateway VM |
| Proxmox VE | Hypervisor | 3-node cluster managing all VMs |
| Unifi | Network Infrastructure | VLAN segmentation, firewall rules, traffic mirroring |
| Kali Linux | Threat Simulation | Authorized attack simulation to validate detections |

---

## 📁 Repository Structure

```
/hybrid-soc-homelab
│
├── README.md                    ← You are here
│
├── /infrastructure              ← Lab setup guides & configs (sanitized)
│   ├── proxmox-cluster-setup.md
│   ├── wireguard-tunnel-setup.md
│   ├── azure-sentinel-onboarding.md
│   └── network-segmentation.md
│
├── /detections                  ← KQL & Wazuh detection rules
│   ├── README.md
│   ├── kql/
│   │   ├── brute-force-detection.kql
│   │   ├── sudo-abuse-detection.kql
│   │   └── after-hours-login.kql
│   └── wazuh/
│       └── custom-rules.xml
│
├── /runbooks                    ← Incident response playbooks
│   ├── README.md
│   ├── brute-force-response.md
│   ├── malware-triage.md
│   └── unauthorized-access.md
│
├── /findings                    ← Real detections from this lab
│   ├── README.md
│   └── (sanitized screenshots and write-ups)
│
└── /scripts                     ← Automation and utility scripts
    ├── README.md
    └── log-health-check.sh
```

---

## 🚀 Key Achievements

- ✅ Built 3-node Proxmox cluster (320GB RAM) running enterprise security tooling
- ✅ Established encrypted WireGuard tunnel — zero open ports to internet
- ✅ Onboarded logs to Microsoft Sentinel; filtered 6,000+ noise events to optimize budget
- ✅ Deployed Wazuh SIEM with MITRE ATT&CK framework mapping
- ✅ Running continuous OpenVAS vulnerability scans across lab environment
- ✅ Active Directory lab (DC01 + Windows 11 victim) for realistic attack simulation
- 🔄 Building KQL Analytics Rules for automated incident generation
- 🔄 Threat simulation exercises (brute force, privilege escalation) planned

---

## 📬 Connect

- **LinkedIn:** [linkedin.com/in/emilioburgohy198](https://linkedin.com/in/emilioburgohy198)
- **Email:** emilioburgohy@gmail.com
- **GitHub:** [github.com/ebuggy84](https://github.com/ebuggy84)

> *US Army Veteran (9 years, 25L Communications) | Security+ | CySA+ (In Progress)*
