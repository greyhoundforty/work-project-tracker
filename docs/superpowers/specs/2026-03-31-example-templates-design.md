# Example Template Files Design

**Date:** 2026-03-31
**Issue:** #9 — Create example template file
**Branch:** emdash/feat-example-template-file-3rz

## Summary

Add three example `ProjectTemplate` JSON files to `examples/templates/` so users have concrete starting points when setting up their own template folder in Settings.

## Background

The app supports a user-defined template folder (configured in Settings). When creating a new project, templates from that folder appear in a picker and pre-populate the stage, isPOC flag, tags, and initial task list. Currently there are no shipped examples, so users have to infer the format from the code or documentation.

## Design

### Location

```
examples/templates/
├── personal-dev-tracking.json
├── long-term-project.json
└── poc-evaluation.json
```

Placed under `examples/templates/` to keep them separate from the existing import example (`examples/test-projects.json`), which uses a different format (`ExportBundle`).

### Template Format

Each file is a valid `ProjectTemplate` JSON matching the Swift struct:

```json
{
  "name": "string",
  "isPOC": boolean,
  "stage": "Discovery | Initial Delivery | Refine | Proposal | Won | Lost",
  "tags": ["string"],
  "taskTitles": ["string"]
}
```

### Templates

**`personal-dev-tracking.json`**
- Purpose: Tracking personal learning or side-project work
- `isPOC`: false
- `stage`: "Discovery"
- `tags`: ["personal", "development"]
- `taskTitles`: ["Define learning goals", "Set up local environment", "Document progress", "Review and retrospect"]

**`long-term-project.json`**
- Purpose: Multi-phase, milestone-driven project tracking
- `isPOC`: false
- `stage`: "Discovery"
- `tags`: ["long-term", "project"]
- `taskTitles`: ["Define project scope", "Identify stakeholders", "Set milestone schedule", "Conduct quarterly review", "Prepare status report"]

**`poc-evaluation.json`**
- Purpose: Time-boxed proof-of-concept or evaluation
- `isPOC`: true
- `stage`: "Discovery"
- `tags`: ["poc", "evaluation"]
- `taskTitles`: ["Define success criteria", "Stand up evaluation environment", "Run proof-of-concept", "Document results", "Prepare POC readout"]

## Rationale

- All three start at "Discovery" since that's where new projects begin regardless of type.
- Tags are kept generic so users can customize without feeling locked in.
- The three templates cover the primary use-case split: personal work, long-form engagement, and time-boxed evaluation.

## Out of Scope

- No code changes required — the existing `ProjectTemplate.load(from:)` method handles any JSON files placed in the user's template folder.
- No README or documentation update is strictly required, though the README could be updated to mention the examples folder.
