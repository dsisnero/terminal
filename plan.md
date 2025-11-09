# Plan Part 1 — Overview, Design Principles, Messages

**Goal:** Build a production-ready asynchronous terminal UI library in **Crystal** using SOLID principles, Go-like concurrency (Channels + spawn), dependency injection (DI), and full test coverage.

## Current Status (Updated)

**✅ Completed Components:**
- Core messaging system (`messages.cr`) — includes PasteEvent and CopyToClipboard
- Cell type implementation (`cell.cr`)
- ScreenBuffer with diff computation
- DiffRenderer with ANSI output, bracketed paste toggle, OSC 52 copy
- CursorManager for cursor operations
- WidgetManager with focus management, global key handlers, and layout-aware composition
- UI layout system (`Terminal::UI::LayoutNode`, resolver) and high-level builder (`Terminal.app`)
- Lifecycle helper (`Terminal.run`) providing default Ctrl+C / escape shutdown without custom boilerplate
- EventLoop for fiber management with optional ticker
- Dispatcher for message routing and render ticks (now handles key events directly)
- Input providers: Dummy, Raw (Unix), Raw (Windows with VT mode, key mapping, modifier support); `InputProvider.default`
- Color DSL helpers (`color_dsl.cr`) included in `Widget`
- Widgets: InputWidget, TextBoxWidget, DropdownWidget, SpinnerWidget, TableWidget (colors, sort arrows)

**✅ Test Coverage:**
- Cell operations (unit tests)
- ScreenBuffer diff computation (unit tests)
- DiffRenderer ANSI generation (unit tests)
- CursorManager commands (unit tests)
- Widget event routing (integration tests)
- Full integration pipeline (integration tests)
- Input, TextBox, Dropdown, Spinner, and Table widget specs
- ServiceContainer specs
- Prompt helper coverage and Windows key map specs
- **All 240 specs passing successfully**

**🔧 Recent Fixes:**
- Replaced deprecated sleep calls with Time::Span
- Fixed EventLoop wiring, ScreenBuffer API, WaitGroup behavior
- Added bracketed paste parsing, OSC 52 clipboard support, and alternate-screen handling (restores prior shell UI on exit)
- WidgetManager focus cycle, global key handler registration, and key dispatch wiring in Dispatcher
- Shared editable-text helper across InputWidget/FormWidget for consistent cursor/backspace/delete/home/end behaviour
- Interactive builder demo rebuilt with status panel, command shortcuts, and harness-driven specs
- Added channel-based lifecycle wiring (`Terminal.run`, signal forwarding, escape defaults) and runtime harness for deterministic shutdown

**📋 Next Priority Tasks:**
- [ ] Supervisor for actor failures and restart policies
- [ ] CI/CD extensions (benchmarks, lint gate, Windows smoke tests beyond specs)
- [ ] Expand widget catalog (forms, lists) leveraging shared editable-text helper

## Implementation Status Summary

**✅ COMPLETED (Core Infrastructure):**
- ✅ Core messaging system (`messages.cr`)
- ✅ Cell type implementation (`cell.cr`)
- ✅ ScreenBuffer with diff computation
- ✅ DiffRenderer with ANSI output, alternate screen handling, OSC52, bracketed paste
- ✅ CursorManager for cursor operations
- ✅ WidgetManager with focus + layout composition
- ✅ EventLoop for fiber management + ticker
- ✅ Dispatcher for message routing + tick handling
- ✅ Input providers: Dummy, Raw (Unix), Windows VT stub
- ✅ ColorDSL, InputWidget, TextBoxWidget, DropdownWidget, SpinnerWidget, TableWidget, FormWidget
- ✅ Shared editable-text helper for single-line inputs
- ✅ UI builder and layout DSL (`Terminal.app`, constraints)
- ✅ Runtime harness + signal forwarding (`Terminal.run`)
- ✅ Full test suite (240 specs passing)

