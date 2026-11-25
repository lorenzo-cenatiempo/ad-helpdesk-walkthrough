# Glossary

Plain-English definitions of the terms used in this walkthrough. If a module uses a word you don't know, look here first.

| Term | What it means |
| --- | --- |
| **Active Directory (AD)** | Microsoft's directory service. It's the central list of a company's users, computers and groups, and it decides who can sign in and what they can reach. |
| **AD DS** | Active Directory Domain Services, the Windows Server role you install to create a domain. |
| **Domain** | A group of users and computers managed together by AD. In this lab the domain is `HOMELAB`. |
| **Domain Controller (DC)** | A server running AD DS. It stores the directory and checks every sign-in. In this lab that's `DC01`. |
| **DNS** | The service that turns names (like `DC01`) into IP addresses. Domain computers find the DC through DNS, so most "can't join the domain" problems are DNS problems. |
| **OU (Organizational Unit)** | A folder inside AD for organizing objects, such as `Users > Sales`. You link Group Policy to OUs and delegate permissions on them. |
| **ADUC** | *Active Directory Users and Computers*, the main GUI tool for managing accounts. |
| **RSAT** | *Remote Server Administration Tools*. Installs ADUC, GPMC and the AD PowerShell module on a Windows client. |
| **User account** | One person's identity in AD: username, password, group memberships and properties like department and manager. |
| **sAMAccountName** | The short "pre-Windows 2000" logon name, such as `jcarter`. Used as `HOMELAB\jcarter`. |
| **UPN** | *User Principal Name*, the email-style logon name, such as `jcarter@corp.homelab.internal`. |
| **Security group** | A group used to grant access to files, shares, apps or admin rights. Give access to the group, then add people to it. |
| **Distribution group** | A group used only for email lists. It can't be used to grant permissions. |
| **Global / Domain Local / Universal** | Group *scopes*. They control where a group can be used and who can be a member. See AGDLP. |
| **AGDLP** | A best-practice pattern: **A**ccounts go in **G**lobal groups, Global groups go in **D**omain **L**ocal groups, and Domain Local groups get **P**ermissions. |
| **Least privilege** | Give people only the access they need to do their job, and nothing more. |
| **Delegation** | Letting a group (like the help desk) do specific tasks, such as resetting passwords in one OU, without making them Domain Admins. |
| **Group Policy / GPO** | A *Group Policy Object* is a bundle of settings (password rules, mapped drives, desktop restrictions) applied automatically to users or computers in the OUs it's linked to. |
| **GPMC** | *Group Policy Management Console*, the tool for creating and linking GPOs. |
| **`gpupdate /force`** | Makes a computer re-apply Group Policy right now instead of waiting. |
| **`gpresult /r`** | Shows which GPOs actually applied to a user and computer. Your first stop when "the policy isn't working". |
| **Account lockout** | After too many wrong passwords, AD locks the account for a set time. Protects against password guessing. |
| **Event ID 4740** | The Security log entry on the DC that says "a user account was locked out". It names the computer the bad attempts came from. |
| **Credential Manager** | The Windows tool that stores saved passwords. An old saved password here is a classic cause of repeat lockouts. |
| **Kerberos** | The protocol AD uses to check sign-ins behind the scenes. |
| **Trust relationship / secure channel** | Each domain-joined computer has its own machine password shared with the DC. If they get out of sync, you see "the trust relationship between this workstation and the primary domain failed". |
| **`Test-ComputerSecureChannel`** | PowerShell command that checks (and with `-Repair`, fixes) a computer's trust with the domain. |
| **`Reset-ComputerMachinePassword`** | Another way to fix a broken trust by resetting the computer's machine password. |
| **Onboarding / offboarding** | Setting up accounts and access for a new hire, and removing them safely when someone leaves. |
| **Stale account** | A user or computer account that hasn't signed in for a long time. Old accounts are a security risk and get cleaned up regularly. |
| **LastLogonTimestamp** | An AD attribute showing roughly when an account last signed in. Used to find stale accounts. |
| **ProtectedFromAccidentalDeletion** | A setting on OUs and objects that stops them from being deleted by mistake. |
| **NTFS vs share permissions** | Two layers of file access on Windows. Share permissions apply over the network; NTFS permissions apply on the disk. The most restrictive of the two wins. |
| **`-WhatIf`** | A PowerShell switch that shows what a command *would* do without doing it. Always preview first. |
| **Execution policy** | A PowerShell safety setting that controls whether scripts can run. `RemoteSigned` lets your own local scripts run. |
| **Microsoft Entra ID** | Microsoft's cloud identity service (formerly Azure AD). Many companies sync their on-prem AD to it. |
| **Ticket** | A logged support request. Good ticket notes record the problem, what you checked, the root cause and the fix. |
