# Terminal DSL Usage Guide

## Overview

The Terminal library provides a powerful DSL for creating terminal-based applications with full architecture integration. This guide shows how to use the DSL correctly and provides examples for common patterns.

## Quick Start

### Basic Application

```crystal
require "terminal"

app = Terminal.application(80, 24) do |builder|
  # Define layout first
  builder.layout :four_quadrant do |layout|
    if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
      layout.top_left("main", 70, 80)
      layout.top_right("status", 30, 80)
      layout.bottom_full("input", 3)
    end
  end

  # Create widgets for each area
  builder.text_widget("main") do |text|
    text.content("Welcome to the application!")
    text.title("📝 Main")
    text.auto_scroll(true)
  end

  builder.text_widget("status") do |text|
    text.content("Status: Ready")
    text.title("📊 Status")
    text.color(:cyan)
  end

  builder.input_widget("input") do |input|
    input.prompt("Command: ")
    input.placeholder("Type here...")
  end

  # Handle events
  builder.on_input("input") do |text|
    # Process user input
    puts "User entered: #{text}"
  end

  builder.on_key("escape") do
    # Exit application
    app.stop if app
  end
end

# Start the application
app.start
```

### Chat Application (Convenience Method)

```crystal
require "terminal"

app = Terminal.chat_application("My Chat App", 80, 24) do |chat|
  # Pre-configured four-quadrant layout for chat
  chat.chat_area do |area|
    area.content("Welcome to the chat!")
    area.auto_scroll(true)
  end

  chat.status_area do |area|
    area.content("Connected")
  end

  chat.system_area do |area|
    area.content("System ready")
  end

  chat.input_area do |input|
    input.prompt("Say: ")
  end

  chat.on_user_input do |text|
    # Handle chat message
    puts "Chat message: #{text}"
  end

  chat.on_key(:escape) do
    app.stop if app
  end
end

app.start
```

## Layout Types

### Four Quadrant Layout (Recommended for Chat Apps)

```crystal
builder.layout :four_quadrant do |layout|
  if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
    layout.top_left("main_area", width_percent, height_percent)
    layout.top_right("sidebar", width_percent, height_percent)
    layout.bottom_left("logs", width_percent, height_percent)
    layout.bottom_right("help", width_percent, height_percent)
    layout.bottom_full("input", height_lines)  # Spans full width
    layout.top_full("header", height_lines)    # Spans full width
  end
end
```

### Grid Layout

```crystal
builder.layout :grid do |layout|
  if layout.is_a?(Terminal::ApplicationDSL::GridLayout)
    layout.configure(rows: 3, cols: 2)
    layout.cell("cell1", row: 0, col: 0)
    layout.cell("cell2", row: 0, col: 1)
    layout.cell("cell3", row: 1, col: 0, colspan: 2)  # Spans 2 columns
  end
end
```

### Vertical Layout

```crystal
builder.layout :vertical do |layout|
  if layout.is_a?(Terminal::ApplicationDSL::VerticalLayout)
    layout.section("header", height: 5)
    layout.section("main", height: 15)
    layout.section("footer", height: 3)
  end
end
```

### Horizontal Layout

```crystal
builder.layout :horizontal do |layout|
  if layout.is_a?(Terminal::ApplicationDSL::HorizontalLayout)
    layout.section("sidebar", width: 20)
    layout.section("main", width: 50)
    layout.section("details", width: 10)
  end
end
```

## Widget Builders

### Text Widget

```crystal
builder.text_widget("widget_id") do |text|
  text.content("Initial text content")
  text.title("🏷️ Widget Title")
  text.color(:blue)           # :red, :green, :blue, :yellow, :magenta, :cyan, :white
  text.auto_scroll(true)      # Automatically scroll to bottom
  text.border_style(:single)  # :single, :double, :rounded
end
```

### Input Widget

```crystal
builder.input_widget("input_id") do |input|
  input.prompt("Enter text: ", "blue")
  input.placeholder("Type something...")
  input.max_length(100)
  input.multiline(false)
end
```

## Event Handling

### Input Events

```crystal
# Handle input from specific widget
builder.on_input("input_widget_id") do |text|
  puts "User entered: #{text}"
end

# Handle input with context
builder.on_input("chat_input") do |text|
  if text.starts_with?("/")
    handle_command(text)
  else
    send_message(text)
  end
end
```

### Key Events

```crystal
# Handle specific keys
builder.on_key("escape") { app.stop }
builder.on_key("f1") { show_help }
builder.on_key("ctrl+c") { graceful_shutdown }

# Handle key combinations
builder.on_key("ctrl+s") { save_data }
builder.on_key("ctrl+q") { quit_app }
```

### Periodic Events

```crystal
# Update every second
builder.every(1.second) do
  update_status
  refresh_display
end

# Auto-save every 30 seconds
builder.every(30.seconds) do
  save_state
end
```

### Application Lifecycle

```crystal
builder.on_start do
  puts "Application starting..."
  load_initial_data
end

builder.on_stop do
  puts "Application stopping..."
  cleanup_resources
end
```

## Architecture Integration

The DSL automatically integrates with the full terminal architecture:

- **EventLoop**: Handles all events and coordination
- **ScreenBuffer**: Manages screen state and diff computation
- **DiffRenderer**: Outputs only changed parts (no flickering)
- **WidgetManager**: Coordinates widget rendering and input
- **CursorManager**: Handles cursor positioning

