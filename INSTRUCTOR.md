# Instructor Guide

Notes for running this course with a class, study group or mentees.

## Format options

| Format | Suggested schedule |
| --- | --- |
| Weekend bootcamp | Sat: Modules 1–3 · Sun: Module 4 + Exercises 01–05 + portfolio |
| Weekly study group (5 weeks) | Wk 1: Module 1 · Wk 2: Modules 2–3 · Wk 3: Module 4 + Ex 01–02 · Wk 4: Ex 03–05 · Wk 5: portfolio review + mock interviews |
| Self-paced | Learners follow the README; meet once to review portfolios |

## Before the first session

- Have learners confirm their PC has **virtualization enabled** and **16 GB RAM** (8 GB is workable). This is the most common blocker.
- Have them download both evaluation ISOs in advance (~10 GB total).
- Learners with weaker hardware can pair up, or use a cloud lab (e.g. an Azure free-tier account).

## Keeping solutions hidden

The `solutions/` folder is in the same repo for self-learners. For a class, either ask learners to work exercises before opening it, or keep solutions in a separate private repo and release them after each session.

## Completion checklist (per learner)

| Requirement | Evidence |
| --- | --- |
| Lab built: DC promoted, client joined | Screenshots 01–02 |
| OU/group structure and delegation | Screenshots 03–04 |
| GPOs applied and verified | Screenshots 05–06 |
| Exercises 01–05 completed | Ticket notes from `exercises/TEMPLATE.md` + screenshots ex01–ex05 |
| Portfolio published | Their own GitHub repo with a "What I learned" section in their own words |

## Assessment rubric (per exercise)

|  | Needs work | Meets | Strong |
| --- | --- | --- | --- |
| **Diagnosis** | Jumped straight to a fix | Found the root cause | Found root cause and explained how they ruled out alternatives |
| **Fix** | Symptom only (e.g. just unlocked) | Fixed the cause | Fixed the cause and applied least privilege / safe practice (`-WhatIf`, disable not delete) |
| **Verification** | None | Confirmed fixed | Confirmed with evidence (command output, screenshot) |
| **Notes** | Missing or vague | Clear problem/cause/resolution | Someone else could repeat the fix from the notes |

## Mock interview questions

Ask these after the exercises; learners should answer from their own lab experience.

1. A user keeps getting locked out every few minutes. Walk me through what you'd check.
2. What's the difference between an OU and a security group?
3. A user was added to a group but still can't access the share. Why might that be?
4. Why disable an account instead of deleting it when someone leaves?
5. What does `gpresult /r` tell you, and when would you use it?
6. What does "trust relationship failed" mean, and how do you fix it?
7. Someone calls claiming to be the CFO and asks for an urgent password reset. What do you do?
8. Tell me about something that broke in your lab and how you fixed it.

## Integrity note

Encourage learners to publish **their own** notes and screenshots, not the model solutions. Employers ask follow-up questions; a portfolio only helps if the learner can talk through every part of it.
