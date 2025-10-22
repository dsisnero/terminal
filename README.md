# Terminal UI Library (Crystal)

An async terminal UI toolkit for Crystal with a clean actor-based architecture (channels + fibers), SOLID design, and a growing widget ecosystem.

Highlights:
- Message-driven architecture with immutable messages
- Diff-based rendering to minimize output
- Raw input (termios on Unix, VT-mode guard on Windows)
- Color/style convenience DSL (red("text"), bold("text"), styled_line(...))
- Widgets out of the box: Basic, Spinner, and Table with a fluent DSL
- Optional render ticker for animations (spinners, progress)

Status: Library shard (no binary target). Specs: 36/36 passing.

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

## Quick start

Create a minimal app using `TerminalApplication(T)` and the included `BasicWidget`:

```crystal
require "terminal"

# Render a bordered box with the text inside; typing would append chars if wired to input
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
- `RawInputProvider` (Windows): enables VT-input; minimal stub (guarded with `flag?(:win32)`) 

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
crystal spec
crystal tool format
```

## Contributing

1. Fork
2. Create branch (`feat/x`)
3. Commit and push
4. Open a PR

## License

MIT