# AGENTS.md — Terminal Library Assistant Guide

## Workflow Guardrails
- Always run `crystal tool format`, `ameba`, and `crystal spec` before proposing commits; escalate permissions for specs when the sandbox blocks process execution.
- Never restore legacy demos (`examples/enhanced_dsl_demo.cr`, `examples/elegant_chat_demo.cr`); the new builder demos will replace them later.
- Respect cross-platform abstractions (TTY adapters, input providers, Windows key map). Do not introduce UNIX-only code paths.
- Keep edits focused: update only the files relevant to the task and avoid regressing staged work the user already prepared.

## Preferred APIs & Patterns
- For interactive TUIs prefer `Terminal.run(width: 80, height: 24) { |ui| ... }`, which keeps the app alive, wires Ctrl+C by default, and still returns the application when it stops. Follow the practices listed in `RENDERING_GUIDELINES.md` when wiring shutdown hooks or drawing borders.
- Use the **UI builder** entry point: `Terminal.app(width: 80, height: 24) { |ui| ... }` when you need to compose widgets without booting the full lifecycle helper (e.g., in tests or tooling).
  - Compose layouts with `ui.layout { |layout| layout.vertical { ... } }` and `Terminal::UI::Constraint` helpers (`percent`, `length`, `flex`).
  - Mount widgets via `ui.text_box`, `ui.table`, `ui.input`, `ui.spinner`, or `ui.mount` for custom widgets.
  - Register behavior with `ui.on_input("widget_id") { |value| ... }`, `ui.on_key(:escape) { app.stop }`, and `ui.every(250.milliseconds) { ... }` for tickers.
  - When tests need deterministic shutdown or log capture, pass a `Terminal::RuntimeHarness::Controller` to `Terminal.app` / `Terminal.run` (or call `builder.attach_harness`). Specs can also set `TERM_DEMO_SKIP_MAIN=1` when requiring demos to prevent them from auto-starting.
- Widgets should rely on `include Terminal::Widget` helpers for wrapping, borders, and focus. New widgets must expose `id`, `handle`, and `render`, and honour `can_focus` when focus is not applicable.
- Use the shared styling utilities (`Terminal::ColorDSL`, `Terminal::TextMeasurement`) to keep rendering consistent.

## Layout, Focus & Key Handling
- The `WidgetManager` now cycles focus with Tab / Shift+Tab automatically and supports global key handlers. Register app-level shortcuts through the builder (`ui.on_key(:f1) { ... }`).
- Compose screens by letting `WidgetManager` render into the layout rectangles returned from `Terminal::UI::LayoutResolver`.
- When extending focus behaviour, prefer overriding the navigation hooks in `Terminal::Widget` (`handle_up_key`, `handle_enter_key`, etc.) instead of duplicating key parsing.

## Prompts & Synchronous Utilities
- For simple CLI scripts, use `Terminal::Prompts.ask` and `Terminal::Prompts.password`. They share the same cross-platform TTY adapter used by widgets, so masking and terminal restoration are consistent.

## Testing & Reference Material
- Specs live under `spec/`; prefer focused specs per widget (`spec/input_widget_spec.cr`, `spec/text_box_widget_spec.cr`, etc.). Add regression coverage when fixing bugs.
- Helpful references: `README.md` (quick start + builder overview), `plan.md` (roadmap), `docs2/README.md` (in-progress audit docs: runtime flow, source/spec inventory, demo status, input providers), `LAYOUT_SYSTEM_SUMMARY.md` (layout engine), `TERMINAL_ARCHITECTURE.md` (actor pipeline).
- Keep documentation in sync with behaviour changes, especially when updating the builder API or widget contracts.
