# 🛡️ Hybrid SOC Home Lab

**Built by:** Emilio Burgohy | US Army Veteran (9 years, 25L) | BS Cybersecurity | MS Cybercrime & Digital Forensics (in progress)

[![Security+](https://img.shields.io/badge/Certified-Security%2B-red)](https://www.comptia.org/certifications/security)
[![ISC2 CC](https://img.shields.io/badge/Certified-ISC2%20CC-blue)](https://www.isc2.org/certifications/cc)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Emilio%20Burgohy-blue)](https://linkedin.com/in/emilioburgohy198)

---

## 📋 Project Overview

A fully functional hybrid Security Operations Center (SOC) lab combining on-premises Proxmox infrastructure with Microsoft Azure cloud services. The lab simulates a real enterprise SOC environment — ingesting logs from multiple nodes, detecting threats with custom KQL analytics rules, and auto-generating incidents for analyst triage.

**Core Objective:** Build hands-on SOC analyst skills including SIEM management, threat detection, incident response, and attack simulation.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    HOME LAB (On-Premises)                │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ MSA2-Node1  │  │ MS01-Node2  │  │ MS01-Node3  │    │
│  │ 128GB/4TB   │  │  96GB/2TB   │  │  96GB/2TB   │    │
│  │ Wazuh SIEM  │  │  OpenVAS    │  │ DC01 + Win11│    │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘    │
│         │                │                │             │
│  ┌──────┴────────────────┴────────────────┴──────┐     │
│  │         Unifi Network (UDM Pro Max)            │     │
│  │    USW Pro 48 PoE | 8-port Agg | 24-port      │     │
│  └──────────────────────┬────────────────────────┘     │
│                         │                               │
│  ┌──────────────────────┴──────────┐                   │
│  │  Security Onion (GMKtec 32GB)   │                   │
│  │  Kali Linux (Zimaboard 832)     │                   │
│  └─────────────────────────────────┘                   │
└─────────────────────────┬───────────────────────────────┘
                          │ WireGuard VPN Tunnel
                          │ (Encrypted)
┌─────────────────────────┴───────────────────────────────┐
│                  MICROSOFT AZURE (Cloud)                  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │         SOC-Gateway-VM (Ubuntu 24.04)            │   │
│  │         Standard B2s | IP: 20.55.2.179          │   │
│  │         WireGuard Gateway | rsyslog Forwarder    │   │
│  └─────────────────────┬────────────────────────────┘   │
│                        │                                 │
│  ┌─────────────────────┴────────────────────────────┐   │
│  │     Microsoft Sentinel + Log Analytics Workspace  │   │
│  │            (soc-log-repository)                   │   │
│  │     5 Active Analytics Rules | Incident Response  │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## 🖥️ Hardware Inventory

### Proxmox Cluster (3 Nodes — 320GB RAM Total)

| Node | Hardware | RAM | Storage | Role |
|------|----------|-----|---------|------|
| Node1 | MSA2 | 128GB | 4TB | Wazuh SIEM/XDR |
| Node2 | MS01 | 96GB | 2TB | OpenVAS Vulnerability Scanner |
| Node3 | MS01 | 96GB | 2TB | DC01 (Windows Server) + Windows 11 Victim VM |

### Dedicated Devices

| Device | Hardware | Role |
|--------|----------|------|
| Security Onion | GMKtec Mini PC 32GB | Network Security Monitoring (bare metal) |
| Kali Linux | Zimaboard 832 | Penetration Testing (bare metal) |

### Network

| Device | Role |
|--------|------|
| UDM Pro Max | Core Router / Firewall |
| USW Pro 48 PoE | Core Switch |
| 8-port Aggregation Switch | Uplinks |
| 24-port Switch | Access Layer |

---

## ☁️ Azure Infrastructure

| Resource | Details |
|----------|---------|
| Subscription | Microsoft Student Ambassador ($150/month credits) |
| SOC-Gateway-VM | Ubuntu 24.04, Standard B2s |
| Public IP | 20.55.2.179 |
| Log Analytics Workspace | soc-log-repository |
| SIEM | Microsoft Sentinel |
| DCR | SOC-Linux-Logs |

---

## 🔐 WireGuard VPN Tunnel

Encrypted tunnel connecting all Proxmox nodes to the Azure gateway for secure log forwarding.

| Node | WireGuard IP |
|------|-------------|
| SOC-Gateway-VM | 10.0.0.1 |
| MS01-Node2 | 10.0.0.2 |
| MS01-Node3 | 10.0.0.3 |
| MSA2-Node1 | 10.0.0.5 |

---

## 📊 Microsoft Sentinel Analytics Rules

5 active custom and built-in detection rules:

| Rule | Severity | Type | Tactic |
|------|----------|------|--------|
| SSH Brute Force Attempt | Medium | Scheduled (Custom) | Credential Access, Initial Access |
| Successful Login After Multiple Failures | High | Scheduled (Custom) | Initial Access |
| New Local User Account Created | Low | Scheduled (Custom) | Persistence, Privilege Escalation |
| Privileged Command Execution (Sudo) - Proxmox | Medium | Scheduled (Custom) | Privilege Escalation |
| Advanced Multistage Attack Detection | High | Fusion (Built-in) | Multiple |

---

## ⚔️ Threat Simulations

### SSH Brute Force Attack (Completed)

**Attacker:** Kali Linux (10.0.30.12)  
**Target:** MS01-Node3 (10.0.30.13)  
**Tool:** Hydra  
**Result:** Sentinel detected attack and auto-generated Medium severity incident

**Attack command used:**
```bash
hydra -l root -P /usr/share/wordlists/rockyou.txt -t 10 -s 22 10.0.30.13 ssh
```

**Detection timeline:**
1. Kali launched SSH brute force against Node3
2. Failed login attempts logged by Node3 rsyslog
3. rsyslog forwarded logs through WireGuard tunnel to gateway
4. Azure Monitor Agent ingested logs into Sentinel
5. KQL analytics rule fired (5+ failures in 5 minutes threshold)
6. Incident auto-generated: "SSH Brute Force Attempt" (Medium)
7. Investigation graph showed attacker IP → target host mapping

**Screenshots:**

| Screenshot | Description |
|-----------|-------------|
| `01-sentinel-brute-force-syslog-detection.png` | Live Syslog showing failed SSH attempts from Kali |
| `02-sentinel-analytics-rules-active.png` | All 5 analytics rules enabled |
| `03-wireguard-tunnel-all-nodes-connected.png` | All 4 nodes connected via WireGuard |
| `04-sentinel-all-nodes-reporting.png` | All nodes sending logs to Sentinel |
| `05-sentinel-ssh-brute-force-incident.png` | Auto-generated incident in Sentinel |
| `06-sentinel-incident-details.png` | Incident details panel |
| `07-sentinel-incident-investigation-graph.png` | Attack investigation graph |
| `08-sentinel-incident-timeline.png` | Incident timeline |
| `09-sentinel-incident-entities.png` | Entities extracted from incident |

---

## 🔧 Key Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| WireGuard config | `/etc/wireguard/wg0.conf` | VPN tunnel configuration |
| rsyslog AMA forwarder | `/etc/rsyslog.d/10-azuremonitoragent-omfwd.conf` | Forward logs to Azure Monitor Agent |
| Node rsyslog forwarder | `/etc/rsyslog.d/60-azure-gateway.conf` | Forward node logs to gateway |
| sysctl persistence | `/etc/sysctl.d/99-soc-gateway.conf` | ip_forward + rp_filter settings |
| AppArmor fix | `/etc/systemd/system/disable-apparmor-rsyslog.service` | Persistent AppArmor profile disable |
| iptables rules | `/etc/iptables/rules.v4` | NAT + forwarding rules |

---

## 🛠️ Infrastructure Setup Steps

- [x] Deploy 3-node Proxmox cluster
- [x] Configure Unifi network
- [x] Deploy Azure SOC-Gateway-VM
- [x] Configure WireGuard VPN tunnel (all 3 nodes)
- [x] Deploy Microsoft Sentinel + Log Analytics Workspace
- [x] Configure rsyslog forwarding (all nodes → gateway → Sentinel)
- [x] Fix AppArmor blocking rsyslog (persistent fix via systemd)
- [x] Make sysctl settings persistent
- [x] Make iptables rules persistent (netfilter-persistent)
- [x] Verify all 4 nodes reporting to Sentinel
- [x] Create KQL analytics detection rules
- [x] Run SSH brute force simulation (Kali → Node3)
- [ ] Configure Wazuh SIEM/XDR integration
- [ ] Deploy OpenVAS vulnerability scans
- [ ] Integrate Security Onion with Sentinel
- [ ] Run additional threat simulations (lateral movement, privilege escalation)
- [ ] Build automated incident response playbooks

---

## 📚 Skills Demonstrated

**SIEM & Detection Engineering**
- Microsoft Sentinel deployment and configuration
- Custom KQL analytics rule development
- Log ingestion pipeline design (rsyslog → AMA → Sentinel)
- Incident triage and investigation

**Network & Infrastructure**
- WireGuard VPN tunnel configuration
- Proxmox cluster management
- Linux system administration (Ubuntu, Debian)
- iptables/netfilter firewall management
- AppArmor security policy management

**Offensive Security**
- Hydra brute force attack simulation
- Kali Linux tooling

**Cloud**
- Microsoft Azure VM deployment
- Azure Monitor Agent configuration
- Log Analytics Workspace management

---

## 🎓 Certifications & Education

| Credential | Status |
|-----------|--------|
| CompTIA Security+ | ✅ Certified |
| ISC2 CC | ✅ Certified |
| CompTIA CySA+ | 🎯 Exam March 21, 2026 |
| BS Cybersecurity (SPC) | ✅ December 2025 |
| MS Cybercrime & Digital Forensics (USF) | 🎓 In Progress (GPA 3.7) |
| US Army Veteran (9 years, 25L) | ✅ |

---

## 📬 Connect

- **LinkedIn:** [linkedin.com/in/emilioburgohy198](https://linkedin.com/in/emilioburgohy198)
- **GitHub:** [github.com/ebuggy84](https://github.com/ebuggy84)