This means:
- ✅ No manual screen clearing or flickering
- ✅ Efficient rendering (only diffs are drawn)
- ✅ Proper event coordination
- ✅ Automatic layout management
- ✅ Thread-safe operations

## Common Patterns

### Chat Interface

```crystal
Terminal.chat_application("AI Assistant") do |chat|
  chat.chat_area do |area|
    area.title("💬 Conversation")
    area.auto_scroll(true)
  end

  chat.status_area do |area|
    area.title("📊 Status")
    area.content("Ready")
  end

  chat.input_area do |input|
    input.prompt("You: ")
  end

  chat.on_user_input do |message|
    # Add user message to chat
    chat.add_message("User", message)

    # Process with AI (example)
    response = process_with_ai(message)
    chat.add_message("AI", response)
  end
end
```

### Dashboard Application

```crystal
Terminal.application(120, 30) do |builder|
  builder.layout :grid do |layout|
    if layout.is_a?(Terminal::ApplicationDSL::GridLayout)
      layout.configure(rows: 2, cols: 3)
      layout.cell("metrics", 0, 0)
      layout.cell("logs", 0, 1, colspan: 2)
      layout.cell("status", 1, 0)
      layout.cell("alerts", 1, 1)
      layout.cell("controls", 1, 2)
    end
  end

  # Create dashboard widgets...
end
```

### Form Application

```crystal
Terminal.application(80, 24) do |builder|
  builder.layout :vertical do |layout|
    if layout.is_a?(Terminal::ApplicationDSL::VerticalLayout)
      layout.section("header", 3)
      layout.section("form", 18)
      layout.section("status", 3)
    end
  end

  # Create form widgets...
end
```

## For AI Agents and Automated Usage

### Required Patterns

When integrating this DSL into other codebases or AI agents, follow these patterns:

1. **Always require the library first**:
   ```crystal
   require "terminal"
   ```

2. **Use type checking for layouts** (Crystal requirement):
   ```crystal
   builder.layout :four_quadrant do |layout|
     if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
       # Use layout methods here
     end
   end
   ```

3. **Create widgets for all layout areas**:
   ```crystal
   # If you define an area, create a widget for it
   layout.top_left("main")
   builder.text_widget("main") { |t| t.content("Content") }
   ```

4. **Handle events appropriately**:
   ```crystal
   builder.on_input("input") do |text|
     # Process input
   end

   builder.on_key("escape") do
     app.stop if app  # Proper cleanup
   end
   ```

### Agent Integration Checklist

- [ ] Include `require "terminal"` in source files
- [ ] Use `Terminal.application` or `Terminal.chat_application` entry points
- [ ] Apply type checking with `is_a?()` for layout builders
- [ ] Create widgets for all defined layout areas
- [ ] Add event handlers for input and key events
- [ ] Call `app.start` to begin the application
- [ ] Provide exit mechanisms (escape key, quit commands)

### Error Prevention

**❌ Don't do this:**
```crystal
# Missing type check
builder.layout :four_quadrant do |layout|
  layout.top_left("main")  # Will fail at compile time
end

# Missing widget for area
layout.top_left("main")
# No corresponding text_widget("main") - will cause runtime error

# Manual rendering
puts "manual output"  # Bypasses architecture, causes flickering
```

**✅ Do this:**
```crystal
# Proper type checking
builder.layout :four_quadrant do |layout|
  if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
    layout.top_left("main")
  end
end

# Widget for every area
builder.text_widget("main") { |t| t.content("Content") }

# Use DSL methods only
builder.text_widget("output") { |t| t.content("Proper output") }
```

## Examples

See the following example files for complete working applications:

- `examples/enhanced_dsl_demo.cr` - Complete DSL demonstration
- `examples/chat_application_demo.cr` - Chat interface example
- `examples/dashboard_demo.cr` - Dashboard layout example
- `spec/enhanced_dsl_integration_spec.cr` - Integration test examples

## Testing

The DSL includes comprehensive specs:

```bash
# Run DSL tests
crystal spec spec/application_dsl_spec.cr
crystal spec spec/dsl_convenience_spec.cr
crystal spec spec/enhanced_dsl_integration_spec.cr

# Run all tests
crystal spec
```

## Build and Compilation

```bash
# Build library
crystal build src/terminal.cr

# Build with optimization
crystal build --release src/terminal.cr

# Format code
crystal tool format
```

## Troubleshooting

### Common Issues

1. **"undefined method 'layout'"**
   - Ensure `require "terminal"` is included
   - Check that DSL files are properly loaded

2. **"undefined method 'top_left'"**
   - Add proper type checking with `is_a?()`
   - Use the correct layout class name

3. **Runtime errors about missing widgets**
   - Create widgets for all defined layout areas
   - Check widget IDs match layout area names

4. **Flickering or rendering issues**
   - Don't use manual `puts` or `print` statements
   - Use only DSL widget methods for output

### Getting Help

- Check the specs for usage examples
- Review the example files in `examples/`
- Ensure Crystal version >= 1.17.1
- Verify all required dependencies are installed with `shards install`

## Architecture Notes

This DSL is built on a message-driven actor architecture:

- **EventLoop**: Central coordinator for all operations
- **ScreenBuffer**: Maintains current screen state
- **DiffRenderer**: Computes and renders only changes
- **WidgetManager**: Manages widget lifecycle and input routing
- **Message System**: All communication via typed messages

This ensures thread-safety, efficient rendering, and proper event coordination without manual management.