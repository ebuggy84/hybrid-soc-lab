🛡️ Hybrid SOC Home Lab — Detection Engineering & Incident Response
Built by Emilio Burgohy | Cybersecurity Analyst | USF MS Cybercrime & Digital Forensics
Show Image
Show Image
Show Image
Show Image
Show Image

🎯 Mission
This lab simulates a real-world Hybrid SOC by connecting on-premise infrastructure to cloud-native security tooling. The goal is to practice the full security operations lifecycle:

Detection Engineering — Writing KQL rules that catch real attacker behavior
Incident Response — Triaging, investigating, and documenting security events
Threat Simulation — Attacking my own environment to validate detections
Cloud + On-Prem Integration — Bridging local hardware to Microsoft Sentinel via secure tunnel


This is not a theoretical lab. Every detection rule here was written in response to something observed in this environment.


🏗️ Infrastructure Overview
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
               │   Ubuntu 24.04     │
               │   AMA + rsyslog    │
               │        ↓           │
               │ [Microsoft Sentinel]│
               │   5 Analytics Rules│
               │   Incident Mgmt    │
               └────────────────────┘
                         │
               ┌─────────▼──────────┐
               │  Security Onion    │  ← Bare metal (GMKtec 32GB)
               │  Network IDS/NSM   │
               └────────────────────┘

🖥️ Hardware Inventory
DeviceRoleRAMStorageStatusMinisforum MSA2 (Node 1)Proxmox / Wazuh SIEM128GB4TB NVMe🟢 OnlineMinisforum MS01 (Node 2)Proxmox / OpenVAS96GB2TB NVMe🟢 OnlineMinisforum MS01 (Node 3)Proxmox / DC01 + Victim VM96GB2TB NVMe🟢 OnlineGMKtec Mini PCSecurity Onion (bare metal)32GB1TB HDD🟢 OnlineZimaboard 832Kali Linux Attack Platform--🟢 Online
Network: Unifi UDM Pro Max | USW Pro 48 PoE | 8-Port Aggregation | 24-Port Switch

🔐 WireGuard VPN Tunnel
Encrypted tunnel connecting all Proxmox nodes to Azure gateway for secure log forwarding — zero open inbound ports.
NodeWireGuard IPStatusSOC-Gateway-VM (Azure)10.0.0.1🟢 OnlineMS01-Node210.0.0.2🟢 OnlineMS01-Node310.0.0.3🟢 OnlineMSA2-Node110.0.0.5🟢 Online

🔧 Security Stack
ToolCategoryPurposeMicrosoft SentinelCloud SIEMCentral log analysis, KQL detections, incident managementWazuhOn-Prem SIEM/XDRHost-based IDS, FIM, MITRE ATT&CK mappingSecurity OnionNSM / IDSNetwork traffic analysis, Zeek logs, Suricata alertsOpenVASVulnerability ScannerContinuous vulnerability assessment of lab assetsWireGuardSecure TunnelEncrypted on-prem to Azure log forwardingAzure Monitor AgentLog ForwardingSyslog → Sentinel pipeline via SOC-Gateway VMProxmox VEHypervisor3-node cluster managing all VMsUnifiNetwork InfrastructureVLAN segmentation, firewall rules, traffic mirroringKali LinuxThreat SimulationAuthorized attack simulation to validate detections

📊 Microsoft Sentinel Analytics Rules
5 active detection rules running 24/7:
RuleSeverityTypeTacticSSH Brute Force AttemptMediumScheduled (Custom)Credential Access, Initial AccessSuccessful Login After Multiple FailuresHighScheduled (Custom)Initial AccessNew Local User Account CreatedLowScheduled (Custom)Persistence, Privilege EscalationPrivileged Command Execution (Sudo) - ProxmoxMediumScheduled (Custom)Privilege EscalationAdvanced Multistage Attack DetectionHighFusion (Built-in)Multiple

⚔️ Threat Simulations
✅ SSH Brute Force Attack (Completed — March 2026)
Attacker: Kali Linux (10.0.30.12)
Target: MS01-Node3 (10.0.30.13)
Tool: Hydra
Result: Sentinel detected attack and auto-generated Medium severity incident
Attack command:
bashhydra -l root -P /usr/share/wordlists/rockyou.txt -t 10 -s 22 10.0.30.13 ssh
Detection chain:
Kali launches attack
    → Failed logins logged by Node3 auth facility
    → rsyslog forwards via WireGuard tunnel to SOC-Gateway
    → Azure Monitor Agent ingests into Sentinel
    → KQL rule fires (5+ failures in 5 min threshold)
    → Incident auto-generated: "SSH Brute Force Attempt" (Medium)
    → Investigation graph maps attacker IP → target host
Evidence:
ScreenshotDescriptionscreenshots/01-sentinel-brute-force-syslog-detection.pngLive Syslog showing failed SSH attempts from Kaliscreenshots/02-sentinel-analytics-rules-active.pngAll 5 analytics rules enabledscreenshots/03-wireguard-tunnel-all-nodes-connected.pngAll 4 nodes connected via WireGuardscreenshots/04-sentinel-all-nodes-reporting.pngAll nodes sending logs to Sentinelscreenshots/05-sentinel-ssh-brute-force-incident.pngAuto-generated incident in Sentinelscreenshots/06-sentinel-incident-details.pngIncident details panelscreenshots/07-sentinel-incident-investigation-graph.pngAttack investigation graphscreenshots/08-sentinel-incident-timeline.pngIncident timelinescreenshots/09-sentinel-incident-entities.pngEntities extracted from incident

📁 Repository Structure
/hybrid-soc-homelab
│
├── README.md                    ← You are here
│
├── /screenshots                 ← Evidence from detections and simulations
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
│   │   ├── ssh-brute-force.kql
│   │   ├── successful-login-after-failures.kql
│   │   ├── new-user-created.kql
│   │   └── sudo-abuse-detection.kql
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

🚀 Key Achievements

✅ Built 3-node Proxmox cluster (320GB RAM) running enterprise security tooling
✅ Established encrypted WireGuard tunnel — zero open inbound ports to internet
✅ All 4 nodes reporting logs to Microsoft Sentinel in real time
✅ Fixed AppArmor blocking rsyslog — persistent systemd service solution
✅ Made sysctl + iptables settings persistent across reboots
✅ Deployed 5 custom KQL analytics rules with auto-incident generation
✅ Ran first threat simulation — SSH brute force detected, incident auto-created in Sentinel
✅ Investigated incident using Sentinel investigation graph, timeline, and entities
✅ Deployed Wazuh SIEM with MITRE ATT&CK framework mapping
✅ Active Directory lab (DC01 + Windows 11 victim) for realistic attack simulation
🔄 Security Onion integration with Sentinel (planned)
🔄 OpenVAS vulnerability scan findings documentation (planned)
🔄 Additional threat simulations: lateral movement, privilege escalation (planned)
🔄 Automated incident response playbooks (planned)


🎓 Certifications & Education
CredentialStatusCompTIA Security+✅ CertifiedISC2 CC✅ CertifiedCompTIA CySA+🎯 March 2026BS Cybersecurity (SPC)✅ December 2025MS Cybercrime & Digital Forensics (USF)🎓 In Progress — GPA 3.7US Army (9 years, 25L Signal/Communications)✅ Veteran

📬 Connect

LinkedIn: linkedin.com/in/emilioburgohy198
Email: emilioburgohy@gmail.com
GitHub: github.com/ebuggy84


Building real SOC skills — one detection at a time.
