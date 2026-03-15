# Runbook: Brute Force Attack Response

**Playbook ID:** IRP-001  
**MITRE ATT&CK:** T1110 - Brute Force  
**Severity:** Medium → High (based on volume)  
**Author:** Emilio Burgohy  
**Last Updated:** 2026

---

## Trigger Conditions

This runbook activates when the `brute-force-detection.kql` Analytics Rule fires:
- 5+ failed authentication attempts from a single IP within 5 minutes
- Source can be SSH, RDP, or web application login

---

## Phase 1: IDENTIFICATION (First 15 Minutes)

### Step 1 — Validate the Alert
```kql
// Run in Sentinel — confirm the alert is real
Syslog
| where TimeGenerated > ago(30m)
| where SyslogMessage has "Failed password"
| where Computer == "<AFFECTED_HOST>"
| summarize count() by bin(TimeGenerated, 1m), extract(@"from (\d+\.\d+\.\d+\.\d+)", 1, SyslogMessage)
```

**Questions to answer:**
- [ ] Is the source IP internal or external?
- [ ] Is this a known/authorized IP? (check your asset inventory)
- [ ] What account(s) are being targeted?
- [ ] Is the targeted account a service account or user account?

### Step 2 — Scope the Attack
```kql
// Check if the same IP is hitting other hosts
Syslog
| where TimeGenerated > ago(1h)
| where SyslogMessage has "Failed password"
| where SyslogMessage has "<SOURCE_IP>"
| summarize count() by Computer
```

- [ ] Single host or multiple? → Multiple = Active lateral movement concern
- [ ] Did any attempts **succeed**? (Critical — see Phase 2 if yes)

```kql
// Check for successful login from the same IP
Syslog
| where TimeGenerated > ago(1h)
| where Computer == "<AFFECTED_HOST>"
| where SyslogMessage has_any ("Accepted password", "Accepted publickey")
| where SyslogMessage has "<SOURCE_IP>"
```

---

## Phase 2: CONTAINMENT

### If NO successful login — Low urgency
- [ ] Document source IP and add to firewall blocklist in UDM Pro
- [ ] Continue monitoring for 24 hours
- [ ] No further action required unless pattern repeats

### If SUCCESSFUL login detected — High urgency
- [ ] **Isolate the affected VM in Proxmox immediately** (suspend network, do NOT shut down — preserve memory)
- [ ] Block source IP at UDM Pro firewall
- [ ] Disable the compromised account in AD (if domain-joined)
- [ ] Notify: Self (this is a home lab — document everything)

---

## Phase 3: INVESTIGATION

```kql
// What did the attacker do after logging in?
Syslog
| where TimeGenerated between (<LOGIN_TIME> .. now())
| where Computer == "<AFFECTED_HOST>"
| where SyslogMessage has_any ("sudo", "su ", "passwd", "useradd", "crontab", "wget", "curl", "chmod")
| sort by TimeGenerated asc
```

**Document:**
- [ ] First successful login time
- [ ] Commands executed post-login
- [ ] Files accessed or modified (check Wazuh FIM alerts)
- [ ] Any outbound connections established

---

## Phase 4: ERADICATION & RECOVERY

- [ ] Reset compromised credentials
- [ ] Audit all accounts for unauthorized changes
- [ ] Patch any vulnerability that enabled access (if applicable)
- [ ] Restore from snapshot if system integrity is in question

---

## Phase 5: LESSONS LEARNED

| Field | Notes |
|-------|-------|
| Detection Time | |
| Response Time | |
| Was containment successful? | |
| What worked well? | |
| What needs improvement? | |
| Rule changes needed? | |

---

## Related Files

- Detection Rule: `/detections/kql/brute-force-detection.kql`
- Related: `/runbooks/unauthorized-access.md`
