# Fix Rendering Cohesiveness Plan

## Summary

The rendering pipeline has grown organically across several eras of the project (legacy DSL, experimental concurrent layouts, the new builder). We now have overlapping responsibilities between the builder, `WidgetManager`, dispatcher, and layout primitives. This plan consolidates the flow so that a single source of truth (UI builder → layout resolver → widget manager) produces frames, while keeping key handling, focus, and rendering in sync across platforms.

## Pain Points Identified

1. **Duplicated layout knowledge** – both the builder and `WidgetManager` manage widget IDs, but earlier code left gaps when widgets were not present in the layout tree. We recently added automatic attachment, but we still need stronger validation and diagnostics when a layout node is missing its widget.
2. **Event & lifecycle plumbing** – keyboard events were historically handled inside the dispatcher and individual widgets, while Ctrl+C relied on direct signal callbacks. We’ve moved `Terminal.run` and escape handling onto the message pipeline, but focus validation and additional specs remain.
3. **Rendering contract ambiguity** – some widgets (Input/TextBox/Form) tried to smart-size themselves, while layout rectangles were ignored. We have begun normalising this (Input/TextBox now respect provided width/height), yet we need consistent guidance for new widgets and doc coverage.
4. **Out-of-date documentation** – AGENTS.md and DSL docs referenced the deprecated DSL, leading to confusion for contributors.
5. **Missing integration regression** – builder-driven apps are only tested indirectly; we need coverage that exercises `Terminal.app` through dispatcher, screen buffer, diff renderer, and cursor manager.

## Goals

- Single authoritative layout tree produced by the builder and consumed by `WidgetManager`.
- Predictable focus behaviour (Tab/Shift+Tab, optional per-widget `can_focus`).
- Global key handlers and widget handlers coexisting without duplicated logic.
- Widgets render to the rectangle they are given; auto-sizing is advisory only.
- Documentation and onboarding materials reflect the builder-first API.
- Integration spec ensures builder apps render without relying on demos.

## Plan of Action

### Phase 1 — Documentation & Guardrails (DONE)
- Refresh AGENTS.md to focus on the builder API and required tooling.
- Replace the legacy DSL guide with the new UI builder guide.
- Update README/plan.md to reference the builder and new responsibilities.

### Phase 2 — Core Runtime Cohesion (IN PROGRESS)
- [x] Route `Msg::KeyPress` through the dispatcher and WidgetManager, adding global key registration + Tab navigation.
- [x] Normalise InputWidget/TextBoxWidget rendering against provided dimensions and add specs.
- [x] Tighten DropdownWidget behaviour (filter reset) and add spinner/text box specs.
- [x] Add diagnostics when a layout leaf has no matching widget (raise during build).
- [x] Provide a lifecycle helper (`Terminal.run`) so TUIs stay alive by default, respond to Ctrl+C/`escape`, and still allow opt-in short-running modes.
- [x] Enforce focus configuration for non-focusable widgets (`WidgetManager` skips them, specs cover the behaviour).

-### Phase 3 — Integration Coverage (TODO)
### Phase 3 — Integration Coverage (DONE)
- [x] Write an integration spec that constructs a small builder app, feeds synthetic input, and asserts ScreenBuffer output (ensures dispatcher + layout + widgets cooperate).
- [x] Add regression spec for global key handler consumption to guarantee widgets still receive events when not consumed.
- [x] Introduce `src/spec_support` helpers so TUIs can be exercised in specs without hanging (custom IO + dummy inputs) and demonstrate usage via `spec/runtime_helper_spec.cr`.

### Phase 4 — Rendering Pipeline Cleanup (DONE)
- [x] Evaluate merging or removing the legacy `Frame`, `Layout`, and `ConcurrentLayout` modules once the builder fully replaces them.
- [x] Extract shared helper(s) for bordered widgets to reduce duplication between TextBox/Form/Table.
- [x] Capture rendering guidelines (padding, background fill, ellipsis behaviour) in docs for new widget authors.

### Phase 5 — Tooling & CI (TODO)
- [ ] Extend CI to run `crystal spec` + `ameba` on push (with Windows smoke tests queued).
- [ ] Provide a sample builder demo (`examples/ui_builder_demo.cr`) once the pipeline is cohesive and tested.

## Testing Strategy

- Unit specs for each widget (Input, TextBox, Dropdown, Spinner) – already in place.
- Integration spec for `Terminal.app` (Phase 3) using `DummyInputProvider` to simulate focus and submission.
- Manual smoke tests across macOS/Linux now; rely on Windows CI pipeline once available.

## Risks & Mitigations

- **Breaking existing demos:** Guard by keeping `Terminal.app` API backwards compatible while we finish integration tests.
- **Regression in text rendering:** Maintain per-widget specs that assert rendered grid content (`SpecHelper.grid_to_lines`).
- **Focus loops for non-focusable widgets:** Add builder validation and unit tests covering `Widget#can_focus = false` cases.

## Next Checkpoints

1. Implement layout diagnostics + builder validation (Phase 2).
2. Deliver the end-to-end builder spec (Phase 3) before introducing new demos.
3. Revisit the legacy layout files (`layout.cr`, `concurrent_layout.cr`) after Phase 3 to avoid redundant maintenance.
