# Solution 02 – Onboard new starters

## Before creating anything: what to confirm

- **Authorization:** request came through the ticket system from HR, with manager approval
- **Missing details:** office location, phone, start date/time, any access beyond the department default (shared mailboxes, apps), equipment needed
- **Name check:** does the generated username clash with an existing user? (The script handles this by adding a number.)

## Manual creation (Sam Whitfield) in ADUC

1. Navigate to `HOMELAB → Users → Finance` → right-click → **New → User**
2. First `Sam`, Last `Whitfield`, logon name `swhitfield`
3. Set a temporary password, tick **User must change password at next logon**
4. Properties → **Organization** tab: Title *Payroll Specialist*, Department *Finance*, Manager *Taylor Patel*
5. **Member Of** tab → Add `SG-Finance-Users` and `DL-AllStaff`

## Scripted creation (the other two)

`data/week2-hires.csv`:

```
FirstName,LastName,Department,Title,Manager,Office,Phone
Priya,Desai,Marketing,Graphic Designer,rnguyen,Boston,555-0111
Chris,Dunn,Sales,Account Executive,jcarter,New York,555-0112
```

```powershell
.\02-New-BulkUsers.ps1 -CsvPath ..\data\week2-hires.csv -WhatIf
.\02-New-BulkUsers.ps1 -CsvPath ..\data\week2-hires.csv
```

## Verification

```powershell
'swhitfield','pdesai','cdunn' | ForEach-Object {
    Get-ADUser $_ -Properties Title, Department, Manager |
        Select-Object SamAccountName, Title, Department,
            @{ n = 'Manager'; e = { ($_.Manager -split ',')[0] -replace 'CN=' } },
            @{ n = 'OU';      e = { ($_.DistinguishedName -split ',')[1] -replace 'OU=' } }
}
```

Then log in to CLIENT01 as `pdesai` and confirm the "You must change your password" prompt.

## Temp-password handling

The script writes `temp-passwords-*.csv`. Hand passwords over through an approved channel (e.g. to the manager in person), then delete the file. `.gitignore` already excludes it so it's never committed.

## Teaching points

- Manual first, scripted second: know what the script does before trusting it.
- `-WhatIf` before every bulk change.
- Consistency is the real win of scripting: same OU, groups and attributes every time.
