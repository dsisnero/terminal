# AGENTS.md - AI Coding Assistant Guide for Terminal Library

## Agent Behavior

When working on this terminal library codebase:

- **Use Enhanced DSL** - Always prefer the new DSL over low-level APIs
- **Run tests** after changes: `crystal spec` or specific spec files
- **Check build** after changes: `crystal build src/terminal.cr`
- **Format code**: `crystal tool format`
- **Reference documentation**: Check `DSL_USAGE_GUIDE.md` for DSL patterns

## Enhanced DSL Guidelines for Agents

### ✅ ALWAYS Use Enhanced DSL

When creating terminal applications, **ALWAYS** use the Enhanced DSL:

```crystal
# ✅ Correct - Use Enhanced DSL
app = Terminal.application(80, 24) do |builder|
  builder.layout :four_quadrant do |layout|
    if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
      layout.top_left("main")
    end
  end
  builder.text_widget("main") { |t| t.content("Hello") }
end

# ✅ Correct - Use Chat Convenience DSL
app = Terminal.chat_application("Chat") do |chat|
  chat.chat_area { |a| a.content("Welcome") }
  chat.input_area { |i| i.prompt("You: ") }
end
```

### ❌ DON'T Use Low-Level APIs

```crystal
# ❌ Wrong - Don't use low-level APIs
widget = Terminal::BasicWidget.new("id", "content")
manager = Terminal::WidgetManager.new([widget])
# This bypasses the Enhanced DSL benefits
```

### Required Patterns for DSL

1. **Always include terminal library**:
   ```crystal
   require "terminal"  # or require "../src/terminal"
   ```

2. **Use type checking for layouts**:
   ```crystal
   builder.layout :four_quadrant do |layout|
     if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
       # Use layout methods here
     end
   end
   ```

3. **Create widgets for all areas**:
   ```crystal
   layout.top_left("main")
   builder.text_widget("main") { |t| t.content("Content") }
   ```

4. **Handle events properly**:
   ```crystal
   builder.on_input("input") { |text| puts text }
   builder.on_key(:escape) { app.stop }
   ```

## Commands

- **Test DSL**: `crystal spec spec/application_dsl_spec.cr`
- **Test convenience**: `crystal spec spec/dsl_convenience_spec.cr`
- **Test integration**: `crystal spec spec/enhanced_dsl_integration_spec.cr`
- **Test all**: `crystal spec`
- **Build library**: `crystal build src/terminal.cr`
- **Run demo**: `crystal run examples/enhanced_dsl_demo.cr`
- **Format code**: `crystal tool format`

### Language & Version

- **Language**: Crystal (>= 1.17.1)
- **Project Name**: Terminal UI Library
- **DSL Architecture**: Message-driven actors (EventLoop, ScreenBuffer, DiffRenderer)

## Code Style for DSL

- **Layout First**: Always define layout before widgets
- **Type Safety**: Use `is_a?()` checks for layout builders
- **Widget Matching**: Create widgets for all defined layout areas
- **Event Handling**: Always provide escape/quit mechanisms
- **Naming**: Use descriptive area names like "chat", "status", "input"

### DSL Conventions

```crystal
# ✅ Good DSL patterns
Terminal.chat_application("App Name") do |chat|
  chat.chat_area { |area| area.title("💬 Chat") }
  chat.input_area { |input| input.prompt("User: ") }
  chat.on_user_input { |text| handle_input(text) }
  chat.on_key(:escape) { app.stop }
end

# ✅ Good custom layout
Terminal.application(80, 24) do |builder|
  builder.layout :four_quadrant do |layout|
    if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
      layout.top_left("main", 70, 80)
      layout.bottom_full("input", 3)
    end
  end

  builder.text_widget("main") do |text|
    text.content("Content")
    text.title("📝 Title")
    text.auto_scroll(true)
  end

  builder.input_widget("input") do |input|
    input.prompt("Command: ")
  end
end
```

### Error Prevention for Agents

**❌ Don't do this:**
```crystal
# Missing type check - will fail
builder.layout :four_quadrant do |layout|
  layout.top_left("main")  # Compile error
end

# Missing widget - runtime error
layout.top_left("main")
# No builder.text_widget("main")

# Manual output - breaks architecture
puts "output"  # Causes flickering
```

**✅ Do this:**
```crystal
# Proper type checking
if layout.is_a?(Terminal::ApplicationDSL::FourQuadrantLayout)
  layout.top_left("main")
end

# Widget for every area
builder.text_widget("main") { |t| t.content("Content") }

# Use DSL for output
builder.text_widget("output") { |t| t.content("Message") }
```

## Testing DSL Code

Always test DSL implementations:

```crystal
describe "My DSL Usage" do
  it "creates application correctly" do
    app = Terminal.application(80, 24) do |builder|
      # Your DSL code here
    end

    app.should be_a(Terminal::TerminalApplication(Terminal::Widget))
  end
end
```

## Integration with Other Projects

When integrating this terminal library into other projects (like Clarity2):

1. **Add dependency** to `shard.yml`:
   ```yaml
   dependencies:
     terminal:
       github: dsisnero/terminal
   ```

2. **Use Enhanced DSL patterns**:
   ```crystal
   require "terminal"

   app = Terminal.chat_application("Clarity AI") do |chat|
     # Configure chat interface
   end
   ```

3. **Follow agent guidelines** from this AGENTS.md file

## Documentation References

- **[DSL Usage Guide](DSL_USAGE_GUIDE.md)** - Complete DSL documentation
- **[Enhanced DSL Demo](examples/enhanced_dsl_demo.cr)** - Working examples
- **[Terminal Architecture](TERMINAL_ARCHITECTURE.md)** - Architecture details

## Recent Major Accomplishments

- ✅ Enhanced DSL with layout-focused approach (:four_quadrant, etc.)
- ✅ Generic area methods (top_left, bottom_right, etc.)
- ✅ Full architecture integration (EventLoop, ScreenBuffer, DiffRenderer)
- ✅ Convenience methods (Terminal.chat_application)
- ✅ Comprehensive testing (27 specs passing)
- ✅ Type-safe builders and proper error prevention
- ✅ Complete documentation and examples
