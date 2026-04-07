# On-disk vault for project notes and tasks

## Layout

When **Settings → On-disk vault** has a root folder chosen, each project with a `vaultFolderName` gets:

```
{vaultRoot}/{vaultFolderName}/
  notes/           # `*.md` (recursive allowed for future subfolders)
  tasks/           # `*.txt`, one task per file
```

`vaultFolderName` is a stable directory name: sanitized project name + `-` + first 8 hex digits of `Project.id` (assigned the first time the project needs vault storage).

## Source of truth (hybrid C)

- **SwiftData** remains the canonical store for projects and for CloudKit-eligible models.
- **Notes and tasks** are **mirrored** to disk whenever a vault root is configured: the UI still binds to `Note` / `ProjectTask`, while `VaultService` writes `.md` / `.txt` on create/update/delete and **reconciles from disk** when the Notes or Tasks tab appears (disk wins for content when a file exists).

Rationale: keeps Reminders import, search, and existing queries working; users still get plain files for editors and git.

### CloudKit

`Note` and `ProjectTask` continue to sync via SwiftData if CloudKit is enabled. Files on disk are **local-only** to this Mac’s vault folder. A second device will not see the same files unless the vault lives on a synced volume (e.g. iCloud Drive); CloudKit could then duplicate logical content (store vs files). Product follow-up: disable CloudKit for note/task models, or document “vault + CloudKit” as best-effort.

## File formats

### Markdown note (`notes/{uuid}.md`)

- Filename: `{note.id.uuidString uppercased or lowercased}`.md — use **lowercase** for consistency.
- Frontmatter (YAML-style `key: value` lines between `---` fences):

```markdown
---
id: <UUID>
title: <optional single-line title>
created: <ISO8601>
---

<body markdown>
```

### Task (`tasks/{uuid}.txt`)

- Filename: `{task.id.uuidString}.txt`
- Same frontmatter style:

```text
---
id: <UUID>
title: <single line>
completed: true|false
completedAt: <ISO8601 or empty>
due: <ISO8601 or empty>
created: <ISO8601>
---

```

Body after the closing `---` is ignored.

## macOS / sandbox

Vault root is stored like templates: path string + **security-scoped bookmark**. All reads/writes run inside `URL.startAccessingSecurityScopedResource()` on the vault root (see `VaultService.withVaultRoot`).

## Edge cases (rename / delete / sync)

| Scenario | Behavior |
|----------|----------|
| User renames project in app | `vaultFolderName` unchanged; folder name on disk stays stable. |
| User renames/moves project folder in Finder | App still uses bookmark path + stored `vaultFolderName`; moving the whole vault root is OK if the bookmark is refreshed; moving a single project subfolder breaks resolution until user fixes layout. |
| User deletes a `.md` / `.txt` | Next tab open **sync removes** the orphan `Note` / `ProjectTask` from SwiftData. |
| User adds a new `.md` in `notes/` | Next Notes tab open **imports** a new `Note`. |
| No vault configured | Behavior unchanged: notes/tasks only in SwiftData. |
| Cleared vault in Settings | New writes stay SwiftData-only; existing files are not deleted (intentionally safe). |
| Vault enabled, disk has no note/task files yet, SwiftData holds items | Sync **exports** those rows to disk first; nothing is deleted as an orphan. |

## Future work

- FSEvents or periodic refresh while a tab is open.
- Optional mirror of in-app `ProjectFolder` as nested directories under the vault.
