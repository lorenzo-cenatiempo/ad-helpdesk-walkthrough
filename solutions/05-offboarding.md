# Solution 05 – Offboarding

## Why disable, not delete

- Deleting is hard to undo: a new account with the same name gets a **new SID**, so it won't regain old file permissions.
- Managers often need the person's files or mailbox handed over.
- Mistakes happen (wrong person, termination reversed).
- Auditors may need to see what access the person had.

Most companies disable immediately and delete after a retention period (30–90 days).

## Manual steps (ADUC)

1. Record access: user → **Member Of** tab → screenshot or note each group
2. Right-click user → **Disable Account**
3. **Member Of** → remove every group except Domain Users
4. **General** tab → Description: `Disabled 2026-11-23 - INC-2051 - by <you>`
5. Right-click → **Move** → `HOMELAB\Disabled\Users`

## Scripted

```powershell
.\05-Disable-OffboardUser.ps1 -Identity crivera -TicketNumber INC-2051 -WhatIf
.\05-Disable-OffboardUser.ps1 -Identity crivera -TicketNumber INC-2051
```

Group memberships are saved to `scripts\offboarding-records\crivera-groups-<date>.csv` (excluded from Git).

## Verification

```powershell
Get-ADUser crivera -Properties Description, MemberOf |
    Select-Object Enabled, Description, DistinguishedName, @{ n = 'Groups'; e = { $_.MemberOf.Count } }
```

*Example output:* `Enabled: False`, Groups `0` (Domain Users is the primary group and isn't counted in MemberOf), OU = Disabled\Users.

Sign-in as crivera on CLIENT01 shows **"Your account has been disabled."**

## Teaching points

- Timing matters: coordinate with HR/manager, as access is often removed *during* the exit meeting.
- Disabling the AD account doesn't end sessions already open. In real environments also sign them out of cloud services and collect devices.
