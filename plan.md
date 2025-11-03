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
- **All 245 specs passing successfully**

**🔧 Recent Fixes:**
- Replaced deprecated sleep calls with Time::Span
- Fixed EventLoop wiring, ScreenBuffer API, WaitGroup behavior
- Added bracketed paste parsing and OSC 52 clipboard support
- WidgetManager focus cycle, global key handler registration, and key dispatch wiring in Dispatcher
- InputWidget width handling + background fill, TextBoxWidget scroll/state fixes, Dropdown filter reset
- Resolved TableWidget header truncation and ColorDSL constant visibility
- Added channel-based lifecycle wiring (`Terminal.run`, signal forwarding, escape defaults)

**📋 Next Priority Tasks:**
- [x] Author end-to-end builder spec covering Terminal.app → Dispatcher → ScreenBuffer pipeline
- [x] Document cohesive rendering plan (`plan/fix_cohesiveness.md`, `RENDERING_GUIDELINES.md`) and align README/usage guides
- [ ] Supervisor for actor failures and restart policies
- [ ] CI/CD extensions (benchmarks, lint gate, Windows smoke tests beyond specs)

## Implementation Status Summary

**✅ COMPLETED (Core Infrastructure):**
- ✅ Core messaging system (`messages.cr`)
- ✅ Cell type implementation (`cell.cr`)
- ✅ ScreenBuffer with diff computation
- ✅ DiffRenderer with ANSI output + OSC52 + paste toggle
- ✅ CursorManager for cursor operations
- ✅ WidgetManager with focus + layout composition
- ✅ EventLoop for fiber management + ticker
- ✅ Dispatcher for message routing + tick handling
- ✅ Input providers: Dummy, Raw (Unix), Windows VT stub
- ✅ ColorDSL, InputWidget, TextBoxWidget, DropdownWidget, SpinnerWidget, TableWidget
- ✅ UI builder and layout DSL (`Terminal.app`, constraints)
- ✅ Full test suite (245 specs passing)

**🔄 IN PROGRESS:**
- 🔄 Demo application (example binary) — optional

**⏳ PENDING:**
- ⏳ Windows input parsing
- ⏳ Supervisor for fault tolerance
- ⏳ CI/CD pipeline

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

# Core components (summary)

1. **InputProvider:** sends `InputEvent`/`Stop` to `system_chan`. Implementations: `ConsoleInputProvider`, `DummyInputProvider`, `FileInputProvider`.
2. **Dispatcher:** routes input to `WidgetManager`, broadcasts `Stop`, sends `ScreenUpdate` to `buffer_chan`.
3. **WidgetManager:** manages widgets, per-widget channels, `compose` to produce `ScreenUpdate`.
4. **Widget (base):** interface with `render`, `handle(msg)`, optional `start`.
5. **ScreenBuffer:** receives `ScreenUpdate`, computes `ScreenDiff`, emits to `renderer_chan`.
6. **DiffRenderer:** receives `ScreenDiff`, writes ANSI to injected `IO`, emits `RenderFrame`.
7. **CursorManager:** handles cursor moves, hide/show, save/restore.
8. **Container:** builds channels and components, injects dependencies, starts actors.
9. **Terminal facade:** high-level entry point.
10. **Supervisor:** optional actor supervision for failures.

# Plan Part 2 — File Structure, Phases 0-2

# File Structure

```
src/
  terminal/
    messages.cr
    cell.cr
    raw_terminal.cr
    input_provider.cr
    dummy_input_provider.cr
    dispatcher.cr
    widget_manager.cr
    widgets/
      base.cr
      text_box.cr
      status_bar.cr
      list_view.cr
      button.cr
    screen_buffer.cr
    diff_renderer.cr
    cursor_manager.cr
    widget_renderer.cr
    container.cr
    terminal.cr
spec/
  messages_spec.cr
  cell_spec.cr
  screen_buffer_spec.cr
  diff_renderer_spec.cr
  cursor_manager_spec.cr
  widget_integration_spec.cr
  terminal_integration_spec.cr
README.md
plan.1.md
plan.2.md
plan.3.md
```

---

# Phase 0 — Project setup & conventions

**Tasks:**

* Initialize project (`shard.yml`), create directories.
* Add `spec` to `shard.yml`.
* Set coding conventions (immutable messages, snake_case filenames, DI in Container).

**Acceptance:**

* `crystal spec` runs.
* Optional lint/formatter configured.

---

# Phase 1 — Core messaging, IO injection, lightweight pipeline

**Tasks:**

[✅] Implement `messages.cr`.
[✅] Implement `cell.cr` (Cell type).
[✅] Implement `ScreenBuffer` (string mode) with `start(in, out)` and unit tests.
[✅] Implement `DiffRenderer` with injected `IO` and tests using `IO::Memory`.
[✅] Implement `CursorManager` with injected IO and tests.
[✅] Implement `EventLoop` for fiber management.
[✅] Implement `Dispatcher` for message routing.
[ ] Implement `DummyInputProvider`.
[ ] Implement `Container` to wire channels and start components.
[ ] Write `terminal.cr` demo using `DummyInputProvider`.

**Acceptance:**

* Unit tests pass. ✅ (All 9 tests passing)
* Integration: demo writes expected ANSI sequences to `IO::Memory`.

**Tests:**

* ScreenBuffer: initial N lines yields N `ScreenDiff` entries. ✅
* DiffRenderer: applied diffs produce correct ANSI output. ✅
* CursorManager: emits correct ANSI sequences. ✅
* Widget event routing: input events routed to focused widget. ✅

---

