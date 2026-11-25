# Exercises: Support Tickets

Each exercise is a realistic help desk ticket. You **set up the problem** in your lab, then **troubleshoot and fix it** as if a user had called it in.

| # | Ticket | Skills | Difficulty |
| --- | --- | --- | --- |
| [01](01-account-lockout.md) | "I keep getting locked out" | Lockout policy, Event ID 4740, Credential Manager | ★★☆ |
| [02](02-new-hires.md) | Onboard new starters | Bulk user creation, OU/group placement | ★☆☆ |
| [03](03-shared-drive-access.md) | "I can't see the Finance drive" | Group membership, GPO drive maps, gpresult | ★★☆ |
| [04](04-trust-relationship.md) | "Trust relationship failed" | Computer accounts, secure channel repair | ★★☆ |
| [05](05-offboarding.md) | Employee leaving today | Disabling, group cleanup, documentation | ★☆☆ |

**Prerequisite for all exercises:** Modules 1–3 complete (lab built, OU script and bulk-user script run, GPOs from Module 3 in place).

## How to work an exercise

1. Read the **Scenario** and do the **Setup** to create the problem.
2. Work the problem **without** looking at the solution. Use the [runbook](../docs/04-helpdesk-runbook.md) if you're stuck, then the hints.
3. Write your ticket notes in a copy of [TEMPLATE.md](TEMPLATE.md).
4. Compare with the model answer in [`../solutions/`](../solutions/README.md). Different steps are fine if you reached the right root cause.

> 💡 Snapshot both VMs before each exercise so you can reset and try again.
