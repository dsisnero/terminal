# Rendering Guidelines for Terminal Widgets

This document captures the conventions we follow when implementing widgets and demos in the Terminal library. The goal is consistent visual output, predictable sizing, and a smooth shutdown story across the codebase.

## 1. Sizing & Layout

- **Respect layout constraints.** Widgets should render using the width/height requested by the `WidgetManager`. Prefer `inner_dimensions`, `create_full_grid`, or other helpers from `Terminal::Widget` to honour the area assigned by the layout resolver.
- **Calculate min/max sizes.** Override `calculate_min_size`, `calculate_max_size`, or the width/height variants so the layout engine can reason about constraints. Use `Terminal::TextMeasurement` helpers when sizing text content.
- **Avoid hard-coded screen dimensions.** When an example needs a full-screen feel, let the layout or builder express that through constraints instead of fixed `80x24` grids inside the widget logic.

## 2. Borders, Padding & Backgrounds

- **Use shared helpers.** `create_full_grid`, `create_bordered_grid`, `wrap_content`, and `wrap_words` keep border styles consistent. If you need to draw custom borders, reuse the same characters (`┌┐└┘`, `─`, `│`) and background colours already used by the existing widgets.
- **Fill backgrounds explicitly.** When assigning colours, make sure the entire cell area is filled (e.g., `InputWidget` propagates the input background across the line). This avoids “striped” artefacts when the widget is smaller than the layout slot.
- **Keep padding configurable.** For widgets that benefit from whitespace (forms, text boxes) expose a padding option and apply it via the shared border helpers rather than duplicating loops.

## 3. Message & Lifecycle Handling

- **Stay inside the message pipeline.** Widgets handle user input via `Msg::InputEvent`, `Msg::KeyPress`, or higher-level commands. Avoid direct system calls (`STDIN.gets`, raw `stty`) in widget code. Examples that need custom IO should build on `Terminal.run`, `DummyInputProvider`, or the spec helpers.
- **Default shutdown behaviour.** Use `Terminal.run` for interactive demos so Ctrl+C and Escape dispatch `Msg::Stop` through the event loop. If a widget needs a custom exit shortcut, register a global key handler via the builder rather than calling `Process.exit`.
- **Support non-focusable widgets.** Set `@can_focus = false` for passive elements so the focus cycle in `WidgetManager` can skip them. This prevents focus loops and aligns with the `can_focus` validation we enforce in specs.

## 4. Testing & Spec Support

- **Use the spec runtime helper.** `Terminal::SpecSupport::Runtime.run` keeps tests from hanging by supplying a dummy input provider and IO::Memory capture. The helper returns the `TerminalApplication`; call `result.app.widget_manager.compose(width, height)` to inspect the final grid (see `spec/runtime_helper_spec.cr`).
- **Capture output via IO::Memory.** When verifying rendered frames, build the app with a memory-backed IO or rely on the helper above. Avoid direct terminal IO in specs.

## 5. Documentation & Examples

- **Reference `Terminal.run`.** All new demos should prefer `Terminal.run` so examples are consistent with the default lifecycle. Mention `/quit` or Escape as the canonical shutdown path.
- **Explain sizing choices.** When adding a new widget or demo, note the reasoning behind width/height constraints in the accompanying documentation (e.g., “TableWidget uses min width = columns + separators”).

Adhering to these guidelines keeps the library predictable and reduces the amount of bespoke code we need to maintain. If you introduce a pattern that does not fit here, update this document so future contributors understand the rationale.