**🔄 IN PROGRESS:**
- 🔄 Windows input parsing improvements

**⏳ PENDING:**
- ⏳ Supervisor for fault tolerance
- ⏳ CI/CD pipeline extensions
- ⏳ Expanded widget catalog (list views, buttons, form controls)

---

## Audit Workstream (2025-11)

**Objective:** Run an end-to-end inventory of runtime code, specs, demos, and documentation to ensure the current architecture is fully understood and documented. Fresh notes live under `docs2/` so legacy docs remain untouched until we replace them.

- [x] **Source inventory** – catalog every file under `src/terminal/`, note ownership, dependencies, and whether it is still used. Document findings in `docs2/SRC_SPEC_INVENTORY.md`.
- [x] **Spec coverage map** – build a `src ↔ spec` table showing which specs cover each module, and log gaps/redundancies.
- [x] **Docs refresh** – identify stale Markdown, draft up-to-date replacements in `docs2/` (architecture, runtime flow, component/builder APIs, harness guidance).
- [x] **Demo status** – list every executable (examples, scripts, bin tools), mark which are interactive vs. scripted, and ensure each has a deterministic harness story (`TERM_DEMO_TEST`, `TypescriptReplay`, etc.).
- [x] **Action backlog** – convert audit findings into actionable TODOs (remove dead files, add specs, refresh demos/CI) and feed them back into this roadmap (see `docs2/ACTION_ITEMS.md`).

---

# High-level design summary

* **Architecture:** Actor-like components communicating via immutable messages over `Channel(Msg::Any)`. Each component runs in its own `Fiber`.
* **Concurrency:** Go-style channels, buffered/unbuffered, message-passing. No shared mutable state.
* **DI:** Container creates channels and components, injects dependencies.
* **SOLID mapping:**

  * **S:** Each actor has one responsibility (InputProvider, Dispatcher, ScreenBuffer, DiffRenderer, CursorManager, WidgetManager, Widgets).
  * **O:** Open for extension via interfaces.
  * **L:** Implementations respect interfaces (substitutable).
  * **I:** Small lean interfaces.
  * **D:** High-level modules depend on abstractions, not concrete classes.
* **Testing:** Unit tests for logic; integration tests via `IO::Memory` and `DummyInputProvider`; end-to-end tests.

---

# Core Components (Current)

- **Messages (`messages.cr`)** – immutable union types describing every event flowing through the system (input, stop, render, clipboard, cursor, etc.).
- **Cell (`cell.cr`)** – styled character representation (fg/bg/bold/underline) used by the rendering pipeline.
- **ScreenBuffer (`screen_buffer.cr`)** – maintains the live 2D grid, computes minimal `ScreenDiff` updates.
- **DiffRenderer (`diff_renderer.cr`)** – applies diffs to the target IO, manages alternate screen activation, bracketed paste, OSC 52 clipboard copy.
- **CursorManager (`cursor_manager.cr`)** – moves/hides/shows the cursor and restores state on shutdown.
- **Dispatcher (`dispatcher.cr`)** – routes input events and commands to the active widget, forwards render requests to the buffer.
- **WidgetManager (`widget_manager.cr`)** – tracks widgets, focus order, and composes rendered cells given layout rectangles.
- **Widgets** – `InputWidget`, `TextBoxWidget`, `DropdownWidget`, `SpinnerWidget`, `TableWidget`, `FormWidget`; all mix in `Widget` and many reuse the shared `EditableText` helper.
- **Layout & Builder (`ui_layout.cr`, `ui_builder.cr`)** – declarative constraint-based layout tree plus the `Terminal.app` DSL.
- **Runtime helpers** – `run.cr` (lifecycle wrapper, signal forwarding, initial render), `runtime_harness.cr` (test/deployment hooks), `stop_handler.cr` (signal wiring).
- **Input providers** – dummy provider for tests plus platform-specific raw providers (Unix termios, Windows VT) surfaced via `InputProvider.default`.
- **Prompts & DSL convenience** – high-level prompt helpers (`prompts.cr`) and DSL shortcuts (`dsl_convenience.cr`, `application_dsl.cr`).
- **DI Container / Services** – `container.cr` and `service_provider.cr` wire actors and provide optional dependency injection.

