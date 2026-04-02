---

# Resolve issue with Data reset

## Overview
Currently when using the 'Reset Data' or 'Reset All' option causes the last selected project to remain visible in the app. 

## Context
- Resetting data on a recurring basis to test new features and need to have the app "wipe" to a clean slate
- Incorrect view image: https://images.gh40-dev.systems/Shared-Image-2026-04-02-11-53-07.png
- Expected "clean slate" view after a data reset: https://images.gh40-dev.systems/Shared-Image-2026-04-02-11-58-14.png

## Development Approach
- Update default view if no projects exist or upon data reset

## Implementation Steps

### Task 1: Resolve data reset view issue

- [x] Verify if the Data reset functions have a post-call script or function. If not provide trigger to reset view to default

### Task 2: Update documentation

- [x] Update CLAUDE.md if internal patterns changed
- [x] Move this plan to `docs/plans/completed/`
- [x] Create a document in 'docs/plans/2026-04-02-Customize.md' with instructions on how to customize the app toolbar. I want to add the app name and maybe another icon ir two 
