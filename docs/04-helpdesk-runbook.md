# 04 – Help Desk Runbook

Step-by-step procedures for the Active Directory tickets a help desk sees most. Each one shows the **GUI way** (ADUC, what you'll use on day one) and the **PowerShell way** (faster, and impressive in interviews).

> **Always verify identity before changing an account.** Use the company's process (callback to the number on file, manager confirmation, ID check). Password-reset social engineering is a top attack method.

---

## 1. "I'm locked out"

**Diagnose**

```powershell
Get-ADUser jcarter -Properties LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordExpired |
    Select-Object SamAccountName, LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordExpired
```

**Fix**
- GUI: ADUC → find user → Properties → **Account** tab → tick *Unlock account*
- PowerShell: `.\04-Unlock-UserAccount.ps1 -Identity jcarter`

**If it keeps happening**: something is still using the old password. Check a phone's email account, mapped drives with saved credentials (Credential Manager), a scheduled task, or a second logged-in session. On the DC, Security log Event ID **4740** shows which computer caused the lockout:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4740} -MaxEvents 20 |
    Select-Object TimeCreated, @{n='User';e={$_.Properties[0].Value}}, @{n='Source';e={$_.Properties[1].Value}}
```

---

## 2. "I forgot my password" / password expired

1. Verify identity.
2. GUI: ADUC → right-click user → **Reset Password** → tick *User must change password at next logon* and *Unlock the user's account*.
3. PowerShell: `.\03-Reset-UserPassword.ps1 -Identity jcarter` (generates a random temporary password and unlocks).
4. Give the temporary password through an approved channel. Never send it to the same email account the user can't get into.

---

## 3. New hire onboarding

1. Confirm the request has manager approval, start date, department, job title.
2. Add the person to `data/new-hires.csv` (or a new CSV) and run:

```powershell
   .\02-New-BulkUsers.ps1 -CsvPath ..\data\new-hires.csv -WhatIf   # preview
   .\02-New-BulkUsers.ps1 -CsvPath ..\data\new-hires.csv
```

3. The script places the user in the right department OU and adds them to the department group and `DL-AllStaff`.
4. Hand the temporary password to the manager or new hire on day one; the user must change it at first logon.

---

## 4. Employee leaving (offboarding)

```powershell
.\05-Disable-OffboardUser.ps1 -Identity jcarter -TicketNumber INC-1042 -WhatIf
.\05-Disable-OffboardUser.ps1 -Identity jcarter -TicketNumber INC-1042
```

The script:
- Disables the account
- Saves the user's group memberships to a CSV (so access can be restored or audited)
- Removes all groups except Domain Users
- Stamps the description with date + ticket number
- Moves the account to `HOMELAB\Disabled\Users`

Delete the account after the retention period (e.g. 30–90 days) per company policy.

---

## 5. "I need access to the Finance share"

1. Get **approval from the data owner** (e.g. Finance manager). Don't grant access because a user asked.
2. `.\07-Manage-GroupMembership.ps1 -Action Add -Identity jcarter -Group SG-Finance-Users`
3. Tell the user to **log off and back on** (locking and unlocking isn't enough): group membership is read at logon.
4. Verify: `.\07-Manage-GroupMembership.ps1 -Action Report -Identity jcarter`

---

## 6. "My mapped drive is missing" / policy not applying

On the user's PC:

```
gpupdate /force
gpresult /r
```

- Check that the user is in the right OU and group.
- Check that the PC can reach the DC: `nltest /dsgetdc:corp.homelab.internal`

---

## 7. "This computer says the trust relationship failed"

The computer's machine-account password is out of sync with AD (common after restoring a VM snapshot).

Log in with a **local** admin account, then:

```powershell
Test-ComputerSecureChannel -Repair -Credential HOMELAB\Administrator
```

If that fails, remove the PC from the domain, put it in a workgroup, and rejoin it.

> 🧪 You can reproduce this in the lab: on DC01, open ADUC → Computers → right-click CLIENT01 → *Reset Account*, then restart CLIENT01 and try to log in with a domain account.

---

## 8. Monthly hygiene: stale accounts

```powershell
.\06-Get-StaleAccounts.ps1 -DaysInactive 90 -ExportPath C:\Reports
```

Review the report with managers before disabling anything.
