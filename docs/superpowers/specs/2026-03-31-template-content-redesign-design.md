# Template Content Redesign Design

**Date:** 2026-03-31

## Summary

Replace the three existing example templates with a new set that covers generic, freelance, and personal development use cases. The goal is realistic task titles that make each template immediately useful and serve as clear examples for users building their own.

## Motivation

The original templates (`personal-dev-tracking`, `long-term-project`, `poc-evaluation`) were either too IBM-sales-specific or too generic to be instructive. A user looking at a personal development template shouldn't see tasks like "Discovery Call Scheduled". The new set uses plain language tied to real workflows so the task titles themselves teach the template format.

## Files

**Removed:**
- `examples/templates/personal-dev-tracking.json`
- `examples/templates/long-term-project.json`
- `examples/templates/poc-evaluation.json`

**Added:**
- `examples/templates/base-project.json`
- `examples/templates/freelance-client.json`
- `examples/templates/personal-development.json`

## Template Definitions

### `base-project.json`
```json
{
  "name": "Base Project",
  "isPOC": false,
  "stage": "Discovery",
  "tags": [],
  "taskTitles": [
    "Define project goals",
    "Identify key stakeholders",
    "Set milestones",
    "Track progress",
    "Document outcomes",
    "Close out project"
  ]
}
```
Purpose: minimal default that fits any project type. Empty tags so users aren't steered toward a domain.

### `freelance-client.json`
```json
{
  "name": "Freelance Client Project",
  "isPOC": false,
  "stage": "Discovery",
  "tags": ["freelance", "client"],
  "taskTitles": [
    "Send project proposal",
    "Get contract signed",
    "Schedule kickoff call",
    "Deliver first milestone",
    "Collect feedback",
    "Deliver final deliverable",
    "Send invoice",
    "Get client sign-off"
  ]
}
```
Purpose: full client engagement lifecycle from proposal through sign-off.

### `personal-development.json`
```json
{
  "name": "Personal Development",
  "isPOC": false,
  "stage": "Discovery",
  "tags": ["personal", "learning"],
  "taskTitles": [
    "Define learning goals",
    "Gather resources and references",
    "Set a practice schedule",
    "Build a small proof project",
    "Review progress against goals",
    "Share or publish learnings"
  ]
}
```
Purpose: self-directed learning arc with no business/sales terminology.

## Rationale

- All three start at "Discovery" — consistent with the app's project creation flow.
- `base-project` uses empty tags to signal it's a blank slate.
- Task titles in each template tell the story of that project type's lifecycle, making them useful as learning examples for users building custom templates.
- No POC template in this set — POC is a specific IBM sales concept. Can be added later as a fourth template if needed.
