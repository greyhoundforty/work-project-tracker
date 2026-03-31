# Example Template Files Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three example `ProjectTemplate` JSON files to `examples/templates/` so users have concrete starting points when configuring their template folder.

**Architecture:** Pure data — no Swift code changes. The existing `ProjectTemplate.load(from:)` method already handles any JSON files placed in a folder. We create the folder and three files, validate they parse correctly, then commit.

**Tech Stack:** JSON, Swift (for validation via existing tests)

---

### Task 1: Create examples/templates/ folder and three template files

**Files:**
- Create: `examples/templates/personal-dev-tracking.json`
- Create: `examples/templates/long-term-project.json`
- Create: `examples/templates/poc-evaluation.json`

The `ProjectTemplate` Swift struct (at `EngagementTracker/Models/ProjectTemplate.swift`) decodes these exact fields — all are required:

```swift
struct ProjectTemplate: Codable {
    let name: String       // display name shown in the picker
    let isPOC: Bool        // marks project as POC when applied
    let tags: [String]     // pre-populated tags
    let stage: String      // must match a ProjectStage rawValue exactly
    let taskTitles: [String] // task titles created on project save
}
```

Valid `stage` values (from `EngagementTracker/Models/Enums.swift`):
`"Discovery"`, `"Initial Delivery"`, `"Refine"`, `"Proposal"`, `"Won"`, `"Lost"`

- [ ] **Step 1: Create the templates folder and personal-dev-tracking.json**

```bash
mkdir -p examples/templates
```

File contents for `examples/templates/personal-dev-tracking.json`:

```json
{
  "name": "Personal Dev Tracking",
  "isPOC": false,
  "stage": "Discovery",
  "tags": ["personal", "development"],
  "taskTitles": [
    "Define learning goals",
    "Set up local environment",
    "Document progress",
    "Review and retrospect"
  ]
}
```

- [ ] **Step 2: Create long-term-project.json**

File contents for `examples/templates/long-term-project.json`:

```json
{
  "name": "Long Term Project",
  "isPOC": false,
  "stage": "Discovery",
  "tags": ["long-term", "project"],
  "taskTitles": [
    "Define project scope",
    "Identify stakeholders",
    "Set milestone schedule",
    "Conduct quarterly review",
    "Prepare status report"
  ]
}
```

- [ ] **Step 3: Create poc-evaluation.json**

File contents for `examples/templates/poc-evaluation.json`:

```json
{
  "name": "POC Evaluation",
  "isPOC": true,
  "stage": "Discovery",
  "tags": ["poc", "evaluation"],
  "taskTitles": [
    "Define success criteria",
    "Stand up evaluation environment",
    "Run proof-of-concept",
    "Document results",
    "Prepare POC readout"
  ]
}
```

- [ ] **Step 4: Validate JSON is well-formed**

Run against each file:

```bash
python3 -m json.tool examples/templates/personal-dev-tracking.json > /dev/null && echo "OK"
python3 -m json.tool examples/templates/long-term-project.json > /dev/null && echo "OK"
python3 -m json.tool examples/templates/poc-evaluation.json > /dev/null && echo "OK"
```

Expected output: three lines of `OK`. Any parse error means the JSON is malformed — fix it before continuing.

- [ ] **Step 5: Confirm all required fields are present**

Each file must have exactly these keys: `name`, `isPOC`, `stage`, `tags`, `taskTitles`. Run:

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
print('OK — name:', data['name'], '| stage:', data['stage'], '| isPOC:', data['isPOC'])
"
done
```

Expected output:
```
=== examples/templates/long-term-project.json ===
OK — name: Long Term Project | stage: Discovery | isPOC: False
=== examples/templates/personal-dev-tracking.json ===
OK — name: Personal Dev Tracking | stage: Discovery | isPOC: False
=== examples/templates/poc-evaluation.json ===
OK — name: POC Evaluation | stage: Discovery | isPOC: True
```

- [ ] **Step 6: Commit**

```bash
git add examples/templates/
git commit -m "feat: add example project template files (closes #9)"
```
