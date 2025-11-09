# Terminal UI Library (Crystal)

An async terminal UI toolkit for Crystal with a clean actor-based architecture (channels + fibers), SOLID design, and a modern **UI builder** for composing layouts in seconds.

## 🚀 UI Builder Highlights

- **Declarative layout tree**: nest `horizontal` / `vertical` blocks with `%`, `length`, or `flex` constraints.
- **Mount widgets by id** (`ui.text_box "logs"`, `ui.table "data"`) with builder-style configuration.
- **Focus-aware routing**: widgets receive `focus` / `blur`, navigation handled centrally.
- **Full architecture integration** (EventLoop, ScreenBuffer, DiffRenderer) out of the box.
- **Synchronous prompts** for quick CLI scripts without the async pipeline.

## Architecture Highlights

- Message-driven architecture with immutable messages
- Diff-based rendering to minimize output (no flickering)
- Raw input handling (termios on Unix, VT-mode guard on Windows)
- Color/style convenience DSL (red("text"), bold("text"), styled_line(...))
- Complete widget ecosystem with fluent builders
- Actor-based coordination (EventLoop → ScreenBuffer → DiffRenderer)


## Install

Add to your `shard.yml`:

```yaml
dependencies:
  terminal:
    github: dsisnero/terminal
```

Then:

```bash
shards install
```

## Quick Start with the UI Builder

```crystal
require "terminal"

Terminal.run(width: 80, height: 20) do |ui|
  ui.layout do |layout|
    layout.vertical do
      layout.widget "header", Terminal::UI::Constraint.length(3)
      layout.horizontal do
        layout.widget "sidebar", Terminal::UI::Constraint.percent(30)
        layout.widget "main"
      end
    end
  end

  ui.text_box "header" do |tb|
    tb.set_text("System Monitor — press Ctrl+C to exit")
  end

  ui.text_box "sidebar" do |tb|
    tb.set_text("Logs will appear here…")
  end

  ui.table "main" do |table|
    table.col("Proc", :name, 20, :left, :cyan)
    table.col("CPU%", :cpu, 6, :right, :white)
    table.rows([
      {"name" => "worker-1", "cpu" => "12"},
      {"name" => "worker-2", "cpu" => "7"},
    ])
  end
end
```

## Component Model (Preview)

Prefer to keep state + render logic together? The component layer wraps the builder so you can write Elm/Bubble-Tea style programs:

```crystal
class HelloComponent < Terminal::Components::Component(String)
  def initial_model : String
    "Hello"
  end

  def layout(layout : Terminal::Components::LayoutDSL) : Nil
    layout.compose do
      layout.text_box :log, layout.flex, auto_scroll: true do |box|
        box.can_focus = false
      end
      layout.input :input, layout.length(1), prompt: "> "
    end
  end

  def render(model : String, view : Terminal::Components::ViewContext) : Nil
    view.text_box(:log).set_text(model)
  end

  def update(event, model : String) : String
    case event
    when Terminal::Components::Events::InputSubmitted
      "#{model}\nYou: #{event.value}"
    else
      model
    end
  end
end

Terminal::Components.run(HelloComponent.new, width: 60, height: 12)
```

See `examples/component_chat_demo.cr` for a fuller sample with harness logging, keyboard shortcuts, and scripted playback via `TERM_DEMO_TEST=1`.

## Running Examples with the Harness

Every example can be executed through the harness-aware runner so terminal state stays tidy:

```bash
bin/run_example interactive_builder_demo
bin/run_example -l interactive_builder_demo   # stream harness logs
# or, if you prefer raw crystal:
crystal run scripts/run_example.cr -- -l interactive_builder_demo
```

When a demo supports scripted playback (for example, `component_chat_demo` once reintroduced), set `TERM_DEMO_TEST=1` so the harness drives input automatically. Pair it with `TERMINAL_USE_HARNESS=1` to avoid raw-terminal cleanup.

Need archived ANSI output for regression tests? Capture it via:

```bash
scripts/capture_example.rb interactive_builder_demo -o log/interactive_builder_demo.typescript
```

Then load the transcript in specs using `Terminal::SpecSupport::TypescriptReplay` or inspect it quickly via:

```bash
crystal run scripts/replay_typescript.cr -- -f log/interactive_builder_demo.typescript
```

Need a local raw-input smoke test on macOS/Linux? Run `scripts/smoke_raw_input.rb` (drives the demo via PTY, sends bracketed paste). Need to verify Windows raw input? Follow `docs2/WINDOWS_SMOKE_TESTS.md` (dev box instructions + capture workflow).


## CLI Prompts & TTY Utilities

Need lightweight input for scripts? The synchronous helpers avoid spinning up the full event loop:

```crystal
require "terminal/prompts"

username = Terminal::Prompts.ask("User:")
password = Terminal::Prompts.password("Password:")
```

Both helpers use the shared `Terminal::TTY.with_raw_mode` adapter, so masking and backspace work the same across macOS, Linux, and Windows. Advanced use cases can call the adapter directly:

