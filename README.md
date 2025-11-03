# Terminal UI Library (Crystal)

An async terminal UI toolkit for Crystal with a clean actor-based architecture (channels + fibers), SOLID design, and an **Enhanced DSL** for building terminal applications.

## 🚀 Enhanced DSL Features

- **Layout-focused DSL** with `:four_quadrant`, `:grid`, `:vertical`, `:horizontal` layouts
- **Generic area methods** like `layout.top_left()`, `layout.bottom_right()`
- **Convenience methods** like `Terminal.chat_application()` for common patterns
- **Full architecture integration** (EventLoop, ScreenBuffer, DiffRenderer)
- **Type-safe builders** for widgets and layouts
- **Ruby-style blocks** for elegant configuration

## Architecture Highlights

- Message-driven architecture with immutable messages
- Diff-based rendering to minimize output (no flickering)
- Raw input handling (termios on Unix, VT-mode guard on Windows)
- Color/style convenience DSL (red("text"), bold("text"), styled_line(...))
- Complete widget ecosystem with fluent builders
- Actor-based coordination (EventLoop → ScreenBuffer → DiffRenderer)

Status: **Production Ready** - 27 specs passing, comprehensive DSL documentation.

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

## Quick Start with Enhanced DSL

### Chat Application (Easiest)

```crystal
require "terminal"

app = Terminal.chat_application("My Chat App") do |chat|
  chat.chat_area { |area| area.content("Welcome!") }
  chat.input_area { |input| input.prompt("You: ") }

  chat.on_user_input do |message|
    # Handle user input
    puts "User said: #{message}"
  end

  chat.on_key(:escape) { app.stop }
end

app.start
```

### Custom Layout Application

```crystal
require "terminal"

app = Terminal.application(80, 24) do |builder|
  # Define layout
  builder.layout :four_quadrant do |layout|
    if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
      layout.top_left("main", 70, 80)
      layout.top_right("status", 30, 80)
      layout.bottom_full("input", 3)
    end
  end

  # Create widgets
  builder.text_widget("main") do |text|
    text.content("Main content here")
    text.title("📝 Main")
  end

  builder.text_widget("status") do |text|
    text.content("Status: Ready")
    text.title("📊 Status")
  end

  builder.input_widget("input") do |input|
    input.prompt("Command: ")
  end

  # Handle events
  builder.on_input("input") { |text| puts "Input: #{text}" }
  builder.on_key(:escape) { app.stop }
end

app.start
```

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

## Documentation

- **[DSL Usage Guide](DSL_USAGE_GUIDE.md)** - Complete documentation with examples
- **[Enhanced DSL Demo](examples/enhanced_dsl_demo.cr)** - Working example code
- **[Terminal Architecture](TERMINAL_ARCHITECTURE.md)** - Architecture overview
- **[Windows Dev Box Setup](docs/windows_devbox_setup.md)** - Provision a cloud VM for Windows-specific testing

## Legacy Quick Start (Low-Level API)

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
