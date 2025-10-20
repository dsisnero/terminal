# Terminal UI Library

A production-ready asynchronous terminal UI library built in **Crystal** using SOLID principles, Go-like concurrency (Channels + spawn), dependency injection, and comprehensive test coverage.

## 🚀 Features

- **Actor-based Architecture**: Components communicate via immutable messages over channels
- **Go-style Concurrency**: No shared mutable state, pure message passing
- **Dependency Injection**: Clean separation of concerns with injectable dependencies
- **Full Test Coverage**: Comprehensive unit and integration tests
- **SOLID Principles**: Well-structured, maintainable codebase
- **ANSI Terminal Support**: Full terminal control with cursor management and styling

## 📦 Architecture

### Core Components

- **`InputProvider`**: Handles user input (console, dummy, file implementations)
- **`Dispatcher`**: Routes messages between components
- **`WidgetManager`**: Manages UI widgets and their lifecycle
- **`ScreenBuffer`**: Maintains screen state and computes diffs
- **`DiffRenderer`**: Renders screen changes as ANSI sequences
- **`CursorManager`**: Controls cursor position and visibility
- **`EventLoop`**: Manages fiber lifecycle and coordination
- **`Container`**: Dependency injection container for wiring components

### Message System

All communication happens via immutable message structs defined in `messages.cr`:

```crystal
module Terminal::Msg
  alias Any = Stop | InputEvent | Command | ResizeEvent |
              ScreenUpdate | ScreenDiff | RenderRequest | RenderFrame |
              CursorMove | CursorHide | CursorShow | CursorPosition |
              WidgetEvent
end
```

## 🛠 Installation

Add this to your `shard.yml`:

```yaml
dependencies:
  terminal:
    github: dsisnero/terminal
```

Then run:

```bash
shards install
```

## 📖 Usage

### Basic Example

```crystal
require "terminal"

# Create a terminal instance
terminal = Terminal::Terminal.new

# Start the terminal with a simple widget
terminal.start do |widget_manager|
  # Add your widgets here
  widget_manager.add_widget(MyWidget.new("widget1"))
end
```

### Creating Custom Widgets

```crystal
class MyWidget < Terminal::Widget
  def initialize(@id : String)
  end

  def render : Array(String)
    ["Hello from #{@id}!"]
  end

  def handle(msg : Terminal::Msg::Any) : Terminal::Msg::Any?
    case msg
    when Terminal::Msg::InputEvent
      # Handle input
      nil
    else
      nil
    end
  end
end
```

## 🧪 Testing

The library includes comprehensive tests:

```bash
# Run all tests
crystal spec

# Run specific test files
crystal spec spec/cell_spec.cr
crystal spec spec/dummy_input_provider_spec.cr
```

### Test Coverage

- ✅ **Unit Tests**: Individual component testing
- ✅ **Integration Tests**: Component interaction testing
- ✅ **End-to-End Tests**: Full pipeline validation

## 🏗 Project Structure

```
src/terminal/
├── messages.cr          # Message definitions
├── cell.cr              # Cell type for styled content
├── input_provider.cr    # Input handling interface
├── dummy_input_provider.cr # Test input provider
├── dispatcher.cr        # Message routing
├── widget_manager.cr    # Widget lifecycle management
├── screen_buffer.cr     # Screen state management
├── diff_renderer.cr     # ANSI output generation
├── cursor_manager.cr    # Cursor control
├── event_loop.cr        # Fiber management
└── container.cr         # Dependency injection

spec/
├── cell_spec.cr
├── screen_buffer_spec.cr
├── diff_renderer_spec.cr
├── cursor_manager_spec.cr
├── dummy_input_provider_spec.cr
├── widget_event_routing_spec.cr
└── integration_spec.cr
```

## 🔧 Development

### Prerequisites

- Crystal 1.0+
- Git

### Setup

```bash
git clone https://github.com/dsisnero/terminal.git
cd terminal
shards install
```

### Running Tests

```bash
crystal spec
```

### Code Formatting

```bash
crystal tool format
```

## 📋 Development Status

### ✅ Completed

- Core messaging system
- Cell type implementation
- ScreenBuffer with diff computation
- DiffRenderer with ANSI output
- CursorManager for cursor operations
- WidgetManager with BasicWidget implementation
- EventLoop for fiber management
- Dispatcher for message routing
- DummyInputProvider for testing
- Full test suite (13 tests passing)

### 🔄 In Progress

- Container implementation (dependency injection)
- Demo application

### ⏳ Planned

- Console InputProvider with raw terminal mode
- Styled cells with colors and formatting
- Advanced widgets (TextBox, StatusBar, ListView, Button)
- Supervisor for fault tolerance
- CI/CD pipeline

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by modern terminal UI frameworks
- Built with Crystal's excellent concurrency model
- Following SOLID principles and clean architecture patterns