# File Structure Snapshot

```
src/terminal/
  application_dsl.cr
  basic_widget.cr
  color_dsl.cr
  container.cr
  cursor_manager.cr
  diff_renderer.cr
  dsl_convenience.cr
  editable_text.cr
  event_loop.cr
  form_widget.cr
  input_provider.cr
  input_widget.cr
  interactive_streaming_ui.cr
  messages.cr
  prelude.cr
  prompts.cr
  run.cr
  runtime_harness.cr
  screen_buffer.cr
  service_provider.cr
  spinner_widget.cr
  stop_handler.cr
  table_widget.cr
  terminal_application.cr
  text_box_widget.cr
  ui_builder.cr
  ui_layout.cr
  widget.cr
  widget_manager.cr
```

Examples live under `examples/` (`interactive_builder_demo.cr`, `ui_builder_demo.cr`, etc.) and specs mirror the module layout (`spec/`).

# Phase Completion Status (from `plan/fix_cohesiveness.md`)

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Documentation & guardrails | ✅ Complete |
| 2 | Core runtime cohesion (routing, shared helpers) | ✅ Complete |
| 3 | Integration coverage (builder → renderer) | ✅ Complete |
| 4 | Rendering cleanup & shared borders | ✅ Complete |
| 5 | Tooling & CI (ameba + specs) | ✅ Complete |
| 6 | Demo verification / harness docs | ✅ Complete |
| 7 | Application test harness & widget audit | ✅ Complete |

Remaining work now falls under the roadmap below.

# Roadmap

1. **Supervisor / resilience** – introduce actor supervision and restart policies so individual components can fail without dropping the whole app.
2. **CI/CD extensions** – add benchmark harnesses and smoke tests on Windows runners; gate PRs on lint/spec results.
3. **Windows raw-input polish** – improve paste handling, UTF-8 decoding, and modifier coverage in the VT provider.
4. **Widget expansion** – build additional composable widgets (lists, buttons, forms) that leverage the new shared editable-text utilities and border helpers.
5. **Stress / performance validation** – load-test large layouts, slow renderers, and long-running demos to document recommended tuning knobs.

# Testing Strategy

- **Unit tests** – messages, cells, screen buffer diffs, diff renderer (including alternate screen), cursor manager, editable text helper, prompts, service container.
- **Widget specs** – input, text box, dropdown, spinner, table, form (cursor editing) plus shared border rendering.
- **Integration tests** – widget manager focus routing, dispatcher/ScreenBuffer/DiffRenderer pipeline, runtime helper orchestration, interactive builder demo harness.
- **Platform checks** – Windows key map spec, input provider smoke tests (dummy and raw).
- **Manual / future** – planned benchmark and stress suites (see roadmap).

# Messages

Canonical messages in `src/terminal/messages.cr`:

* `Msg::Any` (union of concrete types)
* `Msg::Stop(reason : String?)`
* `Msg::InputEvent(char : Char, time : Time::Span)`
* `Msg::Command(name : String, payload : String?)`
* `Msg::ResizeEvent(cols : Int32, rows : Int32)`
* `Msg::ScreenUpdate(content : Array(String|Array(Cell)))`
* `Msg::ScreenDiff(changes : Array(Tuple(Int32, String|Array(Cell))))`
* `Msg::RenderRequest(reason : String, content : String)`
* `Msg::RenderFrame(seq : Int32, content : String)`
* Cursor messages: `CursorMove`, `CursorSave/Restore`, `CursorHide/Show`, `CursorPosition`
* Widget messages: `WidgetEvent(widget_id : String, payload : Any?)`

> All messages should be immutable.

---
