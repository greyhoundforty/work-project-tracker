# Template Content Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the three existing example templates with a base, freelance, and personal development template that reflect realistic workflows and serve as clear examples for users building their own.

**Architecture:** Pure data change — delete three JSON files, write three new ones. No Swift code changes required. Validation is done with Python to confirm field presence, types, and valid stage values.

**Tech Stack:** JSON

---

### Task 1: Replace example templates

**Files:**
- Delete: `examples/templates/personal-dev-tracking.json`
- Delete: `examples/templates/long-term-project.json`
- Delete: `examples/templates/poc-evaluation.json`
- Create: `examples/templates/base-project.json`
- Create: `examples/templates/freelance-client.json`
- Create: `examples/templates/personal-development.json`

The `ProjectTemplate` Swift struct (at `EngagementTracker/Models/ProjectTemplate.swift`) decodes these exact fields — all required:

```swift
struct ProjectTemplate: Codable {
    let name: String
    let isPOC: Bool
    let tags: [String]
    let stage: String  // must match ProjectStage rawValue exactly
    let taskTitles: [String]
}
```

Valid `stage` values: `"Discovery"`, `"Initial Delivery"`, `"Refine"`, `"Proposal"`, `"Won"`, `"Lost"`

- [ ] **Step 1: Delete the three old template files**

```bash
rm examples/templates/personal-dev-tracking.json \
   examples/templates/long-term-project.json \
   examples/templates/poc-evaluation.json
```

- [ ] **Step 2: Create base-project.json**

`examples/templates/base-project.json`:

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

- [ ] **Step 3: Create freelance-client.json**

`examples/templates/freelance-client.json`:

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

- [ ] **Step 4: Create personal-development.json**

`examples/templates/personal-development.json`:

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

- [ ] **Step 5: Validate JSON is well-formed**

```bash
python3 -m json.tool examples/templates/base-project.json > /dev/null && echo "OK"
python3 -m json.tool examples/templates/freelance-client.json > /dev/null && echo "OK"
python3 -m json.tool examples/templates/personal-development.json > /dev/null && echo "OK"
```

Expected: three lines of `OK`.

- [ ] **Step 6: Confirm all required fields are present and valid**

```bash
for f in examples/templates/*.json; do
  echo "=== $f ==="
  python3 -c "
import json, sys
data = json.load(open('$f'))
required = {'name', 'isPOC', 'stage', 'tags', 'taskTitles'}
missing = required - data.keys()
if missing:
    print('MISSING:', missing); sys.exit(1)
valid_stages = ['Discovery','Initial Delivery','Refine','Proposal','Won','Lost']
if data['stage'] not in valid_stages:
    print('INVALID STAGE:', data['stage']); sys.exit(1)
if not isinstance(data['tags'], list):
    print('tags must be a list'); sys.exit(1)
if not isinstance(data['taskTitles'], list) or len(data['taskTitles']) == 0:
    print('taskTitles must be a non-empty list'); sys.exit(1)
print('OK — name:', data['name'], '| stage:', data['stage'], '| isPOC:', data['isPOC'], '| tasks:', len(data['taskTitles']))
"
done
```

Expected output:
```
=== examples/templates/base-project.json ===
OK — name: Base Project | stage: Discovery | isPOC: False | tasks: 6
=== examples/templates/freelance-client.json ===
OK — name: Freelance Client Project | stage: Discovery | isPOC: False | tasks: 8
=== examples/templates/personal-development.json ===
OK — name: Personal Development | stage: Discovery | isPOC: False | tasks: 6
```

- [ ] **Step 7: Confirm no old files remain**

```bash
ls examples/templates/
```

Expected output (only the three new files):
```
base-project.json
freelance-client.json
personal-development.json
```

- [ ] **Step 8: Commit**

```bash
git add examples/templates/
git commit -m "feat: replace example templates with base, freelance, and personal development"
```