# Phase 2 — Interactive input, Dispatcher, WidgetManager

**Tasks:**

[ ] Implement `InputProvider` console version (raw mode, `termios`).
[✅] Implement `Dispatcher` routing `InputEvent` -> `WidgetManager`, handling `Command`s.
[✅] Implement `WidgetManager` and widgets: `TextBox`, `StatusBar`, `ListView`.
[✅] Implement `WidgetManager.compose` -> `ScreenUpdate`.
[✅] Add tests for `WidgetManager` and `Dispatcher`.
[ ] Extend `Container` to wire `Dispatcher` and `WidgetManager`.
[ ] Provide interactive demo: `terminal.cr` with Tab focus switching, 'q' to quit.

**Acceptance:**

* Integration: input updates `ScreenBuffer` via Dispatcher.
* End-to-end: demo interactive with Tab focus, 'q' stops gracefully.

**Tests:**

* `widget_event_routing_spec`: assert `ScreenDiff` after sending input.
* `terminal_integration_spec`: simulate input sequence via `DummyInputProvider`, assert final `Stop`.

# Plan Part 3 — Phases 3-5

## Phase 3 — CursorManager, RawTerminal, graceful shutdown

**Tasks:**

[✅] Implement `CursorManager` with injected IO and tests.
[ ] Replace `stty` with `termios` FFI wrapper (`RawTerminal`).
[ ] Ensure fiber loops catch exceptions, send `Msg::Stop`.
[ ] Add `Supervisor` for actor failures.
[ ] Add unit tests for `RawTerminal` toggling.

**Acceptance:**

* CursorManager emits correct ANSI sequences.
* RawTerminal toggling works via FFI.
* Ctrl-C or Stop restores terminal settings.

**Tests:**

* CursorManager_spec: verify hide/show/move sequences.
* Supervisor: simulate failing actor, confirm Stop propagation.

---

## Phase 4 — Styled Cells & ScreenBuffer upgrade

**Tasks:**

[ ] Upgrade `Cell` with fg/bg/bold/underline and `to_ansi`.
[ ] Update `ScreenUpdate` to use `Array(Array(Cell))`.
[ ] ScreenBuffer tracks 2D grid, computes `ScreenDiff`.
[ ] DiffRenderer renders `Cell` sequences with style grouping.
[ ] Tests verifying style diffs and compact ANSI emissions.

**Acceptance:**

* ScreenBuffer-style tests pass.
* DiffRenderer emits minimal ANSI resets.
* Integration tests with IO::Memory validate output.

**Tests:**

* `screen_buffer_styled_spec`: diff counts and content.
* `diff_renderer_styled_spec`: style grouping test.

---

## Phase 5 — Widget composition & async event routing

**Tasks:**

[✅] Implement `Widget` base and widget set.
[✅] WidgetManager per-widget channels, optional `start` fiber for widgets.
[✅] Dispatcher routes input to focused widget, sends `ScreenUpdate`.
[ ] Optional WidgetRenderer to transform widget tree to ScreenUpdate.
[ ] Tests for widget routing, composition, focus, and commands.
[ ] Extend Container to start all components.

**Acceptance:**

* Integration spec runs deterministically using `IO::Memory`.
* Focus commands change targeted widget.
* Widgets can run background tasks publishing updates via channels.

**Tests:**

* `widget_integration_spec`: route input, verify composed output.
* `widget_focus_spec`: focus_next/prev changes receiving widget.

# Plan Part 4 — Phases 6-7, Testing, CI, Extras

## Phase 6 — Robustness, CI, benchmarks

**Tasks:**

[ ] Add continuous integration (GitHub Actions) running `crystal spec`.
[ ] Add benchmarks for throughput and latency.
[ ] Stress tests: many widgets, large buffers, slow renderer.
[ ] Optional supervisor policies for restarts.
[ ] Document performance tuning knobs.

**Acceptance:**

* CI runs green.
* Benchmarks reported.
* Backpressure demonstrated.

**Tests:**

* `bench` folder with benchmark harness.

---

## Phase 7 — Extras (polish, extensions)

**Tasks:**

[ ] Add optional advanced widgets (Tables, Graphs, ProgressBars).
[ ] Add mouse/scroll support if terminal supports.
[ ] Provide color scheme support.
[ ] Add documentation for library usage, DI, and customization.
[ ] Add more integration tests simulating real TUIs.

**Acceptance:**

* Library can be used to build a non-trivial TUI.
* All previously implemented phases remain passing.
* Documentation is complete with examples.

**Tests:**

* Integration tests for optional widgets.
* End-to-end demos using terminal, IO::Memory, and DummyInputProvider.

---

# Testing Strategy (summary)

[✅] **Unit tests:**

   * Messages, Cell operations, ScreenBuffer diff, DiffRenderer ANSI generation, CursorManager commands.
[ ] **Integration tests:**

   * DummyInputProvider → Dispatcher → WidgetManager → ScreenBuffer → DiffRenderer.
   * Focus switching, commands, stop propagation.
[ ] **End-to-end tests:**

   * Interactive flow with terminal input, simulate sequences via DummyInputProvider.
[ ] **Stress and performance tests:**

   * Large number of widgets, rapid updates, slow IO, validate latency and correctness.

# Notes for implementation

* All communication async via Channels, no shared mutable state.
* All actors (components) run in separate fibers using `spawn`.
* Use dependency injection via Container to pass channels and IO.
* Strict immutable messages and Cell structs for safety.
* Each component mapped to a clear SOLID responsibility.
* Tests leverage `IO::Memory` and `DummyInputProvider` for deterministic validation.
