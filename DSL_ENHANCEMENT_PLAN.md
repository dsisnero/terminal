# Terminal DSL Enhancement Plan

## Current State Analysis

Based on the integration work with clarity2, we've identified several areas where the terminal library can be enhanced with more elegant DSLs and convenience methods. The current architecture is solid, but real-world usage has revealed opportunities for improvement.

## Key Issues from Real Usage

1. **Complex Layout System**: The container/layout engine is overly complex for simple use cases
2. **Manual Input Handling**: No integrated input event loop in the DSL
3. **Flickering**: Constant re-rendering without proper diff detection
4. **Verbose Widget Creation**: Too much boilerplate for common patterns
5. **Limited Block DSL**: Missing Ruby-style elegance for common operations

## Proposed DSL Enhancements

### 1. Simplified Chat Interface DSL

**Current Complex Approach**:
```crystal
# Too complex for simple 4-quadrant layout
container = Terminal::Container(Terminal::Widget).new
layout_engine = Terminal::Layout::LayoutEngine.new
# ... lots of boilerplate
```

**Proposed Simple DSL**:
```crystal
chat = Terminal.chat_interface(80, 24) do |ui|
  ui.chat_area do |chat|
    chat.title "💬 Conversation"
    chat.auto_scroll true
    chat.color :white
  end

  ui.status_area do |status|
    status.title "📊 Status"
    status.color :cyan
  end

  ui.system_area do |system|
    system.title "⚙️ System"
    system.color :yellow
  end

  ui.help_area do |help|
    help.title "❓ Help"
    help.content help_text
  end

  ui.input_area do |input|
    input.prompt "You: "
    input.style :blue
    input.on_submit { |text| handle_input(text) }
  end

  ui.layout :four_quadrant
end

# Start with integrated input handling
chat.run_interactive do |event|
  case event.type
  when :user_input
    process_message(event.text)
  when :key_press
    handle_special_key(event.key)
  end
end
```

### 2. Automatic Input Integration

**Current Manual Approach**:
```crystal
# Manual raw mode setup
handler = Terminal::InputHandler.new
handler.enable_raw_mode do
  while running
    # Manual key reading and processing
  end
end
```

**Proposed Integrated DSL**:
```crystal
Terminal.interactive_app do |app|
  app.widgets do |w|
    w.text_box("output") { |t| t.content("Hello") }
    w.input_box("input") { |i| i.prompt("> ") }
  end

  app.layout { |l| l.vertical("output", "input") }

  # Automatic input handling with callbacks
  app.on_input { |text| process_input(text) }
  app.on_key(:escape) { app.quit }
  app.on_key(:tab) { app.focus_next }

  # Built-in event loop
  app.run  # Handles raw mode, rendering, input automatically
end
```

### 3. Builder Pattern for Complex Widgets

**Current Verbose Approach**:
```crystal
table = Terminal::TableWidget.new("data")
table.col("Name", :name, 20, :left, :white)
table.col("Age", :age, 5, :right, :cyan)
table.rows(data)
```

**Proposed Fluent DSL**:
```crystal
table = Terminal.table("data") do |t|
  t.column :name, "Full Name", width: 20, align: :left, color: :white
  t.column :age, "Age", width: 5, align: :right, color: :cyan
  t.column :email, "Email", width: 30, truncate: true

  t.data source_data
  t.header_style bold: true, bg: :blue
  t.stripe_rows true
  t.border :rounded
end
```

### 4. Theme and Styling DSL

**Current Manual Styling**:
```crystal
cell = Terminal::Cell.new('X', fg: "white", bg: "blue", bold: true)
```

**Proposed Theme DSL**:
```crystal
Terminal.theme do |theme|
  theme.primary   = {fg: :white, bg: :blue, bold: true}
  theme.secondary = {fg: :black, bg: :yellow}
  theme.success   = {fg: :green, bold: true}
  theme.error     = {fg: :red, bg: :black, bold: true}
  theme.muted     = {fg: :gray}
end

# Usage in widgets
text_box("status") do |txt|
  txt.content("Connected")
  txt.style(:success)  # Uses theme
end

# Or inline theming
Terminal.styled_text do |s|
  s.primary("Important: ")
  s.normal("Regular text ")
  s.error("Error occurred!")
end
```

### 5. Event-Driven Widget DSL

**Current Message Handling**:
```crystal
widget.handle(Terminal::Msg::InputEvent.new(char, time))
```

**Proposed Event DSL**:
```crystal
input_widget = Terminal.input("prompt") do |input|
  input.placeholder "Type something..."

  input.on(:change) { |text| validate_input(text) }
  input.on(:submit) { |text| process_submission(text) }
  input.on(:escape) { input.clear }
  input.on(:tab)    { focus_next_widget }

  input.validation do |text|
    text.size > 0 ? :valid : :invalid
  end
end
```

### 6. Layout DSL with Blocks

