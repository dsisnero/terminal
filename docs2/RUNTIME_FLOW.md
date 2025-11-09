# Runtime Flow (Builder / Component Stack)

```
input provider → dispatcher → widget manager → screen buffer → diff renderer → IO
                                   ↓
                               widgets
```

1. **Input Providers (`input_provider.cr`)** emit `Msg::InputEvent` into the dispatcher channel. For specs/demos we default to `DummyInputProvider`; production apps use raw Unix/Windows providers.
2. **Dispatcher (`dispatcher.cr`)** fans events out:
   - Key/input events → active widget (through `WidgetManager#handle`).
   - Render ticks (`Msg::RenderRequest`) → `ScreenBuffer`.
   - Global commands (stop, resize) → relevant subsystems.
3. **WidgetManager (`widget_manager.cr`)** owns widget registry, focus order, and layout rectangles. It invokes each widget’s `render(width, height)` and aggregates cells into a frame.
4. **ScreenBuffer (`screen_buffer.cr`)** compares the new frame against the previous one, emits `Msg::ScreenDiff` for dirty rows, and logs diff counts when `TERMINAL_USE_HARNESS` is set.
5. **DiffRenderer (`diff_renderer.cr`)** applies diffs to the target IO (STDOUT or `IO::Memory`), managing the alternate screen, bracketed paste, cursor visibility, and OSC 52 copy operations.
6. **Runtime Harness (`runtime_harness.cr`)** optionally wraps the app, capturing log lines, providing deterministic stop signals, and integrating with scripted demos/tests (`TERM_DEMO_TEST=1`).

## Component Model (`component_program.cr`)

```
Component#layout → UI::Builder
Component#render → ViewContext handles
Component#update → model mutations
program.start → Terminal.app underneath
```

- The program builds widgets via the normal builder API, then exposes typed handles (`ViewContext`) for render/update.
- `Program#dispatch` updates the model and triggers renders; `Program#stop` informs the harness and sends `Msg::Stop`.
- Specs interact directly with handles (e.g., `view.text_box(:chat)`), making it easy to assert widget content without needing terminal IO.

## Harness Tips

- Set `TERM_DEMO_TEST=1` for demos that support scripted flows; combine with `TERMINAL_USE_HARNESS=1` to avoid terminal residue.
- Use `scripts/capture_example.py <demo>` to record `.typescript` transcripts, then replay via `Terminal::SpecSupport::TypescriptReplay`.

Refer to `docs2/SRC_SPEC_INVENTORY.md` for per-module coverage details.
