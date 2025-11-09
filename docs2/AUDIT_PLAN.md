# Terminal Audit Workstream

## Goals

1. Reconcile every runtime component (in `src/terminal/`) with a matching, up-to-date spec.
2. Inventory documentation and produce refreshed references inside `docs2/` while keeping legacy docs untouched for historical context.
3. Confirm the public API + demo surface is consistent with the current builder/component model, flagging any deprecated or dead code.

## Checklists

### 1. Source Inventory
- [ ] Walk `src/terminal/` to capture a table of every file, its role, and whether it still participates in the runtime.
- [ ] Note any legacy or unused files that should be migrated, replaced, or removed.
- [ ] Document shared dependencies between modules (channels, harness hooks, input providers).

### 2. Spec Coverage Audit
- [ ] Produce a `src ↔ spec` mapping (one row per source file) noting existing specs, missing coverage, or redundant specs.
- [ ] Identify integration specs that exercise each major pipeline (input → dispatcher → renderer, component program, builder demos).
- [ ] Flag obsolete specs that reference deprecated APIs.

### 3. Documentation Refresh
- [ ] Record which legacy docs are still accurate (`README.md`, `AGENTS.md`, etc.) and which need replacement.
- [ ] Author new `docs2/` summaries: architecture, runtime flow, component API, harness/testing guidance.
- [ ] Capture demo instructions (including `TERM_DEMO_TEST` usage) and replay tooling (`scripts/capture_example.py`, `TypescriptReplay`).

### 4. Runtime / Demo Verification
- [ ] List all binaries/examples (`examples/*.cr`, `bin/*`, `scripts/*`) and their current status (interactive vs. scripted vs. deprecated).
- [ ] Ensure each example has a reproducible harness story or mark gaps.

## Outputs

1. **Audit Report** – Markdown table(s) under `docs2/` summarizing module/spec/doc status and recommended actions.
2. **Updated Plan** – `plan.md` tracks progress and links to the new audit documents.
3. **Follow-up Issues** – Actionable TODOs (remove dead files, add specs, refresh demos) derived from the audit findings.
