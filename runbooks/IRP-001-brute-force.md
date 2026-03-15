# IRP-001 — Brute Force Attack Response

**Playbook ID:** IRP-001  
**MITRE ATT&CK:** T1110 — Brute Force  
**Tactic:** Credential Access  
**Severity:** Medium (default) → High (if successful login detected)  
**Linked Detection:** [brute-force-detection.kql](../detections/kql/brute-force-detection.kql)  
**Author:** Emilio Burgohy

---

## Phase 1 — Identification

### 1.1 Validate the Alert

Run in Sentinel to confirm the alert is real:

```kql
Syslog
| where TimeGenerated > ago(30m)
| where Facility == "auth"
| where SyslogMessage has "Failed password"
| where Computer == "<AFFECTED_HOST>"
| summarize
    Attempts = count(),
    TargetUsers = make_set(extract(@"for (?:invalid user )?(\S+)", 1, SyslogMessage))
    by bin(TimeGenerated, 1m),
       extract(@"from (\d+\.\d+\.\d+\.\d+)", 1, SyslogMessage)
```

**Answer these questions before proceeding:**
- [ ] Is the source IP internal or external?
- [ ] Is this a known/authorized IP? (check asset list)
- [ ] What account(s) are being targeted?
- [ ] Is this a single burst or sustained over time?

### 1.2 Determine Scope — Is This Spreading?

```kql
// Is the same IP targeting multiple hosts?
Syslog
| where TimeGenerated > ago(1h)
| where SyslogMessage has "Failed password"
| where SyslogMessage has "<SOURCE_IP>"
| summarize Attempts = count() by Computer
```

- **Single host** → Likely automated scanner, low urgency
- **Multiple hosts** → Possible active attacker, escalate severity

---

## Phase 2 — Containment

### 2A — No Successful Login (Most Common)

- [ ] Block source IP in UDM Pro Max firewall
- [ ] Set a 24-hour monitor on the affected host
- [ ] Document the IP in findings log
- [ ] No further action unless pattern repeats

### 2B — Successful Login Detected (CRITICAL)

```kql
// Check for successful logins from the attacker IP
Syslog
| where TimeGenerated > ago(2h)
| where Computer == "<AFFECTED_HOST>"
| where SyslogMessage has_any ("Accepted password", "Accepted publickey")
| where SyslogMessage has "<SOURCE_IP>"
```

If a hit is returned:

- [ ] **Suspend VM network in Proxmox immediately** — do NOT shut down (preserve memory for forensics)
- [ ] Block source IP at UDM Pro Max
- [ ] If host is domain-joined: disable compromised account in DC01
- [ ] Proceed to Phase 3

---

## Phase 3 — Investigation (Successful Login Only)

```kql
// What commands were run after the attacker logged in?
Syslog
| where TimeGenerated between (datetime(<LOGIN_TIME>) .. now())
| where Computer == "<AFFECTED_HOST>"
| where SyslogMessage has_any (
    "sudo", "su ", "passwd", "useradd",
    "crontab", "wget", "curl", "chmod",
    "python", "nc ", "bash"
  )
| project TimeGenerated, SyslogMessage
| sort by TimeGenerated asc
```

**Document:**
- [ ] Exact time of first successful login
- [ ] Commands run post-login (in chronological order)
- [ ] Files accessed or modified (cross-reference Wazuh FIM alerts)
- [ ] Any outbound network connections established

---

## Phase 4 — Eradication & Recovery

- [ ] Reset all credentials on the compromised host
- [ ] Audit all local accounts for unauthorized additions: `cat /etc/passwd`
- [ ] Check for persistence: crontabs, authorized_keys, new services
- [ ] Patch any vulnerability that enabled access (weak password, exposed port)
- [ ] Restore from Proxmox snapshot if system integrity is questionable
- [ ] Re-enable network on VM after clean bill of health

---

## Phase 5 — Lessons Learned

| Field | Notes |
|-------|-------|
| Alert fired at | |
| Investigation started at | |
| Containment action taken at | |
| True positive or false positive | |
| Detection rule changes needed | |
| Runbook changes needed | |
| What worked well | |
| What to improve | |

---

## Related

- Detection Rule: [brute-force-detection.kql](../detections/kql/brute-force-detection.kql)
- Escalation: [IRP-002-unauthorized-access.md](IRP-002-unauthorized-access.md) (if login succeeded)
