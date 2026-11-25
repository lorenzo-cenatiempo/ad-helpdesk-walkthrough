# Walkthrough Checklist

Your step-by-step instruction list for the whole walkthrough. Work top to bottom and tick each box as you finish it. If you get lost, every step links to the page that explains it, and most have a simulated screenshot of what you should see.

> **Tip:** In your own copy of this repo on GitHub, open this file and click the pencil icon to tick boxes as you go. It doubles as a progress tracker.

---

## Before you start (about 30 min)

- [ ] Check your PC: 16 GB RAM (8 GB minimum), ~100 GB free disk, virtualization turned on in BIOS/UEFI
- [ ] Install a hypervisor: **Hyper-V** (Windows Pro) or **VirtualBox** (any edition)
- [ ] Download the free evaluation ISOs: Windows Server 2022 and Windows 11 Enterprise
- [ ] Skim the [glossary](GLOSSARY.md) so the terms aren't new when you meet them

## Module 1: Build the lab (2–3 hrs) → [docs/01-lab-setup.md](docs/01-lab-setup.md)

- [ ] Create the `LabNet` virtual network
- [ ] Build the **DC01** VM (2 vCPU, 4 GB RAM, 60 GB disk) and install Windows Server 2022 *Desktop Experience*
- [ ] Rename it to `DC01` and give it the static IP `10.10.10.10`, DNS `127.0.0.1`
- [ ] Install AD DS and create the domain `corp.homelab.internal` (NetBIOS `HOMELAB`)
- [ ] Verify: `Get-ADDomain`, services running, `dcdiag /q` returns nothing
- [ ] 📸 Take a checkpoint/snapshot of DC01
- [ ] Build the **CLIENT01** VM and install Windows 11
- [ ] Give it the static IP `10.10.10.50` with DNS pointing at `10.10.10.10` (the DC!)
- [ ] Join CLIENT01 to the domain and confirm it in Settings → System → About
- [ ] Copy this repo to `C:\Lab\ad-helpdesk-walkthrough` on DC01
- [ ] Run `01-Build-OUStructure.ps1` (try `-WhatIf` first)
- [ ] Run `02-New-BulkUsers.ps1 -CsvPath ..\data\new-hires.csv`
- [ ] Sign in to CLIENT01 as `HOMELAB\jcarter` with the temporary password
- [ ] Delete the `temp-passwords-*.csv` file once you're done with it

## Module 2: OU, group and naming design (1 hr) → [docs/02-ou-design.md](docs/02-ou-design.md)

- [ ] Open ADUC and find each OU from the diagram
- [ ] Explain in your own words why users and computers are in separate OUs
- [ ] Learn the naming rules (usernames, groups, workstations)
- [ ] Delegate **password reset + unlock** on `HOMELAB\Users` to `SG-IT-HelpDesk`

## Module 3: Group Policy (1–2 hrs) → [docs/03-group-policy.md](docs/03-group-policy.md)

- [ ] Set the password and lockout policy in the Default Domain Policy
- [ ] Create the `Shared` and `Finance` shares on DC01
- [ ] Create and link `GPO-Users-MappedDrives` (S: for everyone, H: for Finance only)
- [ ] Create and link `GPO-Workstations-Security`
- [ ] Create and link `GPO-Users-Desktop`
- [ ] On CLIENT01, run `gpupdate /force` then `gpresult /r` and find each GPO in the output
- [ ] Test the lockout policy: 5 wrong passwords, then `04-Unlock-UserAccount.ps1 -ListLocked`

## Module 4: Help desk runbook (1 hr) → [docs/04-helpdesk-runbook.md](docs/04-helpdesk-runbook.md)

- [ ] Read all 8 procedures
- [ ] For each one, note which script (if any) helps and what you'd check first
- [ ] Practice reset (`03-`), unlock (`04-`) and group changes (`07-`) on a test user

## Module 5: Work the tickets (2–4 hrs) → [exercises/](exercises/README.md)

For every exercise: read the scenario, set up the problem, solve it, write notes in the [template](exercises/TEMPLATE.md), and **only then** compare with the solution.

- [ ] **Ticket 01:** repeated lockouts → find the source computer and the stale saved password
- [ ] **Ticket 02:** three new hires → one by hand in ADUC, two by script
- [ ] **Ticket 03:** missing H: drive → fix group membership with least privilege
- [ ] **Ticket 04:** trust relationship failed → repair the secure channel without leaving the domain
- [ ] **Ticket 05:** offboarding → disable, record, strip groups, stamp the description, move to Disabled
- [ ] Ticket notes written for all five

## Module 6: Publish your portfolio (1 hr) → [README](README.md#turn-your-work-into-a-portfolio)

- [ ] Fork this repo (or make your own)
- [ ] Add your ticket notes to `exercises/`
- [ ] Add your **own** screenshots to `screenshots/` using the [evidence checklist](screenshots/README.md)
- [ ] **Privacy check before you push:** crop out passwords, your real Windows username, your PC's name and your home network details
- [ ] Add a "What I learned" section to your README in your own words

---

### Stuck?

1. Re-read the step and compare your screen with the simulated screenshot.
2. Check the **Troubleshooting** table at the bottom of the module.
3. Look up the term in the [glossary](GLOSSARY.md).
4. Roll back to your last snapshot and try again. Breaking it is part of learning it.
