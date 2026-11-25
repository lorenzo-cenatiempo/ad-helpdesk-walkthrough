# Solution 03 – Can't see the Finance drive

## Troubleshooting

1. **Check the account:**

```
   .\07-Manage-GroupMembership.ps1 -Action Report -Identity abrooks
```

Shows `SG-Sales-Users`, `DL-AllStaff`, `Domain Users`. **Not** in `SG-Finance-Users`. OU is still Sales.
2. **Check the client** (as abrooks on CLIENT01): `gpresult /r`
`GPO-Users-MappedDrives` **is** applied, so the GPO is fine. The H: item is item-level targeted to `SG-Finance-Users`, which the user isn't in.

## Root cause

The department transfer was processed by HR but the AD account (groups, OU, department) was never updated.

## Resolution

1. Confirmed data-owner approval (Taylor Patel) is in the ticket.
2. Least privilege: add Finance, **remove** Sales. A transfer shouldn't accumulate old access.

```powershell
   .\07-Manage-GroupMembership.ps1 -Action Add    -Identity abrooks -Group SG-Finance-Users
   .\07-Manage-GroupMembership.ps1 -Action Remove -Identity abrooks -Group SG-Sales-Users
   $domainDN = (Get-ADDomain).DistinguishedName
   Get-ADUser abrooks | Move-ADObject -TargetPath "OU=Finance,OU=Users,OU=HOMELAB,$domainDN"
   Set-ADUser abrooks -Department Finance -Manager tpatel
```

3. User **signs out and back in.** Group membership is captured in the Kerberos ticket at logon; `gpupdate` alone won't pick it up.

## Verification

- `gpresult /r` lists `SG-Finance-Users` under *The user is a part of the following security groups*
- H: drive is present

## Teaching points

- Check both sides: AD (is the user in the group?) and the client (is the GPO applying?).
- "Log off and back on" is a real fix, and now you know why.
- Never grant access without the data owner's approval, even if the user's manager asks.