```crystal
Terminal::TTY.with_raw_mode do
  # Your console logic here (raw mode, no echo)
end
```
> Need the full architecture map and audit status? See `docs2/README.md` for runtime flow, source/spec inventory, demo status, and input-provider guidance (will replace the legacy docs below once finalized).


## Documentation

- **[UI Builder Guide](DSL_USAGE_GUIDE.md)** – Layout constraints, widget mounting, and event hooks
- **[Layout System Summary](LAYOUT_SYSTEM_SUMMARY.md)** – Deep dive into the layout resolver and geometry helpers
- **[Terminal Architecture](TERMINAL_ARCHITECTURE.md)** – Actor pipeline and rendering overview
- **[Windows Dev Box Setup](docs/windows_devbox_setup.md)** – Provision a cloud VM for Windows-specific testing
- **[Rendering Guidelines](RENDERING_GUIDELINES.md)** – Widget sizing, borders, and lifecycle conventions
- **[Audit Docs (WIP)](docs2/README.md)** – Up-to-date runtime notes, source/spec inventory, demo status, and input-provider guidance (will replace legacy docs once finalized).

## Low-Level API

For advanced use cases, you can use the low-level API:

```crystal
require "terminal"

# Render a bordered box with the text inside
widget = Terminal::BasicWidget.new("basic", "Hello, Terminal")
manager = Terminal::WidgetManager(Terminal::BasicWidget).new([widget])
app = Terminal::TerminalApplication(Terminal::BasicWidget).new(widget_manager: manager)
app.start
sleep 0.5
app.stop
```

## Widgets

### SpinnerWidget

```crystal
spinner = Terminal::SpinnerWidget.new("spin", "Working...")
# Animate via RenderRequest ticks; see EventLoop ticker below
```

### TableWidget (fluent DSL)

```crystal
table = Terminal::TableWidget.new("t1")
  .col("Name", :name, 12, :left, :cyan)
  .col("Age",  :age,   5, :right)
  .col("City", :city, 12, :left)
  .sort_by(:age, asc: true)
  .rows([
    {"name" => "Alice", "age" => "30", "city" => "Paris"},
    {"name" => "Bob",   "age" => "28", "city" => "Berlin"},
  ])
```

## Color DSL

Available in all widgets via `include Terminal::Widget`:

- `red("Error")`, `green("OK")`, `blue("Info")`
- `bold("text", fg: :magenta)`, `underline("text")`
- `styled_line("Title", width, :center, fg: :yellow, bold: true)` → Array(Cell)

## Messages

Defined in `src/terminal/messages.cr`. Key types:

- Input and commands: `InputEvent`, `Command`, `ResizeEvent`
- Screen pipeline: `ScreenUpdate`, `ScreenDiff`, `RenderRequest`, `RenderFrame`
- Cursor: `CursorHide`, `CursorShow`, `CursorMove`, `CursorPosition`
- Widgets: `WidgetEvent`
- Clipboard and paste: `PasteEvent` (bracketed paste), `CopyToClipboard` (OSC 52)

## Input providers

- `DummyInputProvider`: emits a sequence for tests
- `ConsoleInputProvider`: stubbed for now
- `RawInputProvider` (Unix): termios raw mode + non-blocking read, bracketed paste
- `RawInputProvider` (Windows): toggles VT input, disables echo/line mode, emits key events (guarded with `flag?(:win32)`)

`InputProvider.default` picks the best available.

## Event loop and ticker

`EventLoop(T)` manages subsystem fibers and channels. It supports an optional ticker to emit `RenderRequest` messages periodically, which widgets can use for animations (e.g., `SpinnerWidget`).

## Rendering and clipboard

`DiffRenderer` can enable bracketed paste (optional) and handles `CopyToClipboard` via OSC 52 (supported in many terminals like iTerm2/Kitty/xterm with settings).

## Project layout

```
src/terminal/
  prelude.cr            # roll-up requires for library
  messages.cr           # message definitions (incl. PasteEvent, CopyToClipboard)
  cell.cr               # styled cell type (to_ansi)
  widget.cr             # Widget interface + helpers (includes ColorDSL)
  color_dsl.cr          # red(), bold(), styled_line(), etc.
  widget_manager.cr     # focus, broadcast, compose
  dispatcher.cr         # routes input/commands and composes frames
  screen_buffer.cr      # ScreenUpdate→ScreenDiff
  diff_renderer.cr      # ANSI output, cursor control, OSC 52
  cursor_manager.cr     # cursor show/hide/move
  event_loop.cr         # fiber coordinator + optional ticker
  input_provider.cr     # base + default()
  input_raw_unix.cr     # raw input using termios (Unix)
  input_raw_windows.cr  # VT input (Windows stub)
  spinner_widget.cr     # animated spinner
  table_widget.cr       # table with DSL, colors, sort arrows

spec/
  ... 36 examples, 0 failures
```

## Development

```bash
git clone https://github.com/dsisnero/terminal.git
cd terminal
shards install
CRYSTAL_CACHE_DIR="$PWD/temp/crystal_cache" crystal spec
./bin/ameba
crystal tool format
```

## Contributing

1. Fork
2. Create branch (`feat/x`)
3. Commit and push
4. Open a PR

## License

MIT