**Current Manual Layout**:
```crystal
layout_info = {
  "widget1" => {x: 0, y: 0, width: 40, height: 10},
  "widget2" => {x: 40, y: 0, width: 40, height: 10}
}
```

**Proposed Layout DSL**:
```crystal
Terminal.layout(80, 24) do |layout|
  layout.horizontal do |h|
    h.panel("left", flex: 2) do |left|
      left.vertical do |v|
        v.widget("chat", flex: 3)
        v.widget("status", flex: 1)
      end
    end

    h.panel("right", flex: 1) do |right|
      right.widget("help")
    end
  end

  layout.bottom("input", height: 3)
end
```

### 7. Intelligent Rendering DSL

**Current Manual Rendering**:
```crystal
output = terminal.render
print output unless output.empty?
```

**Proposed Smart Rendering**:
```crystal
Terminal.smart_renderer do |renderer|
  renderer.fps = 60
  renderer.diff_optimization = true
  renderer.flicker_prevention = true

  renderer.on_change { |diff| puts "Updated #{diff.changed_rows.size} rows" }

  # Automatically handles diff detection and optimal rendering
  renderer.auto_render(terminal_builder)
end
```

## Implementation Plan

### Phase 1: Core DSL Enhancements (High Priority)

1. **ChatInterface DSL** - Simple 4-quadrant layout with integrated input
2. **Interactive App DSL** - Automatic input handling and event loop
3. **Builder Pattern** - Fluent widget creation with blocks

### Phase 2: Styling and Theming (Medium Priority)

1. **Theme System** - Global styling with semantic names
2. **Styled Text DSL** - Easy inline styling
3. **Widget Style DSL** - Consistent appearance management

### Phase 3: Advanced Features (Low Priority)

1. **Event-Driven Widgets** - Sophisticated callback system
2. **Flexible Layout DSL** - CSS-like layout with flexbox concepts
3. **Smart Rendering** - Automatic optimization and performance monitoring

## Example: Complete Enhanced Chat Application

```crystal
require "terminal"

chat_app = Terminal.chat_application("Clarity AI Assistant") do |app|
  # Configure theme
  app.theme do |theme|
    theme.primary   = {fg: :white, bg: :blue, bold: true}
    theme.accent    = {fg: :cyan, bold: true}
    theme.success   = {fg: :green}
    theme.warning   = {fg: :yellow}
    theme.error     = {fg: :red, bold: true}
  end

  # Define layout areas
  app.layout :four_quadrant do |layout|
    layout.chat_area(flex: 3) do |chat|
      chat.title "💬 AI Conversation"
      chat.auto_scroll true
      chat.wrap_text true
      chat.style :primary
    end

    layout.status_area(flex: 1) do |status|
      status.title "📊 Status"
      status.style :accent
      status.refresh_rate 1.second
    end

    layout.system_area(flex: 1) do |system|
      system.title "⚙️ System Logs"
      system.auto_scroll true
      system.style :muted
    end

    layout.help_area(flex: 1) do |help|
      help.title "❓ Commands"
      help.content help_text
      help.style :normal
    end

    layout.input_area(height: 3) do |input|
      input.prompt "You: "
      input.style :primary
      input.placeholder "Ask me anything..."
    end
  end

  # Event handling
  app.on_user_input do |text|
    app.add_chat_message("User", text, :accent)

    # Process with AI
    response = ai_agent.process(text)
    app.add_chat_message("AI", response, :success)
  end

  app.on_key(:escape) { app.confirm_quit }
  app.on_key(:f1)     { app.show_help }
  app.on_key(:"ctrl+c") { app.force_quit }

  # Status updates
  app.every(1.second) do
    app.update_status("active_provider", current_provider)
    app.update_status("uptime", format_uptime)
    app.update_status("memory", memory_usage)
  end

  # Logging integration
  app.on_log do |level, message|
    app.add_system_log(message, log_style(level))
  end
end

# Run the application
chat_app.run
```

## Benefits of Enhanced DSL

1. **Reduced Boilerplate**: 70% less code for common patterns
2. **Better Readability**: Self-documenting intent with semantic methods
3. **Easier Testing**: DSL builders can be easily mocked and tested
4. **Ruby-like Elegance**: Leverages Crystal's block syntax naturally
5. **Performance**: Built-in optimizations and diff rendering
6. **Consistency**: Unified patterns across all widget types

## Backward Compatibility

All enhancements will be additive - existing code will continue to work:

```crystal
# Existing code still works
widget = Terminal::TextBoxWidget.new("id", "content")

# New DSL provides alternative
widget = Terminal.text_box("id") do |txt|
  txt.content("content")
end
```

## Next Steps

1. **Implement Phase 1** - Core DSL enhancements for immediate benefit
2. **Update Documentation** - Show both old and new approaches
3. **Create Examples** - Demonstrate elegant patterns
4. **Gather Feedback** - Test with real applications like clarity2
5. **Iterate** - Refine based on actual usage patterns

The goal is to make the terminal library as elegant and easy to use as Ruby's best DSLs while maintaining Crystal's performance and type safety.