# Findings

This folder contains documented security findings and audit reports 
produced by Burgohy Security Solutions (BSS).
Each engagement is self-contained with a full report and supporting 
artifacts.

---

## Completed Engagements

### 🔴 ASUS GT-AXE16000 — Factory Reset Security Audit
**Date:** 2026-05-07  
**Severity:** Critical (CVE-2024-3080, CVSS 9.8)  
**Tools:** Nmap, searchsploit, curl, Metasploit Framework  

**Summary:** Six vulnerabilities identified including unauthenticated 
dashboard access, version disclosure via state.js, and plaintext HTTP 
admin interface.  

📄 [Full Report →](Audit_ASUS_AXE16000_Factory_Reset.pdf)

---

### 🔴 BSS Purple Team SOC — Port Scan Detection
**Date:** 2026-05-12  
**Severity:** Medium  
**Tools:** Nmap, Microsoft Sentinel, KQL, Azure Arc  

**Summary:** Simulated network reconnaissance attack from Kali Linux 
against three domain-joined Windows 11 workstations. Microsoft Sentinel 
detected the attack in real time via Event ID 5156, auto-generated a 
Medium severity incident, and rendered the full attack path in the 
investigation graph.  

📄 [Full Report →](BSS-Purple-Team-SOC-Report.pdf)

---

*Reports are produced following BSS engagement methodology. 
All testing conducted in authorized lab environments.*
